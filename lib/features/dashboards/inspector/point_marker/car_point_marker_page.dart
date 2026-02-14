import 'package:flutter/material.dart';
import '../../../../models/inspection_point_marker.dart';

class CarPointMarkerPage extends StatefulWidget {
  final List<InspectionPointMarker> initialMarkers;

  const CarPointMarkerPage({
    super.key,
    this.initialMarkers = const [],
  });

  @override
  State<CarPointMarkerPage> createState() => _CarPointMarkerPageState();
}

class _CarPointMarkerPageState extends State<CarPointMarkerPage> {
  static const _views = <_CarView>[
    _CarView('front', 'Front', 'assets/images/car_views/front.png'),
    _CarView('rear', 'Rear', 'assets/images/car_views/rear.png'),
    _CarView('left', 'Left', 'assets/images/car_views/left.png'),
    _CarView('right', 'Right', 'assets/images/car_views/right.png'),
    _CarView('top', 'Top', 'assets/images/car_views/top.png'),
  ];

  static const _damageTypes = <String>[
    'Scratch',
    'Dent',
    'Paint Damage',
    'Crack',
    'Rust',
    'Broken',
    'Other',
  ];

  String _view = 'front';
  late List<InspectionPointMarker> _markers;

  @override
  void initState() {
    super.initState();
    _markers = widget.initialMarkers.map((m) => InspectionPointMarker.fromJson(m.toJson())).toList();
  }

  List<InspectionPointMarker> get _markersForView =>
      _markers.where((m) => m.view == _view).toList();

  Future<void> _addMarkerAt(Offset localPos, Size size) async {
    // Normalize tap position (0..1)
    final nx = (localPos.dx / size.width).clamp(0.0, 1.0);
    final ny = (localPos.dy / size.height).clamp(0.0, 1.0);

    final marker = InspectionPointMarker(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      view: _view,
      x: nx,
      y: ny,
    );

    final saved = await _editMarker(marker, isNew: true);
    if (saved == null) return;

    setState(() => _markers.add(saved));
  }

  Future<InspectionPointMarker?> _editMarker(InspectionPointMarker marker, {required bool isNew}) async {
    final tmp = InspectionPointMarker.fromJson(marker.toJson());
    final noteCtrl = TextEditingController(text: tmp.note);

    return showModalBottomSheet<InspectionPointMarker>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setM) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isNew ? 'Add Marker' : 'Edit Marker',
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: tmp.damageType,
                    items: _damageTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setM(() => tmp.damageType = v ?? tmp.damageType),
                    decoration: const InputDecoration(labelText: 'Damage Type'),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Text('Severity'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: tmp.severity.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: tmp.severity.toString(),
                          onChanged: (v) => setM(() => tmp.severity = v.round()),
                        ),
                      ),
                    ],
                  ),

                  TextField(
                    controller: noteCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Note'),
                    onChanged: (v) => tmp.note = v,
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (!isNew)
                        TextButton.icon(
                          onPressed: () => Navigator.pop(ctx, null),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          tmp.note = noteCtrl.text.trim();
                          Navigator.pop(ctx, tmp);
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _deleteMarker(String id) {
    setState(() => _markers.removeWhere((m) => m.id == id));
  }

  @override
  Widget build(BuildContext context) {
    final activeView = _views.firstWhere((v) => v.key == _view);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Damage Markers'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, _markers),
            icon: const Icon(Icons.check),
            label: const Text('Done'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _views.map((v) {
                      final selected = v.key == _view;
                      return ChoiceChip(
                        label: Text(v.label),
                        selected: selected,
                        onSelected: (_) => setState(() => _view = v.key),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: LayoutBuilder(
                      builder: (ctx, c) {
                        final size = Size(c.maxWidth, c.maxHeight);
                        final markers = _markersForView;

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Material(
                            color: Colors.black12,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (d) => _addMarkerAt(d.localPosition, size),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Image.asset(activeView.assetPath, fit: BoxFit.contain),
                                    ),
                                  ),
                                  ...markers.asMap().entries.map((e) {
                                    final idx = e.key;
                                    final m = e.value;

                                    final left = m.x * size.width;
                                    final top = m.y * size.height;

                                    return Positioned(
                                      left: left - 14,
                                      top: top - 28,
                                      child: GestureDetector(
                                        onTap: () async {
                                          final edited = await _editMarker(m, isNew: false);
                                          if (edited == null) {
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (dctx) => AlertDialog(
                                                title: const Text('Delete marker?'),
                                                content: const Text('This will remove the marker.'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(dctx, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(dctx, true),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (ok == true) _deleteMarker(m.id);
                                            return;
                                          }
                                          setState(() {
                                            final i = _markers.indexWhere((x) => x.id == m.id);
                                            if (i >= 0) _markers[i] = edited;
                                          });
                                        },
                                        child: _MarkerPin(index: idx + 1),
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
                ],
              ),
            ),
          ),

          Container(
            width: 360,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text('Markers (${_markersForView.length})'),
                  subtitle: Text('View: ${activeView.label}'),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: _markersForView.length,
                    itemBuilder: (_, i) {
                      final m = _markersForView[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(m.damageType),
                        subtitle: Text('Severity ${m.severity} • ${m.note.isEmpty ? 'No note' : m.note}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteMarker(m.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkerPin extends StatelessWidget {
  final int index;
  const _MarkerPin({required this.index});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$index',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const Icon(Icons.location_on, size: 28),
        ],
      ),
    );
  }
}

class _CarView {
  final String key;
  final String label;
  final String assetPath;
  const _CarView(this.key, this.label, this.assetPath);
}
