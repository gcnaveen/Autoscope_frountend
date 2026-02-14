import 'dart:async';
import 'dart:typed_data';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<({Uint8List bytes, String fileName})?> pickOneMp4VideoFromWeb({bool preferCamera = true}) async {
  final input = html.FileUploadInputElement()
    ..accept = 'video/*'
    ..multiple = false;

  if (preferCamera) {
    // helps mobile browsers open camera directly
    input.setAttribute('capture', 'environment');
  }

  final completer = Completer<({Uint8List bytes, String fileName})?>();

  input.onChange.listen((_) async {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }

    final file = files.first;
    final name = file.name;

    // Enforce MP4 (as your backend expects contentType video/mp4)
    final isMp4 = (file.type.toLowerCase().contains('mp4')) || name.toLowerCase().endsWith('.mp4');
    if (!isMp4) {
      completer.completeError('Please select/record an MP4 video only.');
      return;
    }

    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);

    reader.onError.listen((_) {
      completer.completeError('Failed to read video file.');
    });

    reader.onLoadEnd.listen((_) {
      final buf = reader.result as ByteBuffer;
      completer.complete((bytes: buf.asUint8List(), fileName: name));
    });
  });

  input.click();

  return completer.future;
}
