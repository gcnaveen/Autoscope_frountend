// lib/services/reviews_service.dart
import 'api_client.dart';

class ReviewsService {
  final ApiClient apiClient;
  ReviewsService({required this.apiClient});

  /// Change this if your ApiClient does NOT already include /api in baseUrl.
  /// Example:
  ///   const String _base = '/api/reviews';
  static const String _base = '/reviews';

  /// POST /reviews
  Future<Map<String, dynamic>> submitReview({
    required String inspectionRequestId,
    required int rating,
    required String comment,
  }) async {
    final body = {
      "inspectionRequestId": inspectionRequestId,
      "rating": rating,
      "comment": comment,
    };

    final res = await apiClient.postJson(_base, body);
    return _asMap(res);
  }

  /// GET /reviews/public
  /// Returns list of public approved reviews (parsed safely)
  Future<List<Map<String, dynamic>>> getApprovedPublicReviews() async {
    final res = await apiClient.getJson('$_base/public');
    final items = _extractList(res, preferKeys: const ['reviews', 'items', 'data']);
    return items;
  }

  /// GET /reviews/admin?status=pending&page=1&limit=20
  /// Returns list of admin reviews (parsed safely)
  Future<List<Map<String, dynamic>>> getAllAdminReviews({
    String? status, // pending/approved/rejected
    int? page,
    int? limit,
  }) async {
    final params = <String, dynamic>{};
    if (status != null && status.trim().isNotEmpty) params['status'] = status.trim();
    if (page != null) params['page'] = page;
    if (limit != null) params['limit'] = limit;

    final url = _withQuery('$_base/admin', params);
    final res = await apiClient.getJson(url);

    final items = _extractList(res, preferKeys: const ['reviews', 'items', 'data']);
    return items;
  }

  /// PUT /reviews/{id}/approve
  Future<Map<String, dynamic>> approveReview(String reviewId) async {
    final id = reviewId.trim();
    final res = await apiClient.putJson('$_base/$id/approve', {});
    return _asMap(res);
  }

  /// PUT /reviews/{id}/reject
  Future<Map<String, dynamic>> rejectReview(String reviewId) async {
    final id = reviewId.trim();
    final res = await apiClient.putJson('$_base/$id/reject', {});
    return _asMap(res);
  }

  // ---------------- helpers ----------------

  /// Builds: /path?key=value&...
  String _withQuery(String path, Map<String, dynamic> params) {
    if (params.isEmpty) return path;

    final parts = <String>[];
    params.forEach((k, v) {
      if (v == null) return;
      final s = v.toString().trim();
      if (s.isEmpty) return;
      parts.add('${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(s)}');
    });

    if (parts.isEmpty) return path;

    final qs = parts.join('&');
    return path.contains('?') ? '$path&$qs' : '$path?$qs';
  }

  /// Extracts list from typical API shapes:
  /// { data: { reviews: [...] } } OR { data: [...] } OR { reviews: [...] } OR [...]
  List<Map<String, dynamic>> _extractList(
    dynamic res, {
    List<String> preferKeys = const ['items', 'data'],
  }) {
    List<dynamic> items = [];

    // If API returns List directly
    if (res is List) {
      items = res;
      return items.whereType<Map>().map((x) => Map<String, dynamic>.from(x)).toList();
    }

    if (res is Map<String, dynamic>) {
      // Most common: res['data'] contains object or list
      final data = res['data'];

      // data is a Map, try keys inside it
      if (data is Map<String, dynamic>) {
        for (final k in preferKeys) {
          final v = data[k];
          if (v is List) {
            items = v;
            break;
          }
        }
      }

      // data itself is a List
      if (items.isEmpty && data is List) {
        items = data;
      }

      // fallback: root keys
      if (items.isEmpty) {
        for (final k in preferKeys) {
          final v = res[k];
          if (v is List) {
            items = v;
            break;
          }
        }
      }
    }

    return items.whereType<Map>().map((x) => Map<String, dynamic>.from(x)).toList();
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }
}