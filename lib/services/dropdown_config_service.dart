import 'api_client.dart';

// ─── Custom field model ───────────────────────────────────────────────────────

class CustomField {
  final String id;
  final String label;
  final String type;    // 'text' | 'dropdown'
  final String section; // 'vehicle_details' | 'service_warranty' | 'interior_details' | 'exterior_details'
  final List<String> options;
  final bool required;

  const CustomField({
    required this.id,
    required this.label,
    required this.type,
    required this.section,
    required this.options,
    required this.required,
  });

  CustomField copyWith({
    String? label,
    String? type,
    String? section,
    List<String>? options,
    bool? required,
  }) {
    return CustomField(
      id: id,
      label: label ?? this.label,
      type: type ?? this.type,
      section: section ?? this.section,
      options: options ?? this.options,
      required: required ?? this.required,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'type': type,
    'section': section,
    'options': options,
    'required': required,
  };

  factory CustomField.fromJson(Map<String, dynamic> j) => CustomField(
    id: j['id']?.toString() ?? '',
    label: j['label']?.toString() ?? '',
    type: j['type']?.toString() ?? 'text',
    section: j['section']?.toString() ?? 'vehicle_details',
    options: (j['options'] as List?)?.map((x) => x.toString()).toList() ?? [],
    required: j['required'] as bool? ?? false,
  );

  /// Sanitised camelCase key used when saving values in the API payload.
  String get payloadKey => _toCamelCase(label);
}

String _toCamelCase(String s) {
  final parts = s.trim().split(RegExp(r'[\s_\-]+'));
  if (parts.isEmpty) return s;
  final first = parts.first.toLowerCase();
  final rest = parts.skip(1).map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1).toLowerCase());
  return first + rest.join();
}

// ─── Section labels ────────────────────────────────────────────────────────

const sectionLabels = <String, String>{
  'vehicle_details': 'Vehicle Details',
  'service_warranty': 'Service & Warranty',
  'interior_details': 'Interior Details',
  'exterior_details': 'Exterior Details',
};

// ─── Service ──────────────────────────────────────────────────────────────────

// Expected GET /api/configured-inputs response shape:
// {
//   "data": {
//     "dropdownOptions": { "gradeVariant": [...], "transmission": [...], ... },
//     "customFields":    [ { "id": "...", "label": "...", "type": "text|dropdown",
//                            "section": "vehicle_details|...", "options": [...], "required": true } ]
//   }
// }
//
// PATCH /api/admin/configured-inputs body shape:
// {
//   "dropdownOptions": { ... },
//   "customFields":    [ ... ]
// }

class DropdownConfigService {
  DropdownConfigService({required this.apiClient});

  final ApiClient apiClient;

  static const String _getPath   = '/configured-inputs';
  static const String _patchPath = '/admin/configured-inputs';

  static const Map<String, List<String>> defaults = {
    'gradeVariant': ['XLE', 'LIMITED'],
    'cylinderSize': ['3', '4', '6', '8'],
    'transmission': ['Automatic', 'Manual'],
    'fuelType': ['Petrol', 'Diesel', 'Hybrid', 'Electric'],
    'driveTrain': ['FWD', 'RWD', '4X4'],
    'specs': ['GCC', 'AMERICAN', 'EUROPEAN', 'JAPANESE', 'KOREAN', 'CANADIAN', 'AUSTRALIAN', 'CHINESE'],
    'seats': ['2', '4', '5', '6', '7', '8', '9'],
    'interiorColor': [
      'WHITE', 'BLACK', 'GRAY / GREY', 'SILVER', 'BLUE', 'RED',
      'BEIGE / TAN', 'BROWN / CHOCOLATE', 'GOLD', 'GREEN', 'ORANGE',
      'PURPLE / VIOLET', 'MAROON / BURGUNDY', 'YELLOW', 'PINK',
    ],
    'exteriorColor': [
      'WHITE', 'BLACK', 'GRAY / GREY', 'SILVER', 'BLUE', 'RED',
      'BEIGE / TAN', 'BROWN / CHOCOLATE', 'GOLD', 'GREEN', 'ORANGE',
      'PURPLE / VIOLET', 'MAROON / BURGUNDY', 'YELLOW', 'PINK',
    ],
    'upholstery': ['LEATHER', 'FABRIC'],
    'numberOfKeys': ['1', '2', '3', '4', '5'],
    'doors': ['2', '3', '4', '5'],
    'wheelSize': ['14"', '15"', '16"', '17"', '18"', '19"', '20"', '21"', '22"', '23"'],
    'wheelType': ['Alloy Wheel', 'Steel Wheel'],
    'servicedWith': ['AGENCY', 'THIRD PARTY'],
  };

  static const Map<String, String> fieldLabels = {
    'gradeVariant': 'Grade / Variant',
    'cylinderSize': 'Cylinder Size',
    'transmission': 'Transmission',
    'fuelType': 'Fuel Type',
    'driveTrain': 'Drive Train',
    'specs': 'Specs',
    'seats': 'Seats',
    'interiorColor': 'Interior Color',
    'exteriorColor': 'Exterior Color',
    'upholstery': 'Upholstery',
    'numberOfKeys': 'Number of Keys',
    'doors': 'Doors',
    'wheelSize': 'Wheel Size',
    'wheelType': 'Wheel Type',
    'servicedWith': 'Serviced With',
  };

  // Reverse of fieldLabels: "Grade / Variant" → "gradeVariant"
  static final Map<String, String> _labelToKey = {
    for (final e in fieldLabels.entries) e.value: e.key,
  };

