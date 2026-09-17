import 'api_client.dart';

// GET  /admin/rating-scale
//   → { "data": { "scale": [{ "label": "Excellent", "value": 5 }, ...],
//                 "notApplicableLabel": "Not Applicable",
//                 "excludedFromAverage": ["Not Applicable", "Not Checked"] } }
//
// PATCH /admin/rating-scale
//   body: { "scale": [{ "label": "Excellent", "value": 5 }, ...],
//           "notApplicableLabel": "Not Applicable",
//           "excludedFromAverage": ["Not Applicable", "Not Checked"] }

class RatingTier {
  const RatingTier({required this.label, required this.value});

  final String label;
  final double value;
}

class RatingScale {
  const RatingScale({
    required this.tiers,
    required this.notApplicableLabel,
    required this.excludedFromAverage,
  });

  final List<RatingTier> tiers;
  final String notApplicableLabel;
  final List<String> excludedFromAverage;

  /// Safety net matching the previously hardcoded scale — used whenever the
  /// live endpoint hasn't loaded yet (or fails to load).
  static const List<RatingTier> fallbackTiers = [
    RatingTier(label: 'Excellent', value: 5),
    RatingTier(label: 'Good', value: 4),
    RatingTier(label: 'Average', value: 3),
    RatingTier(label: 'Poor', value: 1),
  ];

  static const String fallbackNotApplicableLabel = 'Not Applicable';

  /// Parses the real API shape. Throws on any shape mismatch so callers can
  /// catch it and fall back to [fallbackTiers] / [fallbackNotApplicableLabel]
  /// instead of silently building a broken scale.
  static RatingScale fromJson(dynamic res) {
    if (res is! Map) {
      throw const FormatException('rating-scale: invalid response');
    }
    final data = res['data'];
    if (data is! Map) {
      throw const FormatException('rating-scale: missing data');
    }

    final rawScale = data['scale'];
    if (rawScale is! List || rawScale.isEmpty) {
      throw const FormatException('rating-scale: missing scale');
    }

    final tiers = <RatingTier>[];
    for (final e in rawScale) {
      if (e is! Map) continue;
      final label = (e['label'] ?? '').toString().trim();
      final value = _toDouble(e['value']);
      if (label.isEmpty || value == null) continue;
      tiers.add(RatingTier(label: label, value: value));
    }
    if (tiers.isEmpty) {
      throw const FormatException('rating-scale: no valid tiers');
    }

    final naLabel = (data['notApplicableLabel'] ?? '').toString().trim();
    final excluded = data['excludedFromAverage'];

    return RatingScale(
      tiers: tiers,
      notApplicableLabel: naLabel.isEmpty ? fallbackNotApplicableLabel : naLabel,
      excludedFromAverage: excluded is List
          ? excluded.map((x) => x.toString()).where((s) => s.isNotEmpty).toList()
          : <String>[naLabel.isEmpty ? fallbackNotApplicableLabel : naLabel],
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class RatingScaleService {
  RatingScaleService({required this.apiClient});
  final ApiClient apiClient;

  static const _path = '/admin/rating-scale';

  RatingScale? _cache;

  Future<RatingScale> loadRatingScale() async {
    if (_cache != null) return _cache!;
    final res = await apiClient.getJson(_path);
    _cache = RatingScale.fromJson(res);
    return _cache!;
  }

  Future<void> saveRatingScale(RatingScale scale) async {
    await apiClient.patchJson(_path, {
      'scale': scale.tiers.map((t) => {'label': t.label, 'value': t.value}).toList(),
      'notApplicableLabel': scale.notApplicableLabel,
      'excludedFromAverage': scale.excludedFromAverage,
    });
    _cache = scale;
  }

  void clearCache() => _cache = null;
}
