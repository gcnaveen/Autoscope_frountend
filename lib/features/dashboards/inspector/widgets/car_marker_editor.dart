// import 'package:flutter/material.dart';

// import '../../../shared/widgets/image_uploader.dart';

// class CarMarkerPoint {
//   final String id;
//   final String view; // "top"
//   final double x; // 0..1
//   final double y; // 0..1
//   final String title;
//   final String notes;
//   final List<String> photos;

//   const CarMarkerPoint({
//     required this.id,
//     required this.view,
//     required this.x,
//     required this.y,
//     this.title = '',
//     this.notes = '',
//     this.photos = const [],
//   });

//   CarMarkerPoint copyWith({
//     String? id,
//     String? view,
//     double? x,
//     double? y,
//     String? title,
//     String? notes,
//     List<String>? photos,
//   }) {
//     return CarMarkerPoint(
//       id: id ?? this.id,
//       view: view ?? this.view,
//       x: x ?? this.x,
//       y: y ?? this.y,
//       title: title ?? this.title,
//       notes: notes ?? this.notes,
//       photos: photos ?? this.photos,
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         'id': id,
//         'view': view,
//         'x': x,
//         'y': y,
//         'title': title,
//         'notes': notes,
//         'photos': photos,
//       };
// }

// class CarMarkerEditor extends StatefulWidget {
//   final String imageAsset;
//   final String inspectionRequestId;

//   final List<CarMarkerPoint> markers;
//   final ValueChanged<List<CarMarkerPoint>> onChanged;

//   final double height;

//   const CarMarkerEditor({
//     super.key,
//     required this.imageAsset,
//     required this.inspectionRequestId,
//     required this.markers,
//     required this.onChanged,
//     this.height = 560,
//   });

//   @override
//   State<CarMarkerEditor> createState() => _CarMarkerEditorState();
// }

// class _CarMarkerEditorState extends State<CarMarkerEditor> {
//   static double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

//   void _emit(List<CarMarkerPoint> next) => widget.onChanged(next);

//   void _addMarker(Offset localPos, Size size) {
//     final id = DateTime.now().microsecondsSinceEpoch.toString();
//     final x = _clamp01(localPos.dx / size.width);
//     final y = _clamp01(localPos.dy / size.height);

//     final next = [
//       ...widget.markers,
//       CarMarkerPoint(id: id, view: 'top', x: x, y: y),
//     ];
//     _emit(next);
//   }

//   void _removeMarkerAt(int index) {
//     final next = [...widget.markers]..removeAt(index);
//     _emit(next);
//   }

//   void _updateMarkerAt(int index, CarMarkerPoint updated) {
//     final next = [...widget.markers];
//     next[index] = updated;
//     _emit(next);
//   }

//   Future<void> _openMarkerSheet(BuildContext context, int index) async {
//     final m = widget.markers[index];

//     final titleCtrl = TextEditingController(text: m.title);
//     final notesCtrl = TextEditingController(text: m.notes);

//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       showDragHandle: true,
//       builder: (ctx) {
//         return Padding(
//           padding: EdgeInsets.only(
//             left: 16,
//             right: 16,
//             top: 12,
//             bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
//           ),
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Damage Marker #${index + 1}',
//                   style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
//                 ),
//                 const SizedBox(height: 12),
//                 TextField(
//                   controller: titleCtrl,
//                   decoration: const InputDecoration(
//                     labelText: 'Title (optional)',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 TextField(
//                   controller: notesCtrl,
//                   maxLines: 3,
//                   decoration: const InputDecoration(
//                     labelText: 'Notes (optional)',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 12),

//                 // Upload photos per marker (uses your existing S3 flow)
//                 ImageUploader(
//                   typeName: 'DamageMarkers_${m.id}',
//                   inspectionRequestId: widget.inspectionRequestId,
//                   title: 'Marker Photos',
//                   initialImages: m.photos,
//                   onChanged: (urls) {
//                     final updated = m.copyWith(photos: urls);
//                     _updateMarkerAt(index, updated);
//                   },
//                 ),

//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton.icon(
//                         onPressed: () {
//                           _removeMarkerAt(index);
//                           Navigator.pop(ctx);
//                         },
//                         icon: const Icon(Icons.delete_outline),
//                         label: const Text('Delete Marker'),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: FilledButton.icon(
//                         onPressed: () {
//                           final updated = m.copyWith(
//                             title: titleCtrl.text.trim(),
//                             notes: notesCtrl.text.trim(),
//                           );
//                           _updateMarkerAt(index, updated);
//                           Navigator.pop(ctx);
//                         },
//                         icon: const Icon(Icons.save_outlined),
//                         label: const Text('Save'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );

//     titleCtrl.dispose();
//     notesCtrl.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: widget.height,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: Colors.black.withOpacity(0.10)),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(18),
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             final size = Size(constraints.maxWidth, constraints.maxHeight);

//             return GestureDetector(
//               behavior: HitTestBehavior.opaque,
//               onTapUp: (d) => _addMarker(d.localPosition, size),
//               child: Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   // Base car image
//                   Image.asset(
//                     widget.imageAsset,
//                     fit: BoxFit.contain,
//                   ),

