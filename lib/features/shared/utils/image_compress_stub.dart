// lib/features/shared/utils/image_compress_stub.dart
//
// Non-web fallback: compression is a web-specific optimization (canvas
// based), so on other platforms this just passes the original bytes through
// unchanged.

import 'dart:typed_data';

Future<Uint8List> compressImageBytesForUpload(
  Uint8List originalBytes, {
  int maxDimension = 1920,
  double quality = 0.9,
}) async {
  return originalBytes;
}
