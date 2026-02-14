// lib/features/shared/widgets/web_camera_capture_web.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<String?> capturePhotoViaPopupPage({
  int width = 420,
  int height = 560,
}) async {
  final id = DateTime.now().microsecondsSinceEpoch.toString();
  final completer = Completer<String?>();

  late final StreamSubscription<html.MessageEvent> sub;
  sub = html.window.onMessage.listen((event) {
    final data = event.data;
    if (data is! Map) return;
    if (data['source'] != 'autoscope_camera') return;
    if (data['id'] != id) return;

    final type = data['type']?.toString();
    if (type == 'captured') {
      sub.cancel();
      completer.complete(data['dataUrl']?.toString());
    } else if (type == 'cancel' || type == 'error') {
      sub.cancel();
      completer.complete(null);
    }
  });

  final origin = html.window.location.origin; // https://...ngrok... OR http://localhost
  final url = '$origin/camera.html?id=$id';

  final popupBase = html.window.open(
    url,
    'autoscopecam_$id',
    'popup=yes,width=$width,height=$height',
  );

  if (popupBase == null) {
    await sub.cancel();
    return null;
  }

  return completer.future.timeout(
    const Duration(seconds: 60),
    onTimeout: () async {
      await sub.cancel();
      try {
        (popupBase as dynamic).close();
      } catch (_) {}
      return null;
    },
  );
}
