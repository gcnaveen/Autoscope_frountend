import 'api_client.dart';

class ChecklistTemplatesService {
  final ApiClient apiClient;
  ChecklistTemplatesService({required this.apiClient});

  /// INSPECTOR: GET /api/checklists/templates/active
  /// Response: { data: { templates: [...] } }
  Future<List<Map<String, dynamic>>> listActiveTemplates() async {
    final res = await apiClient.getJson('/checklists/templates/active');

    if (res is Map && res['data'] is Map && (res['data']['templates'] is List)) {
      return List<Map<String, dynamic>>.from(res['data']['templates']);
    }

    return [];
  }

  /// ADMIN: GET /api/checklists/templates?page=&limit=
  /// Response: { data: { templates: [...], pagination: {...} } }
  /// Returns normalized { templates: List<Map>, pagination: Map }
  Future<Map<String, dynamic>> listAllAdmin({int page = 1, int limit = 10}) async {
    final res = await apiClient.getJson('/checklists/templates?page=$page&limit=$limit');

    if (res is Map && res['data'] is Map) {
      final data = res['data'] as Map;

      final templates = (data['templates'] is List) ? data['templates'] as List : const [];
      final pagination = (data['pagination'] is Map) ? data['pagination'] as Map : const {};

      return {
        'templates': List<Map<String, dynamic>>.from(templates),
        'pagination': Map<String, dynamic>.from(pagination),
      };
    }

    return {'templates': <Map<String, dynamic>>[], 'pagination': <String, dynamic>{}};
  }

  /// ADMIN: POST /api/checklists/templates
  /// Request body:
  /// { name, description, types: [...] }
  Future<Map<String, dynamic>> createTemplate({
    required String name,
    String description = '',
    List<Map<String, dynamic>> types = const [],
  }) async {
    final res = await apiClient.postJson('/checklists/templates', {
      'name': name,
      'description': description,
      'types': types,
    });

    // Not fully defined in your spec, handle common patterns safely.
    if (res is Map && res['data'] is Map) {
      final data = res['data'] as Map;
      if (data['template'] is Map) return Map<String, dynamic>.from(data['template'] as Map);
      return Map<String, dynamic>.from(data);
    }

    if (res is Map) return Map<String, dynamic>.from(res);

    return {};
  }

  /// ADMIN: GET /api/checklists/templates/{id}
  /// Response: { data: { template: {...} } }
  Future<Map<String, dynamic>> getTemplateById(String id) async {
    final res = await apiClient.getJson('/checklists/templates/$id');

    if (res is Map && res['data'] is Map) {
      final data = res['data'] as Map;
      if (data['template'] is Map) return Map<String, dynamic>.from(data['template'] as Map);
    }

    return {};
  }

  /// ADMIN: PUT /api/checklists/templates/{id}
  /// Body:
  /// { name, description, isActive, types }
  Future<Map<String, dynamic>> updateTemplate({
    required String id,
    required Map<String, dynamic> body,
  }) async {
    final res = await apiClient.putJson('/checklists/templates/$id', body);

    // Spec doesn't show response. Handle common patterns.
    if (res is Map && res['data'] is Map) {
      final data = res['data'] as Map;
      if (data['template'] is Map) return Map<String, dynamic>.from(data['template'] as Map);
      return Map<String, dynamic>.from(data);
    }

    if (res is Map) return Map<String, dynamic>.from(res);

    return {};
  }

  /// ADMIN: DELETE /api/checklists/templates/{id}
  Future<void> deleteTemplate(String id) async {
    await apiClient.deleteJson('/checklists/templates/$id');
  }

  /// Toggle Active/Inactive.
  /// Since your PUT expects full template body, we GET then PUT.
  Future<void> setActive(String id, bool isActive) async {
    final tpl = await getTemplateById(id);
    if (tpl.isEmpty) throw Exception('Template not found');

    await updateTemplate(
      id: id,
      body: {
        'name': tpl['name'] ?? '',
        'description': tpl['description'] ?? '',
        'isActive': isActive,
        'types': tpl['types'] ?? [],
      },
    );
  }
}
