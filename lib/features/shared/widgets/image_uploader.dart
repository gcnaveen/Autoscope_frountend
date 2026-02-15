// import 'dart:async';
// import 'dart:typed_data';

// // ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;

// import 'package:flutter/material.dart';

// import '../../../services/service_locator.dart';
// import 'web_camera_capture_web.dart' as cam;

// class ImageUploader extends StatefulWidget {
//   final String typeName;
//   final String inspectionRequestId;

//   final String title;
//   final List<String> initialImages;
//   final void Function(List<String> images) onChanged;

//   final bool enabled;

//   /// keep this as 'photos' because your backend expects mediaType: 'photos'
//   final String mediaType;

//   final bool allowCapture;
//   final bool allowUpload;

//   const ImageUploader({
//     super.key,
//     required this.typeName,
//     required this.inspectionRequestId,
//     required this.title,
//     required this.initialImages,
//     required this.onChanged,
//     this.enabled = true,
//     this.mediaType = 'photos',
//     this.allowCapture = true,
//     this.allowUpload = true,
//   });

//   @override
//   State<ImageUploader> createState() => _ImageUploaderState();
// }

// class _ImageUploaderState extends State<ImageUploader> {
//   late List<String> _images;

//   bool _working = false;
//   String? _status;

//   @override
//   void initState() {
//     super.initState();
//     _images = List<String>.from(widget.initialImages);
//   }

//   @override
//   void didUpdateWidget(covariant ImageUploader oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.initialImages != widget.initialImages) {
//       _images = List<String>.from(widget.initialImages);
//     }
//   }

//   void _toast(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//   }

//   Future<List<html.File>> _openPicker({required bool multiple}) async {
//     final input = html.FileUploadInputElement();
//     input.accept = 'image/*';
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

//   Future<String> _uploadImageBytes({
//     required Uint8List bytes,
//     required String contentType,
//     required String fileName,
//   }) {
//     // Uses your existing service method (same one used in StartInspectionPage)
//     return inspectionRequestsService.uploadInspectionMedia(
//       inspectionRequestId: widget.inspectionRequestId,
//       typeName: widget.typeName,
//       bytes: bytes,
//       fileName: fileName,
//       contentType: contentType,
//       mediaType: widget.mediaType, // 'photos'
//     );
//   }

//   Future<void> _showChooser() async {
//     if (_working || !widget.enabled) return;

//     final showCapture = widget.allowCapture;
//     final showUpload = widget.allowUpload;

//     await showModalBottomSheet<void>(
//       context: context,
//       showDragHandle: true,
//       builder: (ctx) {
//         return SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (showCapture)
//                 ListTile(
//                   leading: const Icon(Icons.photo_camera_outlined),
//                   title: const Text('Capture Photo'),
//                   onTap: () {
//                     Navigator.pop(ctx);
//                     _capturePhoto();
//                   },
//                 ),
//               if (showUpload)
//                 ListTile(
//                   leading: const Icon(Icons.upload_file_outlined),
//                   title: const Text('Upload Photos'),
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
//       // ✅ FIX: use the correct function from web_camera_capture_web.dart
//       final cap = await cam.capturePhotoBytesViaPopup();
//       if (cap == null) return;

//       setState(() => _status = 'Uploading photo...');
//       final url = await _uploadImageBytes(
//         bytes: cap.bytes,
//         contentType: cap.contentType,
//         fileName: cap.fileName,
//       );

//       if (!mounted) return;
//       setState(() => _images.add(url));
//       widget.onChanged(List<String>.from(_images));
//     } catch (e) {
//       _toast('Capture failed: $e');
//     } finally {
//       if (!mounted) return;
//       setState(() {
//         _working = false;
//         _status = null;
//       });
//     }
//   }

//   Future<void> _uploadFromFiles() async {
//     if (_working) return;

//     setState(() {
//       _working = true;
//       _status = 'Selecting files...';
//     });

//     try {
//       final files = await _openPicker(multiple: true);
//       if (files.isEmpty) return;

//       for (var i = 0; i < files.length; i++) {
//         final f = files[i];
//         setState(() => _status = 'Uploading ${i + 1}/${files.length}...');

//         final bytes = await _readFileBytes(f);
//         final contentType =
//             f.type.trim().isNotEmpty ? f.type.trim() : 'image/jpeg';

//         final url = await _uploadImageBytes(
//           bytes: bytes,
//           contentType: contentType,
//           fileName: f.name,
//         );

