import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import '../../../../services/service_locator.dart';

import 'web_camera_capture_web.dart';
import 'web_image_pick_web.dart';

class ImageUploader extends StatefulWidget {
  final List<String> initialImages;
  final void Function(List<String>) onChanged;

  /// Optional UI title
  final String? title;

  /// Optional close button (for dialogs)
  final VoidCallback? onClose;

  /// ✅ Required for S3 upload API
  final String inspectionRequestId;
  final String typeName;

  /// Disable Add button
  final bool enabled;

  /// ✅ NEW (optional): "photos" (default) OR "videos"
  final String mediaType;

  /// ✅ NEW (optional): what to send when browser doesn't give a video type
  /// Your requirement: "video/mp4"
  final String defaultVideoContentType;

  const ImageUploader({
    super.key,
    this.title,
    required this.initialImages,
    required this.onChanged,
    required this.inspectionRequestId,
    required this.typeName,
    this.onClose,
    this.enabled = true,
    this.mediaType = 'photos',
    this.defaultVideoContentType = 'video/mp4',
  });

  @override
  State<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  late List<String> _images;
  bool _picking = false;
  String? _uploadingMsg;

  bool get _isVideo => widget.mediaType.toLowerCase() == 'videos';

  @override
  void initState() {
    super.initState();
    _images = List<String>.from(widget.initialImages);
  }

