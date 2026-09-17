import 'dart:typed_data';

import 'api_client.dart';

/// Admin CRUD + bulk-import for the vehicle specs catalog
/// ({ make, model, variant, subVariant, engineDisplay, engineCc, cylinders,
/// fuelType, driveTypes[], bodyType, specs }) used to auto-fill parts of the
/// inspector's inspection form (see InspectionRequestsService.getVehicleSpecs).
///
/// Kept as its own service (rather than growing inspection_requests_service.dart
/// further) since this is purely admin management of the catalog, not part of
/// the inspection flow.
///
/// NOTE: none of these backend endpoints exist yet (spec only) — every method
/// throws normally on failure so the calling page can show its own error UI;
/// nothing here silently swallows errors (unlike the read-only
/// getVehicleSpecs used by the inspector wizard).
class VehicleSpecsService {
  final ApiClient apiClient;
  VehicleSpecsService({required this.apiClient});

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  /// GET /admin/vehicle-specs?page=&limit=&search=
  /// Defensive parsing mirrors UsersService.listUsersPaged since the backend
  /// hasn't picked a final pagination envelope shape yet.
  Future<({List<Map<String, dynamic>> items, int total, int totalPages})>
      listVehicleSpecsPaged({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final buf = StringBuffer('/admin/vehicle-specs?page=$page&limit=$limit');
    if (search != null && search.trim().isNotEmpty) {
      buf.write('&search=${Uri.encodeQueryComponent(search.trim())}');
    }

    final res = await apiClient.getJson(buf.toString());

    List<dynamic> raw = [];
    int total = 0;
    int totalPages = 1;

    if (res is Map) {
      final data = res['data'];
      if (data is Map) {
        final list = data['vehicleSpecs'] ??
            data['items'] ??
            data['rows'] ??
            data['data'];
        if (list is List) raw = list;

        final pag = data['pagination'];
        if (pag is Map) {
          total = _asInt(pag['total'] ?? pag['totalCount']) ?? 0;
          totalPages = _asInt(pag['totalPages'] ?? pag['pages']) ?? 1;
        } else {
          total = _asInt(data['total'] ?? data['totalCount']) ?? 0;
          totalPages = _asInt(data['totalPages'] ?? data['pages']) ?? 1;
        }
      } else if (data is List) {
        raw = data;
        final pag = res['pagination'];
        if (pag is Map) {
          total = _asInt(pag['total'] ?? pag['totalCount']) ?? 0;
          totalPages = _asInt(pag['totalPages'] ?? pag['pages']) ?? 1;
        } else {
          total = _asInt(res['total'] ?? res['totalCount']) ?? 0;
          totalPages = _asInt(res['totalPages'] ?? res['pages']) ?? 1;
        }
      }
      if (raw.isEmpty) {
        final v = res['vehicleSpecs'] ?? res['items'] ?? res['rows'];
        if (v is List) raw = v;
      }
    } else if (res is List) {
      raw = res;
      total = raw.length;
      totalPages = 1;
    }

    if (total == 0) total = raw.length;
    if (totalPages <= 0) totalPages = (total / limit).ceil().clamp(1, 999999);

    final items = raw
        .whereType<Map>()
        .map((x) => Map<String, dynamic>.from(x))
        .toList();

    return (items: items, total: total, totalPages: totalPages);
  }

  Map<String, dynamic>? _extractRow(dynamic res) {
    if (res is! Map) return null;
    final data = res['data'];
    if (data is Map) {
      final row = data['vehicleSpec'] ?? data['item'] ?? data;
      if (row is Map) return Map<String, dynamic>.from(row);
    }
    final row = res['vehicleSpec'] ?? res['item'];
    if (row is Map) return Map<String, dynamic>.from(row);
    return Map<String, dynamic>.from(res);
  }

  /// POST /admin/vehicle-specs
  Future<Map<String, dynamic>> createVehicleSpec(Map<String, dynamic> row) async {
    final res = await apiClient.postJson('/admin/vehicle-specs', row);
    return _extractRow(res) ?? row;
  }

  /// PUT /admin/vehicle-specs/:id
  Future<Map<String, dynamic>> updateVehicleSpec(
    String id,
    Map<String, dynamic> row,
  ) async {
    final res = await apiClient.putJson('/admin/vehicle-specs/$id', row);
    return _extractRow(res) ?? row;
  }

  /// DELETE /admin/vehicle-specs/:id
  Future<void> deleteVehicleSpec(String id) async {
    await apiClient.deleteJson('/admin/vehicle-specs/$id');
  }

  /// POST /admin/vehicle-specs/import (multipart CSV upload)
  /// Columns: Make,Model,Variant,Sub_Variant,Engine_Display,Engine_CC,
  /// Cylinders,Fuel_Type,Drive_Type,Body_Type,Brand_Origin
  /// Returns a best-effort summary of the import (e.g. { imported, failed }).
  Future<Map<String, dynamic>> importVehicleSpecsCsv({
    required Uint8List bytes,
    required String filename,
  }) async {
    final res = await apiClient.postMultipart(
      '/admin/vehicle-specs/import',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
    );

    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'raw': res};
  }
}
