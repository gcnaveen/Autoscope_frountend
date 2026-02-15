import 'package:flutter/material.dart';
import '../../shared/app_shell.dart';
import '../../../../services/service_locator.dart';
import '../../shared/top_snackbar.dart';

class UserRequestDetailsPage extends StatefulWidget {
  final String requestId;
  const UserRequestDetailsPage({super.key, required this.requestId});

  @override
  State<UserRequestDetailsPage> createState() => _UserRequestDetailsPageState();
}

class _UserRequestDetailsPageState extends State<UserRequestDetailsPage> {
  late Future<Map<String, dynamic>> _future;

  bool _editing = false;
  bool _saving = false;

  // Editable fields
  final _formKey = GlobalKey<FormState>();

  final makeCtrl = TextEditingController();
  final modelCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
  final vinCtrl = TextEditingController();
  final plateCtrl = TextEditingController();
  final mileageCtrl = TextEditingController();
  final colorCtrl = TextEditingController();

  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final zipCtrl = TextEditingController();

  final notesCtrl = TextEditingController();
  final preferredTimeCtrl = TextEditingController();

  DateTime? preferredDateLocal; // user picked (local)

  Map<String, dynamic>? _latest; // store current data for cancel/reset

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final r = await userRequestsService.getRequestById(widget.requestId);
    _latest = r;
    _hydrateControllers(r);
    return r;
  }

  void _reload() {
    setState(() => _future = _load());
  }

  void _hydrateControllers(Map<String, dynamic> r) {
    final vehicle = (r['vehicleInfo'] is Map) ? (r['vehicleInfo'] as Map) : {};
    final loc = (r['location'] is Map) ? (r['location'] as Map) : {};

    makeCtrl.text = (vehicle['make'] ?? '').toString();
    modelCtrl.text = (vehicle['model'] ?? '').toString();
    yearCtrl.text = (vehicle['year'] ?? '').toString();
    vinCtrl.text = (vehicle['vin'] ?? '').toString();
    plateCtrl.text = (vehicle['licensePlate'] ?? '').toString();
    mileageCtrl.text = (vehicle['mileage'] ?? '').toString();
    colorCtrl.text = (vehicle['color'] ?? '').toString();

    addressCtrl.text = (loc['address'] ?? '').toString();
    cityCtrl.text = (loc['city'] ?? '').toString();
    stateCtrl.text = (loc['state'] ?? '').toString();
    zipCtrl.text = (loc['zipCode'] ?? '').toString();

    notesCtrl.text = (r['notes'] ?? '').toString();
    preferredTimeCtrl.text = (r['preferredTime'] ?? '').toString();

    final pd = r['preferredDate'];
    preferredDateLocal = DateTime.tryParse((pd ?? '').toString())?.toLocal();
  }

  @override
  void dispose() {
    makeCtrl.dispose();
    modelCtrl.dispose();
    yearCtrl.dispose();
    vinCtrl.dispose();
    plateCtrl.dispose();
    mileageCtrl.dispose();
    colorCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    zipCtrl.dispose();
    notesCtrl.dispose();
    preferredTimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPreferredDate() async {
    final now = DateTime.now();
    final initial = preferredDateLocal ?? now;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      initialDate: initial,
    );
    if (picked == null) return;

    // keep existing time if present
    final existing = preferredDateLocal ?? picked;
    preferredDateLocal = DateTime(
      picked.year,
      picked.month,
      picked.day,
      existing.hour,
      existing.minute,
    );
    setState(() {});
  }

  void _toggleEdit() {
    if (_editing) {
      // Cancel edit -> reset to last loaded data
      final r = _latest;
      if (r != null) _hydrateControllers(r);
      setState(() => _editing = false);
      return;
    }
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _saving = true);

    try {
      final payload = <String, dynamic>{
        "vehicleInfo": {
          "make": makeCtrl.text.trim(),
          "model": modelCtrl.text.trim(),
          "year": int.tryParse(yearCtrl.text.trim()),
          "vin": vinCtrl.text.trim(),
          "licensePlate": plateCtrl.text.trim(),
          "mileage": int.tryParse(mileageCtrl.text.trim()),
          "color": colorCtrl.text.trim(),
        },
        "location": {
          "address": addressCtrl.text.trim(),
          "city": cityCtrl.text.trim(),
          "state": stateCtrl.text.trim(),
          "zipCode": zipCtrl.text.trim(),
        },
        "notes": notesCtrl.text.trim(),
        "preferredTime": preferredTimeCtrl.text.trim(),
        // backend expects ISO string
        "preferredDate": preferredDateLocal?.toUtc().toIso8601String(),
      };

      // Remove nulls from year/mileage/preferredDate if not set
      final vi = payload["vehicleInfo"] as Map<String, dynamic>;
      if (vi["year"] == null) vi.remove("year");
      if (vi["mileage"] == null) vi.remove("mileage");
      if (payload["preferredDate"] == null) payload.remove("preferredDate");

      final updated = await userRequestsService.updateRequest(widget.requestId, payload);

      // ✅ IMPORTANT: update FutureBuilder immediately
      _latest = updated;
      _hydrateControllers(updated);

      if (!mounted) return;

      setState(() {
        _editing = false;
        _future = Future.value(updated); // ✅ THIS FIXES YOUR ISSUE
      });

      showTopSnack(context, 'Request updated successfully.', variant: 'success');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Request updated successfully.')),
      // );
    } catch (e) {
      if (!mounted) return;
      showTopSnack(context, 'Update failed: $e', variant: 'error');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Update failed: $e')),
      // );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Request Details',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                );
              }

              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Failed to load request: ${snap.error}'),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              // ✅ Prefer snap.data; fallback to latest (helps during quick updates)
              final r = snap.data ?? _latest ?? {};
              final vehicle = (r['vehicleInfo'] is Map) ? (r['vehicleInfo'] as Map) : {};
              final location = (r['location'] is Map) ? (r['location'] as Map) : {};
              final user = (r['userId'] is Map) ? (r['userId'] as Map) : {};

              final status = (r['status'] ?? 'pending').toString();
              final type = (r['requestType'] ?? '-').toString();
              final requestId = (r['requestId'] ?? r['id'] ?? widget.requestId).toString();

              final createdAt = DateTime.tryParse((r['createdAt'] ?? '').toString());
              final updatedAt = DateTime.tryParse((r['updatedAt'] ?? '').toString());

              final preferredDateStr = _prettyDate(r['preferredDate']);

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Request: $requestId',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: _saving ? null : _toggleEdit,
                        child: Text(_editing ? 'Cancel' : 'Edit'),
                      ),
                      const SizedBox(width: 10),
                      if (_editing)
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: Text(_saving ? 'Saving…' : 'Save Changes'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Pill(label: 'Type: $type'),
                          _Pill(label: 'Status: $status', tone: _toneForStatus(status)),
                          if (preferredDateStr != null) _Pill(label: 'Preferred: $preferredDateStr'),
                          if ((r['preferredTime'] ?? '').toString().trim().isNotEmpty)
                            _Pill(label: 'Time: ${r['preferredTime']}'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _Section(
                          title: 'Vehicle Info',
                          child: _editing
                              ? _VehicleEditForm(
                                  makeCtrl: makeCtrl,
                                  modelCtrl: modelCtrl,
                                  yearCtrl: yearCtrl,
                                  vinCtrl: vinCtrl,
                                  plateCtrl: plateCtrl,
                                  mileageCtrl: mileageCtrl,
                                  colorCtrl: colorCtrl,
                                )
                              : _KeyValues(items: [
                                  ('Make', vehicle['make']),
                                  ('Model', vehicle['model']),
                                  ('Year', vehicle['year']),
                                  ('VIN', vehicle['vin']),
                                  ('License Plate', vehicle['licensePlate']),
                                  ('Mileage', vehicle['mileage']),
                                  ('Color', vehicle['color']),
                                ]),
                        ),

                        const SizedBox(height: 12),

                        _Section(
                          title: 'Location',
                          child: _editing
                              ? _LocationEditForm(
                                  addressCtrl: addressCtrl,
                                  cityCtrl: cityCtrl,
                                  stateCtrl: stateCtrl,
                                  zipCtrl: zipCtrl,
                                )
                              : _KeyValues(items: [
                                  ('Address', location['address']),
                                  ('City', location['city']),
                                  ('State', location['state']),
                                  ('Zip', location['zipCode']),
                                ]),
                        ),

                        const SizedBox(height: 12),

                        _Section(
                          title: 'Preferred Schedule',
                          child: _editing
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _pickPreferredDate,
                                            icon: const Icon(Icons.event),
                                            label: Text(
                                              preferredDateLocal == null
                                                  ? 'Pick Preferred Date'
                                                  : 'Date: ${preferredDateLocal!.day}/${preferredDateLocal!.month}/${preferredDateLocal!.year}',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: preferredTimeCtrl,
                                      autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
                                      decoration: const InputDecoration(
                                        labelText: 'Preferred Time',
                                        border: OutlineInputBorder(),
                                        hintText: '10:00 AM',
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty) ? 'Preferred time is required' : null,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Tip: Time is a text field because backend expects “10:00 AM” format.',
                                      style: TextStyle(color: Colors.black54, fontSize: 12),
                                    ),
                                  ],
                                )
                              : _KeyValues(items: [
                                  ('Preferred Date', preferredDateStr ?? '-'),
                                  ('Preferred Time', r['preferredTime']),
                                ]),
                        ),

                        const SizedBox(height: 12),

                        _Section(
                          title: 'Notes',
                          child: _editing
                              ? TextFormField(
                                  controller: notesCtrl,
                                  autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'Notes',
                                    border: OutlineInputBorder(),
                                  ),
                                )
                              : Text(
                                  (r['notes'] == null || r['notes'].toString().trim().isEmpty)
                                      ? '-'
                                      : r['notes'].toString(),
                                  style: const TextStyle(color: Colors.black87, height: 1.5),
                                ),
                        ),

                        const SizedBox(height: 12),

                        _Section(
                          title: 'Owner',
                          child: _KeyValues(items: [
                            ('Name', '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim()),
                            ('Email', user['email']),
                            ('Phone', user['phone']),
                          ]),
                        ),

                        const SizedBox(height: 12),

                        _Section(
                          title: 'System',
                          child: _KeyValues(items: [
                            ('Created', createdAt != null ? _fmt(createdAt) : '-'),
                            ('Updated', updatedAt != null ? _fmt(updatedAt) : '-'),
                            ('Internal Id', r['id']),
                          ]),
                        ),
                      ],
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

  static String? _prettyDate(dynamic v) {
    if (v == null) return null;
    final dt = DateTime.tryParse(v.toString());
    if (dt == null) return v.toString();
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  static String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static Color _toneForStatus(String s) {
    final v = s.toLowerCase();
    if (v.contains('pending')) return Colors.orange;
    if (v.contains('assign')) return Colors.blue;
    if (v.contains('complete') || v.contains('done')) return Colors.green;
    if (v.contains('cancel')) return Colors.red;
    return Colors.grey;
  }
}

