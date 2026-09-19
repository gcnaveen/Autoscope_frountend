// lib/features/shared/utils/image_compress_web.dart
//
// Client-side image resize/compression for "Upload from Files" pickers.
// Mirrors the canvas-to-bytes technique already used by the live camera
// capture path (see widgets/web_camera_capture_web.dart) so both paths
// behave/consistently look the same.

import 'dart:async';
import 'dart:typed_data';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Resizes+re-encodes [originalBytes] as a JPEG for upload, entirely
/// client-side via a canvas draw. Runs on web only.
///
/// - Preserves aspect ratio exactly — the longer side is scaled down to fit
///   [maxDimension], the shorter side is scaled by the exact same factor.
/// - Never upscales: if the image's longer side is already <= [maxDimension]
///   the original bytes are returned unchanged.
/// - On any failure (corrupt file, decode error, canvas export failure) this
///   falls back to returning the original bytes unchanged — compression is a
///   best-effort optimization and must never block an upload.
Future<Uint8List> compressImageBytesForUpload(
  Uint8List originalBytes, {
  int maxDimension = 1920,
  double quality = 0.9,
}) async {
  String? objectUrl;
  try {
    final blob = html.Blob([originalBytes]);
    objectUrl = html.Url.createObjectUrlFromBlob(blob);

    final img = html.ImageElement();

    final loadCompleter = Completer<void>();
    final onLoadSub = img.onLoad.listen((_) {
      if (!loadCompleter.isCompleted) loadCompleter.complete();
    });
    final onErrorSub = img.onError.listen((_) {
      if (!loadCompleter.isCompleted) {
        loadCompleter.completeError(Exception('Failed to decode image'));
      }
    });

    img.src = objectUrl;

    try {
      await loadCompleter.future;
    } finally {
      await onLoadSub.cancel();
      await onErrorSub.cancel();
    }

    final naturalWidth = img.naturalWidth;
    final naturalHeight = img.naturalHeight;
    if (naturalWidth <= 0 || naturalHeight <= 0) {
      return originalBytes;
    }

    // Never upscale — only shrink when the longer side exceeds maxDimension.
    final longerSide = naturalWidth > naturalHeight ? naturalWidth : naturalHeight;
    if (longerSide <= maxDimension) {
      return originalBytes;
    }

    final scale = maxDimension / longerSide;
    final targetWidth = (naturalWidth * scale).round().clamp(1, naturalWidth);
    final targetHeight = (naturalHeight * scale).round().clamp(1, naturalHeight);

    final canvas = html.CanvasElement(width: targetWidth, height: targetHeight);
    canvas.context2D.drawImageScaled(
      img,
      0,
      0,
      targetWidth.toDouble(),
      targetHeight.toDouble(),
    );

    final html.Blob? outBlob = await canvas.toBlob('image/jpeg', quality);
    if (outBlob == null) {
      return originalBytes;
    }

    return await _blobToBytes(outBlob);
  } catch (_) {
    return originalBytes;
  } finally {
    if (objectUrl != null) {
      html.Url.revokeObjectUrl(objectUrl);
    }
  }
}

Future<Uint8List> _blobToBytes(html.Blob blob) async {
  final completer = Completer<Uint8List>();
  final reader = html.FileReader();

  reader.onLoad.listen((_) {
    final r = reader.result;
    if (r is ByteBuffer) {
      completer.complete(Uint8List.view(r));
    } else if (r is Uint8List) {
      completer.complete(r);
    } else {
      completer.completeError(Exception('Unexpected FileReader result type: ${r.runtimeType}'));
    }
  });

  reader.onError.listen((_) {
    completer.completeError(reader.error ?? Exception('Failed to read blob'));
  });

  reader.readAsArrayBuffer(blob);
  return completer.future;
}
