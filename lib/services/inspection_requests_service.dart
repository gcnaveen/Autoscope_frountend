// import 'dart:typed_data';
// import 'package:http/http.dart' as http;

// import 'api_client.dart';

// class InspectionRequestsService {
//   final ApiClient apiClient;
//   InspectionRequestsService({required this.apiClient});

//   /* =========================================================
//      ADMIN – INSPECTION REQUESTS
//   ========================================================= */

//   Future<List<Map<String, dynamic>>> listAdminRequests() async {
//     final res = await apiClient.getJson('/inspection-requests');

//     if (res is Map && res['data'] is List) {
//       return List<Map<String, dynamic>>.from(res['data']);
//     }

//     if (res is Map && res['data'] is Map && (res['data']['requests'] is List)) {
//       return List<Map<String, dynamic>>.from(res['data']['requests']);
//     }

//     if (res is List) return List<Map<String, dynamic>>.from(res);

//     return [];
//   }

//   /* =========================================================
//      INSPECTOR – ASSIGNED REQUESTS
//   ========================================================= */

//   Future<List<Map<String, dynamic>>> listInspectorAssigned() async {
//     final res = await apiClient.getJson('/inspection-requests/inspector/assigned');

//     if (res is Map && res['data'] is Map && res['data']['requests'] is List) {
//       return List<Map<String, dynamic>>.from(res['data']['requests']);
//     }

//     if (res is Map && res['data'] is List) {
//       return List<Map<String, dynamic>>.from(res['data']);
//     }

//     if (res is Map && res['requests'] is List) {
//       return List<Map<String, dynamic>>.from(res['requests']);
//     }

//     if (res is List) return List<Map<String, dynamic>>.from(res);

//     return [];
//   }

//   /* =========================================================
//      COMMON – REQUEST DETAILS
//   ========================================================= */

//   Future<Map<String, dynamic>> getRequestById(String id) async {
//     final res = await apiClient.getJson('/inspection-requests/$id');
//     if (res is Map<String, dynamic>) return res;
//     if (res is Map) return Map<String, dynamic>.from(res);
//     return {};
//   }

//   /* =========================================================
//      ADMIN – ASSIGN / REASSIGN INSPECTOR
//   ========================================================= */

//   Future<Map<String, dynamic>> assignRequest({
//     required String requestId,
//     required String inspectorId,
//   }) async {
//     final res = await apiClient.putJson(
//       '/inspection-requests/$requestId/assign',
//       {'inspectorId': inspectorId},
//     );

//     if (res is Map<String, dynamic>) return res;
//     if (res is Map) return Map<String, dynamic>.from(res);
//     return {};
//   }

//   /* =========================================================
//      CHECKLIST TEMPLATES (INSPECTOR)
//   ========================================================= */

//   Future<List<Map<String, dynamic>>> listActiveChecklistTemplates() async {
//     final res = await apiClient.getJson('/checklists/templates/active');

//     if (res is Map && res['data'] is Map && res['data']['templates'] is List) {
//       return List<Map<String, dynamic>>.from(res['data']['templates']);
//     }

//     if (res is Map && res['templates'] is List) {
//       return List<Map<String, dynamic>>.from(res['templates']);
//     }

//     if (res is List) return List<Map<String, dynamic>>.from(res);

//     return [];
//   }

//   /* =========================================================
//      INSPECTOR – START INSPECTION
//   ========================================================= */

//   Future<String?> startInspection(String id) async {
//     final res = await apiClient.postJson(
//       '/checklists/inspections/$id/start',
//       {},
//     );
//     return _extractInspectionId(res);
//   }

//   String? _extractInspectionId(dynamic res) {
//     if (res is! Map) return null;

//     final data = res['data'];
//     if (data is Map) {
//       final id = (data['inspectionId'] ?? data['_id'] ?? data['id'] ?? '').toString().trim();
//       return id.isEmpty ? null : id;
//     }

//     final id = (res['inspectionId'] ?? res['_id'] ?? res['id'] ?? '').toString().trim();
//     return id.isEmpty ? null : id;
//   }

//   /* =========================================================
//      UPLOAD – PRESIGNED URL + PUT TO S3
//   ========================================================= */

//   Future<Map<String, dynamic>> getPresignedUrl({
//     required String inspectionRequestId,
//     required String typeName,
//     required String fileName,
//     required String contentType,
//     required String mediaType,
//     int expiresIn = 14400,
//   }) async {
//     final safeFileName =
//         '${DateTime.now().millisecondsSinceEpoch}_${fileName.replaceAll(' ', '_')}';

//     final res = await apiClient.postJson(
//       '/upload/presigned-url',
//       {
//         "inspectionRequestId": inspectionRequestId,
//         "typeName": typeName,
//         "fileName": safeFileName,
//         "contentType": contentType,
//         "mediaType": mediaType,
//         "expiresIn": expiresIn,
//       },
//     );

