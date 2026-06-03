import 'api_client.dart';

// GET  /admin/report-settings
//   → { "data": { "disclaimer": ["point 1", "point 2", ...] } }
//
// PATCH /admin/report-settings
//   body: { "disclaimer": ["point 1", "point 2", ...] }

class ReportSettingsService {
  ReportSettingsService({required this.apiClient});
  final ApiClient apiClient;

  static const _path = '/admin/report-settings';

  List<String>? _cache;

  Future<List<String>> loadDisclaimer() async {
    if (_cache != null) return _cache!;
    final res = await apiClient.getJson(_path);
    _cache = _extract(res);
    return _cache!;
  }

  Future<void> saveDisclaimer(List<String> points) async {
    await apiClient.patchJson(_path, {'disclaimer': points});
    _cache = List<String>.from(points);
  }

  void clearCache() => _cache = null;

  static List<String> _extract(dynamic res) {
    if (res is! Map) return [];
    final data = res['data'];
    if (data is! Map) return [];
    final d = data['disclaimer'];
    if (d is! List) return [];
    return d.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }
}
