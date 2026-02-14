import 'dart:typed_data';

class WebPickedImage {
  final Uint8List bytes;
  final String fileName;
  final String contentType;

  WebPickedImage({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });
}

Future<WebPickedImage?> openWebCameraForImage({required String requestId}) async {
  return null;
}

Future<List<WebPickedImage>> pickWebImagesFromGallery({bool multiple = true}) async {
  return const [];
}
