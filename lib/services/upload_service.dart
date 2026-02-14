import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:html' as html;


import 'api_client.dart';

class UploadService {
  final ApiClient apiClient;
  UploadService({required this.apiClient});

  /// 1) Ask backend for presigned URL
  Future<Map<String, String>> getPresignedUrl({
    required String fileName,
    required String contentType,
  }) async {
    final res = await apiClient.postJson('/uploads/presign', {
      'fileName': fileName,
      'contentType': contentType,
      'folder': 'inspections',
    });

    return {
      'uploadUrl': res['uploadUrl'],
      'fileUrl': res['fileUrl'],
    };
  }

  Future<Map<String, String>> getPresignedUrlSimple({
    required String fileName,
    required String contentType,
  }) async {
    final res = await apiClient.postJson('/upload/simple-image', {
      'fileName': fileName,
      'contentType': contentType,
      'folder': 'inspections',
    });

    return {
      'uploadUrl': res['uploadUrl'],
      'fileUrl': res['fileUrl'],
    };
  }

  /// 2) Upload bytes directly to S3
  Future<void> uploadToS3({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final r = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Type': contentType,
      },
      body: bytes,
    );

    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('S3 upload failed (${r.statusCode})');
    }
  }

  Future<void> putBlobToPresignedUrl({
    required String uploadUrl,
    required html.Blob blob,
    required String contentType,
  }) async {
    final req = await html.HttpRequest.request(
      uploadUrl,
      method: 'PUT',
      sendData: blob,
      requestHeaders: {'Content-Type': contentType},
    );

    // S3 usually returns 200 or 204 for successful PUT
    if (req.status != 200 && req.status != 204) {
      throw Exception('S3 upload failed: ${req.status} ${req.statusText}');
    }
  }

}
