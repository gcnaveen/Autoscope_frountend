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

  // strip codecs / params
  final semi = v.indexOf(';');
  if (semi >= 0) v = v.substring(0, semi).trim();

  // common video fixes
  if (v == 'video/quicktime') return 'video/quicktime';
  if (v == 'video/m4v') return 'video/mp4';
  if (v.startsWith('video/')) return v;

  // images
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
  bool _capturing = false;

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

      video.style.width = '100%';
      video.style.height = '100%';
      video.style.objectFit = 'cover';

      _video = video;

      final stream = await devices.getUserMedia({
        'video': {
          'facingMode': {'ideal': 'environment'},
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
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
      _video?.srcObject = null;
    } catch (_) {}
  }

  Future<void> _capture() async {
    if (_capturing || !_ready || _video == null) return;
    setState(() => _capturing = true);

    try {
      final video = _video!;
      final w = video.videoWidth > 0 ? video.videoWidth : 1280;
      final h = video.videoHeight > 0 ? video.videoHeight : 720;

      final canvas = html.CanvasElement(width: w, height: h);
      canvas.context2D.drawImage(video, 0, 0);

      final blob = await _canvasToBlob(canvas, 'image/jpeg', 0.92);
      final bytes = await _blobToBytes(blob);

      final fileName = 'capture_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _stopStream();

      if (!mounted) return;
      Navigator.pop(
        context,
        CapturedPhotoBytes(bytes: bytes, fileName: fileName, contentType: 'image/jpeg'),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Capture failed: $e');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (_capturing) return false;
    await _stopStream();
    return true;
  }

  Future<void> _close() async {
    await _stopStream();
    if (!mounted) return;
    Navigator.pop(context, null);
  }

  @override
  void dispose() {
    _subLoadedMetadata?.cancel();
    _subCanPlay?.cancel();
    _stopStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.photo_camera_outlined),
                    const SizedBox(width: 8),
                    Text('Capture Photo',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    IconButton(onPressed: _capturing ? null : _close, icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 10),
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.red.withOpacity(0.08),
                    ),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                if (_error == null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Container(
                        color: Colors.black12,
                        child: _ready
                            ? HtmlElementView(viewType: _viewType)
                            : const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _capturing ? null : _close,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_ready && !_capturing) ? _capture : null,
                          icon: _capturing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.camera_alt_outlined),
                          label: Text(_capturing ? 'Capturing...' : 'Capture'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}