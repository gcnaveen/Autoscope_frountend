import 'api_client.dart';

class UserRequestsService {
  final ApiClient apiClient;
  UserRequestsService({required this.apiClient});

  /// Expected endpoint for user's requests:
  /// GET /api/inspection-requests
  ///
  /// JWT:
  /// - If logged in, ApiClient should attach Authorization automatically.
  /// - If not logged in, backend may return error/empty depending on your API.
  Future<List<Map<String, dynamic>>> listMyRequests() async {
    final res = await apiClient.getJson('/inspection-requests');

    List<dynamic> items = [];

    if (res is Map<String, dynamic>) {
      // common: data.requests
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        final v = data['requests'] ?? data['items'] ?? data['data'];
        if (v is List) items = v;
      }

      // fallback: requests/items at root
      if (items.isEmpty) {
        final v = res['requests'] ?? res['items'];
        if (v is List) items = v;
      }

      // some APIs might return { data: [ ... ] }
      if (items.isEmpty && res['data'] is List) {
        items = res['data'] as List;
      }
    }

    return items.whereType<Map>().map((x) => Map<String, dynamic>.from(x)).toList();
  }

  Future<({List<Map<String, dynamic>> requests, int total, int totalPages})>
      listMyRequestsPaged({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await apiClient.getJson(
      '/inspection-requests/me?page=$page&limit=$limit',
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
      if (items.isEmpty) {
        final v = res['requests'] ?? res['items'];
        if (v is List) {
          items = v.whereType<Map>().map((x) => Map<String, dynamic>.from(x)).toList();
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

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  /// Get single request details by id
  /// GET /api/inspection-requests/:id
  Future<Map<String, dynamic>> getRequestById(String id) async {
    final res = await apiClient.getJson('/inspection-requests/$id');

    // your API example: data.request
    if (res is Map<String, dynamic>) {
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        final r = data['request'];
        if (r is Map) return Map<String, dynamic>.from(r);
      }
    }

    // fallback: return root if already the request object
    if (res is Map) return Map<String, dynamic>.from(res);
    return {};
  }

  /// Update request (user editable fields)
  ///
  /// Recommended endpoint:
  /// PATCH /api/inspection-requests/:id
  ///
  /// If your backend uses PUT instead of PATCH:
  /// - replace patchJson -> putJson (or change the method call accordingly)
  ///
  /// Payload example (partial allowed):
  /// {
  ///   "vehicleInfo": {...},
  ///   "location": {...},
  ///   "notes": "...",
  ///   "preferredDate": "2026-01-28T18:30:00.000Z",
  ///   "preferredTime": "10:00 AM"
  /// }
  Future<Map<String, dynamic>> updateRequest(String id, Map<String, dynamic> payload) async {
    // ✅ PATCH (preferred)
    final res = await apiClient.putJson('/inspection-requests/$id', payload);

    // If your API responds like: { success, message, data: { request: {...} } }
    if (res is Map<String, dynamic>) {
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        final r = data['request'];
        if (r is Map) return Map<String, dynamic>.from(r);

        // fallback if backend returns updated object directly in "data"
        return Map<String, dynamic>.from(data);
      }

      // fallback if backend returns updated object at root
      return Map<String, dynamic>.from(res);
    }

    return {};
  }
}