//     if (res is Map<String, dynamic>) {
//       _throwIfValidationError(res);
//       return res;
//     }
//     if (res is Map) {
//       final m = Map<String, dynamic>.from(res);
//       _throwIfValidationError(m);
//       return m;
//     }

//     throw Exception('Invalid presigned-url response: $res');
//   }

//   void _throwIfValidationError(Map<String, dynamic> res) {
//     final statusCode = res['statusCode'];
//     if (statusCode == 400) {
//       final msg = (res['message'] ?? 'Validation failed').toString();
//       final errors = res['errors'];

//       if (errors is List && errors.isNotEmpty) {
//         final details = errors
//             .whereType<Map>()
//             .map((e) => '${e['field']}: ${e['message']}')
//             .join(', ');
//         throw Exception('$msg ($details)');
//       }
//       throw Exception(msg);
//     }
//   }

//   Future<void> uploadToS3({
//     required String uploadUrl,
//     required Uint8List bytes,
//     required String contentType,
//   }) async {
//     final putRes = await http.put(
//       Uri.parse(uploadUrl),
//       headers: {'Content-Type': contentType},
//       body: bytes,
//     );

//     if (putRes.statusCode != 200 && putRes.statusCode != 204) {
//       throw Exception('S3 upload failed: ${putRes.statusCode} ${putRes.body}');
//     }
//   }

//   Future<String> uploadInspectionMedia({
//     required String inspectionRequestId,
//     required String typeName,
//     required Uint8List bytes,
//     required String fileName,
//     required String contentType,
//     required String mediaType,
//   }) async {
//     final safeName = _safeFileName(fileName);

//     // ✅ ONLY damage photos go through the NEW API
//     if (mediaType.toLowerCase() == 'photos' && _isDamageType(typeName)) {
//       final simple = await getPresignedUrlSimple(
//         fileName: safeName,
//         contentType: contentType,
//       );

//       final uploadUrl = simple['uploadUrl']!;
//       final fileUrl = simple['fileUrl']!;

//       await uploadToS3(uploadUrl: uploadUrl, bytes: bytes, contentType: contentType);
//       return fileUrl;
//     }

//     // ✅ Everything else stays the OLD way
//     final presignRes = await getPresignedUrl(
//       inspectionRequestId: inspectionRequestId,
//       typeName: typeName,
//       fileName: safeName,
//       contentType: contentType,
//       mediaType: mediaType,
//       expiresIn: 14400,
//     );

//     final data = presignRes['data'];
//     if (data is! Map) throw Exception('Missing data in presigned response');

//     final uploadUrl = (data['uploadUrl'] ?? '').toString();
//     final fileUrl = (data['fileUrl'] ?? '').toString();

//     if (uploadUrl.isEmpty || fileUrl.isEmpty) {
//       throw Exception('Presigned response missing uploadUrl/fileUrl');
//     }

//     await uploadToS3(uploadUrl: uploadUrl, bytes: bytes, contentType: contentType);
//     return fileUrl;
//   }



//   Future<String> uploadInspectionPhoto({
//     required String inspectionRequestId,
//     required String typeName,
//     required Uint8List bytes,
//     required String fileName,
//     required String contentType,
//   }) {
//     // ✅ Use NEW API only for damage marker images
//     final tn = typeName.trim().toLowerCase();
//     if (tn == 'damages' || tn == 'damage') {
//       return uploadDamageMarkerImage(
//         bytes: bytes,
//         fileName: fileName,
//         contentType: contentType,
//       );
//     }

//     // ✅ Everything else stays on old API (no change)
//     return uploadInspectionMedia(
//       inspectionRequestId: inspectionRequestId,
//       typeName: typeName,
//       bytes: bytes,
//       fileName: fileName,
//       contentType: contentType,
//       mediaType: 'photos',
//     );
//   }


//   Future<String> uploadInspectionVideo({
//     required String inspectionRequestId,
//     required String typeName,
//     required Uint8List bytes,
//     required String fileName,
//   }) {
//     return uploadInspectionMedia(
//       inspectionRequestId: inspectionRequestId,
//       typeName: typeName,
//       bytes: bytes,
//       fileName: fileName,
//       contentType: 'video/mp4',
//       mediaType: 'videos',
//     );
//   }

//   // =========================================================
//   // ✅ NEW: SIMPLE UPLOAD FOR DAMAGE MARKER ONLY
//   // =========================================================

//   bool _isDamageType(String typeName) {
//     final t = typeName.trim().toLowerCase();
//     return t == 'damages' || t == 'damage';
//   }

//   String _safeFileName(String fileName) =>
//       '${DateTime.now().millisecondsSinceEpoch}_${fileName.replaceAll(' ', '_')}';

