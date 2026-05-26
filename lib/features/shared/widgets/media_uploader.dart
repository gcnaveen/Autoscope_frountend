// import 'dart:async';
// import 'dart:typed_data';

// // ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;

// import 'package:flutter/material.dart';

// import 'web_camera_capture_web.dart' as cam;

// typedef UploadFn = Future<String> Function({
//   required Uint8List bytes,
//   required String contentType,
//   required String fileName,
// });

// class MediaUploader extends StatefulWidget {
//   // existing URLs
//   final List<String> initialPhotos;
//   final List<String> initialVideos;

//   final void Function(List<String> photos) onPhotosChanged;
//   final void Function(List<String> videos) onVideosChanged;

//   // Two different APIs (you pass them from caller)
//   final UploadFn uploadPhoto;
//   final UploadFn uploadVideo;

//   final String? title;
//   final bool enabled;

//   // flags to control per-place behavior
//   final bool allowCapturePhoto;
//   final bool allowCaptureVideo;
//   final bool allowUploadPhoto;
//   final bool allowUploadVideo;

//   const MediaUploader({
//     super.key,
//     required this.initialPhotos,
//     required this.initialVideos,
//     required this.onPhotosChanged,
//     required this.onVideosChanged,
//     required this.uploadPhoto,
//     required this.uploadVideo,
//     this.title,
//     this.enabled = true,
//     this.allowCapturePhoto = true,
//     this.allowCaptureVideo = true,
//     this.allowUploadPhoto = true,
//     this.allowUploadVideo = true,
//   });

//   @override
//   State<MediaUploader> createState() => _MediaUploaderState();
// }

// class _MediaUploaderState extends State<MediaUploader> {
//   late List<String> _photos;
//   late List<String> _videos;

//   bool _working = false;
//   String? _status;

//   @override
//   void initState() {
//     super.initState();
//     _photos = List<String>.from(widget.initialPhotos);
//     _videos = List<String>.from(widget.initialVideos);
//   }

//   @override
//   void didUpdateWidget(covariant MediaUploader oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.initialPhotos != widget.initialPhotos) {
//       _photos = List<String>.from(widget.initialPhotos);
//     }
//     if (oldWidget.initialVideos != widget.initialVideos) {
//       _videos = List<String>.from(widget.initialVideos);
//     }
//   }

//   void _toast(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//   }

//   Future<List<html.File>> _openPicker({
//     required String accept,
//     required bool multiple,
//   }) async {
//     final input = html.FileUploadInputElement();
//     input.accept = accept;
//     input.multiple = multiple;

//     final completer = Completer<List<html.File>>();
//     input.onChange.listen((_) {
//       final files = input.files;
//       if (files == null || files.isEmpty) {
//         completer.complete(<html.File>[]);
//       } else {
//         completer.complete(files.toList());
//       }
//     });

//     input.click();
//     return completer.future;
//   }

//   Future<Uint8List> _readFileBytes(html.File f) async {
//     final c = Completer<Uint8List>();
//     final reader = html.FileReader();
//     reader.onLoad.listen((_) {
//       final buf = reader.result as ByteBuffer;
//       c.complete(buf.asUint8List());
//     });
//     reader.onError.listen((_) {
//       c.completeError(reader.error ?? Exception('Failed to read file'));
//     });
//     reader.readAsArrayBuffer(f);
//     return c.future;
//   }

//   bool _looksLikeVideo(html.File f) {
//     final name = f.name.toLowerCase();
//     if (f.type.toLowerCase().startsWith('video/')) return true;
//     return name.endsWith('.mp4') || name.endsWith('.webm') || name.endsWith('.mov');
//   }

//   Future<void> _showChooser() async {
//     if (_working || !widget.enabled) return;

//     final showCapturePhoto = widget.allowCapturePhoto;
//     final showCaptureVideo = widget.allowCaptureVideo;
//     final showUpload = widget.allowUploadPhoto || widget.allowUploadVideo;

