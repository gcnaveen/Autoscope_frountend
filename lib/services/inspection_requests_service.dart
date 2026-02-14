import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'api_client.dart';

class InspectionRequestsService {
  final ApiClient apiClient;
  InspectionRequestsService({required this.apiClient});

  /* =========================================================
     ADMIN – INSPECTION REQUESTS
  ========================================================= */

  Future<List<Map<String, dynamic>>> listAdminRequests() async {
    final res = await apiClient.getJson('/inspection-requests');

    if (res is Map && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }

    if (res is Map && res['data'] is Map && (res['data']['requests'] is List)) {
      return List<Map<String, dynamic>>.from(res['data']['requests']);
    }

    if (res is List) return List<Map<String, dynamic>>.from(res);

    return [];
  }

  /* =========================================================
     INSPECTOR – ASSIGNED REQUESTS
  ========================================================= */

  Future<List<Map<String, dynamic>>> listInspectorAssigned() async {
    final res = await apiClient.getJson('/inspection-requests/inspector/assigned');

    if (res is Map && res['data'] is Map && res['data']['requests'] is List) {
      return List<Map<String, dynamic>>.from(res['data']['requests']);
    }

    if (res is Map && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data']);
    }

    if (res is Map && res['requests'] is List) {
      return List<Map<String, dynamic>>.from(res['requests']);
    }

    if (res is List) return List<Map<String, dynamic>>.from(res);

    return [];
  }

  /* =========================================================
     COMMON – REQUEST DETAILS
  ========================================================= */

