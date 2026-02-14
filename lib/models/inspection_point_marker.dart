class InspectionPointMarker {
  final String id;
  final String view; // front/rear/left/right/top
  double x; // normalized 0..1
  double y; // normalized 0..1

  String damageType;
  int severity; // 1..5
  String note;

  InspectionPointMarker({
    required this.id,
    required this.view,
    required this.x,
    required this.y,
    this.damageType = 'Scratch',
    this.severity = 3,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'view': view,
        'x': x,
        'y': y,
        'damageType': damageType,
        'severity': severity,
        'note': note,
      };

  factory InspectionPointMarker.fromJson(Map<String, dynamic> json) {
    return InspectionPointMarker(
      id: (json['id'] ?? '').toString(),
      view: (json['view'] ?? 'front').toString(),
      x: (json['x'] is num) ? (json['x'] as num).toDouble() : 0.5,
      y: (json['y'] is num) ? (json['y'] as num).toDouble() : 0.5,
      damageType: (json['damageType'] ?? 'Scratch').toString(),
      severity: (json['severity'] is num) ? (json['severity'] as num).toInt() : 3,
      note: (json['note'] ?? '').toString(),
    );
  }
}