  @override
  void didUpdateWidget(covariant ImageUploader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialImages != widget.initialImages) {
      _images = List<String>.from(widget.initialImages);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// data:image/png;base64,XXXX -> bytes + contentType
  ({Uint8List bytes, String contentType})? _parseDataUrl(String dataUrl) {
    if (!dataUrl.startsWith('data:')) return null;

    final comma = dataUrl.indexOf(',');
    if (comma <= 0) return null;

    final meta = dataUrl.substring(5, comma); // "image/png;base64"
    final b64 = dataUrl.substring(comma + 1);

    final contentType = meta.split(';').first.trim();
    if (contentType.isEmpty) return null;

    final bytes = base64Decode(b64);
    return (bytes: bytes, contentType: contentType);
  }

  /// Fetch bytes for blob:... or http(s) url (web only)
  Future<({Uint8List bytes, String contentType})> _fetchBytesFromUrl(String url) async {
    final req = await html.HttpRequest.request(
      url,
      method: 'GET',
      responseType: 'arraybuffer',
    );

    final ct = req.getResponseHeader('content-type') ??
        (_isVideo ? widget.defaultVideoContentType : 'image/jpeg');

    final buf = req.response as ByteBuffer;
    return (bytes: buf.asUint8List(), contentType: ct);
  }

  Future<Uint8List> _readFileBytes(html.File f) async {
    final c = Completer<Uint8List>();
    final reader = html.FileReader();

    reader.onLoad.listen((_) {
      final buf = reader.result as ByteBuffer;
      c.complete(buf.asUint8List());
    });

    reader.onError.listen((_) {
      c.completeError(reader.error ?? Exception('Failed to read file'));
    });

    reader.readAsArrayBuffer(f);
    return c.future;
  }

  String _fileExtFromContentType(String contentType) {
    final ct = contentType.toLowerCase();
    if (ct.contains('png')) return 'png';
    if (ct.contains('webp')) return 'webp';
    if (ct.contains('gif')) return 'gif';
    if (ct.contains('mp4')) return 'mp4';
    if (ct.contains('webm')) return 'webm';
    if (ct.contains('quicktime')) return 'mov';
    return _isVideo ? 'mp4' : 'jpg';
  }

  Future<String> _uploadOne({
    required Uint8List bytes,
    required String contentType,
    String? originalName,
  }) async {
    final ext = _fileExtFromContentType(contentType);

    final base = widget.typeName.toLowerCase().replaceAll(' ', '_');
    final fileName = originalName != null && originalName.trim().isNotEmpty
        ? originalName
        : '${base}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    // ✅ same service method, but now supports photos/videos
    return inspectionRequestsService.uploadInspectionMedia(
      inspectionRequestId: widget.inspectionRequestId,
      typeName: widget.typeName,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
      mediaType: _isVideo ? 'videos' : 'photos',
    );
  }

  Future<void> _pick() async {
    if (_picking || !widget.enabled) return;

    setState(() {
      _picking = true;
      _uploadingMsg = null;
    });

    try {
      if (_isVideo) {
        await _pickVideo();
      } else {
        await _pickPhotos();
      }
    } catch (e) {
      _toast('Upload failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _picking = false;
          _uploadingMsg = null;
        });
      }
    }
  }

  // ============================
  // PHOTOS (kept as-is)
  // ============================
  Future<void> _pickPhotos() async {
    // 1) Webcam popup capture (camera.html) -> usually returns dataUrl
    final captured = await capturePhotoViaPopupPage();
    if (captured != null) {
      setState(() => _uploadingMsg = 'Uploading capture...');

      final parsed = _parseDataUrl(captured);
      if (parsed == null) {
        // popup returned blob url
        final fetched = await _fetchBytesFromUrl(captured);
        final fileUrl = await _uploadOne(bytes: fetched.bytes, contentType: fetched.contentType);
        setState(() => _images.add(fileUrl));
        widget.onChanged(List<String>.from(_images));
        return;
      }

      final fileUrl = await _uploadOne(bytes: parsed.bytes, contentType: parsed.contentType);
      setState(() => _images.add(fileUrl));
      widget.onChanged(List<String>.from(_images));
      return;
    }

    // 2) Fallback: web file input (your existing helper)
    final picked = await pickImagesFromWebInput(multiple: true, preferCamera: true);
    if (picked.isEmpty) return;

    final newUrls = <String>[];

    for (var i = 0; i < picked.length; i++) {
      setState(() => _uploadingMsg = 'Uploading ${i + 1}/${picked.length}...');
      final p = picked[i];

      final parsed = _parseDataUrl(p);
      if (parsed != null) {
        final fileUrl = await _uploadOne(bytes: parsed.bytes, contentType: parsed.contentType);
        newUrls.add(fileUrl);
        continue;
      }

      // blob:... or http(s)...
      final fetched = await _fetchBytesFromUrl(p);
      final fileUrl = await _uploadOne(bytes: fetched.bytes, contentType: fetched.contentType);
      newUrls.add(fileUrl);
    }

    if (newUrls.isNotEmpty) {
      setState(() => _images.addAll(newUrls));
      widget.onChanged(List<String>.from(_images));
    }
  }

  // ============================
  // VIDEOS (new, safe)
  // Uses native file input with capture (works on mobile; desktop opens file picker)
  // ============================
  Future<void> _pickVideo() async {
    final input = html.FileUploadInputElement();
    input.accept = 'video/*';
    input.multiple = false;

    // helps mobile show camera recorder
    input.setAttribute('capture', 'environment');

    final files = await _openFilePicker(input);
    if (files.isEmpty) return;

    final f = files.first;
    setState(() => _uploadingMsg = 'Uploading video...');

    final bytes = await _readFileBytes(f);

    // IMPORTANT:
    // If browser provides file.type use it (avoids presign signature mismatch).
    // If empty -> use your required "video/mp4".
    final ct = (f.type.trim().isNotEmpty) ? f.type.trim() : widget.defaultVideoContentType;

    final fileUrl = await _uploadOne(
      bytes: bytes,
      contentType: ct,
      originalName: f.name,
    );

    setState(() => _images.add(fileUrl));
    widget.onChanged(List<String>.from(_images));
  }

  Future<List<html.File>> _openFilePicker(html.FileUploadInputElement input) async {
    final completer = Completer<List<html.File>>();
    input.onChange.listen((_) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete(<html.File>[]);
      } else {
        completer.complete(files.toList());
      }
    });
    input.click();
    return completer.future;
  }

  void _removeAt(int i) {
    setState(() => _images.removeAt(i));
    widget.onChanged(List<String>.from(_images));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = widget.title ?? (_isVideo ? 'Videos' : 'Photos');

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
                    title,
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
                  onPressed: (_picking || !widget.enabled) ? null : _pick,
                  icon: _picking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_isVideo ? Icons.videocam_outlined : Icons.add_photo_alternate_outlined),
                  label: Text(_picking ? "Working..." : (_isVideo ? "Add Video" : "Add Photos")),
                ),
                const SizedBox(width: 12),
                Text("${_images.length} selected", style: theme.textTheme.bodyMedium),
              ],
            ),

            if (_uploadingMsg != null) ...[
              const SizedBox(height: 10),
              Text(_uploadingMsg!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
            ],

            const SizedBox(height: 12),

            if (_images.isNotEmpty)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_images.length, (i) {
                  final u = _images[i];

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 96,
                          height: 72,
                          color: Colors.black12,
                          child: _isVideo
                              ? const Center(child: Icon(Icons.play_circle_outline, size: 28))
                              : Image.network(
                                  u,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        right: -10,
                        top: -10,
                        child: InkWell(
                          onTap: () => _removeAt(i),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.black12),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close, size: 18, color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}