//   Future<Map<String, String>> getPresignedUrlSimple({
//     required String fileName,
//     required String contentType,
//   }) async {
//     // NOTE: fileName should already be "safe"
//     final res = await apiClient.postJson('/upload/simple-image', {
//       'fileName': fileName,
//       'contentType': contentType,
//       'folder': 'inspections',
//     });

//     // backend may return {uploadUrl,fileUrl} OR {data:{uploadUrl,fileUrl}}
//     final data = (res is Map && res['data'] is Map) ? res['data'] as Map : (res as Map);

//     final uploadUrl = (data['uploadUrl'] ?? '').toString();
//     final fileUrl = (data['fileUrl'] ?? '').toString();

//     if (uploadUrl.isEmpty || fileUrl.isEmpty) {
//       throw Exception('simple-image response missing uploadUrl/fileUrl');
//     }

//     return {'uploadUrl': uploadUrl, 'fileUrl': fileUrl};
//   }

//   Future<String> uploadDamageMarkerImage({
//     required Uint8List bytes,
//     required String fileName,
//     required String contentType,
//   }) async {
//     final presigned = await getPresignedUrlSimple(
//       fileName: fileName,
//       contentType: contentType,
//     );

//     await uploadToS3(
//       uploadUrl: presigned['uploadUrl']!,
//       bytes: bytes,
//       contentType: contentType,
//     );

//     return presigned['fileUrl']!;
//   }


//   // Future<String> uploadDamageMarkerPhoto({
//   //   required Uint8List bytes,
//   //   required String fileName,
//   //   required String contentType,
//   // }) async {
//   //   final presign = await getPresignedUrlSimple(fileName: fileName, contentType: contentType);
//   //   final uploadUrl = presign['uploadUrl']!;
//   //   final fileUrl = presign['fileUrl']!;

//   //   await uploadToS3(uploadUrl: uploadUrl, bytes: bytes, contentType: contentType);
//   //   return fileUrl;
//   // }

//   /* =========================================================
//      INSPECTOR – SUBMIT INSPECTION
//   ========================================================= */

//   Future<Map<String, dynamic>> submitInspection(Map<String, dynamic> payload) async {
//     final res = await apiClient.postJson('/checklists/inspections', payload);

//     if (res is Map<String, dynamic>) return res;
//     if (res is Map) return Map<String, dynamic>.from(res);
//     return {'raw': res};
//   }

//   /* =========================================================
//     GET INSPECTION DETAILS
//   ========================================================= */

//   Future<Map<String, dynamic>> getInspectionById(String inspectionId) async {
//     final res = await apiClient.getJson('/checklists/inspections/$inspectionId');

//     if (res is Map) {
//       return Map<String, dynamic>.from(res);
//     }

//     throw Exception('Unexpected response type: ${res.runtimeType}');
//   }