//     await showModalBottomSheet<void>(
//       context: context,
//       showDragHandle: true,
//       builder: (ctx) {
//         return SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (showCapturePhoto)
//                 ListTile(
//                   leading: const Icon(Icons.photo_camera_outlined),
//                   title: const Text('Capture Photo'),
//                   onTap: () {
//                     Navigator.pop(ctx);
//                     _capturePhoto();
//                   },
//                 ),
//               if (showCaptureVideo)
//                 ListTile(
//                   leading: const Icon(Icons.videocam_outlined),
//                   title: const Text('Capture Video'),
//                   onTap: () {
//                     Navigator.pop(ctx);
//                     _captureVideo();
//                   },
//                 ),
//               if (showUpload)
//                 ListTile(
//                   leading: const Icon(Icons.upload_file_outlined),
//                   title: const Text('Upload'),
//                   subtitle: Text(
//                     (widget.allowUploadPhoto && widget.allowUploadVideo)
//                         ? 'Upload photos or videos'
//                         : (widget.allowUploadPhoto ? 'Upload photos' : 'Upload videos'),
//                   ),
//                   onTap: () {
//                     Navigator.pop(ctx);
//                     _uploadFromFiles();
//                   },
//                 ),
//               const SizedBox(height: 8),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Future<void> _capturePhoto() async {
//     if (_working) return;
//     setState(() {
//       _working = true;
//       _status = 'Opening camera...';
//     });

//     try {
//       final cap = await cam.capturePhotoBytesViaPopup();
//       if (cap == null) return;

//       setState(() => _status = 'Uploading photo...');
//       final url = await widget.uploadPhoto(
//         bytes: cap.bytes,
//         contentType: cap.contentType,
//         fileName: cap.fileName,
//       );

//       setState(() => _photos.add(url));
//       widget.onPhotosChanged(List<String>.from(_photos));
//     } catch (e) {
//       _toast('Photo failed: $e');
//     } finally {
//       if (mounted) setState(() => _working = false);
//       if (mounted) setState(() => _status = null);
//     }
//   }

//   Future<void> _captureVideo() async {
//     if (_working) return;
//     setState(() {
//       _working = true;
//       _status = 'Opening recorder...';
//     });

//     try {
//       final cap = await cam.captureVideoBytesViaPopup();
//       if (cap == null) return;

//       setState(() => _status = 'Uploading video...');
//       final url = await widget.uploadVideo(
//         bytes: cap.bytes,
//         contentType: cap.contentType,
//         fileName: cap.fileName,
//       );

//       setState(() => _videos.add(url));
//       widget.onVideosChanged(List<String>.from(_videos));
//     } catch (e) {
//       _toast('Video failed: $e');
//     } finally {
//       if (mounted) setState(() => _working = false);
//       if (mounted) setState(() => _status = null);
//     }
//   }

//   Future<void> _uploadFromFiles() async {
//     if (_working) return;

//     setState(() {
//       _working = true;
//       _status = 'Selecting files...';
//     });

//     try {
//       final accept = (widget.allowUploadPhoto && widget.allowUploadVideo)
//           ? 'image/*,video/*'
//           : (widget.allowUploadPhoto ? 'image/*' : 'video/*');

//       final files = await _openPicker(accept: accept, multiple: true);
//       if (files.isEmpty) return;

//       for (var i = 0; i < files.length; i++) {
//         final f = files[i];
//         final isVideo = _looksLikeVideo(f);

//         if (isVideo && !widget.allowUploadVideo) continue;
//         if (!isVideo && !widget.allowUploadPhoto) continue;

//         setState(() => _status = 'Uploading ${i + 1}/${files.length}...');

//         final bytes = await _readFileBytes(f);

//         final contentType = (f.type.trim().isNotEmpty)
//             ? f.type.trim()
//             : (isVideo ? 'video/mp4' : 'image/jpeg');

//         final url = isVideo
//             ? await widget.uploadVideo(bytes: bytes, contentType: contentType, fileName: f.name)
//             : await widget.uploadPhoto(bytes: bytes, contentType: contentType, fileName: f.name);

//         if (isVideo) {
//           setState(() => _videos.add(url));
//           widget.onVideosChanged(List<String>.from(_videos));
//         } else {
//           setState(() => _photos.add(url));
//           widget.onPhotosChanged(List<String>.from(_photos));
//         }
//       }
//     } catch (e) {
//       _toast('Upload failed: $e');
//     } finally {
//       if (mounted) setState(() => _working = false);
//       if (mounted) setState(() => _status = null);
//     }
//   }

//   void _removePhotoAt(int i) {
//     setState(() => _photos.removeAt(i));
//     widget.onPhotosChanged(List<String>.from(_photos));
//   }

//   void _removeVideoAt(int i) {
//     setState(() => _videos.removeAt(i));
//     widget.onVideosChanged(List<String>.from(_videos));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final title = widget.title ?? 'Media';

