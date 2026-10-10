// lib/features/shared/widgets/web_camera_capture_web.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

// navigator.vibrate isn't exposed by dart:html — bind it directly. Supported on
// Android browsers; a no-op / throw elsewhere (callers wrap in try/catch).
@JS('navigator.vibrate')
external JSAny? _navigatorVibrate(JSNumber ms);

class CapturedPhotoBytes {
  final Uint8List bytes;
  final String fileName;
  final String contentType;

  CapturedPhotoBytes({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });
}

/// ✅ Works for image + video content types.
/// - strips codecs: "video/webm;codecs=vp8,opus" => "video/webm"
String normalizeContentType(String? ct) {
  var v = (ct ?? '').trim().toLowerCase();
  if (v.isEmpty) return '';

  final semi = v.indexOf(';');
  if (semi >= 0) v = v.substring(0, semi).trim();

  if (v == 'video/quicktime') return 'video/quicktime';
  if (v == 'video/m4v') return 'video/mp4';
  if (v.startsWith('video/')) return v;

  if (v.contains('jpeg') || v.contains('jpg')) return 'image/jpeg';
  if (v.contains('png')) return 'image/png';
  if (v.contains('webp')) return 'image/webp';
  if (v.startsWith('image/')) return v;

  return '';
}

Future<CapturedPhotoBytes?> capturePhotoBytesViaPopup(BuildContext context) async {
  return showDialog<CapturedPhotoBytes?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _WebCameraCaptureDialog(),
  );
}

class _WebCameraCaptureDialog extends StatefulWidget {
  const _WebCameraCaptureDialog();

  @override
  State<_WebCameraCaptureDialog> createState() => _WebCameraCaptureDialogState();
}

class _WebCameraCaptureDialogState extends State<_WebCameraCaptureDialog> {
  html.MediaStream? _stream;
  html.VideoElement? _video;

  String? _error;

  bool _ready = false;
  bool _busy = false; // capture/finalize in progress

  Uint8List? _captured; // frozen preview bytes

  double _zoom = 1.0;
  double _pinchStartZoom = 1.0;
  static const double _kMinZoom = 1.0;
  static const double _kMaxZoom = 4.0;

  bool _flash = false; // shutter flash overlay
  bool _shutterDown = false; // shutter button pressed state

  late final String _viewType;
  static int _seq = 0;

  StreamSubscription? _subLoadedMetadata;
  StreamSubscription? _subCanPlay;

  @override
  void initState() {
    super.initState();
    _viewType = 'webcam_photo_view_${_seq++}';
    _setup();
  }

  Future<void> _setup() async {
    try {
      final devices = html.window.navigator.mediaDevices;
      // Browsers hide mediaDevices entirely on non-secure origins (plain http://
      // on a LAN IP) — say so instead of a generic 'not supported'.
      if (devices == null) {
        throw Exception(html.window.isSecureContext == false
            ? 'Camera requires a secure connection (HTTPS). Open the site over https:// and try again.'
            : 'mediaDevices not supported');
      }

      final video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..controls = false;

      video.setAttribute('playsinline', 'true');
      video.setAttribute('webkit-playsinline', 'true');

      // The preview box is laid out at the capture aspect (4:3), so
      // object-fit: cover center-crops the stream exactly like
      // _captureVisibleFrame does — the viewfinder shows what gets saved.
      video.style.width = '100%';
      video.style.height = '100%';
      video.style.objectFit = 'cover';
      video.style.pointerEvents = 'none'; // pinch-zoom is handled by Flutter

      // Clip wrapper so the CSS zoom (transform: scale) stays inside the box.
      final wrapper = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = 'black'
        ..append(video);

      _video = video;

      final stream = await devices.getUserMedia({
        'video': {
          'facingMode': {'ideal': 'environment'},
          'width': {'ideal': 1920},
          'height': {'ideal': 1080},
        },
        'audio': false,
      });

      _stream = stream;
      video.srcObject = stream;

      try {
        // ignore: discarded_futures
        video.play();
      } catch (_) {}

      ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) => wrapper);

