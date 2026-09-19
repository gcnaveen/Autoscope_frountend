// lib/features/shared/utils/image_compress.dart
export 'image_compress_stub.dart' if (dart.library.html) 'image_compress_web.dart';

/// Returns [fileName] with its extension changed to `.jpg` if it doesn't
/// already look like a JPEG. Use this after [compressImageBytesForUpload]
/// has re-encoded a picked file (e.g. a PNG) to JPEG, so the uploaded
/// filename stays consistent with the actual bytes/contentType sent.
String withJpegFileName(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return fileName;
  final dotIndex = fileName.lastIndexOf('.');
  final base = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
  return '$base.jpg';
}