//     final showVideosUi =
//         widget.allowCaptureVideo || widget.allowUploadVideo || _videos.isNotEmpty;

//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(title,
//                 style: theme.textTheme.titleMedium
//                     ?.copyWith(fontWeight: FontWeight.w800)),
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: (_working || !widget.enabled) ? null : _showChooser,
//                   icon: _working
//                       ? const SizedBox(
//                           width: 18,
//                           height: 18,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         )
//                       : const Icon(Icons.add),
//                   label: Text(_working ? 'Working...' : 'Add'),
//                 ),
//                 const SizedBox(width: 12),
//                 Text(
//                   showVideosUi
//                       ? '${_photos.length} photos, ${_videos.length} videos'
//                       : '${_photos.length} photos',
//                   style: theme.textTheme.bodyMedium,
//                 ),
//               ],
//             ),
//             if (_status != null) ...[
//               const SizedBox(height: 10),
//               Text(_status!,
//                   style: theme.textTheme.bodySmall
//                       ?.copyWith(color: Colors.black54)),
//             ],
//             const SizedBox(height: 12),
//             if (_photos.isNotEmpty) ...[
//               Text('Photos',
//                   style: theme.textTheme.titleSmall
//                       ?.copyWith(fontWeight: FontWeight.w800)),
//               const SizedBox(height: 8),
//               Wrap(
//                 spacing: 10,
//                 runSpacing: 10,
//                 children: List.generate(_photos.length, (i) {
//                   final u = _photos[i];
//                   return Stack(
//                     clipBehavior: Clip.none,
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(12),
//                         child: Container(
//                           width: 96,
//                           height: 72,
//                           color: Colors.black12,
//                           child: Image.network(
//                             u,
//                             fit: BoxFit.cover,
//                             errorBuilder: (_, __, ___) => const Center(
//                               child: Icon(Icons.broken_image_outlined),
//                             ),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         right: -10,
//                         top: -10,
//                         child: InkWell(
//                           onTap: () => _removePhotoAt(i),
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(999),
//                               border: Border.all(color: Colors.black12),
//                             ),
//                             padding: const EdgeInsets.all(2),
//                             child: const Icon(Icons.close,
//                                 size: 18, color: Colors.red),
//                           ),
//                         ),
//                       ),
//                     ],
//                   );
//                 }),
//               ),
//               const SizedBox(height: 14),
//             ],
//             if (showVideosUi && _videos.isNotEmpty) ...[
//               Text('Videos',
//                   style: theme.textTheme.titleSmall
//                       ?.copyWith(fontWeight: FontWeight.w800)),
//               const SizedBox(height: 8),
//               Wrap(
//                 spacing: 10,
//                 runSpacing: 10,
//                 children: List.generate(_videos.length, (i) {
//                   return Stack(
//                     clipBehavior: Clip.none,
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(12),
//                         child: Container(
//                           width: 96,
//                           height: 72,
//                           color: Colors.black12,
//                           child: const Center(
//                               child: Icon(Icons.play_circle_outline, size: 30)),
//                         ),
//                       ),
//                       Positioned(
//                         right: -10,
//                         top: -10,
//                         child: InkWell(
//                           onTap: () => _removeVideoAt(i),
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(999),
//                               border: Border.all(color: Colors.black12),
//                             ),
//                             padding: const EdgeInsets.all(2),
//                             child: const Icon(Icons.close,
//                                 size: 18, color: Colors.red),
//                           ),
//                         ),
//                       ),
//                     ],
//                   );
//                 }),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'dart:async';
import 'dart:typed_data';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';

import 'web_camera_capture_web.dart';
import 'web_video_capture_web.dart';
import '../top_snackbar.dart';

typedef UploadFn = Future<String> Function({
  required Uint8List bytes,
  required String contentType,
  required String fileName,
});

class MediaUploader extends StatefulWidget {
  final List<String> initialPhotos;
  final List<String> initialVideos;

  final void Function(List<String> photos) onPhotosChanged;
  final void Function(List<String> videos) onVideosChanged;

  final UploadFn uploadPhoto;
  final UploadFn uploadVideo;

  final String? title;
  final bool enabled;

  final bool allowCapturePhoto;
  final bool allowCaptureVideo;
  final bool allowUploadPhoto;
  final bool allowUploadVideo;

