import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/app_shell.dart';
import '../../../services/service_locator.dart';

class InspectorRequestDetailsPage extends StatefulWidget {
  final String requestId;
  const InspectorRequestDetailsPage({super.key, required this.requestId});

  @override
  State<InspectorRequestDetailsPage> createState() => _InspectorRequestDetailsPageState();
}

class _InspectorRequestDetailsPageState extends State<InspectorRequestDetailsPage> {
  late Future<Map<String, dynamic>> _future;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final res = await inspectionRequestsService.getRequestById(widget.requestId);

    if (res is Map && res['data'] is Map) {
      final data = Map<String, dynamic>.from(res['data']);
      if (data['request'] is Map) return Map<String, dynamic>.from(data['request']);
      return data;
    }

    if (res is Map && res['data'] is Map && res['data']['request'] == null) {
      return Map<String, dynamic>.from(res['data']);
    }

    return res;
  }

  void _reload() {
    setState(() {
      _tick++;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final isMobile = screenW < 720;
    final isVeryNarrow = screenW < 420;

    return AppShell(
      title: 'Request Details',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: FutureBuilder<Map<String, dynamic>>(
            key: ValueKey(_tick),
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Text('Failed to load request:\n${snap.error}', textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      FilledButton.tonal(onPressed: _reload, child: const Text('Retry')),
                    ],
                  ),
                );
              }

              final r = snap.data ?? {};
              final requestId = (r['requestId'] ?? r['_id'] ?? widget.requestId).toString();
              final status = (r['status'] ?? 'pending').toString();
              final type = (r['requestType'] ?? r['type'] ?? 'Inspection').toString();

              final user = (r['userId'] is Map) ? Map<String, dynamic>.from(r['userId']) : <String, dynamic>{};
              final name = '${(user['firstName'] ?? '').toString()} ${(user['lastName'] ?? '').toString()}'.trim();
              final email = (user['email'] ?? '').toString();
              final phone = (user['phone'] ?? '').toString();

              final vehicle =
                  (r['vehicleInfo'] is Map) ? Map<String, dynamic>.from(r['vehicleInfo']) : <String, dynamic>{};
              final make = (vehicle['make'] ?? '').toString();
              final model = (vehicle['model'] ?? '').toString();
              final year = (vehicle['year'] ?? '').toString();
              final vin = (vehicle['vin'] ?? '').toString();
              final plate = (vehicle['licensePlate'] ?? '').toString();

              final loc = (r['location'] is Map) ? Map<String, dynamic>.from(r['location']) : <String, dynamic>{};
              final address = (loc['address'] ?? '').toString();
              final city = (loc['city'] ?? '').toString();
              final state = (loc['state'] ?? '').toString();
              final zip = (loc['zipCode'] ?? '').toString();

              final preferredDate = DateTime.tryParse((r['preferredDate'] ?? '').toString());
              final preferredTime = (r['preferredTime'] ?? '').toString();

              final notes = (r['notes'] ?? '').toString();

              final customerCard = _SectionCard(
                title: 'Customer',
                icon: Icons.person_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kv(context, 'Name', name.isEmpty ? '-' : name),
                    _kv(context, 'Email', email.isEmpty ? '-' : email),
                    _kv(context, 'Phone', phone.isEmpty ? '-' : phone),
                  ],
                ),
              );

              final vehicleCard = _SectionCard(
                title: 'Vehicle',
                icon: Icons.directions_car_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kv(context, 'Make', make.isEmpty ? '-' : make),
                    _kv(context, 'Model', model.isEmpty ? '-' : model),
                    _kv(context, 'Year', year.isEmpty ? '-' : year),
                    _kv(context, 'VIN', vin.isEmpty ? '-' : vin),
                    _kv(context, 'Plate', plate.isEmpty ? '-' : plate),
                  ],
                ),
              );

              final scheduleCard = _SectionCard(
                title: 'Schedule',
                icon: Icons.event_available_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kv(context, 'Preferred Date', preferredDate == null ? '-' : _fmt(preferredDate)),
                    _kv(context, 'Preferred Time', preferredTime.isEmpty ? '-' : preferredTime),
                  ],
                ),
              );

              final locationCard = _SectionCard(
                title: 'Location',
                icon: Icons.location_on_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kv(context, 'Address', address.isEmpty ? '-' : address),
                    _kv(context, 'City', city.isEmpty ? '-' : city),
                    _kv(context, 'State', state.isEmpty ? '-' : state),
                    _kv(context, 'Zip', zip.isEmpty ? '-' : zip),
                  ],
                ),
              );

              final notesCard = _SectionCard(
                title: 'Notes',
                icon: Icons.notes_outlined,
                child: Text(notes.isEmpty ? '-' : notes),
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  // Header
                  if (!isMobile)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$requestId • $type',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Chip(label: Text(status)),
                        const SizedBox(width: 10),
                        IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$requestId • $type',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Chip(label: Text(status)),
                            OutlinedButton.icon(
                              onPressed: _reload,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                      ],
                    ),

                  const SizedBox(height: 12),

                  // Sections (re-ordered for desktop)
                  LayoutBuilder(
                    builder: (context, c) {
                      final wide = c.maxWidth >= 900;
                      if (!wide) {
                        // Mobile order stays one by one (existing order)
                        return Column(
                          children: [
                            customerCard,
                            const SizedBox(height: 12),
                            vehicleCard,
                            const SizedBox(height: 12),
                            scheduleCard,
                            const SizedBox(height: 12),
                            locationCard,
                            const SizedBox(height: 12),
                            notesCard,
                          ],
                        );
                      }

                      // ✅ Desktop order requested:
                      // vehicle -> location
                      // schedule -> customer
                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: vehicleCard),
                              const SizedBox(width: 12),
                              Expanded(child: locationCard),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: scheduleCard),
                              const SizedBox(width: 12),
                              Expanded(child: customerCard),
                            ],
                          ),
                          const SizedBox(height: 12),
                          notesCard,
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // Actions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          if (!isVeryNarrow)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => context.pop(),
                                    child: const Text('Back'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => context.go(
                                      '/dashboard/inspector/requests/${widget.requestId}/start',
                                    ),
                                    child: const Text('Start Inspection'),
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: () => context.go(
                                      '/dashboard/inspector/requests/${widget.requestId}/start',
                                    ),
                                    child: const Text('Start Inspection'),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => context.pop(),
                                    child: const Text('Back'),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static Widget _kv(BuildContext context, String k, String v) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 720;

    if (!isMobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 140, child: Text(k, style: const TextStyle(color: Colors.black54))),
            const SizedBox(width: 10),
            Expanded(child: Text(v)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(v),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: Colors.black.withOpacity(0.02),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: Colors.black87),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}