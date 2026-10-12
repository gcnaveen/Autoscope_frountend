import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'api_client.dart';

/// ===============================
/// PDF Download Model + Helpers
/// ===============================
class PdfDownload {
  final Uint8List bytes;
  final String fileName;
  final String contentType;

  const PdfDownload({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });
}

String? _fileNameFromDisposition(String? cd) {
  if (cd == null) return null;

  // filename*=UTF-8''encoded-name.pdf
  final star =
      RegExp(r"filename\*\s*=\s*UTF-8''([^;]+)", caseSensitive: false).firstMatch(cd);
  if (star != null) {
    return Uri.decodeFull(star.group(1)!).replaceAll('"', '').trim();
  }

  // filename="name.pdf"
  final normal =
      RegExp(r'filename\s*=\s*"([^"]+)"', caseSensitive: false).firstMatch(cd);
  if (normal != null) return normal.group(1)!.trim();

  // filename=name.pdf
  final bare =
      RegExp(r'filename\s*=\s*([^;]+)', caseSensitive: false).firstMatch(cd);
  if (bare != null) return bare.group(1)!.replaceAll('"', '').trim();

  return null;
}

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

  Future<({List<Map<String, dynamic>> requests, int total, int totalPages})>
      listAdminRequestsPaged({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await apiClient.getJson(
      '/inspection-requests/admin/all?page=$page&limit=$limit',
    );

    List<Map<String, dynamic>> items = [];
    int total = 0;
    int totalPages = 1;

    if (res is Map) {
      final data = res['data'];

      if (data is Map) {
        final list = data['requests'] ?? data['data'] ?? data['items'];
        if (list is List) items = List<Map<String, dynamic>>.from(list);

        final pag = data['pagination'];
        if (pag is Map) {
          total = _asInt(pag['total'] ?? pag['totalCount']) ?? 0;
          totalPages = _asInt(pag['totalPages'] ?? pag['pages']) ?? 1;
        } else {
          total = _extractTotal(data) ?? 0;
          totalPages = _asInt(data['totalPages'] ?? data['pages']) ?? 1;
        }
      } else if (data is List) {
        items = List<Map<String, dynamic>>.from(data);
        final pag = res['pagination'];
        if (pag is Map) {
          total = _asInt(pag['total'] ?? pag['totalCount']) ?? 0;
          totalPages = _asInt(pag['totalPages'] ?? pag['pages']) ?? 1;
        } else {
          total = _extractTotal(res) ?? 0;
          totalPages = _asInt(res['totalPages'] ?? res['pages']) ?? 1;
        }
      }
    } else if (res is List) {
      items = List<Map<String, dynamic>>.from(res);
      total = items.length;
      totalPages = 1;
    }

    if (total == 0) total = items.length;
    if (totalPages <= 0) totalPages = (total / limit).ceil().clamp(1, 999999);

    return (requests: items, total: total, totalPages: totalPages);
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  int? _extractTotal(dynamic obj) {
    if (obj is! Map) return null;
    for (final key in const ['total', 'totalCount', 'count', 'totalItems', 'Total']) {
      final v = _asInt(obj[key]);
      if (v != null) return v;
    }
    final pagination = obj['pagination'];
    if (pagination is Map) {
      for (final key in const ['total', 'totalCount', 'count', 'totalItems']) {
        final v = _asInt(pagination[key]);
        if (v != null) return v;
      }
    }
    return null;
  }

  /* =========================================================
     INSPECTOR – ASSIGNED REQUESTS
  ========================================================= */

  Future<({List<Map<String, dynamic>> requests, int total, int totalPages})>
      listInspectorAssignedPaged({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await apiClient.getJson(
      '/inspection-requests/inspector/assigned?page=$page&limit=$limit',
    );

    List<Map<String, dynamic>> items = [];
    int total = 0;
    int totalPages = 1;

    if (res is Map) {
      final data = res['data'];
      if (data is Map) {
        final list = data['requests'] ?? data['items'] ?? data['data'];
        if (list is List) {
          items = list.whereType<Map>().map((x) => Map<String, dynamic>.from(x)).toList();
        }
        final pag = data['pagination'];
        if (pag is Map) {
          total = _asInt(pag['total'] ?? pag['totalCount']) ?? 0;
          totalPages = _asInt(pag['totalPages'] ?? pag['pages']) ?? 1;
        } else {
          total = _asInt(data['total'] ?? data['totalCount']) ?? 0;
          totalPages = _asInt(data['totalPages'] ?? data['pages']) ?? 1;
        }
      } else if (data is List) {
        items = data.whereType<Map>().map((x) => Map<String, dynamic>.from(x)).toList();
        final pag = res['pagination'];
        if (pag is Map) {
          total = _asInt(pag['total'] ?? pag['totalCount']) ?? 0;
          totalPages = _asInt(pag['totalPages'] ?? pag['pages']) ?? 1;
        } else {
          total = _asInt(res['total'] ?? res['totalCount']) ?? 0;
          totalPages = _asInt(res['totalPages'] ?? res['pages']) ?? 1;
        }
      }
    } else if (res is List) {
      items = res.whereType<Map>().map((x) => Map<String, dynamic>.from(x)).toList();
      total = items.length;
      totalPages = 1;
    }

    if (total == 0) total = items.length;
    if (totalPages <= 0) totalPages = (total / limit).ceil().clamp(1, 999999);

    return (requests: items, total: total, totalPages: totalPages);
  }

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

  /// ✅ GET vehicle-spec catalog rows for a make/model (variant → engine → specs).
  /// Any failure (network error, malformed shape, etc.) is swallowed and an
  /// empty list is returned so the Start Inspection wizard keeps working.
  Future<List<Map<String, dynamic>>> getVehicleSpecs({
    required String make,
    required String model,
  }) async {
    try {
      final res = await apiClient.getJson(
        '/admin/vehicle-specs?make=${Uri.encodeQueryComponent(make)}&model=${Uri.encodeQueryComponent(model)}',
      );
      final data = (res is Map) ? res['data'] : null;
      if (data is! List) return [];
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches the FULL vehicle-specs catalog fresh from the API — no caching —
  /// paging through `/admin/vehicle-specs` until every row is in. Forms call
  /// this once when they open and derive makes, models and Variant/Engine
  /// rows from the result locally (see [VehicleCatalog]), so selecting a
  /// make/model needs no further catalog calls and can't miss rows.
  ///
  /// This catalog (admin → Vehicle Specs, incl. its CSV import) is the single
  /// source of truth for makes, models and all vehicle data.
  ///
  /// Never throws: a page that fails twice ends the load and the result is
  /// returned with `complete == false` so the caller can warn the user.
  Future<VehicleCatalog> fetchVehicleCatalog() async {
    const limit = 100;
    const maxPages = 1000; // hard stop against a misbehaving paginator

    final rows = <Map<String, dynamic>>[];
    final seenIds = <String>{};
    var fetched = 0; // unique rows received, approved or not
    int? reportedTotal;
    var complete = true;

    for (var page = 1; page <= maxPages; page++) {
      dynamic res;
      try {
        res = await apiClient.getJson('/admin/vehicle-specs?page=$page&limit=$limit');
      } catch (_) {
        // One retry per page before giving up on the rest.
        try {
          res = await apiClient.getJson('/admin/vehicle-specs?page=$page&limit=$limit');
        } catch (_) {
          complete = false;
          break;
        }
      }

      // Accept every envelope shape this endpoint is parsed with elsewhere
      // (VehicleSpecsService.listVehicleSpecsPaged / getVehicleSpecs):
      // data.{vehicleSpecs|items|rows|data}, data as a plain list, or a
      // root-level list.
      final data = (res is Map) ? res['data'] : null;
      dynamic items;
      dynamic pag;
      if (data is Map) {
        items = data['vehicleSpecs'] ?? data['items'] ?? data['rows'] ?? data['data'];
        pag = data['pagination'] ?? data;
      } else if (data is List) {
        items = data;
        pag = (res is Map) ? (res['pagination'] ?? res) : null;
      } else if (res is List) {
        items = res;
      }

      final pageItems = (items is List)
          ? items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      for (final r in pageItems) {
        // De-dupe by id in case the backend's page order shifts between calls.
        final id = (r['id'] ?? r['_id'] ?? '').toString();
        if (id.isNotEmpty && !seenIds.add(id)) continue;
        fetched++;
        // Only approved rows feed the forms; pending "OTHER" suggestions
        // stay in admin → Vehicle Specs until the admin approves them.
        if (isApprovedVehicleSpec(r)) rows.add(r);
      }

      int? totalPages;
      if (pag is Map) {
        totalPages = int.tryParse('${pag['totalPages'] ?? pag['pages'] ?? ''}');
        reportedTotal ??= int.tryParse('${pag['total'] ?? pag['totalCount'] ?? ''}');
      }

      // Keep going while the backend says there are more pages, or — when it
      // doesn't report a page count — while pages keep coming back full.
      final more = totalPages != null ? page < totalPages : pageItems.length >= limit;
      if (!more || pageItems.isEmpty) break;
    }

    if (reportedTotal != null && fetched < reportedTotal) complete = false;

    return VehicleCatalog(rows, complete: complete);
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
      final id = (data['inspectionId'] ?? data['_id'] ?? data['id'] ?? '')
          .toString()
          .trim();
      return id.isEmpty ? null : id;
    }

    final id = (res['inspectionId'] ?? res['_id'] ?? res['id'] ?? '')
        .toString()
        .trim();
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

  /* =========================================================
    ✅ DOWNLOAD INSPECTION REPORT PDF
    GET /checklists/inspections/{id}/report/pdf
  ========================================================= */

  Future<PdfDownload> getInspectionReportPdf(String inspectionId) async {
    final http.Response res = await apiClient.getBytes(
      '/checklists/inspections/$inspectionId/report/pdf',
      extraHeaders: {
        'Accept': 'application/pdf',
      },
    );

    final contentType = res.headers['content-type'] ?? 'application/pdf';
    final fileName =
        _fileNameFromDisposition(res.headers['content-disposition']) ??
            'inspection_$inspectionId.pdf';

    return PdfDownload(
      bytes: res.bodyBytes,
      fileName: fileName,
      contentType: contentType,
    );
  }

  /* =========================================================
     ADMIN – APPROVE / REJECT INSPECTION
  ========================================================= */

  Future<Map<String, dynamic>> approveInspection({
    required String inspectionId,
    required String signatureUrl,
  }) async {
    final res = await apiClient.putJson(
      '/admin/inspections/$inspectionId/review',
      {'action': 'approve', 'adminSignature': signatureUrl},
    );
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  Future<Map<String, dynamic>> rejectInspection({
    required String inspectionId,
    required String rejectionReason,
  }) async {
    final res = await apiClient.putJson(
      '/admin/inspections/$inspectionId/review',
      {'action': 'reject', 'rejectionReason': rejectionReason},
    );
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  Future<String> uploadSignatureImage({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final safeName = 'signature_${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final presigned = await getPresignedUrlSimple(
      fileName: safeName,
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
    MOCK (KEEP)
  ========================================================= */

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

  /* =========================================================
     ✅ NEW: SECTION PROGRESS (DRAFT)
     - PUT /checklists/inspections/{id}/section-progress
     - GET /checklists/inspections/{id}/section-progress
     (Added only, no other changes)
  ========================================================= */

  Future<Map<String, dynamic>> getInspectionSectionProgress(String inspectionId) async {
    final res = await apiClient.getJson(
      '/checklists/inspections/$inspectionId/section-progress',
    );

    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'raw': res};
  }

  Future<Map<String, dynamic>> updateInspectionSectionProgress(
    String inspectionId,
    Map<String, dynamic> payload,
  ) async {
    final res = await apiClient.putJson(
      '/checklists/inspections/$inspectionId/section-progress',
      payload,
    );

    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'raw': res};
  }
}


/// Whether a vehicle-specs row is approved (usable in the forms). Rows with
/// no status — i.e. everything imported before the approval flow existed —
/// count as approved; 'pending' (an "OTHER" make/model awaiting admin
/// review) and 'rejected' do not.
bool isApprovedVehicleSpec(Map<String, dynamic> row) {
  final s = (row['status'] ?? '').toString().trim().toLowerCase();
  return s.isEmpty || s == 'approved' || s == 'active';
}

/// The full vehicle-specs catalog as loaded by
/// [InspectionRequestsService.fetchVehicleCatalog], with the lookups the
/// forms need. Make/model matching is case-insensitive (trimmed, upper-cased),
/// matching how the dropdowns store names.
class VehicleCatalog {
  final List<Map<String, dynamic>> rows;

  /// False when some pages couldn't be fetched (or fewer rows came back than
  /// the backend reported), i.e. makes/models may be missing.
  final bool complete;

  VehicleCatalog(this.rows, {this.complete = true});

  static String _norm(dynamic v) => (v ?? '').toString().trim().toUpperCase();

  /// Unique, sorted make names.
  List<String> get makes {
    final set = <String>{};
    for (final r in rows) {
      final m = _norm(r['make']);
      if (m.isNotEmpty) set.add(m);
    }
    return set.toList()..sort();
  }

  /// Unique, sorted model names for [make].
  List<String> modelsFor(String make) {
    final target = _norm(make);
    if (target.isEmpty) return [];
    final set = <String>{};
    for (final r in rows) {
      if (_norm(r['make']) != target) continue;
      final model = _norm(r['model']);
      if (model.isNotEmpty) set.add(model);
    }
    return set.toList()..sort();
  }

  /// All catalog rows (variant / engine / specs) for [make] + [model].
  List<Map<String, dynamic>> specsFor(String make, String model) {
    final mk = _norm(make);
    final md = _norm(model);
    if (mk.isEmpty || md.isEmpty) return [];
    return rows.where((r) => _norm(r['make']) == mk && _norm(r['model']) == md).toList();
  }
}
