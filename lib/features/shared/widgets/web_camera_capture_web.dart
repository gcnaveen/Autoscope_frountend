// lib/features/shared/widgets/web_camera_capture_web.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'dart:async';
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
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
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