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

// ─── Field definition model ───────────────────────────────────────────────────
// Populated from the backend's fieldDefinitions array; falls back to static
// defaults when the API does not yet return them.

class FieldDefinition {
  final String key;            // camelCase,  e.g. 'gradeVariant'
  final String label;          // display name, e.g. 'Grade / Variant'
  final List<String> defaultOptions;

  const FieldDefinition({
    required this.key,
    required this.label,
    required this.defaultOptions,
  });

  factory FieldDefinition.fromJson(Map<dynamic, dynamic> j) => FieldDefinition(
    key: j['key']?.toString() ?? '',
    label: j['label']?.toString() ?? '',
    defaultOptions:
        (j['defaultOptions'] as List?)?.map((x) => x.toString()).toList() ?? [],
  );
}

// ─── Section labels (static fallback) ─────────────────────────────────────────
// Overridden at runtime when the backend returns sectionDefinitions.

const sectionLabels = <String, String>{
  'vehicle_details': 'Vehicle Details',
  'service_warranty': 'Service & Warranty',
  'interior_details': 'Interior Details',
  'exterior_details': 'Exterior Details',
};

// ─── Service ──────────────────────────────────────────────────────────────────
//
// GET /api/configured-inputs — expected response:
// {
//   "data": {
//     "fieldDefinitions": [
//       { "key": "gradeVariant", "label": "Grade / Variant", "defaultOptions": ["XLE", "LIMITED"] },
//       ...
//     ],
//     "sectionDefinitions": [
//       { "key": "vehicle_details", "label": "Vehicle Details" },
//       ...
//     ],
//     "configuredInputs": { "Grade / Variant": { "options": [...], "status": "active" }, ... },
//     "customFields": [ { "id": "...", "label": "...", "type": "text|dropdown",
//                         "section": "vehicle_details|...", "options": [...], "required": true } ]
//   }
// }
//
// PATCH /api/admin/configured-inputs — body:
// { "configuredInputs": { "Grade / Variant": { "options": [...], "status": "active" }, ... } }

class DropdownConfigService {
  DropdownConfigService({required this.apiClient});

  final ApiClient apiClient;

  static const String _getPath   = '/configured-inputs';
  static const String _patchPath = '/admin/configured-inputs';

  // ── Static fallbacks (used when API does not return definitions) ────────────

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

  // ── In-memory cache (cleared on logout) ────────────────────────────────────

  Map<String, List<String>>? _dropdownCache;
  Map<String, String>? _statusCache;
  List<CustomField>? _customFieldsCache;
  List<FieldDefinition>? _fieldDefsCache;
  Map<String, String>? _sectionDefsCache;

  // ── Field / section definitions ────────────────────────────────────────────

  /// Ordered list of built-in dropdown field definitions. Populated from the
  /// API when available; falls back to [fieldLabels] + [defaults] otherwise.
  List<FieldDefinition> get fieldDefinitions =>
      _fieldDefsCache ?? _buildDefaultFieldDefs();

  /// Section key → label map. Populated from the API; falls back to the
  /// top-level [sectionLabels] const otherwise.
  Map<String, String> get currentSectionLabels =>
      _sectionDefsCache ?? Map<String, String>.from(sectionLabels);

  static List<FieldDefinition> _buildDefaultFieldDefs() => [
    for (final e in fieldLabels.entries)
      FieldDefinition(
        key: e.key,
        label: e.value,
        defaultOptions: List<String>.from(defaults[e.key] ?? []),
      ),
  ];

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

  static dynamic _extractFromResponse(dynamic res, String key) {
    if (res is! Map) return null;
    final data = res['data'];
    if (data is Map && data.containsKey(key)) return data[key];
    return res[key];
  }