/* ========================= Edit Forms ========================= */

class _VehicleEditForm extends StatelessWidget {
  final TextEditingController makeCtrl;
  final TextEditingController modelCtrl;
  final TextEditingController yearCtrl;
  final TextEditingController vinCtrl;
  final TextEditingController plateCtrl;
  final TextEditingController mileageCtrl;
  final TextEditingController colorCtrl;

  const _VehicleEditForm({
    required this.makeCtrl,
    required this.modelCtrl,
    required this.yearCtrl,
    required this.vinCtrl,
    required this.plateCtrl,
    required this.mileageCtrl,
    required this.colorCtrl,
  });

  @override
  Widget build(BuildContext context) {
    Widget f(Widget child) => Padding(padding: const EdgeInsets.only(bottom: 12), child: child);

    return Column(
      children: [
        f(TextFormField(
          controller: makeCtrl,
          autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
          decoration: const InputDecoration(labelText: 'Make', border: OutlineInputBorder()),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Make is required' : null,
        )),
        f(TextFormField(
          controller: modelCtrl,
          autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
          decoration: const InputDecoration(labelText: 'Model', border: OutlineInputBorder()),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Model is required' : null,
        )),
        f(TextFormField(
          controller: yearCtrl,
          autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Year is required';
            final y = int.tryParse(v.trim());
            if (y == null || y < 1900 || y > DateTime.now().year + 1) return 'Enter valid year';
            return null;
          },
        )),
        f(TextFormField(
          controller: vinCtrl,
          autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
          decoration: const InputDecoration(labelText: 'VIN', border: OutlineInputBorder()),
        )),
        f(TextFormField(
          controller: plateCtrl,
          autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
          decoration: const InputDecoration(labelText: 'License Plate', border: OutlineInputBorder()),
        )),
        f(TextFormField(
          controller: mileageCtrl,
          autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Mileage', border: OutlineInputBorder()),
        )),
        TextFormField(
          controller: colorCtrl,
          autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
          decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder()),
        ),
      ],
    );
  }
}

