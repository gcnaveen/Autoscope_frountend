// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';

// // ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;

// class CapturedBytes {
//   final Uint8List bytes;
//   final String contentType;
//   final String fileName;

//   const CapturedBytes({
//     required this.bytes,
//     required this.contentType,
//     required this.fileName,
//   });
// }

// /// Public helpers used by MediaUploader
// Future<CapturedBytes?> capturePhotoBytesViaPopup() {
//   return _captureBytesViaPopup(mode: 'photo');
// }

// Future<CapturedBytes?> captureVideoBytesViaPopup() {
//   return _captureBytesViaPopup(mode: 'video');
// }

// Future<CapturedBytes?> _captureBytesViaPopup({required String mode}) async {
//   final completer = Completer<CapturedBytes?>();

//   // open popup (served from /web folder)
//   final popup = html.window.open(
//     'camera_capture.html?mode=$mode',
//     'autoscopecam_$mode',
//     'width=520,height=760',
//   );

//   StreamSubscription<html.MessageEvent>? sub;
//   Timer? timeout;
//   Timer? closedPoll;

//   void finish(CapturedBytes? result) {
//     if (completer.isCompleted) return;
//     timeout?.cancel();
//     closedPoll?.cancel();
//     sub?.cancel();
//     completer.complete(result);
//   }

//   // If popup blocked or failed
//   if (popup == null) {
//     return null;
//   }

//   // Timeout safety (in case no message comes)
//   timeout = Timer(const Duration(minutes: 5), () => finish(null));

//   // If user closes popup without sending anything
//   closedPoll = Timer.periodic(const Duration(milliseconds: 300), (_) {
//     try {
//       final isClosed = popup.closed ?? false;
//       if (isClosed) finish(null);
//     } catch (_) {
//       // ignore cross-window issues
//     }
//   });

//   sub = html.window.onMessage.listen((event) {
//     try {
//       final data = event.data;

//       // Case A: Map payload
//       if (data is Map) {
//         final map = Map<String, dynamic>.from(data);

//         // Optional type check if your HTML sends it
//         // If not present, we still accept as long as bytes exist.
//         final ok = map['ok'];
//         if (ok == false) {
//           finish(null);
//           return;
//         }

//         Uint8List? bytes;
//         String? contentType;
//         String? fileName;

//         // bytes may come as:
//         // - base64 string in "bytes" or "base64"
//         // - dataUrl string in "dataUrl"
//         // - ByteBuffer / Uint8List
//         final rawBytes = map['bytes'] ?? map['base64'] ?? map['data'] ?? map['buffer'];
//         final rawDataUrl = map['dataUrl'] ?? map['dataURL'];

//         contentType = (map['contentType'] ?? map['mimeType'] ?? '').toString();
//         fileName = (map['fileName'] ?? map['filename'] ?? '').toString();

//         if (rawDataUrl is String && rawDataUrl.startsWith('data:')) {
//           final parsed = _bytesFromDataUrl(rawDataUrl);
//           bytes = parsed.item1;
//           contentType = parsed.item2 ?? contentType;
//           if (fileName.isEmpty) {
//             fileName = mode == 'video' ? 'capture.webm' : 'capture.jpg';
//           }
//         } else if (rawBytes is String) {
//           // If it's a dataUrl anyway
//           if (rawBytes.startsWith('data:')) {
//             final parsed = _bytesFromDataUrl(rawBytes);
//             bytes = parsed.item1;
//             contentType = parsed.item2 ?? contentType;
//           } else {
//             bytes = base64Decode(rawBytes);
//           }
//           if (fileName.isEmpty) {
//             fileName = mode == 'video' ? 'capture.webm' : 'capture.jpg';
//           }
//         } else if (rawBytes is ByteBuffer) {
//           bytes = rawBytes.asUint8List();
//           if (fileName.isEmpty) fileName = mode == 'video' ? 'capture.webm' : 'capture.jpg';
//         } else if (rawBytes is Uint8List) {
//           bytes = rawBytes;
//           if (fileName.isEmpty) fileName = mode == 'video' ? 'capture.webm' : 'capture.jpg';
//         }

//         // Fallback content types
//         if (contentType.isEmpty) {
//           contentType = mode == 'video' ? 'video/webm' : 'image/jpeg';
//         }

//         if (bytes == null || bytes.isEmpty) {
//           finish(null);
//           return;
//         }

//         finish(CapturedBytes(bytes: bytes, contentType: contentType, fileName: fileName));
//         return;
//       }

//       // Case B: String dataUrl directly
//       if (data is String && data.startsWith('data:')) {
//         final parsed = _bytesFromDataUrl(data);
//         final bytes = parsed.item1;
//         final contentType = parsed.item2 ?? (mode == 'video' ? 'video/webm' : 'image/jpeg');
//         final fileName = mode == 'video' ? 'capture.webm' : 'capture.jpg';
//         finish(CapturedBytes(bytes: bytes, contentType: contentType, fileName: fileName));
//         return;
//       }

