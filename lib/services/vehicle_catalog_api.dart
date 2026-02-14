import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

class VehicleCatalogApi {
  final ApiClient _api;

  VehicleCatalogApi(this._api);

  // Expected API examples:
  // GET /vehicle-catalog/makes  -> ["Toyota","Nissan",...]
  // GET /vehicle-catalog/models?make=Toyota -> ["Camry","Corolla",...]
  Future<List<String>> fetchMakes() async {
    final res = await _api.getJson('/vehicle-catalog/makes');
    return _toStringList(res);
  }

  Future<List<String>> fetchModels(String make) async {
    final res = await _api.getJson('/vehicle-catalog/models?make=${Uri.encodeComponent(make)}');
    return _toStringList(res);
  }

  List<String> _toStringList(dynamic res) {
    if (res is List) {
      return res.map((e) => e.toString()).toList();
    }
    if (res is String) {
      final decoded = jsonDecode(res);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    }
    throw FlutterError('Unexpected catalog response: $res');
  }
}