//   Future<Map<String, dynamic>> fetchInspectionReportMock(String requestId) async {
//     return {
//       "reference": "REF-$requestId",
//       "name": "Customer Name",
//       "emirate": "Dubai",
//       "inspectedOn": DateTime.now().toIso8601String().substring(0, 10),
//       "summary": "Mock inspector summary. Replace with API data later.",
//       "vehicleLine": "Toyota Camry (2020) • ABC-123 • 55,000 km",
//       "sections": [
//         {
//           "title": "Exterior",
//           "heroUrl": "https://picsum.photos/1200/700?random=1",
//           "photos": List.generate(8, (i) => "https://picsum.photos/400/300?random=${i + 10}"),
//         },
//         {
//           "title": "Interior",
//           "heroUrl": "https://picsum.photos/1200/700?random=2",
//           "photos": List.generate(6, (i) => "https://picsum.photos/400/300?random=${i + 30}"),
//         },
//       ],
//     };
//   }
// }


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
     ✅ VEHICLE MAKE / MODEL (NEW)
     - API-first
     - Tries multiple endpoints (so it works with your backend even if route differs)
     - Normalizes responses into List<String>
  ========================================================= */

  Future<dynamic> _tryGet(String path) async {
    try {
      return await apiClient.getJson(path);
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> _tryPost(String path, Map<String, dynamic> body) async {
    try {
      return await apiClient.postJson(path, body);
    } catch (_) {
      return null;
    }
  }

  List<String> _normalizeStringList(dynamic res) {
    dynamic v = res;

    // unwrap common formats
    if (v is Map && v['data'] != null) v = v['data'];
    if (v is Map && v['result'] != null) v = v['result'];

    // { data: { makes: [...] } } or { data: { models: [...] } } etc.
    if (v is Map) {
      for (final k in const ['makes', 'models', 'items', 'list', 'rows', 'values']) {
        if (v[k] is List) {
          v = v[k];
          break;
        }
      }
    }

    final out = <String>[];

    if (v is List) {
      for (final x in v) {
        if (x is String) out.add(x.trim());
        if (x is Map && x['name'] != null) out.add(x['name'].toString().trim());
        if (x is Map && x['label'] != null) out.add(x['label'].toString().trim());
        if (x is Map && x['value'] != null) out.add(x['value'].toString().trim());
      }
    }

    out.removeWhere((e) => e.isEmpty);

    // unique + sort
    final set = <String>{};
    final uniq = <String>[];
    for (final s in out) {
      final t = s.trim();
      if (t.isEmpty) continue;
      if (set.add(t)) uniq.add(t);
    }

    uniq.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return uniq;
  }

  /// ✅ Get vehicle makes list from backend
  Future<List<Map<String, dynamic>>> listVehicleMakesDetailed() async {
    final res = await apiClient.getJson('/admin/makes');

    dynamic list = res;
    if (res is Map && res['data'] is List) list = res['data'];

    if (list is! List) return [];

    final out = <Map<String, dynamic>>[];

    for (final x in list) {
      if (x is String) {
        // If backend returns only strings, id will be missing.
        out.add({'_id': '', 'name': x});
      } else if (x is Map) {
        final m = Map<String, dynamic>.from(x);
        final id = (m['_id'] ?? m['id'] ?? '').toString();
        final name = (m['name'] ?? m['make'] ?? '').toString();
        out.add({'_id': id, 'name': name});
      }
    }

    // clean + unique + sort
    out.removeWhere((e) => (e['name'] ?? '').toString().trim().isEmpty);
    final seen = <String>{};
    final uniq = <Map<String, dynamic>>[];
    for (final e in out) {
      final name = (e['name'] ?? '').toString().trim();
      if (seen.add(name.toUpperCase())) uniq.add(e);
    }
    uniq.sort((a, b) => a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase()));
    return uniq;
  }

  /// ✅ GET makes (names only) - keeps your old signature working
  Future<List<String>> listVehicleMakes() async {
    final detailed = await listVehicleMakesDetailed();
    return detailed.map((e) => (e['name'] ?? '').toString()).where((s) => s.trim().isNotEmpty).toList();
  }

  /// ✅ GET models for a makeId (your endpoint uses /admin/models/:make)
  Future<List<String>> listVehicleModels(String makeId) async {
    final mk = makeId.trim();
    if (mk.isEmpty) return [];

    final res = await apiClient.getJson('/admin/models/${Uri.encodeComponent(mk)}');

    dynamic list = res;
    if (res is Map && res['data'] is List) list = res['data'];

    if (list is List) {
      final out = <String>[];
      for (final x in list) {
        if (x is String) out.add(x.trim());
        if (x is Map && x['name'] != null) out.add(x['name'].toString().trim());
      }
      out.removeWhere((e) => e.isEmpty);
      out.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return out.toSet().toList();
    }

    return [];
  }

  /// ✅ POST add make
  String? _extractIdFromRes(dynamic res) {
    if (res is! Map) return null;

    dynamic data = res['data'];
    if (data is Map) {
      final id = (data['id'] ?? data['_id'] ?? data['makeId'] ?? data['modelId'])?.toString().trim();
      if (id != null && id.isNotEmpty) return id;

    // sometimes makeId is object { _id, name }
    final mk = data['makeId'];
    if (mk is Map) {
      final mid = (mk['_id'] ?? mk['id'])?.toString().trim();
      if (mid != null && mid.isNotEmpty) return mid;
    }
  }

  final id = (res['id'] ?? res['_id'])?.toString().trim();
  return (id == null || id.isEmpty) ? null : id;
}
  /// returns created makeId (or null if backend doesn't return it)
  Future<String?> addVehicleMake(String name) async {
    final n = name.trim();
    if (n.isEmpty) return null;

    try {
      final res = await apiClient.postJson('/admin/makes', {'name': n});
      return _extractIdFromRes(res);
    } catch (e) {
      final s = e.toString().toLowerCase();
      if (s.contains('already') || s.contains('exists') || s.contains('duplicate') || s.contains('409')) {
        return null; // ignore duplicate
      }
      rethrow;
    }
  }

  /// ✅ POST add model (needs makeId!)
  Future<void> addVehicleModel({required String makeId, required String name}) async {
    final mk = makeId.trim();
    final n = name.trim();
    if (mk.isEmpty || n.isEmpty) return;

    try {
      await apiClient.postJson('/admin/models', {
        'name': n,
        'makeId': mk,
      });
    } catch (e) {
      final s = e.toString().toLowerCase();
      if (s.contains('already') || s.contains('exists') || s.contains('duplicate') || s.contains('409')) {
        return; // ignore duplicate
      }
      rethrow;
    }
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