class _LocationEditForm extends StatelessWidget {
  final TextEditingController addressCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController stateCtrl;
  final TextEditingController zipCtrl;

  const _LocationEditForm({
    required this.addressCtrl,
    required this.cityCtrl,
    required this.stateCtrl,
    required this.zipCtrl,
  });

  @override
  Widget build(BuildContext context) {
    Widget f(Widget child) => Padding(padding: const EdgeInsets.only(bottom: 12), child: child);

    return Column(
      children: [
        f(TextFormField(
          controller: addressCtrl,
          autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
          decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
        )),
        f(TextFormField(
          controller: cityCtrl,
          autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
          decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'City is required' : null,
        )),
        f(TextFormField(
          controller: stateCtrl,
          autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
          decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
        )),
        TextFormField(
          controller: zipCtrl,
          autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
          decoration: const InputDecoration(labelText: 'Zip Code', border: OutlineInputBorder()),
        ),
      ],
    );
  }
}

/* ========================= UI Helpers ========================= */

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          child,
        ]),
      ),
    );
  }
}

class _KeyValues extends StatelessWidget {
  final List<(String, dynamic)> items;
  const _KeyValues({required this.items});

  @override
  Widget build(BuildContext context) {
    final filtered = items.where((x) => x.$2 != null && x.$2.toString().trim().isNotEmpty).toList();
    if (filtered.isEmpty) return const Text('-', style: TextStyle(color: Colors.black54));

    return Column(
      children: filtered
          .map((x) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 140, child: Text(x.$1, style: const TextStyle(color: Colors.black54))),
                    Expanded(child: Text(x.$2.toString(), style: const TextStyle(fontWeight: FontWeight.w700))),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color? tone;
  const _Pill({required this.label, this.tone});

  @override
  Widget build(BuildContext context) {
    final c = tone ?? const Color(0xFF1E5EFF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.22)),
      ),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: c)),
    );
  }
}