  Future<void> _fetchFromApi() async {
    try {
      final res = await apiClient.getJson(_getPath);

      // ── Section definitions ───────────────────────────────────────────────
      // Optional backend key; falls back to the top-level const sectionLabels.
      final rawSectionDefs = _extractFromResponse(res, 'sectionDefinitions');
      if (rawSectionDefs is List) {
        final map = <String, String>{};
        for (final d in rawSectionDefs.whereType<Map>()) {
          final k = d['key']?.toString() ?? '';
          final v = d['label']?.toString() ?? '';
          if (k.isNotEmpty && v.isNotEmpty) map[k] = v;
        }
        if (map.isNotEmpty) _sectionDefsCache = map;
      }
      _sectionDefsCache ??= Map<String, String>.from(sectionLabels);

      // ── label → camelKey mapping ──────────────────────────────────────────
      // Seed with static fieldLabels so known labels get the expected camelCase
      // keys. The optional backend fieldDefinitions array can extend/override
      // this for any labels not covered by the static map.
      final labelToKey = <String, String>{
        for (final e in fieldLabels.entries) e.value: e.key,
      };
      List<FieldDefinition>? explicitDefs;
      final rawFieldDefs = _extractFromResponse(res, 'fieldDefinitions');
      if (rawFieldDefs is List) {
        explicitDefs = rawFieldDefs
            .whereType<Map>()
            .map(FieldDefinition.fromJson)
            .where((d) => d.key.isNotEmpty && d.label.isNotEmpty)
            .toList();
        for (final d in explicitDefs) {
          labelToKey[d.label] = d.key; // extend/override static mapping
        }
        if (explicitDefs.isEmpty) explicitDefs = null;
      }

      // ── Configured inputs ─────────────────────────────────────────────────
      // The backend returns every active field with its current options.
      // We derive _fieldDefsCache from these keys — no hardcoded list needed.
      Map? rawInputs;
      if (res is Map) {
        final data = res['data'];
        rawInputs = (data is Map ? data['configuredInputs'] : null) as Map?;
        rawInputs ??= res['configuredInputs'] as Map?;
      }

      if (rawInputs != null && rawInputs.isNotEmpty) {
        final optionsResult = <String, List<String>>{};
        final statusResult  = <String, String>{};
        final derivedDefs   = <FieldDefinition>[];

        for (final e in rawInputs.entries) {
          final labelStr = e.key.toString();
          // Use static/explicit mapping first; fall back to toCamelCase
          final camelKey = labelToKey[labelStr] ?? _toCamelCase(labelStr);
          final fieldData = e.value;

          if (fieldData is Map) {
            final opts = fieldData['options'];
            if (opts is List) {
              optionsResult[camelKey] = opts.map((x) => x.toString()).toList();
            }
            statusResult[camelKey] = (fieldData['status'] ?? 'active').toString();
          } else if (fieldData is List) {
            optionsResult[camelKey] = fieldData.map((x) => x.toString()).toList();
            statusResult[camelKey] = 'active';
          }

          // Build field definition from API key — backend is the source of truth
          final explicitDef = explicitDefs?.firstWhere(
            (d) => d.label == labelStr,
            orElse: () => FieldDefinition(key: camelKey, label: labelStr, defaultOptions: []),
          );
          derivedDefs.add(explicitDef ??
              FieldDefinition(key: camelKey, label: labelStr, defaultOptions: []));
        }

        _fieldDefsCache = derivedDefs;
        _dropdownCache  = optionsResult;
        _statusCache    = statusResult;
      } else {
        // API returned no configuredInputs — fall back to static defaults
        _fieldDefsCache = explicitDefs ?? _buildDefaultFieldDefs();
        _dropdownCache  = _copyDefaults();
        _statusCache    = {for (final d in _fieldDefsCache!) d.key: 'active'};
      }

      // ── Custom fields ─────────────────────────────────────────────────────
      final rawFields = _extractFromResponse(res, 'customFields');
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
      _fieldDefsCache   ??= _buildDefaultFieldDefs();
      _sectionDefsCache ??= Map<String, String>.from(sectionLabels);
      _dropdownCache    ??= _copyDefaults();
      _statusCache      ??= {for (final d in _fieldDefsCache!) d.key: 'active'};
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
    _statusCache ??= {for (final d in fieldDefinitions) d.key: 'active'};
    _statusCache![camelKey] = status;
    await _patchApi();
  }

  Future<void> _patchApi() async {
    // Build key → label mapping from current field definitions
    final keyToLabel = <String, String>{
      for (final d in fieldDefinitions) d.key: d.label,
    };
    for (final e in fieldLabels.entries) {
      keyToLabel.putIfAbsent(e.key, () => e.value);
    }

    final configuredInputs = <String, dynamic>{};
    for (final e in (_dropdownCache ?? {}).entries) {
      final label = keyToLabel[e.key] ?? e.key;
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
    _fieldDefsCache = null;
    _sectionDefsCache = null;
  }

  // clearCustomFieldsCache kept for compatibility — clearCache() covers both
  void clearCustomFieldsCache() => clearCache();

  Map<String, List<String>> _copyDefaults() =>
      defaults.map((k, v) => MapEntry(k, List<String>.from(v)));
}