      await _waitForVideoReady(video);

      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      await _stopStream();
      if (!mounted) return;
      setState(() => _error = _friendlyError('$e'));
    }
  }

  String _friendlyError(String raw) {
    final v = raw.toLowerCase();
    if (v.contains('notallowed') || v.contains('permission')) {
      return 'Camera permission denied. Allow camera access in Safari settings and try again.';
    }
    if (v.contains('notfound')) return 'No camera found on this device.';
    if (v.contains('notreadable')) return 'Camera is in use by another app/browser.';
    if (v.contains('https') || v.contains('secure')) {
      return 'Camera requires HTTPS. Open the site on https://';
    }
    return raw;
  }

  Future<void> _waitForVideoReady(html.VideoElement video) async {
    if (video.videoWidth > 0 && video.videoHeight > 0) return;

    final c = Completer<void>();
    void done() {
      if (!c.isCompleted) c.complete();
    }

    _subLoadedMetadata = video.onLoadedMetadata.listen((_) => done());
    _subCanPlay = video.onCanPlay.listen((_) => done());

    Future.delayed(const Duration(seconds: 3), () {
      if (!c.isCompleted) c.complete();
    });

    await c.future;
    await _subLoadedMetadata?.cancel();
    await _subCanPlay?.cancel();
    _subLoadedMetadata = null;
    _subCanPlay = null;
  }

  Future<html.Blob> _canvasToBlob(html.CanvasElement canvas, String mime, double quality) async {
    final html.Blob? b = await canvas.toBlob(mime, quality);
    if (b == null) throw Exception('Failed to create blob');
    return b;
  }

  Future<Uint8List> _blobToBytes(html.Blob blob) async {
    final c = Completer<Uint8List>();
    final reader = html.FileReader();

    reader.onLoad.listen((_) {
      final r = reader.result;
      if (r is ByteBuffer) c.complete(Uint8List.view(r));
      else if (r is Uint8List) c.complete(r);
      else c.completeError(Exception('Unexpected FileReader result type: ${r.runtimeType}'));
    });

    reader.onError.listen((_) {
      c.completeError(reader.error ?? Exception('Failed to read blob'));
    });

    reader.readAsArrayBuffer(blob);
    return c.future;
  }

  /// Capture at a fixed 4:3 aspect ratio regardless of device orientation.
  /// Ignores the preview container size so portrait and landscape shots
  /// always produce the same shape output (1440 × 1080 px).
  Future<Uint8List> _captureVisibleFrame() async {
    final video = _video!;
    final vw = (video.videoWidth  > 0) ? video.videoWidth.toDouble()  : 1920.0;
    final vh = (video.videoHeight > 0) ? video.videoHeight.toDouble() : 1080.0;

    // Always output 4:3 landscape — consistent across portrait/landscape capture
    const kAspect = 4.0 / 3.0;
    const kOutW   = 1440;
    const kOutH   = 1080;

    // Center-crop the raw video frame to kAspect, then shrink by zoom factor.
    double cropW, cropH;
    if (vw / vh >= kAspect) {
      // Video wider than 4:3 — constrain by height, trim sides
      cropH = vh / _zoom;
      cropW = cropH * kAspect;
    } else {
      // Video taller than 4:3 — constrain by width, trim top/bottom
      cropW = vw / _zoom;
      cropH = cropW / kAspect;
    }

    final sx = (vw - cropW) / 2.0;
    final sy = (vh - cropH) / 2.0;

    final canvas = html.CanvasElement(width: kOutW, height: kOutH);
    canvas.context2D.drawImageScaledFromSource(
      video,
      sx.clamp(0.0, vw), sy.clamp(0.0, vh),
      cropW.clamp(1.0, vw), cropH.clamp(1.0, vh),
      0, 0, kOutW.toDouble(), kOutH.toDouble(),
    );

    final blob = await _canvasToBlob(canvas, 'image/jpeg', 0.92);
    return _blobToBytes(blob);
  }

  Future<void> _stopStream() async {
    try {
      final s = _stream;
      if (s != null) {
        for (final t in s.getTracks()) {
          try {
            t.stop();
          } catch (_) {}
        }
      }
      _stream = null;

      try {
        _video?.pause();
      } catch (_) {}

      _video?.srcObject = null;
      // Tell browser to fully release camera hardware
      try {
        _video?.load();
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _onCapturePressed() async {
    if (_busy || !_ready || _video == null) return;

    // Instant shutter feedback (like a native camera): freeze the frame,
    // flash, and a short vibration (Android) — all before the JPEG encode,
    // which can take a few hundred ms on phones.
    try {
      _video?.pause();
    } catch (_) {}
    try {
      _navigatorVibrate(40.toJS);
    } catch (_) {}
    setState(() {
      _busy = true;
      _flash = true;
    });
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) setState(() => _flash = false);
    });

    try {
      // Drawing from the paused video captures exactly the frozen frame.
      final bytes = await _captureVisibleFrame();

      if (!mounted) return;
      setState(() => _captured = bytes);
    } catch (e) {
      // Resume the live preview so the user can try again.
      try {
        // ignore: discarded_futures
        _video?.play();
      } catch (_) {}
      if (!mounted) return;
      setState(() => _error = 'Capture failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retake() async {
    if (_busy) return;
    setState(() => _captured = null);
    try {
      // Resume live preview
      // ignore: discarded_futures
      _video?.play();
    } catch (_) {}
  }

  Future<void> _usePhoto() async {
    if (_busy || _captured == null) return;

    setState(() => _busy = true);

    try {
      final bytes = _captured!;
      final fileName = 'capture_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _stopStream();

      if (!mounted) return;
      Navigator.pop(
        context,
        CapturedPhotoBytes(bytes: bytes, fileName: fileName, contentType: 'image/jpeg'),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to finalize photo: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (_busy) return false;
    await _stopStream();
    return true;
  }

  void _setZoom(double z) {
    z = z.clamp(_kMinZoom, _kMaxZoom).toDouble();
    setState(() => _zoom = z);
    _video?.style.transform = 'scale($z)';
    _video?.style.transformOrigin = 'center';
  }

  Future<void> _close() async {
    if (_busy) return;
    await _stopStream();
    if (!mounted) return;
    Navigator.pop(context, null);
  }

  @override
  void dispose() {
    _subLoadedMetadata?.cancel();
    _subCanPlay?.cancel();
    // ignore: discarded_futures
    _stopStream();
    super.dispose();
  }

  /// Capture aspect — must match _captureVisibleFrame (1440 × 1080).
  static const double _kAspect = 4.0 / 3.0;

  /// The viewfinder: a 4:3 box (letterboxed in black, like a native camera's
  /// 4:3 mode) showing exactly the region that gets saved. After capture the
  /// frozen photo is shown in the same box, so review matches the preview.
  Widget _viewfinder() {
    return Center(
      child: AspectRatio(
        aspectRatio: _kAspect,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_ready)
                HtmlElementView(viewType: _viewType)
              else if (_error == null)
                const Center(child: CircularProgressIndicator()),

              if (_ready && _captured == null) ...[
                // Pinch-to-zoom over the live preview.
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onScaleStart: (_) => _pinchStartZoom = _zoom,
                  onScaleUpdate: (d) {
                    if (d.pointerCount >= 2) _setZoom(_pinchStartZoom * d.scale);
                  },
                ),
                const IgnorePointer(child: CustomPaint(painter: _GridPainter())),
              ],

              if (_captured != null)
                Image.memory(_captured!, fit: BoxFit.cover, gaplessPlayback: true),

              // Shutter flash.
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _flash ? 0.85 : 0.0,
                  duration: Duration(milliseconds: _flash ? 0 : 200),
                  child: const ColoredBox(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _zoomChips() {
    // The preset nearest the current zoom is highlighted; while pinching
    // between presets it shows the live value (like native "1.4×").
    final nearest = _zoom < 1.5 ? 1.0 : (_zoom < 3.0 ? 2.0 : 4.0);

    Widget chip(double z) {
      final active = nearest == z;
      final exact = (_zoom - z).abs() < 0.05;
      final label = (active && !exact) ? '${_zoom.toStringAsFixed(1)}×' : '${z.toStringAsFixed(0)}×';
      return GestureDetector(
        onTap: () => _setZoom(z),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.amber : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [chip(1), chip(2), chip(4)],
    );
  }

  Widget _shutterButton() {
    final enabled = _ready && !_busy;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _shutterDown = true) : null,
      onTapCancel: () => setState(() => _shutterDown = false),
      onTapUp: (_) => setState(() => _shutterDown = false),
      onTap: enabled ? _onCapturePressed : null,
      child: Container(
        width: 78,
        height: 78,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: AnimatedScale(
          scale: _shutterDown ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 90),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (enabled || _busy) ? Colors.white : Colors.white38,
            ),
            child: _busy
                ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black54),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _reviewButtons({required bool vertical}) {
    final retake = OutlinedButton(
      onPressed: _busy ? null : _retake,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      ),
      child: const Text('Retake'),
    );
    final use = ElevatedButton(
      onPressed: _busy ? null : _usePhoto,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      ),
      child: const Text('Use Photo'),
    );
    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [use, const SizedBox(height: 12), retake],
      );
    }
    return Row(
      children: [
        Expanded(child: retake),
        const SizedBox(width: 12),
        Expanded(child: use),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReview = _captured != null;
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;

    final topBar = Row(
      children: [
        IconButton(
          onPressed: _busy ? null : _close,
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        const SizedBox(width: 6),
        const Text(
          'Camera',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ],
    );

    final error = _error == null
        ? const SizedBox.shrink()
        : Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
            ),
            child: Text(_error!, style: const TextStyle(color: Colors.white)),
          );

    // Portrait: top bar / viewfinder / zoom + shutter below (native layout).
    // Landscape: viewfinder on the left, controls in a side column so the
    // preview keeps as much height as possible.
    final Widget body;
    if (!landscape) {
      body = Column(
        children: [
          topBar,
          error,
          Expanded(child: _viewfinder()),
          SizedBox(
            height: 64,
            child: Center(child: (_ready && !isReview) ? _zoomChips() : null),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: SizedBox(
              height: 84,
              child: Center(child: isReview ? _reviewButtons(vertical: false) : _shutterButton()),
            ),
          ),
        ],
      );
    } else {
      body = Row(
        children: [
          Expanded(
            child: Column(
              children: [
                topBar,
                error,
                Expanded(child: _viewfinder()),
              ],
            ),
          ),
          SizedBox(
            width: 160,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: isReview
                  ? [Padding(padding: const EdgeInsets.all(12), child: _reviewButtons(vertical: true))]
                  : [
                      if (_ready) FittedBox(fit: BoxFit.scaleDown, child: _zoomChips()),
                      const SizedBox(height: 20),
                      _shutterButton(),
                    ],
            ),
          ),
        ],
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: SizedBox(
          width: double.infinity,
          height: size.height,
          child: SafeArea(child: body),
        ),
      ),
    );
  }
}

/// Rule-of-thirds grid over the viewfinder (as in native camera apps).
class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    for (var i = 1; i <= 2; i++) {
      final x = size.width * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}