  Future<Map<String, dynamic>> getRequestById(String id) async {
    final res = await apiClient.getJson('/inspection-requests/$id');
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /* =========================================================
     ADMIN – ASSIGN / REASSIGN INSPECTOR
  ========================================================= */

  Future<Map<String, dynamic>> assignRequest({
    required String requestId,
    required String inspectorId,
  }) async {
    final res = await apiClient.putJson(
      '/inspection-requests/$requestId/assign',
      {'inspectorId': inspectorId},
    );

    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /* =========================================================
     CHECKLIST TEMPLATES (INSPECTOR)
  ========================================================= */

  Future<List<Map<String, dynamic>>> listActiveChecklistTemplates() async {
    final res = await apiClient.getJson('/checklists/templates/active');

    if (res is Map && res['data'] is Map && res['data']['templates'] is List) {
      return List<Map<String, dynamic>>.from(res['data']['templates']);
    }

    if (res is Map && res['templates'] is List) {
      return List<Map<String, dynamic>>.from(res['templates']);
    }

    if (res is List) return List<Map<String, dynamic>>.from(res);

    return [];
  }

  /* =========================================================
     INSPECTOR – START INSPECTION
  ========================================================= */

  Future<String?> startInspection(String id) async {
    final res = await apiClient.postJson(
      '/checklists/inspections/$id/start',
      {},
    );
    return _extractInspectionId(res);
  }

  String? _extractInspectionId(dynamic res) {
    if (res is! Map) return null;

    final data = res['data'];
    if (data is Map) {
      final id = (data['inspectionId'] ?? data['_id'] ?? data['id'] ?? '').toString().trim();
      return id.isEmpty ? null : id;
    }

    final id = (res['inspectionId'] ?? res['_id'] ?? res['id'] ?? '').toString().trim();
    return id.isEmpty ? null : id;
  }

  /* =========================================================
     UPLOAD – PRESIGNED URL + PUT TO S3
  ========================================================= */

  Future<Map<String, dynamic>> getPresignedUrl({
    required String inspectionRequestId,
    required String typeName,
    required String fileName,
    required String contentType,
    required String mediaType,
    int expiresIn = 14400,
  }) async {
    final safeFileName =
        '${DateTime.now().millisecondsSinceEpoch}_${fileName.replaceAll(' ', '_')}';

    final res = await apiClient.postJson(
      '/upload/presigned-url',
      {
        "inspectionRequestId": inspectionRequestId,
        "typeName": typeName,
        "fileName": safeFileName,
        "contentType": contentType,
        "mediaType": mediaType,
        "expiresIn": expiresIn,
      },
    );

    if (res is Map<String, dynamic>) {
      _throwIfValidationError(res);
      return res;
    }
    if (res is Map) {
      final m = Map<String, dynamic>.from(res);
      _throwIfValidationError(m);
      return m;
    }

    throw Exception('Invalid presigned-url response: $res');
  }

  void _throwIfValidationError(Map<String, dynamic> res) {
    final statusCode = res['statusCode'];
    if (statusCode == 400) {
      final msg = (res['message'] ?? 'Validation failed').toString();
      final errors = res['errors'];

      if (errors is List && errors.isNotEmpty) {
        final details = errors
            .whereType<Map>()
            .map((e) => '${e['field']}: ${e['message']}')
            .join(', ');
        throw Exception('$msg ($details)');
      }
      throw Exception(msg);
    }
  }

  Future<void> uploadToS3({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final putRes = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );

    if (putRes.statusCode != 200 && putRes.statusCode != 204) {
      throw Exception('S3 upload failed: ${putRes.statusCode} ${putRes.body}');
    }
  }

  Future<String> uploadInspectionMedia({
    required String inspectionRequestId,
    required String typeName,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required String mediaType,
  }) async {
    final safeName = _safeFileName(fileName);

    // ✅ ONLY damage photos go through the NEW API
    if (mediaType.toLowerCase() == 'photos' && _isDamageType(typeName)) {
      final simple = await getPresignedUrlSimple(
        fileName: safeName,
        contentType: contentType,
      );

      final uploadUrl = simple['uploadUrl']!;
      final fileUrl = simple['fileUrl']!;

      await uploadToS3(uploadUrl: uploadUrl, bytes: bytes, contentType: contentType);
      return fileUrl;
    }

    // ✅ Everything else stays the OLD way
    final presignRes = await getPresignedUrl(
      inspectionRequestId: inspectionRequestId,
      typeName: typeName,
      fileName: safeName,
      contentType: contentType,
      mediaType: mediaType,
      expiresIn: 14400,
    );

    final data = presignRes['data'];
    if (data is! Map) throw Exception('Missing data in presigned response');

    final uploadUrl = (data['uploadUrl'] ?? '').toString();
    final fileUrl = (data['fileUrl'] ?? '').toString();

    if (uploadUrl.isEmpty || fileUrl.isEmpty) {
      throw Exception('Presigned response missing uploadUrl/fileUrl');
    }

    await uploadToS3(uploadUrl: uploadUrl, bytes: bytes, contentType: contentType);
    return fileUrl;
  }



  Future<String> uploadInspectionPhoto({
    required String inspectionRequestId,
    required String typeName,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) {
    // ✅ Use NEW API only for damage marker images
    final tn = typeName.trim().toLowerCase();
    if (tn == 'damages' || tn == 'damage') {
      return uploadDamageMarkerImage(
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
      );
    }

    // ✅ Everything else stays on old API (no change)
    return uploadInspectionMedia(
      inspectionRequestId: inspectionRequestId,
      typeName: typeName,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
      mediaType: 'photos',
    );
  }


  Future<String> uploadInspectionVideo({
    required String inspectionRequestId,
    required String typeName,
    required Uint8List bytes,
    required String fileName,
  }) {
    return uploadInspectionMedia(
      inspectionRequestId: inspectionRequestId,
      typeName: typeName,
      bytes: bytes,
      fileName: fileName,
      contentType: 'video/mp4',
      mediaType: 'videos',
    );
  }

  // =========================================================
  // ✅ NEW: SIMPLE UPLOAD FOR DAMAGE MARKER ONLY
  // =========================================================

  bool _isDamageType(String typeName) {
    final t = typeName.trim().toLowerCase();
    return t == 'damages' || t == 'damage';
  }

  String _safeFileName(String fileName) =>
      '${DateTime.now().millisecondsSinceEpoch}_${fileName.replaceAll(' ', '_')}';

  Future<Map<String, String>> getPresignedUrlSimple({
    required String fileName,
    required String contentType,
  }) async {
    // NOTE: fileName should already be "safe"
    final res = await apiClient.postJson('/upload/simple-image', {
      'fileName': fileName,
      'contentType': contentType,
      'folder': 'inspections',
    });

    // backend may return {uploadUrl,fileUrl} OR {data:{uploadUrl,fileUrl}}
    final data = (res is Map && res['data'] is Map) ? res['data'] as Map : (res as Map);

    final uploadUrl = (data['uploadUrl'] ?? '').toString();
    final fileUrl = (data['fileUrl'] ?? '').toString();

    if (uploadUrl.isEmpty || fileUrl.isEmpty) {
      throw Exception('simple-image response missing uploadUrl/fileUrl');
    }

    return {'uploadUrl': uploadUrl, 'fileUrl': fileUrl};
  }

  Future<String> uploadDamageMarkerImage({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final presigned = await getPresignedUrlSimple(
      fileName: fileName,
      contentType: contentType,
    );

    await uploadToS3(
      uploadUrl: presigned['uploadUrl']!,
      bytes: bytes,
      contentType: contentType,
    );

    return presigned['fileUrl']!;
  }


  // Future<String> uploadDamageMarkerPhoto({
  //   required Uint8List bytes,
  //   required String fileName,
  //   required String contentType,
  // }) async {
  //   final presign = await getPresignedUrlSimple(fileName: fileName, contentType: contentType);
  //   final uploadUrl = presign['uploadUrl']!;
  //   final fileUrl = presign['fileUrl']!;

  //   await uploadToS3(uploadUrl: uploadUrl, bytes: bytes, contentType: contentType);
  //   return fileUrl;
  // }

  /* =========================================================
     INSPECTOR – SUBMIT INSPECTION
  ========================================================= */

  Future<Map<String, dynamic>> submitInspection(Map<String, dynamic> payload) async {
    final res = await apiClient.postJson('/checklists/inspections', payload);

    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'raw': res};
  }

  /* =========================================================
    GET INSPECTION DETAILS
  ========================================================= */

  Future<Map<String, dynamic>> getInspectionById(String inspectionId) async {
    final res = await apiClient.getJson('/checklists/inspections/$inspectionId');

    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }

    throw Exception('Unexpected response type: ${res.runtimeType}');
  }

  Future<Map<String, dynamic>> fetchInspectionReportMock(String requestId) async {
    return {
      "reference": "REF-$requestId",
      "name": "Customer Name",
      "emirate": "Dubai",
      "inspectedOn": DateTime.now().toIso8601String().substring(0, 10),
      "summary": "Mock inspector summary. Replace with API data later.",
      "vehicleLine": "Toyota Camry (2020) • ABC-123 • 55,000 km",
      "sections": [
        {
          "title": "Exterior",
          "heroUrl": "https://picsum.photos/1200/700?random=1",
          "photos": List.generate(8, (i) => "https://picsum.photos/400/300?random=${i + 10}"),
        },
        {
          "title": "Interior",
          "heroUrl": "https://picsum.photos/1200/700?random=2",
          "photos": List.generate(6, (i) => "https://picsum.photos/400/300?random=${i + 30}"),
        },
      ],
    };
  }
}


