import '../models/inspection.dart';
import 'api_client.dart';

class ChecklistsService {
  final ApiClient apiClient;
  ChecklistsService({required this.apiClient});

  Future<Inspection> createInspection(Map<String, dynamic> body) async {
    final res = await apiClient.postJson('/checklists/inspections', body);
    final j = (res['inspection'] ?? res['data'] ?? res) as Map;
    return Inspection.fromJson(Map<String, dynamic>.from(j));
  }

  Future<List<Inspection>> listInspections() async {
    final res = await apiClient.getJson('/checklists/inspections');
    final items = (res['items'] ?? res['data'] ?? res['inspections'] ?? []) as List;
    return items.whereType<Map>().map((x) => Inspection.fromJson(Map<String, dynamic>.from(x))).toList();
  }

  Future<Inspection> updateInspection(String id, Map<String, dynamic> body) async {
    final res = await apiClient.putJson('/checklists/inspections/$id', body);
    final j = (res['inspection'] ?? res['data'] ?? res) as Map;
    return Inspection.fromJson(Map<String, dynamic>.from(j));
  }
}