  // ── In-memory cache (cleared on logout) ────────────────────────────────────

  Map<String, List<String>>? _dropdownCache;
  Map<String, String>? _statusCache;   // camelKey → 'active' | 'inactive'
  List<CustomField>? _customFieldsCache;

  // ── Fetch from API ─────────────────────────────────────────────────────────

  Future<Map<String, List<String>>> load() async {
    if (_dropdownCache != null) return _dropdownCache!;
    await _fetchFromApi();
    return _dropdownCache!;
  }

  Future<List<CustomField>> loadCustomFields() async {
    if (_customFieldsCache != null) return _customFieldsCache!;
    await _fetchFromApi();
    return _customFieldsCache!;
  }

  /// Whether a field (by camelCase key) is active. Defaults to true if unknown.
  bool isActive(String camelKey) =>
      (_statusCache?[camelKey] ?? 'active') == 'active';

  /// Full status map — used by the configure page to render toggles.
  Map<String, String> get statusMap => Map.unmodifiable(_statusCache ?? {});

  Future<void> _fetchFromApi() async {
    try {
      final res = await apiClient.getJson(_getPath);

      Map? rawInputs;
      if (res is Map) {
        final data = res['data'];
        rawInputs = (data is Map ? data['configuredInputs'] : null) as Map?;
        rawInputs ??= res['configuredInputs'] as Map?;
      }

      if (rawInputs != null) {
        final optionsResult = <String, List<String>>{};
        final statusResult  = <String, String>{};

        for (final e in rawInputs.entries) {
          final camelKey = _labelToKey[e.key.toString()] ?? e.key.toString();
          final fieldData = e.value;

          if (fieldData is Map) {
            // New format: { options: [...], status: 'active' }
            final opts = fieldData['options'];
            if (opts is List) {
              optionsResult[camelKey] = opts.map((x) => x.toString()).toList();
            }
            statusResult[camelKey] = (fieldData['status'] ?? 'active').toString();
          } else if (fieldData is List) {
            // Legacy flat format
            optionsResult[camelKey] = fieldData.map((x) => x.toString()).toList();
            statusResult[camelKey] = 'active';
          }
        }

        for (final k in defaults.keys) {
          optionsResult.putIfAbsent(k, () => List<String>.from(defaults[k]!));
          statusResult.putIfAbsent(k, () => 'active');
        }

        _dropdownCache = optionsResult;
        _statusCache   = statusResult;
      } else {
        _dropdownCache = _copyDefaults();
        _statusCache   = {for (final k in defaults.keys) k: 'active'};
      }

      // Custom fields
      final rawFields = (res is Map)
          ? ((res['data'] is Map ? res['data']['customFields'] : null) ?? res['customFields'])
          : null;
      if (rawFields is List) {
        _customFieldsCache = rawFields
            .whereType<Map<String, dynamic>>()
            .map(CustomField.fromJson)
            .where((f) => f.id.isNotEmpty && f.label.isNotEmpty)
            .toList();
      } else {
        _customFieldsCache = [];
      }
    } catch (_) {
      _dropdownCache ??= _copyDefaults();
      _statusCache   ??= {for (final k in defaults.keys) k: 'active'};
      _customFieldsCache ??= [];
    }
  }

  // ── Save to API (admin only) ───────────────────────────────────────────────

  Future<void> save(Map<String, List<String>> config) async {
    _dropdownCache = Map<String, List<String>>.from(config);
    await _patchApi();
  }

  Future<void> saveCustomFields(List<CustomField> fields) async {
    _customFieldsCache = List<CustomField>.from(fields);
    await _patchApi();
  }

  Future<void> setStatus(String camelKey, String status) async {
    _statusCache ??= {for (final k in defaults.keys) k: 'active'};
    _statusCache![camelKey] = status;
    await _patchApi();
  }

  Future<void> _patchApi() async {
    final configuredInputs = <String, dynamic>{};
    for (final e in (_dropdownCache ?? {}).entries) {
      final label = fieldLabels[e.key] ?? e.key;
      configuredInputs[label] = {
        'options': e.value,
        'status': _statusCache?[e.key] ?? 'active',
      };
    }
    await apiClient.patchJson(_patchPath, {
      'configuredInputs': configuredInputs,
    });
  }

  // ── Individual custom-field CRUD (each call updates cache + PATCHes) ───────

  Future<void> addCustomField(CustomField field) async {
    final fields = await loadCustomFields();
    fields.add(field);
    await saveCustomFields(fields);
  }

  Future<void> updateCustomField(CustomField updated) async {
    final fields = await loadCustomFields();
    final idx = fields.indexWhere((f) => f.id == updated.id);
    if (idx != -1) {
      fields[idx] = updated;
      await saveCustomFields(fields);
    }
  }

  Future<void> deleteCustomField(String id) async {
    final fields = await loadCustomFields();
    fields.removeWhere((f) => f.id == id);
    await saveCustomFields(fields);
  }

  // ── Cache management ───────────────────────────────────────────────────────

  void clearCache() {
    _dropdownCache = null;
    _statusCache = null;
    _customFieldsCache = null;
  }

  // clearCustomFieldsCache kept for compatibility — clearCache() covers both
  void clearCustomFieldsCache() => clearCache();

  Map<String, List<String>> _copyDefaults() =>
      defaults.map((k, v) => MapEntry(k, List<String>.from(v)));
}
