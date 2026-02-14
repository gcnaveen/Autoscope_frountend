// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
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
  final completer = Completer<WebPickedImage?>();

  final w = html.window.open(
    'camera_image.html?id=$requestId',
    'autoscope_camera_image',
    'width=520,height=680',
  );

  StreamSubscription<html.MessageEvent>? sub;
  sub = html.window.onMessage.listen((event) async {
    try {
      // security: only accept same-origin messages
      if (event.origin != html.window.location.origin) return;

      final data = event.data;
      if (data is! Map) return;

      if (data['source'] != 'autoscope_camera') return;
      if ((data['id'] ?? '').toString() != requestId) return;

      final type = (data['type'] ?? '').toString();

      if (type == 'cancel') {
        await sub?.cancel();
        completer.complete(null);
        return;
      }

      if (type == 'image_captured') {
        final blob = data['blob'];
        final fileName = (data['fileName'] ?? 'damage.jpg').toString();
        final contentType = (data['contentType'] ?? 'image/jpeg').toString();

        if (blob is html.Blob) {
          final bytes = await _blobToBytes(blob);
          await sub?.cancel();
          completer.complete(
            WebPickedImage(bytes: bytes, fileName: fileName, contentType: contentType),
          );
        }
      }

      if (type == 'error') {
        // ignore errors here, let UI show its own
      }
    } catch (_) {}
  });

  // if popup blocked
  if (w == null) {
    await sub.cancel();
    return null;
  }

  return completer.future;
}

Future<List<WebPickedImage>> pickWebImagesFromGallery({bool multiple = true}) async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = multiple;

  final completer = Completer<List<WebPickedImage>>();

  input.onChange.listen((_) async {
    final files = input.files ?? [];
    final out = <WebPickedImage>[];

    for (final f in files) {
      final bytes = await _fileToBytes(f);
      out.add(
        WebPickedImage(
          bytes: bytes,
          fileName: f.name,
          contentType: f.type.isEmpty ? 'image/jpeg' : f.type,
        ),
      );
    }

    completer.complete(out);
  });

  input.click();
  return completer.future;
}

Future<Uint8List> _blobToBytes(html.Blob blob) {
  final c = Completer<Uint8List>();
  final reader = html.FileReader();

  reader.readAsArrayBuffer(blob);

  reader.onLoad.listen((_) {
    final result = reader.result;
    if (result is ByteBuffer) {
      c.complete(result.asUint8List());
    } else if (result is Uint8List) {
      c.complete(result);
    } else {
      c.completeError('Unexpected blob read type: ${result.runtimeType}');
    }
  });

  reader.onError.listen((_) => c.completeError(reader.error ?? 'blob read error'));
  return c.future;
}

Future<Uint8List> _fileToBytes(html.File file) {
  final c = Completer<Uint8List>();
  final reader = html.FileReader();

  reader.readAsArrayBuffer(file);

  reader.onLoad.listen((_) {
    final result = reader.result;
    if (result is ByteBuffer) {
      c.complete(result.asUint8List());
    } else if (result is Uint8List) {
      c.complete(result);
    } else {
      c.completeError('Unexpected file read type: ${result.runtimeType}');
    }
  });

  reader.onError.listen((_) => c.completeError(reader.error ?? 'file read error'));
  return c.future;
}

