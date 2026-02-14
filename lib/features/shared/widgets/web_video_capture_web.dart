import 'dart:async';
import 'dart:html' as html;

class CapturedVideo {
  final html.Blob blob;
  final String fileName;
  final String contentType;

  CapturedVideo({
    required this.blob,
    required this.fileName,
    required this.contentType,
  });
}

Future<CapturedVideo?> captureVideoViaPopupPage({
  required String requestId,
  int width = 420,
  int height = 720,
}) async {
  final completer = Completer<CapturedVideo?>();
  final origin = html.window.location.origin;

  final popup = html.window.open(
    'camera_video.html?id=$requestId',
    'autoscope_video',
    'width=$width,height=$height,menubar=no,toolbar=no,location=no,resizable=yes,scrollbars=yes',
  );

  late StreamSubscription sub;
  sub = html.window.onMessage.listen((event) async {
    // Security: only accept same-origin messages
    if (event.origin != origin) return;

    final data = event.data;
    if (data is! Map) return;
    if (data['source'] != 'autoscope_camera') return;
    if ((data['id'] ?? '').toString() != requestId) return;

    final type = (data['type'] ?? '').toString();

    if (type == 'video_captured') {
      final blob = data['blob'];
      final fileName = (data['fileName'] ?? 'video.webm').toString();
      final contentType = (data['contentType'] ?? 'video/webm').toString();

      if (blob is html.Blob) {
        await sub.cancel();
        popup?.close();
        completer.complete(CapturedVideo(blob: blob, fileName: fileName, contentType: contentType));
      }
    }

    if (type == 'cancel' || type == 'error') {
      await sub.cancel();
      popup?.close();
      completer.complete(null);
    }
  });

  // If user blocks popup / closes window
  Timer.periodic(const Duration(milliseconds: 400), (t) async {
    if (completer.isCompleted) {
      t.cancel();
      return;
    }
    try {
      if (popup == null || popup.closed == true) {
        t.cancel();
        await sub.cancel();
        completer.complete(null);
      }
    } catch (_) {}
  });

  return completer.future;
}
