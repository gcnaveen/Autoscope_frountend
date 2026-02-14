import 'package:flutter/material.dart';

import '../../../shared/widgets/image_uploader.dart';

@immutable
class DamageCoordinate {
  final String damageid;

  /// Normalized coordinates (0..1) relative to the displayed image area
  final double x;
  final double y;

  final String damagedescription;
  final List<String> damageImages;

  const DamageCoordinate({
    required this.damageid,
    required this.x,
    required this.y,
    required this.damagedescription,
    required this.damageImages,
  });

  DamageCoordinate copyWith({
    String? damageid,
    double? x,
    double? y,
    String? damagedescription,
    List<String>? damageImages,
  }) {
    return DamageCoordinate(
      damageid: damageid ?? this.damageid,
      x: x ?? this.x,
      y: y ?? this.y,
      damagedescription: damagedescription ?? this.damagedescription,
      damageImages: damageImages ?? this.damageImages,
    );
  }

  /// ✅ Used by StartInspectionPage -> damaged_coordinates payload
  /// Matches your structure:
  /// damaged_coordinates: { data: [ { damageid, damagedescription, damageImages, coordinates } ] }
  Map<String, dynamic> toApiJson() {
    return {
      'damageid': damageid,
      'damagedescription': damagedescription,
      'damageImages': damageImages,
      'coordinates': {
        'x': x,
        'y': y,
      },
    };
  }

  factory DamageCoordinate.fromJson(Map<String, dynamic> json) {
    final coords = (json['coordinates'] is Map) ? (json['coordinates'] as Map) : const {};
    return DamageCoordinate(
      damageid: (json['damageid'] ?? '').toString(),
      x: (coords['x'] is num) ? (coords['x'] as num).toDouble() : ((json['x'] is num) ? (json['x'] as num).toDouble() : 0),
      y: (coords['y'] is num) ? (coords['y'] as num).toDouble() : ((json['y'] is num) ? (json['y'] as num).toDouble() : 0),
      damagedescription: (json['damagedescription'] ?? '').toString(),
      damageImages: (json['damageImages'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

class DamageMarkerEditor extends StatefulWidget {
  final String inspectionRequestId;

  /// Car top outline image asset (example: assets/images/car_top_outline.png)
  final String imageAsset;

  /// Keep aspect ratio stable so markers map correctly
  final double aspectRatio;

  /// ✅ NEW preferred param
  final List<DamageCoordinate>? initial;

  /// ✅ Backward-compatible alias (so your StartInspectionPage can keep using markers:)
  final List<DamageCoordinate>? markers;

  final ValueChanged<List<DamageCoordinate>> onChanged;

  const DamageMarkerEditor({
    super.key,
    required this.inspectionRequestId,
    required this.imageAsset,
    required this.onChanged,
    this.initial,
    this.markers,
    this.aspectRatio = 0.7643, // matches 574/751
  });

  @override
  State<DamageMarkerEditor> createState() => _DamageMarkerEditorState();
}

class _DamageMarkerEditorState extends State<DamageMarkerEditor> {
  late List<DamageCoordinate> _items;

  @override
  void initState() {
    super.initState();
    _items = [
      ...(widget.initial ?? widget.markers ?? const <DamageCoordinate>[]),
    ];
  }

  @override
  void didUpdateWidget(covariant DamageMarkerEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newList = widget.initial ?? widget.markers;
    final oldList = oldWidget.initial ?? oldWidget.markers;

    if (newList != oldList && newList != null) {
      _items = [...newList];
    }
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _emit() => widget.onChanged([..._items]);

  Future<void> _addMarkerAndEdit(double nx, double ny) async {
    final created = DamageCoordinate(
      damageid: _newId(),
      x: nx,
      y: ny,
      damagedescription: '',
      damageImages: const [],
    );

    setState(() => _items.add(created));
    _emit();

    final updated = await _openEditorDialog(created);
    if (!mounted) return;

    if (updated == null) {
      // cancel => remove the just-added marker
      setState(() => _items.removeWhere((e) => e.damageid == created.damageid));
      _emit();
      return;
    }

    setState(() {
      final idx = _items.indexWhere((e) => e.damageid == created.damageid);
      if (idx >= 0) _items[idx] = updated;
    });
    _emit();
  }

  Future<void> _editMarker(DamageCoordinate item) async {
    final updated = await _openEditorDialog(item);
    if (!mounted || updated == null) return;

    setState(() {
      final idx = _items.indexWhere((e) => e.damageid == item.damageid);
      if (idx >= 0) _items[idx] = updated;
    });
    _emit();
  }

  void _deleteMarker(String id) {
    setState(() => _items.removeWhere((e) => e.damageid == id));
    _emit();
  }

  Future<DamageCoordinate?> _openEditorDialog(DamageCoordinate item) async {
    final descCtrl = TextEditingController(text: item.damagedescription);
    List<String> imgs = [...item.damageImages];

    final result = await showDialog<DamageCoordinate?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Damage Details'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Damage Description',
                          hintText: 'e.g. scratch on left door',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ImageUploader(
                        typeName: 'Damages',
                        inspectionRequestId: widget.inspectionRequestId,
                        title: 'Damage Images',
                        initialImages: imgs,
                        onChanged: (v) => setLocal(() => imgs = v),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tip: tap an existing marker to edit.',
                        style: TextStyle(color: Colors.black.withOpacity(0.55)),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                ),
                TextButton.icon(
                  onPressed: () {
                    _deleteMarker(item.damageid);
                    Navigator.of(ctx).pop(null);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final updated = item.copyWith(
                      damagedescription: descCtrl.text.trim(),
                      damageImages: imgs,
                    );
                    Navigator.of(ctx).pop(updated);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    descCtrl.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Damage Marking (click on car)',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final h = c.maxHeight;

              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black.withOpacity(0.12)),
                    color: Colors.white,
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) {
                      final p = d.localPosition;
                      final nx = (p.dx / w).clamp(0.0, 1.0);
                      final ny = (p.dy / h).clamp(0.0, 1.0);
                      _addMarkerAndEdit(nx, ny);
                    },
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            widget.imageAsset,
                            fit: BoxFit.fill,
                            errorBuilder: (ctx, err, st) => Center(
                              child: Text(
                                'Image not found:\n${widget.imageAsset}\n\nAdd it in pubspec.yaml assets.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        ),
                        ..._items.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;

                          final left = (item.x * w) - 10;
                          final top = (item.y * h) - 10;

                          return Positioned(
                            left: left,
                            top: top,
                            child: InkWell(
                              onTap: () => _editMarker(item),
                              child: Container(
                                height: 20,
                                width: 20,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    )
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        if (_items.isEmpty)
          Text(
            'No damages marked yet.',
            style: TextStyle(color: Colors.black.withOpacity(0.6)),
          )
        else
          Column(
            children: _items.asMap().entries.map((e) {
              final i = e.key + 1;
              final d = e.value;
              final desc = d.damagedescription.trim().isEmpty ? '(no description)' : d.damagedescription.trim();

              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('$i')),
                  title: Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    'x=${d.x.toStringAsFixed(3)}, y=${d.y.toStringAsFixed(3)} • images=${d.damageImages.length}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => _editMarker(d),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () => _deleteMarker(d.damageid),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
