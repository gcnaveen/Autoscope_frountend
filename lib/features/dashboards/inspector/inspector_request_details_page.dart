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

    // Common backend formats:
    // { success, data: { request: {...} } }
    if (res is Map && res['data'] is Map) {
      final data = Map<String, dynamic>.from(res['data']);
      if (data['request'] is Map) return Map<String, dynamic>.from(data['request']);
      return data;
    }

    // { success, data: {...} }
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

              final vehicle = (r['vehicleInfo'] is Map) ? Map<String, dynamic>.from(r['vehicleInfo']) : <String, dynamic>{};
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

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$requestId • $type',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Chip(label: Text(status)),
                      const SizedBox(width: 10),
                      IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _section('Customer'),
                          _kv('Name', name.isEmpty ? '-' : name),
                          _kv('Email', email.isEmpty ? '-' : email),
                          _kv('Phone', phone.isEmpty ? '-' : phone),

                          const SizedBox(height: 12),
                          _section('Vehicle'),
                          _kv('Make', make.isEmpty ? '-' : make),
                          _kv('Model', model.isEmpty ? '-' : model),
                          _kv('Year', year.isEmpty ? '-' : year),
                          _kv('VIN', vin.isEmpty ? '-' : vin),
                          _kv('Plate', plate.isEmpty ? '-' : plate),

                          const SizedBox(height: 12),
                          _section('Schedule'),
                          _kv('Preferred Date', preferredDate == null ? '-' : _fmt(preferredDate)),
                          _kv('Preferred Time', preferredTime.isEmpty ? '-' : preferredTime),

                          const SizedBox(height: 12),
                          _section('Location'),
                          _kv('Address', address.isEmpty ? '-' : address),
                          _kv('City', city.isEmpty ? '-' : city),
                          _kv('State', state.isEmpty ? '-' : state),
                          _kv('Zip', zip.isEmpty ? '-' : zip),

                          const SizedBox(height: 12),
                          _section('Notes'),
                          Text(notes.isEmpty ? '-' : notes),

                          const SizedBox(height: 16),
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

  static Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w900)),
      );

  static Widget _kv(String k, String v) => Padding(
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

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
