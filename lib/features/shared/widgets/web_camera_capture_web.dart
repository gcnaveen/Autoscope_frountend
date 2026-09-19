// lib/features/shared/widgets/web_camera_capture_web.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

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
      if (devices == null) throw Exception('mediaDevices not supported');

      final video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..controls = false;

      video.setAttribute('playsinline', 'true');
      video.setAttribute('webkit-playsinline', 'true');

      // make it like native camera: fill screen
      video.style.width = '100%';
      video.style.height = '100%';
      video.style.objectFit = 'cover';

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

      ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) => video);

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

    setState(() => _busy = true);

    try {
      final bytes = await _captureVisibleFrame();

      // Freeze preview like native camera
      try {
        _video?.pause();
      } catch (_) {}

      if (!mounted) return;
      setState(() => _captured = bytes);
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final isReview = _captured != null;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.sizeOf(context).height,
          child: Stack(
            children: [
              // Live preview
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: _ready
                      ? HtmlElementView(viewType: _viewType)
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),

              // Crop-boundary guide (live preview only — matches _captureVisibleFrame's math)
              if (_ready && !isReview)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _CropGuidePainter(
                        videoWidth: (_video?.videoWidth ?? 0) > 0
                            ? _video!.videoWidth.toDouble()
                            : 1920.0,
                        videoHeight: (_video?.videoHeight ?? 0) > 0
                            ? _video!.videoHeight.toDouble()
                            : 1080.0,
                        zoom: _zoom,
                      ),
                    ),
                  ),
                ),

              // Frozen captured preview overlay
              if (_captured != null)
                Positioned.fill(
                  child: Image.memory(
                    _captured!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),

              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
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
                        const Spacer(),
                        if (_busy)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Error overlay
              if (_error != null)
                Positioned(
                  left: 12,
                  right: 12,
                  top: 80,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.25)),
                    ),
                    child: Text(_error!, style: const TextStyle(color: Colors.white)),
                  ),
                ),

              // Zoom slider (only while live preview is active)
              if (_ready && !isReview)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 120,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_zoom.toStringAsFixed(1)}×',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          shadows: [Shadow(blurRadius: 4)],
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbColor: Colors.white,
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white38,
                          overlayColor: Colors.white24,
                          trackHeight: 5,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 26),
                        ),
                        child: Slider(
                          value: _zoom,
                          min: 1.0,
                          max: 4.0,
                          divisions: 30,
                          onChanged: _setZoom,
                        ),
                      ),
                    ],
                  ),
                ),

              // Bottom controls (native-like)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                    child: isReview
                        ? Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _busy ? null : _retake,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white54),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text('Retake'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _busy ? null : _usePhoto,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text('Use Photo'),
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: GestureDetector(
                              onTap: (_ready && !_busy) ? _onCapturePressed : null,
                              child: Container(
                                width: 74,
                                height: 74,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.15),
                                  border: Border.all(color: Colors.white, width: 4),
                                ),
                                child: const Center(
                                  child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: 30),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws a live crop-boundary guide (dim mask + border + rule-of-thirds grid +
/// corner brackets) over the camera preview, so what the user frames matches
/// what `_captureVisibleFrame` actually outputs.
///
/// This mirrors `_captureVisibleFrame`'s math exactly:
///  - The video element is rendered with `object-fit: cover` into the
///    preview box, then scaled by `zoom` via a CSS `transform: scale(zoom)`
///    centered on itself. That determines how much of the native video
///    frame (`videoWidth` x `videoHeight`) is actually visible on screen.
///  - `_captureVisibleFrame` separately center-crops the native frame to a
///    fixed 4:3 aspect ratio, shrunk by the same `zoom` factor.
///  - Mapping that capture-crop rectangle into on-screen coordinates (using
///    the same center + cover-fit + zoom math as the live preview) gives a
///    rectangle that is always centered in the preview, whose size relative
///    to the preview box is `cropSize / visibleNativeSize` on each axis.
class _CropGuidePainter extends CustomPainter {
  final double videoWidth;
  final double videoHeight;
  final double zoom;

  const _CropGuidePainter({
    required this.videoWidth,
    required this.videoHeight,
    required this.zoom,
  });

  static const double _kAspect = 4.0 / 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final containerW = size.width;
    final containerH = size.height;
    if (containerW <= 0 || containerH <= 0) return;

    final vw = videoWidth > 0 ? videoWidth : 1920.0;
    final vh = videoHeight > 0 ? videoHeight : 1080.0;
    final z = zoom <= 0 ? 1.0 : zoom;

    // Same branch as _captureVisibleFrame: center-crop the raw video frame
    // to 4:3, then shrink by the zoom factor.
    double cropW, cropH;
    if (vw / vh >= _kAspect) {
      cropH = vh / z;
      cropW = cropH * _kAspect;
    } else {
      cropW = vw / z;
      cropH = cropW / _kAspect;
    }

    // Same math the live preview uses: object-fit: cover maps the native
    // frame onto the container (displayScale), then the CSS zoom transform
    // shrinks the visible native window further, centered.
    final displayScale = math.max(containerW / vw, containerH / vh);
    final visibleNativeW = (containerW / displayScale) / z;
    final visibleNativeH = (containerH / displayScale) / z;

    // Ratio of the capture crop to what's actually visible on screen —
    // both are centered on the same point, so this maps directly to a
    // centered rectangle within the container.
    final rW = (cropW / visibleNativeW).clamp(0.0, 1.0);
    final rH = (cropH / visibleNativeH).clamp(0.0, 1.0);

    final rectW = containerW * rW;
    final rectH = containerH * rH;
    final left = (containerW - rectW) / 2;
    final top = (containerH - rectH) / 2;
    final cropRect = Rect.fromLTWH(left, top, rectW, rectH);
    final cropRRect = RRect.fromRectAndRadius(cropRect, const Radius.circular(14));

    // 1) Dim everything outside the capture region.
    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, containerW, containerH));
    final innerPath = Path()..addRRect(cropRRect);
    final dimPath = Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(dimPath, Paint()..color = Colors.black.withOpacity(0.45));

    // 2) Clear border around the capture region.
    canvas.drawRRect(
      cropRRect,
      Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // 3) Rule-of-thirds grid inside the capture region.
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.0;
    final thirdW = cropRect.width / 3;
    final thirdH = cropRect.height / 3;
    for (var i = 1; i <= 2; i++) {
      final x = cropRect.left + thirdW * i;
      canvas.drawLine(Offset(x, cropRect.top), Offset(x, cropRect.bottom), gridPaint);
      final y = cropRect.top + thirdH * i;
      canvas.drawLine(Offset(cropRect.left, y), Offset(cropRect.right, y), gridPaint);
    }

    // 4) Corner brackets for a scanner-style reticle.
    _drawCornerBrackets(
      canvas,
      cropRect,
      Paint()
        ..color = Colors.white.withOpacity(0.95)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawCornerBrackets(Canvas canvas, Rect r, Paint paint) {
    final len = math.min(24.0, math.min(r.width, r.height) / 4);
    if (len <= 0) return;

    // Top-left
    canvas.drawLine(r.topLeft, r.topLeft + Offset(len, 0), paint);
    canvas.drawLine(r.topLeft, r.topLeft + Offset(0, len), paint);
    // Top-right
    canvas.drawLine(r.topRight, r.topRight + Offset(-len, 0), paint);
    canvas.drawLine(r.topRight, r.topRight + Offset(0, len), paint);
    // Bottom-left
    canvas.drawLine(r.bottomLeft, r.bottomLeft + Offset(len, 0), paint);
    canvas.drawLine(r.bottomLeft, r.bottomLeft + Offset(0, -len), paint);
    // Bottom-right
    canvas.drawLine(r.bottomRight, r.bottomRight + Offset(-len, 0), paint);
    canvas.drawLine(r.bottomRight, r.bottomRight + Offset(0, -len), paint);
  }

  @override
  bool shouldRepaint(covariant _CropGuidePainter oldDelegate) {
    return oldDelegate.videoWidth != videoWidth ||
        oldDelegate.videoHeight != videoHeight ||
        oldDelegate.zoom != zoom;
  }
}