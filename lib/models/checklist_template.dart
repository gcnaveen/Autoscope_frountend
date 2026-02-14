class ChecklistTemplate {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final int? version;
  final List<ChecklistType> types;

  ChecklistTemplate({
    required this.id,
    required this.name,
    required this.types,
    this.description,
    required this.isActive,
    this.version,
  });

  factory ChecklistTemplate.fromJson(Map<String, dynamic> j) {
    final rawTypes = (j['types'] is List) ? (j['types'] as List) : const [];
    return ChecklistTemplate(
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      description: j['description']?.toString(),
      isActive: j['isActive'] == true,
      version: (j['version'] is num) ? (j['version'] as num).toInt() : null,
      types: rawTypes
          .whereType<Map>()
          .map((x) => ChecklistType.fromJson(Map<String, dynamic>.from(x)))
          .toList(),
    );
  }
}

class ChecklistType {
  final String typeName;
  final List<ChecklistItem> checklistItems;

  final bool allowOverallRemarks;
  final bool allowOverallPhotos;
  final bool allowVideos;
  final int maxVideos;

  ChecklistType({
    required this.typeName,
    required this.checklistItems,
    required this.allowOverallRemarks,
    required this.allowOverallPhotos,
    required this.allowVideos,
    required this.maxVideos,
  });

  factory ChecklistType.fromJson(Map<String, dynamic> j) {
    final rawItems = (j['checklistItems'] is List) ? (j['checklistItems'] as List) : const [];
    final items = rawItems
        .whereType<Map>()
        .map((x) => ChecklistItem.fromJson(Map<String, dynamic>.from(x)))
        .toList();

    // ✅ enforce order by position
    items.sort((a, b) => a.position.compareTo(b.position));

    return ChecklistType(
      typeName: (j['typeName'] ?? 'Section').toString(),
      checklistItems: items,
      allowOverallRemarks: j['allowOverallRemarks'] == true,
      allowOverallPhotos: j['allowOverallPhotos'] == true,
      allowVideos: j['allowVideos'] == true,
      maxVideos: (j['maxVideos'] is num) ? (j['maxVideos'] as num).toInt() : 0,
    );
  }
}

class ChecklistItem {
  final int position;
  final String label;
  final String? description;
  final bool isRequired;

  ChecklistItem({
    required this.position,
    required this.label,
    this.description,
    required this.isRequired,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> j) {
    return ChecklistItem(
      position: (j['position'] is num) ? (j['position'] as num).toInt() : 0,
      label: (j['label'] ?? 'Item').toString(),
      description: j['description']?.toString(),
      isRequired: j['isRequired'] == true,
    );
  }
}

/// UI choice for each checklist item
enum ChecklistAnswer { pass, fail, na }

extension ChecklistAnswerX on ChecklistAnswer {
  String get label {
    switch (this) {
      case ChecklistAnswer.pass:
        return 'Pass';
      case ChecklistAnswer.fail:
        return 'Fail';
      case ChecklistAnswer.na:
        return 'N/A';
    }
  }

  String get value {
    switch (this) {
      case ChecklistAnswer.pass:
        return 'pass';
      case ChecklistAnswer.fail:
        return 'fail';
      case ChecklistAnswer.na:
        return 'na';
    }
  }
}
