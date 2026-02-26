// lib/features/shared/widgets/web_video_capture_web.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'web_camera_capture_web.dart'; // for normalizeContentType

class CapturedVideoBytes {
  final Uint8List bytes;
  final String fileName;
  final String contentType;

  CapturedVideoBytes({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });
}

Future<CapturedVideoBytes?> captureVideoBytesViaPopup(
  BuildContext context, {
  bool includeAudio = true,
  int maxSeconds = 60,
}) async {
  return showDialog<CapturedVideoBytes?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _WebVideoRecorderDialog(includeAudio: includeAudio, maxSeconds: maxSeconds),
  );
}

class _WebVideoRecorderDialog extends StatefulWidget {
  final bool includeAudio;
  final int maxSeconds;

  const _WebVideoRecorderDialog({
    required this.includeAudio,
    required this.maxSeconds,
  });

  @override
  State<_WebVideoRecorderDialog> createState() => _WebVideoRecorderDialogState();
}

class _WebVideoRecorderDialogState extends State<_WebVideoRecorderDialog> {
  html.MediaStream? _stream;
  html.VideoElement? _video;

  html.MediaRecorder? _recorder;
  final List<html.Blob> _chunks = [];

  html.Blob? _recordedBlob;
  String? _recordedType;

  String? _error;
  bool _ready = false;
  bool _recording = false;
  int _sec = 0;

  Timer? _timer;

  late final String _viewType;
  static int _seq = 0;

  @override
  void initState() {
    super.initState();
    _viewType = 'webcam_video_view_${_seq++}';
    _setup();
  }

  Future<void> _setup() async {
    try {
      // MediaRecorder support
      if (html.MediaRecorder == null) {
        throw Exception('Video recording is not supported on this browser. Use Upload instead.');
      }

      final devices = html.window.navigator.mediaDevices;
      if (devices == null) throw Exception('mediaDevices not supported');

      final video = html.VideoElement()
        ..autoplay = true
        ..muted = true // allow autoplay
        ..controls = false;

      video.setAttribute('playsinline', 'true');
      video.setAttribute('webkit-playsinline', 'true');

      video.style.width = '100%';
      video.style.height = '100%';
      video.style.objectFit = 'cover';

      _video = video;

      // Try with audio, fallback to no-audio if denied
      html.MediaStream stream;
      try {
        stream = await devices.getUserMedia({
          'video': {'facingMode': {'ideal': 'environment'}},
          'audio': widget.includeAudio,
        });
      } catch (_) {
        stream = await devices.getUserMedia({
          'video': {'facingMode': {'ideal': 'environment'}},
          'audio': false,
        });
      }

      _stream = stream;
      video.srcObject = stream;

      try {
        // ignore: discarded_futures
        video.play();
      } catch (_) {}

      ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) => video);

      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      await _stopStream();
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  String _pickMimeType() {
    final candidates = <String>[
      'video/webm;codecs=vp9,opus',
      'video/webm;codecs=vp8,opus',
      'video/webm',
      'video/mp4', // some Safari versions
    ];

    for (final t in candidates) {
      try {
        if (html.MediaRecorder.isTypeSupported(t)) return t;
      } catch (_) {}
    }
    return ''; // let browser decide
  }

  void _startTimer() {
    _timer?.cancel();
    _sec = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _sec++;
        if (_sec >= widget.maxSeconds && _recording) {
          _stopRecording();
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _startRecording() async {
    if (!_ready || _stream == null || _recording) return;

    setState(() {
      _error = null;
      _recordedBlob = null;
      _recordedType = null;
      _chunks.clear();
      _recording = true;
    });

    try {
      final mime = _pickMimeType();
      final rec = mime.isNotEmpty
          ? html.MediaRecorder(_stream!, {'mimeType': mime})
          : html.MediaRecorder(_stream!);

      _recorder = rec;

      // rec.onDataAvailable.listen((ev) {
      //   final b = ev.data;
      //   if (b != null && b.size > 0) _chunks.add(b);
      // });

      // rec.onStop.listen((_) {
      //   final t = rec.mimeType ?? mime;
      //   final blob = html.Blob(_chunks, t.isNotEmpty ? t : 'video/webm');
      //   setState(() {
      //     _recordedBlob = blob;
      //     _recordedType = blob.type;
      //     _recording = false;
      //   });
      //   _stopTimer();
      // });

      rec.addEventListener('dataavailable', (html.Event e) {
        try {
          final data = (e as dynamic).data; // BlobEvent.data
          if (data is html.Blob && data.size > 0) {
            _chunks.add(data);
          }
        } catch (_) {}
      });

      rec.addEventListener('stop', (html.Event e) {
        final t = mime.isNotEmpty ? mime : 'video/webm';
        final blob = html.Blob(_chunks, t);

        if (!mounted) return;
        setState(() {
          _recordedBlob = blob;
          _recordedType = blob.type;
          _recording = false;
        });
        _stopTimer();
      });

      rec.start(250);
      _startTimer();
    } catch (e) {
      setState(() {
        _recording = false;
        _error = 'Recorder error: $e';
      });
      _stopTimer();
    }
  }

  void _stopRecording() {
    try {
      final r = _recorder;
      if (r != null && r.state != 'inactive') {
        r.stop();
      }
    } catch (_) {}
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

  Future<void> _useVideo() async {
    final blob = _recordedBlob;
    if (blob == null) return;

    try {
      final bytes = await _blobToBytes(blob);
      final rawType = _recordedType ?? blob.type;
      final ct = normalizeContentType(rawType);
      final safeCt = ct.isEmpty ? 'video/webm' : ct;

      final ext = safeCt.contains('mp4') ? 'mp4' : 'webm';
      final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _stopStream();

      if (!mounted) return;
      Navigator.pop(
        context,
        CapturedVideoBytes(bytes: bytes, fileName: fileName, contentType: safeCt),
      );
    } catch (e) {
      setState(() => _error = 'Use video failed: $e');
    }
  }

  Future<void> _stopStream() async {
    _stopTimer();
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

  Future<void> _close() async {
    try {
      if (_recording) _stopRecording();
    } catch (_) {}
    await _stopStream();
    if (!mounted) return;
    Navigator.pop(context, null);
  }

  Future<bool> _onWillPop() async {
    if (_recording) return false;
    await _stopStream();
    return true;
  }

  @override
  void dispose() {
    _stopTimer();
    _stopStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String fmt(int s) {
      final m = (s ~/ 60).toString().padLeft(2, '0');
      final ss = (s % 60).toString().padLeft(2, '0');
      return '$m:$ss';
    }

    final canUse = _recordedBlob != null && !_recording;

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
                    const Icon(Icons.videocam_outlined),
                    const SizedBox(width: 8),
                    Text('Capture Video',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    IconButton(onPressed: _recording ? null : _close, icon: const Icon(Icons.close)),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Text(fmt(_sec), style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      const Spacer(),
                      Text(
                        _recording ? 'Recording…' : (canUse ? 'Recorded' : 'Ready'),
                        style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _recording ? null : _close,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: !_ready
                              ? null
                              : (_recording ? _stopRecording : _startRecording),
                          icon: Icon(_recording ? Icons.stop : Icons.fiber_manual_record),
                          label: Text(_recording ? 'Stop' : 'Record'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: canUse ? _useVideo : null,
                          icon: const Icon(Icons.check),
                          label: const Text('Use'),
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