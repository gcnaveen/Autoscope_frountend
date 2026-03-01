// lib/features/shared/widgets/web_video_capture_web.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'web_camera_capture_web.dart'; // normalizeContentType

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
    builder: (_) => _WebVideoRecorderDialog(
      includeAudio: includeAudio,
      maxSeconds: maxSeconds,
    ),
  );
}

enum _VideoMode { live, review }

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

  html.VideoElement? _liveVideo;
  html.VideoElement? _playbackVideo;

  html.MediaRecorder? _recorder;
  final List<html.Blob> _chunks = [];

  html.Blob? _recordedBlob;
  String? _recordedType;
  String? _objectUrl;

  String? _error;
  bool _ready = false;
  bool _recording = false;
  bool _busy = false;

  _VideoMode _mode = _VideoMode.live;

  // ✅ timer without rebuilding whole dialog
  final ValueNotifier<int> _secVN = ValueNotifier<int>(0);
  Timer? _timer;

  // review play/pause
  bool _playing = false;

  late final String _liveViewType;
  late final String _playViewType;
  static int _seq = 0;

  @override
  void initState() {
    super.initState();
    final n = _seq++;
    _liveViewType = 'webcam_video_live_$n';
    _playViewType = 'webcam_video_play_$n';
    _setup();
  }

  Future<void> _setup() async {
    try {
      if (html.MediaRecorder == null) {
        throw Exception('Video recording is not supported on this browser. Use Upload instead.');
      }

      final devices = html.window.navigator.mediaDevices;
      if (devices == null) throw Exception('mediaDevices not supported');

      // Live preview element (GPU hint)
      final live = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..controls = false;

      live.setAttribute('playsinline', 'true');
      live.setAttribute('webkit-playsinline', 'true');

      live.style.width = '100%';
      live.style.height = '100%';
      live.style.objectFit = 'cover';
      live.style.pointerEvents = 'none';
      live.style.transform = 'translateZ(0)';
      live.style.willChange = 'transform';

      _liveVideo = live;

      // Playback element (review)
      final play = html.VideoElement()
        ..autoplay = false
        ..muted = true
        ..controls = false
        ..loop = false;

      play.setAttribute('playsinline', 'true');
      play.setAttribute('webkit-playsinline', 'true');

      play.style.width = '100%';
      play.style.height = '100%';
      play.style.objectFit = 'cover';
      play.style.pointerEvents = 'none';
      play.style.transform = 'translateZ(0)';
      play.style.willChange = 'transform';

      _playbackVideo = play;

      // Register factories once (kept mounted)
      ui.platformViewRegistry.registerViewFactory(_liveViewType, (int viewId) => live);
      ui.platformViewRegistry.registerViewFactory(_playViewType, (int viewId) => play);

      // ✅ BALANCED constraints for smoother recording preview
      html.MediaStream stream;
      final constraints = {
        'video': {
          'facingMode': {'ideal': 'environment'},
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
          'frameRate': {'ideal': 24, 'max': 30},
        },
        'audio': widget.includeAudio,
      };

      try {
        stream = await devices.getUserMedia(constraints);
      } catch (_) {
        // fallback without audio
        stream = await devices.getUserMedia({
          'video': constraints['video'],
          'audio': false,
        });
      }

      _stream = stream;
      live.srcObject = stream;

      try {
        // ignore: discarded_futures
        live.play();
      } catch (_) {}

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
      'video/webm;codecs=vp8,opus',
      'video/webm',
      'video/mp4', // Safari variants
    ];

    for (final t in candidates) {
      try {
        if (html.MediaRecorder.isTypeSupported(t)) return t;
      } catch (_) {}
    }
    return '';
  }

  void _startTimer() {
    _timer?.cancel();
    _secVN.value = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = _secVN.value + 1;
      _secVN.value = next;
      if (next >= widget.maxSeconds && _recording) {
        _stopRecording();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _startRecording() async {
    if (!_ready || _stream == null || _recording || _busy) return;

    setState(() {
      _error = null;
      _recordedBlob = null;
      _recordedType = null;
      _chunks.clear();
      _recording = true;
      _mode = _VideoMode.live;
      _playing = false;
    });

    _clearPlayback();

    try {
      final mime = _pickMimeType();

      // ✅ bitrate options to reduce encoding load
      final options = <String, dynamic>{
        // 2.5 Mbps is usually smooth on mobiles
        'videoBitsPerSecond': 2500000,
        'audioBitsPerSecond': 128000,
      };
      if (mime.isNotEmpty) options['mimeType'] = mime;

      final rec = html.MediaRecorder(_stream!, options);
      _recorder = rec;

      rec.addEventListener('dataavailable', (html.Event e) {
        try {
          final data = (e as dynamic).data;
          if (data is html.Blob && data.size > 0) _chunks.add(data);
        } catch (_) {}
      });

      rec.addEventListener('stop', (html.Event e) {
        final usedType = (rec.mimeType != null && (rec.mimeType ?? '').trim().isNotEmpty)
            ? rec.mimeType!
            : (mime.isNotEmpty ? mime : 'video/webm');

        final blob = html.Blob(_chunks, usedType);

        if (!mounted) return;
        setState(() {
          _recordedBlob = blob;
          _recordedType = blob.type;
          _recording = false;
          _mode = _VideoMode.review;
          _playing = false;
        });

        _stopTimer();
        _loadPlaybackPreview(blob);
      });

      // ✅ fewer callbacks = less jank
      rec.start(2000);
      _startTimer();
    } catch (e) {
      if (!mounted) return;
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
      if (r != null && r.state != 'inactive') r.stop();
    } catch (_) {}
  }

  void _loadPlaybackPreview(html.Blob blob) {
    try {
      _revokeObjectUrl();
      final url = html.Url.createObjectUrlFromBlob(blob);
      _objectUrl = url;

      final pv = _playbackVideo;
      if (pv != null) {
        pv.src = url;
        pv.loop = false;
        pv.muted = true;
        pv.autoplay = false;
        pv.controls = false;
        pv.load();

        // Show first frame (paused)
        pv.currentTime = 0;
        pv.pause();
      }

      try {
        _liveVideo?.pause();
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _togglePlayPause() async {
    final pv = _playbackVideo;
    if (pv == null) return;

    try {
      if (pv.paused == true) {
        await pv.play();
        setState(() => _playing = true);
      } else {
        pv.pause();
        setState(() => _playing = false);
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
    if (blob == null || _busy) return;

    setState(() => _busy = true);

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
      if (!mounted) return;
      setState(() => _error = 'Use video failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retake() async {
    if (_busy) return;

    setState(() {
      _recordedBlob = null;
      _recordedType = null;
      _mode = _VideoMode.live;
      _error = null;
      _playing = false;
    });

    _clearPlayback();

    try {
      // ignore: discarded_futures
      _liveVideo?.play();
    } catch (_) {}
  }

  void _clearPlayback() {
    try {
      _playbackVideo?.pause();
      _playbackVideo?.src = '';
    } catch (_) {}
    _revokeObjectUrl();
  }

  void _revokeObjectUrl() {
    final u = _objectUrl;
    if (u != null) {
      try {
        html.Url.revokeObjectUrl(u);
      } catch (_) {}
    }
    _objectUrl = null;
  }

  Future<void> _stopStream() async {
    _stopTimer();
    _clearPlayback();

    try {
      try {
        if (_recording) _stopRecording();
      } catch (_) {}

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
        _liveVideo?.pause();
      } catch (_) {}

      _liveVideo?.srcObject = null;
    } catch (_) {}
  }

  Future<void> _close() async {
    if (_busy) return;
    try {
      if (_recording) _stopRecording();
    } catch (_) {}
    await _stopStream();
    if (!mounted) return;
    Navigator.pop(context, null);
  }

  Future<bool> _onWillPop() async {
    if (_recording || _busy) return false;
    await _stopStream();
    return true;
  }

  @override
  void dispose() {
    _stopTimer();
    _secVN.dispose();
    // ignore: discarded_futures
    _stopStream();
    super.dispose();
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withOpacity(0.35),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReview = _mode == _VideoMode.review && _recordedBlob != null && !_recording;

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
              // keep both mounted; fade only
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: isReview,
                  child: AnimatedOpacity(
                    opacity: isReview ? 0 : 1,
                    duration: const Duration(milliseconds: 120),
                    child: _ready
                        ? HtmlElementView(viewType: _liveViewType)
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !isReview,
                  child: AnimatedOpacity(
                    opacity: isReview ? 1 : 0,
                    duration: const Duration(milliseconds: 120),
                    child: HtmlElementView(viewType: _playViewType),
                  ),
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
                          onPressed: (_recording || _busy) ? null : _close,
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isReview ? 'Review Video' : 'Camera',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
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

              // timer + status
              Positioned(
                left: 16,
                bottom: 120,
                child: SafeArea(
                  top: false,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _secVN,
                    builder: (_, sec, __) {
                      final status = _recording ? 'REC' : (isReview ? 'PREVIEW' : 'READY');
                      return Row(
                        children: [
                          _pill(_fmt(sec)),
                          const SizedBox(width: 10),
                          _pill(status),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // review play button (no autoplay loop)
              if (isReview)
                Positioned.fill(
                  child: Center(
                    child: IconButton(
                      onPressed: _togglePlayPause,
                      iconSize: 72,
                      icon: Icon(
                        _playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                        color: Colors.white.withOpacity(0.92),
                      ),
                    ),
                  ),
                ),

              // bottom controls
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
                                  onPressed: _busy ? null : _useVideo,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text('Use Video'),
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: GestureDetector(
                              onTap: (!_ready || _busy)
                                  ? null
                                  : (_recording ? _stopRecording : _startRecording),
                              child: Container(
                                width: 78,
                                height: 78,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.12),
                                  border: Border.all(
                                    color: _recording ? Colors.redAccent : Colors.white,
                                    width: 4,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    _recording ? Icons.stop : Icons.fiber_manual_record,
                                    color: _recording ? Colors.redAccent : Colors.white,
                                    size: 34,
                                  ),
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