// lib/features/shared/widgets/web_image_pick_web.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<List<String>> pickImagesFromWebInput({
  bool multiple = true,
  bool preferCamera = true,
}) async {
  final input = html.FileUploadInputElement();

  input.accept = 'image/*';
  if (multiple) input.multiple = true;

  // Helps on mobiles/tabs to open camera directly (desktop may ignore)
  if (preferCamera) {
    input.setAttribute('capture', 'environment');
  }

  final completer = Completer<List<String>>();
  var done = false;

  void finish(List<String> out) {
    if (done) return;
    done = true;
    completer.complete(out);
  }

  // When user picks files
  input.onChange.listen((_) async {
    final files = input.files;
    if (files == null || files.isEmpty) {
      finish([]);
      return;
    }

    final out = <String>[];

    for (final f in files) {
      final reader = html.FileReader();
      final r = Completer<void>();
      reader.onLoadEnd.listen((_) => r.complete());
      reader.readAsDataUrl(f);
      await r.future;

      final result = reader.result;
      if (result is String) out.add(result);
    }

    finish(out);
  });

  // If user cancels, browser often returns focus without change
  StreamSubscription<html.Event>? focusSub;
  focusSub = html.window.onFocus.listen((_) async {
    // small delay to allow change event first if selection happened
    await Future.delayed(const Duration(milliseconds: 350));
    if (!done) finish([]);
    await focusSub?.cancel();
  });

  // Safety timeout
  Future.delayed(const Duration(seconds: 30), () async {
    if (!done) finish([]);
    await focusSub?.cancel();
  });

  input.click();
  return completer.future;
}