//                   // Markers
//                   ...List.generate(widget.markers.length, (i) {
//                     final m = widget.markers[i];
//                     final px = m.x * size.width;
//                     final py = m.y * size.height;

//                     return Positioned(
//                       left: px - 14,
//                       top: py - 14,
//                       child: GestureDetector(
//                         onTap: () => _openMarkerSheet(context, i),
//                         onPanUpdate: (details) {
//                           final nx = _clamp01(m.x + (details.delta.dx / size.width));
//                           final ny = _clamp01(m.y + (details.delta.dy / size.height));
//                           _updateMarkerAt(i, m.copyWith(x: nx, y: ny));
//                         },
//                         child: Container(
//                           height: 28,
//                           width: 28,
//                           decoration: BoxDecoration(
//                             color: Colors.redAccent,
//                             shape: BoxShape.circle,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.18),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, 6),
//                               )
//                             ],
//                           ),
//                           alignment: Alignment.center,
//                           child: Text(
//                             '${i + 1}',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.w900,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   }),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

import '../../../shared/widgets/image_uploader.dart';

class CarMarkerPoint {
  final String id;
  final String view; // "top"
  final double x; // 0..1
  final double y; // 0..1
  final String title;
  final String notes;
  final List<String> photos;

  const CarMarkerPoint({
    required this.id,
    required this.view,
    required this.x,
    required this.y,
    this.title = '',
    this.notes = '',
    this.photos = const [],
  });

  CarMarkerPoint copyWith({
    String? id,
    String? view,
    double? x,
    double? y,
    String? title,
    String? notes,
    List<String>? photos,
  }) {
    return CarMarkerPoint(
      id: id ?? this.id,
      view: view ?? this.view,
      x: x ?? this.x,
      y: y ?? this.y,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'view': view,
        'x': x,
        'y': y,
        'title': title,
        'notes': notes,
        'photos': photos,
      };
}

class CarMarkerEditor extends StatefulWidget {
  final String imageAsset;
  final String inspectionRequestId;

  final List<CarMarkerPoint> markers;
  final ValueChanged<List<CarMarkerPoint>> onChanged;

  final double height;

  const CarMarkerEditor({
    super.key,
    required this.imageAsset,
    required this.inspectionRequestId,
    required this.markers,
    required this.onChanged,
    this.height = 560,
  });

  @override
  State<CarMarkerEditor> createState() => _CarMarkerEditorState();
}

class _CarMarkerEditorState extends State<CarMarkerEditor> {
  static double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  void _emit(List<CarMarkerPoint> next) => widget.onChanged(next);

  void _addMarker(Offset localPos, Size size) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final x = _clamp01(localPos.dx / size.width);
    final y = _clamp01(localPos.dy / size.height);

    final next = [
      ...widget.markers,
      CarMarkerPoint(id: id, view: 'top', x: x, y: y),
    ];
    _emit(next);
  }

  void _removeMarkerAt(int index) {
    final next = [...widget.markers]..removeAt(index);
    _emit(next);
  }

  void _updateMarkerAt(int index, CarMarkerPoint updated) {
    final next = [...widget.markers];
    next[index] = updated;
    _emit(next);
  }

  Future<void> _openMarkerSheet(BuildContext context, int index) async {
    final m = widget.markers[index];

    final titleCtrl = TextEditingController(text: m.title);
    final notesCtrl = TextEditingController(text: m.notes);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Damage Marker #${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Upload photos per marker (uses your existing S3 flow)
                ImageUploader(
                  typeName: 'DamageMarkers_${m.id}',
                  inspectionRequestId: widget.inspectionRequestId,
                  title: 'Marker Photos',
                  initialImages: m.photos,
                  onChanged: (urls) {
                    final updated = m.copyWith(photos: urls);
                    _updateMarkerAt(index, updated);
                  },
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _removeMarkerAt(index);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete Marker'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          final updated = m.copyWith(
                            title: titleCtrl.text.trim(),
                            notes: notesCtrl.text.trim(),
                          );
                          _updateMarkerAt(index, updated);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    titleCtrl.dispose();
    notesCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.10)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _addMarker(d.localPosition, size),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Base car image
                  Image.asset(
                    widget.imageAsset,
                    fit: BoxFit.contain,
                  ),

                  // Markers
                  ...List.generate(widget.markers.length, (i) {
                    final m = widget.markers[i];
                    final px = m.x * size.width;
                    final py = m.y * size.height;

                    return Positioned(
                      left: px - 14,
                      top: py - 14,
                      child: GestureDetector(
                        onTap: () => _openMarkerSheet(context, i),
                        onPanUpdate: (details) {
                          final nx = _clamp01(m.x + (details.delta.dx / size.width));
                          final ny = _clamp01(m.y + (details.delta.dy / size.height));
                          _updateMarkerAt(i, m.copyWith(x: nx, y: ny));
                        },
                        child: Container(
                          height: 28,
                          width: 28,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