//         if (!mounted) return;
//         setState(() => _images.add(url));
//         widget.onChanged(List<String>.from(_images));
//       }
//     } catch (e) {
//       _toast('Upload failed: $e');
//     } finally {
//       if (!mounted) return;
//       setState(() {
//         _working = false;
//         _status = null;
//       });
//     }
//   }

//   void _removeAt(int i) {
//     setState(() => _images.removeAt(i));
//     widget.onChanged(List<String>.from(_images));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(widget.title,
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
//                 Text('${_images.length} photos',
//                     style: theme.textTheme.bodyMedium),
//               ],
//             ),

//             if (_status != null) ...[
//               const SizedBox(height: 10),
//               Text(_status!,
//                   style: theme.textTheme.bodySmall
//                       ?.copyWith(color: Colors.black54)),
//             ],

//             if (_images.isNotEmpty) ...[
//               const SizedBox(height: 12),
//               Wrap(
//                 spacing: 10,
//                 runSpacing: 10,
//                 children: List.generate(_images.length, (i) {
//                   final u = _images[i];
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
//                           onTap: () => _removeAt(i),
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

import '../../../services/service_locator.dart';
import 'web_camera_capture_web.dart';

class ImageUploader extends StatefulWidget {
  final String typeName;
  final String inspectionRequestId;
  final String title;

  final List<String> initialImages;
  final void Function(List<String> images) onChanged;

  final bool enabled;

  /// keep for compatibility with your existing calls
  final String mediaType; // usually 'photos'

  const ImageUploader({
    super.key,
    required this.typeName,
    required this.inspectionRequestId,
    required this.title,
    required this.initialImages,
    required this.onChanged,
    this.enabled = true,
    this.mediaType = 'photos',
  });

  @override
  State<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  late List<String> _images;

  bool _working = false;
  String? _status;

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

  Future<List<html.File>> _openPicker() async {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = true;

    final completer = Completer<List<html.File>>();
    input.onChange.listen((_) {
      completer.complete(input.files?.toList() ?? <html.File>[]);
    });

    input.click();
    return completer.future;
  }

  Future<Uint8List> _readFileBytes(html.File f) async {
    final c = Completer<Uint8List>();
    final reader = html.FileReader();

    reader.onLoad.listen((_) {
      final r = reader.result;
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

  Future<void> _showChooser() async {
    if (_working || !widget.enabled) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Capture Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _capture();
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('Upload Photos'),
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

  Future<void> _capture() async {
    if (_working) return;
    setState(() {
      _working = true;
      _status = 'Opening camera...';
    });

    try {
      final cap = await capturePhotoBytesViaPopup();
      if (cap == null) return;

      final ct = normalizeContentType(cap.contentType);
      if (ct.isEmpty) {
        _toast('Photo contentType missing from capture');
        return;
      }

      setState(() => _status = 'Uploading photo...');

      final url = await inspectionRequestsService.uploadInspectionMedia(
        inspectionRequestId: widget.inspectionRequestId,
        typeName: widget.typeName,
        bytes: cap.bytes,
        fileName: cap.fileName,
        contentType: ct,
        mediaType: widget.mediaType, // 'photos'
      );

      setState(() => _images.add(url));
      widget.onChanged(List<String>.from(_images));
    } catch (e) {
      _toast('Capture upload failed: $e');
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
      final files = await _openPicker();
      if (files.isEmpty) return;

      for (var i = 0; i < files.length; i++) {
        final f = files[i];
        setState(() => _status = 'Uploading ${i + 1}/${files.length}...');

        final bytes = await _readFileBytes(f);

        // Use actual file type (don’t force), but normalize for backend validation
        var ct = normalizeContentType(f.type);
        if (ct.isEmpty) ct = 'image/jpeg';

        final url = await inspectionRequestsService.uploadInspectionMedia(
          inspectionRequestId: widget.inspectionRequestId,
          typeName: widget.typeName,
          bytes: bytes,
          fileName: f.name,
          contentType: ct,
          mediaType: widget.mediaType,
        );

        setState(() => _images.add(url));
        widget.onChanged(List<String>.from(_images));
      }
    } catch (e) {
      _toast('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _working = false);
      if (mounted) setState(() => _status = null);
    }
  }

  void _removeAt(int i) {
    setState(() => _images.removeAt(i));
    widget.onChanged(List<String>.from(_images));
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
            Text(widget.title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
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
                Text('${_images.length} photos', style: theme.textTheme.bodyMedium),
              ],
            ),

            if (_status != null) ...[
              const SizedBox(height: 10),
              Text(_status!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
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
