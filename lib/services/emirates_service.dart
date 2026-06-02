import 'api_client.dart';

// ─── DTOs ─────────────────────────────────────────────────────────────────────

class AreaDto {
  final String id;
  final String name;
  final bool isActive;

  const AreaDto({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory AreaDto.fromJson(Map<String, dynamic> j) => AreaDto(
    id: (j['_id'] ?? j['id'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    isActive: j['isActive'] as bool? ?? true,
  );
}

class EmirateDto {
  final String id;
  final String name;
  final bool isActive;
  final List<AreaDto> areas;

  const EmirateDto({
    required this.id,
    required this.name,
    required this.isActive,
    required this.areas,
  });

  factory EmirateDto.fromJson(Map<String, dynamic> j) => EmirateDto(
    id: (j['_id'] ?? j['id'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    isActive: j['isActive'] as bool? ?? true,
    areas: (j['areas'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AreaDto.fromJson)
        .where((a) => a.id.isNotEmpty && a.name.isNotEmpty)
        .toList(),
  );
}

// ─── Service ──────────────────────────────────────────────────────────────────
//
// GET  /admin/emirates
//   → { "data": [ { "_id", "name", "isActive", "areas": [ { "_id", "name", "isActive" } ] } ] }
//
// POST /admin/emirates   body: { "name": "ABU DHABI" }
// DELETE /admin/emirates/:id
// POST /admin/areas      body: { "name": "AL AIN", "emirateId": "..." }
// DELETE /admin/areas/:id

class EmiratesService {
  const EmiratesService({required this.apiClient});
  final ApiClient apiClient;

  Future<List<EmirateDto>> listEmirates() async {
    final res = await apiClient.getJson('/admin/emirates');
    final list = res is Map && res['data'] is List
        ? List<dynamic>.from(res['data'] as List)
        : (res is List ? res : <dynamic>[]);
    return list
        .whereType<Map<String, dynamic>>()
        .map(EmirateDto.fromJson)
        .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
        .toList();
  }

  Future<void> addEmirate(String name) async {
    await apiClient.postJson('/admin/emirates', {
      'name': name.trim().toUpperCase(),
    });
  }

  Future<void> deleteEmirate(String id) async {
    await apiClient.deleteJson('/admin/emirates/$id');
  }

  Future<void> addArea(String emirateId, String name) async {
    await apiClient.postJson('/admin/areas', {
      'name': name.trim().toUpperCase(),
      'emirateId': emirateId,
    });
  }

  Future<void> deleteArea(String areaId) async {
    await apiClient.deleteJson('/admin/areas/$areaId');
  }
}
