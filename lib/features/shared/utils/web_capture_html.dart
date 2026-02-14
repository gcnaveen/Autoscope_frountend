import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class WebPickedFile {
  final Uint8List bytes;
  final String name;
  final String mime;

  WebPickedFile({required this.bytes, required this.name, required this.mime});
}

/// Pick from device (file picker)
Future<WebPickedFile?> pickWebFile({
  required String accept,
}) async {
  final input = html.FileUploadInputElement()
    ..accept = accept
    ..multiple = false;

  final completer = Completer<WebPickedFile?>();
  input.onChange.listen((_) async {
    try {
      final file = input.files?.isNotEmpty == true ? input.files!.first : null;
      if (file == null) {
        completer.complete(null);
        return;
      }

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      await reader.onLoad.first;
      final data = reader.result as ByteBuffer;

      completer.complete(
        WebPickedFile(
          bytes: Uint8List.view(data),
          name: file.name,
          mime: file.type.isNotEmpty ? file.type : _guessMimeFromName(file.name),
        ),
      );
    } catch (_) {
      completer.complete(null);
    }
  });

  // Trigger picker
  input.click();
  return completer.future;
}

/// Capture using camera hint (works mainly on mobile web).
/// On desktop browsers, many will still open file picker (browser limitation).
Future<WebPickedFile?> captureWebFile({
  required String accept,
  String capture = 'environment', // or 'user'
}) async {
  final input = html.FileUploadInputElement()
    ..accept = accept
    ..multiple = false;

  // ✅ No .capture setter exists -> set attribute directly
  input.setAttribute('capture', capture);

  final completer = Completer<WebPickedFile?>();
  input.onChange.listen((_) async {
    try {
      final file = input.files?.isNotEmpty == true ? input.files!.first : null;
      if (file == null) {
        completer.complete(null);
        return;
      }

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      final data = reader.result as ByteBuffer;

      completer.complete(
        WebPickedFile(
          bytes: Uint8List.view(data),
          name: file.name,
          mime: file.type.isNotEmpty ? file.type : _guessMimeFromName(file.name),
        ),
      );
    } catch (_) {
      completer.complete(null);
    }
  });

  input.click();
  return completer.future;
}

String _guessMimeFromName(String name) {
  final n = name.toLowerCase();
  if (n.endsWith('.png')) return 'image/png';
  if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
  if (n.endsWith('.webp')) return 'image/webp';
  if (n.endsWith('.mp4')) return 'video/mp4';
  if (n.endsWith('.mov')) return 'video/quicktime';
  if (n.endsWith('.webm')) return 'video/webm';
  return 'application/octet-stream';
}
