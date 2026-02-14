import 'dart:typed_data';

class PickedWebFile {
  final Uint8List bytes;
  final String name;
  final String mime;
  PickedWebFile({required this.bytes, required this.name, required this.mime});
}

Future<PickedWebFile?> pickWebCapturedImage() async {
  throw UnsupportedError('Web capture is only available on web.');
}

Future<PickedWebFile?> pickWebCapturedVideo() async {
  throw UnsupportedError('Web capture is only available on web.');
}