  const MediaUploader({
    super.key,
    required this.initialPhotos,
    required this.initialVideos,
    required this.onPhotosChanged,
    required this.onVideosChanged,
    required this.uploadPhoto,
    required this.uploadVideo,
    this.title,
    this.enabled = true,
    this.allowCapturePhoto = true,
    this.allowCaptureVideo = true,
    this.allowUploadPhoto = true,
    this.allowUploadVideo = true,
  });

  @override
  State<MediaUploader> createState() => _MediaUploaderState();
}

class _MediaUploaderState extends State<MediaUploader> {
  late List<String> _photos;
  late List<String> _videos;

  bool _working = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _photos = List<String>.from(widget.initialPhotos);
    _videos = List<String>.from(widget.initialVideos);
  }

  @override
  void didUpdateWidget(covariant MediaUploader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPhotos != widget.initialPhotos) {
      _photos = List<String>.from(widget.initialPhotos);
    }
    if (oldWidget.initialVideos != widget.initialVideos) {
      _videos = List<String>.from(widget.initialVideos);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    showTopSnack(context, msg);
  }

  String _normalizeCt(String raw) => normalizeContentType(raw);

  Future<List<html.File>> _openPicker({
    required String accept,
    required bool multiple,
  }) async {
    final input = html.FileUploadInputElement();
    input.accept = accept;
    input.multiple = multiple;

    final completer = Completer<List<html.File>>();
    input.onChange.listen((_) {
      final files = input.files;
      completer.complete(files?.toList() ?? <html.File>[]);
    });

    input.click();
    return completer.future;
  }

  Future<Uint8List> _readFileBytes(html.File f) async {
    final c = Completer<Uint8List>();
    final reader = html.FileReader();

    reader.onLoad.listen((_) {
      final r = reader.result;

      // ✅ FIX: result may be ByteBuffer OR Uint8List on web builds
      if (r is ByteBuffer) {
        c.complete(Uint8List.view(r));
      } else if (r is Uint8List) {
        c.complete(r);
      } else {
        c.completeError(Exception('Unexpected FileReader result type: ${r.runtimeType}'));
      }
    });

    reader.onError.listen((_) {
      c.completeError(reader.error ?? Exception('Failed to read file'));
    });

    reader.readAsArrayBuffer(f);
    return c.future;
  }

  bool _looksLikeVideo(html.File f) {
    final name = f.name.toLowerCase();
    final t = f.type.toLowerCase();
    if (t.startsWith('video/')) return true;
    return name.endsWith('.mp4') || name.endsWith('.webm') || name.endsWith('.mov') || name.endsWith('.m4v');
  }

  Future<void> _showChooser() async {
    if (_working || !widget.enabled) return;

    final showCapturePhoto = widget.allowCapturePhoto;
    final showCaptureVideo = widget.allowCaptureVideo;
    final showUpload = widget.allowUploadPhoto || widget.allowUploadVideo;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCapturePhoto)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Capture Photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _capturePhoto();
                  },
                ),
              if (showCaptureVideo)
                ListTile(
                  leading: const Icon(Icons.videocam_outlined),
                  title: const Text('Capture Video'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _captureVideo();
                  },
                ),
              if (showUpload)
                ListTile(
                  leading: const Icon(Icons.upload_file_outlined),
                  title: const Text('Upload'),
                  subtitle: Text(
                    (widget.allowUploadPhoto && widget.allowUploadVideo)
                        ? 'Upload photos or videos'
                        : (widget.allowUploadPhoto ? 'Upload photos' : 'Upload videos'),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _uploadFromFiles();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _capturePhoto() async {
    if (_working) return;
    setState(() {
      _working = true;
      _status = 'Opening camera...';
    });

    try {
      final cap = await capturePhotoBytesViaPopup(context);
      if (cap == null) return;

      final ct = _normalizeCt(cap.contentType);
      if (ct.isEmpty) {
        _toast('Photo contentType missing from capture');
        return;
      }

      setState(() => _status = 'Uploading photo...');
      final url = await widget.uploadPhoto(
        bytes: cap.bytes,
        contentType: ct,
        fileName: cap.fileName,
      );

      setState(() => _photos.add(url));
      widget.onPhotosChanged(List<String>.from(_photos));
    } catch (e) {
      _toast('Photo failed: $e');
    } finally {
      if (mounted) setState(() => _working = false);
      if (mounted) setState(() => _status = null);
    }
  }

  Future<void> _captureVideo() async {
    if (_working) return;
    setState(() {
      _working = true;
      _status = 'Opening recorder...';
    });

    try {
      final cap = await captureVideoBytesViaPopup(context);
      if (cap == null) return;

      final ct = _normalizeCt(cap.contentType); // strips codecs, keeps video/*
      if (ct.isEmpty) {
        _toast('Video contentType missing from capture');
        return;
      }

      setState(() => _status = 'Uploading video...');
      final url = await widget.uploadVideo(
        bytes: cap.bytes,
        contentType: ct,
        fileName: cap.fileName,
      );

      setState(() => _videos.add(url));
      widget.onVideosChanged(List<String>.from(_videos));
    } catch (e) {
      _toast('Video failed: $e');
    } finally {
      if (mounted) setState(() => _working = false);
      if (mounted) setState(() => _status = null);
    }
  }

  
  Future<void> _uploadFromFiles() async {
    if (_working) return;

    setState(() {
      _working = true;
      _status = 'Selecting files...';
    });

    try {
      final accept = (widget.allowUploadPhoto && widget.allowUploadVideo)
          ? 'image/*,video/*'
          : (widget.allowUploadPhoto ? 'image/*' : 'video/*');

      final files = await _openPicker(accept: accept, multiple: true);
      if (files.isEmpty) return;

      for (var i = 0; i < files.length; i++) {
        final f = files[i];
        final isVideo = _looksLikeVideo(f);

        if (isVideo && !widget.allowUploadVideo) continue;
        if (!isVideo && !widget.allowUploadPhoto) continue;

        setState(() => _status = 'Uploading ${i + 1}/${files.length}...');

        final bytes = await _readFileBytes(f);

        // ✅ Do NOT force type. Use uploaded file mime, but normalize it.
        var contentType = _normalizeCt(f.type);
        if (contentType.isEmpty) {
          // only if browser didn't provide a type
          contentType = isVideo ? 'video/mp4' : 'image/jpeg';
        }

        final url = isVideo
            ? await widget.uploadVideo(bytes: bytes, contentType: contentType, fileName: f.name)
            : await widget.uploadPhoto(bytes: bytes, contentType: contentType, fileName: f.name);

        if (isVideo) {
          setState(() => _videos.add(url));
          widget.onVideosChanged(List<String>.from(_videos));
        } else {
          setState(() => _photos.add(url));
          widget.onPhotosChanged(List<String>.from(_photos));
        }
      }
    } catch (e) {
      _toast('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _working = false);
      if (mounted) setState(() => _status = null);
    }
  }

  void _removePhotoAt(int i) {
    setState(() => _photos.removeAt(i));
    widget.onPhotosChanged(List<String>.from(_photos));
  }

  void _removeVideoAt(int i) {
    setState(() => _videos.removeAt(i));
    widget.onVideosChanged(List<String>.from(_videos));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.title ?? 'Media';

    final showVideosUi =
        widget.allowCaptureVideo || widget.allowUploadVideo || _videos.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),

            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: (_working || !widget.enabled) ? null : _showChooser,
                  icon: _working
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add),
                  label: Text(_working ? 'Working...' : 'Add'),
                ),
                const SizedBox(width: 12),
                Text(
                  showVideosUi ? '${_photos.length} photos, ${_videos.length} videos' : '${_photos.length} photos',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),

            if (_status != null) ...[
              const SizedBox(height: 10),
              Text(_status!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
            ],

            const SizedBox(height: 12),

            if (_photos.isNotEmpty) ...[
              Text('Photos', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_photos.length, (i) {
                  final u = _photos[i];
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 96,
                          height: 72,
                          color: Colors.black12,
                          child: Image.network(
                            u,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Center(child: Icon(Icons.broken_image_outlined)),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -10,
                        top: -10,
                        child: InkWell(
                          onTap: () => _removePhotoAt(i),
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
              const SizedBox(height: 14),
            ],

            if (showVideosUi && _videos.isNotEmpty) ...[
              Text('Videos', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_videos.length, (i) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 96,
                          height: 72,
                          color: Colors.black12,
                          child: const Center(child: Icon(Icons.play_circle_outline, size: 30)),
                        ),
                      ),
                      Positioned(
                        right: -10,
                        top: -10,
                        child: InkWell(
                          onTap: () => _removeVideoAt(i),
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
          ],
        ),
      ),
    );
  }
}
