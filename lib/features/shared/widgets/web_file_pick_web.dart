// lib/features/shared/widgets/web_file_pick_web.dart
// Mirrors web_image_pick_web.dart's hand-rolled dart:html file picker pattern,
// but for a single non-image file (e.g. .csv) and returns raw bytes instead
// of a data URL, since multipart upload needs the actual file bytes.
// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

class PickedWebFile {
  final String name;
  final Uint8List bytes;
  const PickedWebFile({required this.name, required this.bytes});
}

/// Opens the browser's native file picker restricted to [accept] (e.g. '.csv')
/// and resolves with the picked file's name + raw bytes, or null if the user
/// cancelled / picked nothing.
Future<PickedWebFile?> pickFileFromWebInput({String accept = '.csv'}) async {
  final input = html.FileUploadInputElement();
  input.accept = accept;

  final completer = Completer<PickedWebFile?>();
  var done = false;

  void finish(PickedWebFile? out) {
    if (done) return;
    done = true;
    completer.complete(out);
  }

  input.onChange.listen((_) async {
    final files = input.files;
    if (files == null || files.isEmpty) {
      finish(null);
      return;
    }

    final f = files.first;
    final reader = html.FileReader();
    final r = Completer<void>();
    reader.onLoadEnd.listen((_) => r.complete());
    reader.readAsArrayBuffer(f);
    await r.future;

    final result = reader.result;
    if (result is ByteBuffer) {
      finish(PickedWebFile(name: f.name, bytes: Uint8List.view(result)));
    } else if (result is List<int>) {
      finish(PickedWebFile(name: f.name, bytes: Uint8List.fromList(result)));
    } else {
      finish(null);
    }
  });

  // If user cancels, browser often returns focus without a change event.
  StreamSubscription<html.Event>? focusSub;
  focusSub = html.window.onFocus.listen((_) async {
    await Future.delayed(const Duration(milliseconds: 350));
    if (!done) finish(null);
    await focusSub?.cancel();
  });

  // Safety timeout
  Future.delayed(const Duration(seconds: 60), () async {
    if (!done) finish(null);
    await focusSub?.cancel();
  });

  input.click();
  return completer.future;
}
