import 'api_client.dart';

// GET  /admin/legal-content
//   → { "data": { "termsAndConditions": ["point 1", ...], "privacyPolicy": ["point 1", ...] } }
//
// PATCH /admin/legal-content
//   body: { "termsAndConditions": ["point 1", ...], "privacyPolicy": ["point 1", ...] }

class LegalContentService {
  LegalContentService({required this.apiClient});
  final ApiClient apiClient;

  static const _path = '/admin/legal-content';

  ({List<String> termsAndConditions, List<String> privacyPolicy})? _cache;

  Future<({List<String> termsAndConditions, List<String> privacyPolicy})>
      loadLegalContent() async {
    if (_cache != null) return _cache!;
    final res = await apiClient.getJson(_path);
    _cache = _extract(res);
    return _cache!;
  }

  Future<void> saveLegalContent({
    required List<String> termsAndConditions,
    required List<String> privacyPolicy,
  }) async {
    await apiClient.patchJson(_path, {
      'termsAndConditions': termsAndConditions,
      'privacyPolicy': privacyPolicy,
    });
    _cache = (
      termsAndConditions: List<String>.from(termsAndConditions),
      privacyPolicy: List<String>.from(privacyPolicy),
    );
  }

  void clearCache() => _cache = null;

  static ({List<String> termsAndConditions, List<String> privacyPolicy})
      _extract(dynamic res) {
    if (res is! Map) return (termsAndConditions: <String>[], privacyPolicy: <String>[]);
    final data = res['data'];
    if (data is! Map) return (termsAndConditions: <String>[], privacyPolicy: <String>[]);

    final terms = data['termsAndConditions'];
    final privacy = data['privacyPolicy'];

    final termsList = terms is List
        ? terms.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : <String>[];
    final privacyList = privacy is List
        ? privacy.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    return (termsAndConditions: termsList, privacyPolicy: privacyList);
  }
}
