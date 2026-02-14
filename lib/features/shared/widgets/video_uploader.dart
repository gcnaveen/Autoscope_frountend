import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/service_locator.dart';
import 'web_video_pick_web.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class VideoUploader extends StatefulWidget {
  final List<String> initialVideos;
  final void Function(List<String>) onChanged;

  final String? title;
  final VoidCallback? onClose;

  final String inspectionRequestId;
  final String typeName;

  final bool enabled;

  const VideoUploader({
    super.key,
    required this.initialVideos,
    required this.onChanged,
    required this.inspectionRequestId,
    required this.typeName,
    this.title,
    this.onClose,
    this.enabled = true,
  });

  @override
  State<VideoUploader> createState() => _VideoUploaderState();
}

class _VideoUploaderState extends State<VideoUploader> {
  late List<String> _videos;
  bool _working = false;
  String? _msg;

  @override
  void initState() {
    super.initState();
    _videos = List<String>.from(widget.initialVideos);
  }

  @override
  void didUpdateWidget(covariant VideoUploader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialVideos != widget.initialVideos) {
      _videos = List<String>.from(widget.initialVideos);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addVideo() async {
    if (_working || !widget.enabled) return;

    setState(() {
      _working = true;
      _msg = null;
    });

    try {
      final picked = await pickOneMp4VideoFromWeb(preferCamera: true);
      if (picked == null) return;

      setState(() => _msg = 'Uploading video...');

      final fileName =
          '${widget.typeName.toLowerCase().replaceAll(" ", "_")}_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final fileUrl = await inspectionRequestsService.uploadInspectionVideo(
        inspectionRequestId: widget.inspectionRequestId,
        typeName: widget.typeName,
        bytes: picked.bytes,
        fileName: fileName,
      );

      setState(() {
        _videos.add(fileUrl);
        _msg = null;
      });
      widget.onChanged(List<String>.from(_videos));
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
          _msg = null;
        });
      }
    }
  }

  void _removeAt(int i) {
    setState(() => _videos.removeAt(i));
    widget.onChanged(List<String>.from(_videos));
  }

  void _openVideo(String url) {
    // Web: open in new tab
    html.window.open(url, '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title ?? 'Videos',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    tooltip: 'Close',
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: (_working || !widget.enabled) ? null : _addVideo,
                  icon: _working
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.videocam_outlined),
                  label: Text(_working ? 'Working...' : 'Add Video'),
                ),
                const SizedBox(width: 12),
                Text("${_videos.length} selected", style: theme.textTheme.bodyMedium),
              ],
            ),

            if (_msg != null) ...[
              const SizedBox(height: 10),
              Text(_msg!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
            ],

            const SizedBox(height: 12),

            if (_videos.isNotEmpty)
              Column(
                children: List.generate(_videos.length, (i) {
                  final u = _videos[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Open',
                          onPressed: () => _openVideo(u),
                          icon: const Icon(Icons.play_circle_outline),
                        ),
                        Expanded(
                          child: Text(
                            u,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(decoration: TextDecoration.underline),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          onPressed: () => _removeAt(i),
                          icon: const Icon(Icons.close, color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}

