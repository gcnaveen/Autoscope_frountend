import 'package:flutter/material.dart';

class DamagePoint {
  final String id;
  final String description;
  final List<String> images;
  final double x; // normalized 0..1
  final double y; // normalized 0..1

  DamagePoint({
    required this.id,
    required this.description,
    required this.images,
    required this.x,
    required this.y,
  });

  static List<DamagePoint> fromInspection(Map<String, dynamic> inspection) {
    // inspection["damaged_coordinates"] can be:
    // { data: [ ... ] }  OR directly a list  OR null
    final damagedCoordinates = inspection['damaged_coordinates'];

    dynamic listRaw;
    if (damagedCoordinates is Map) {
      listRaw = damagedCoordinates['data'];
    } else {
      listRaw = damagedCoordinates;
    }

    final list = (listRaw is List) ? listRaw : const [];

    return list
        .whereType<Map>()
        .map((m) => DamagePoint.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  factory DamagePoint.fromJson(Map<String, dynamic> j) {
    final coords = (j['coordinates'] is Map)
        ? Map<String, dynamic>.from(j['coordinates'])
        : const <String, dynamic>{};

    double x = (coords['x'] is num) ? (coords['x'] as num).toDouble() : 0.0;
    double y = (coords['y'] is num) ? (coords['y'] as num).toDouble() : 0.0;

    // clamp to safe range
    x = x.clamp(0.0, 1.0);
    y = y.clamp(0.0, 1.0);

    final imgsRaw = j['damageImages'];
    final imgs = (imgsRaw is List)
        ? imgsRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    return DamagePoint(
      id: (j['damageid'] ?? j['_id'] ?? j['id'] ?? '').toString(),
      description: (j['damagedescription'] ?? '').toString(),
      images: imgs,
      x: x,
      y: y,
    );
  }
}

class DamageMapCard extends StatelessWidget {
  final List<DamagePoint> points;

  /// IMPORTANT: Use the SAME asset path you used in StartInspectionPage
  /// Example: 'assets/images/car_top_outline.png'
  final String outlineAssetPath;

  const DamageMapCard({
    super.key,
    required this.points,
    required this.outlineAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: const [
              Icon(Icons.info_outline),
              SizedBox(width: 10),
              Text('No damages marked.'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Damage Map',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),

            // Zoom / pan
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                color: Colors.black.withOpacity(0.03),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: _DamageCanvas(
                    outlineAssetPath: outlineAssetPath,
                    points: points,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 18),

            Text(
              'Damages (${points.length})',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),

            ...points.map((p) => _DamageRow(point: p)),
          ],
        ),
      ),
    );
  }
}

class _DamageCanvas extends StatelessWidget {
  final String outlineAssetPath;
  final List<DamagePoint> points;

  const _DamageCanvas({
    required this.outlineAssetPath,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    // Keep a stable aspect ratio for the map area
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;

          return Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    outlineAssetPath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // markers
              ...points.asMap().entries.map((entry) {
                final idx = entry.key;
                final p = entry.value;

                final left = (p.x * w);
                final top = (p.y * h);

                return Positioned(
                  left: left - 12,
                  top: top - 12,
                  child: _DamageMarker(
                    index: idx + 1,
                    point: p,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _DamageMarker extends StatelessWidget {
  final int index;
  final DamagePoint point;

  const _DamageMarker({
    required this.index,
    required this.point,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: point.description.isEmpty ? 'Damage #$index' : point.description,
      child: InkWell(
        onTap: () => _showDamageDialog(context, point, index),
        child: Container(
          height: 24,
          width: 24,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.95),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                color: Colors.black.withOpacity(0.18),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  void _showDamageDialog(BuildContext context, DamagePoint p, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Damage #$index'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.description.isNotEmpty) ...[
                  Text(p.description),
                  const SizedBox(height: 10),
                ],
                if (p.images.isEmpty)
                  const Text('No damage images.')
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: p.images.map((url) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          url,
                          width: 150,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 150,
                            height: 110,
                            color: Colors.black12,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _DamageRow extends StatelessWidget {
  final DamagePoint point;

  const _DamageRow({required this.point});

  @override
  Widget build(BuildContext context) {
    final hasImg = point.images.isNotEmpty;
    final thumb = hasImg ? point.images.first : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              point.description.isEmpty ? 'Damage marked' : point.description,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (thumb != null) ...[
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                thumb,
                width: 56,
                height: 42,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