//       // Case C: ByteBuffer directly
//       if (data is ByteBuffer) {
//         finish(CapturedBytes(
//           bytes: data.asUint8List(),
//           contentType: mode == 'video' ? 'video/webm' : 'image/jpeg',
//           fileName: mode == 'video' ? 'capture.webm' : 'capture.jpg',
//         ));
//         return;
//       }

//       // Unknown payload => ignore
//     } catch (_) {
//       finish(null);
//     }
//   });

//   return completer.future;
// }

// /// returns (bytes, mimeType?)
// _Tuple2<Uint8List, String?> _bytesFromDataUrl(String dataUrl) {
//   // data:<mime>;base64,<payload>
//   final comma = dataUrl.indexOf(',');
//   if (comma < 0) return _Tuple2(Uint8List(0), null);

//   final meta = dataUrl.substring(0, comma); // data:image/jpeg;base64
//   final b64 = dataUrl.substring(comma + 1);

//   String? mime;
//   final m = RegExp(r'^data:([^;]+)').firstMatch(meta);
//   if (m != null) mime = m.group(1);

//   final bytes = base64Decode(b64);
//   return _Tuple2(bytes, mime);
// }

// class _Tuple2<T1, T2> {
//   final T1 item1;
//   final T2 item2;
//   const _Tuple2(this.item1, this.item2);
// }

import 'dart:async';
import 'dart:typed_data';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class CapturedMediaBytes {
  final Uint8List bytes;
  final String contentType; // normalized (no ;codecs=...)
  final String fileName;

  CapturedMediaBytes({
    required this.bytes,
    required this.contentType,
    required this.fileName,
  });
}

String normalizeContentType(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return '';
  // IMPORTANT: backend expects base mime only (e.g. video/webm), not "video/webm;codecs=..."
  return s.split(';').first.trim().toLowerCase();
}

Future<CapturedMediaBytes?> capturePhotoBytesViaPopup({
  Duration timeout = const Duration(minutes: 2),
}) {
  return _captureViaPopup(mode: 'photo', timeout: timeout);
}

Future<CapturedMediaBytes?> captureVideoBytesViaPopup({
  Duration timeout = const Duration(minutes: 3),
}) {
  return _captureViaPopup(mode: 'video', timeout: timeout);
}

/// Backward compatible aliases (your older code may call these)
Future<CapturedMediaBytes?> capturePhotoViaPopupPage() => capturePhotoBytesViaPopup();
Future<CapturedMediaBytes?> captureVideoViaPopupPage() => captureVideoBytesViaPopup();

Future<CapturedMediaBytes?> _captureViaPopup({
  required String mode, // photo | video
  required Duration timeout,
}) async {
  final completer = Completer<CapturedMediaBytes?>();

  html.WindowBase? popup;
  StreamSubscription<html.MessageEvent>? sub;
  Timer? closedPoll;

  try {
    final url = 'camera_capture.html?mode=$mode';

    // MUST open synchronously from the user gesture callstack to avoid popup blockers.
    popup = html.window.open(
      url,
      'autoscopecapture_$mode',
      'width=420,height=780,menubar=no,toolbar=no,location=no,status=no,resizable=yes,scrollbars=yes',
    );

    if (popup == null) {
      // popup blocked
      return null;
    }

    sub = html.window.onMessage.listen((event) {
      // Security: only accept messages from same origin
      if (event.origin != html.window.location.origin) return;

      final data = event.data;

      if (data is! Map) return;
      if ((data['kind'] ?? '').toString() != 'autoscopecapture') return;

      final media = (data['media'] ?? '').toString().toLowerCase();
      if (media != mode) return;

      final ct = normalizeContentType((data['contentType'] ?? '').toString());
      final name = (data['fileName'] ?? '').toString().trim();

      final buf = data['buffer'];

      Uint8List bytes;
      if (buf is ByteBuffer) {
        bytes = Uint8List.view(buf);
      } else if (buf is Uint8List) {
        bytes = buf;
      } else if (buf is List<int>) {
        bytes = Uint8List.fromList(buf);
      } else {
        // unexpected payload
        return;
      }

      if (!completer.isCompleted) {
        completer.complete(
          CapturedMediaBytes(
            bytes: bytes,
            contentType: ct,
            fileName: name.isNotEmpty ? name : '${mode}_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
      }
    });

    // If user closes popup without capturing
    closedPoll = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final closed = (popup as dynamic).closed == true;
      if (closed && !completer.isCompleted) {
        completer.complete(null);
      }
    });

    // Timeout safety
    Future.delayed(timeout, () {
      if (!completer.isCompleted) completer.complete(null);
    });

    final res = await completer.future;
    return res;
  } finally {
    try {
      await sub?.cancel();
    } catch (_) {}
    closedPoll?.cancel();
  }
}
