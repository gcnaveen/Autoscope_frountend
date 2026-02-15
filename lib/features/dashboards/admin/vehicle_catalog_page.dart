import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/app_shell.dart';
import '../../../services/service_locator.dart';
import '../../shared/top_snackbar.dart';

class VehicleCatalogPage extends StatefulWidget {
  const VehicleCatalogPage({super.key});

  @override
  State<VehicleCatalogPage> createState() => _VehicleCatalogPageState();
}

class _VehicleCatalogPageState extends State<VehicleCatalogPage> {
  bool _loading = false; // ✅ IMPORTANT: start false (otherwise _load() returns immediately)
  bool _busy = false;
  bool _refreshing = false;
  bool _dialogOpen = false;
  String? _error;

  List<_MakeDto> _makes = const [];

  @override
  void initState() {
    super.initState();
    // Let first frame mount fully, then load (avoids some web timing issues)
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _safeTopSnack(String msg, {required String variant}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showTopSnack(context, msg, variant: variant);
    });
  }

  Future<void> _load() async {
    // prevent overlapping loads
    if (_loading || _refreshing) return;

    final isInitial = _makes.isEmpty;

    setState(() {
      _error = null;
      if (isInitial) {
        _loading = true;
      } else {
        _refreshing = true;
      }
    });

    try {
      // ✅ Use /admin/... and let apiClient prefix /api if it does in your app
      final res = await apiClient.getJson('/admin/makes').timeout(const Duration(seconds: 15));

      final list = (res is Map && res['data'] is List)
          ? List<dynamic>.from(res['data'])
          : (res is List ? res : <dynamic>[]);

      final makes = list.map((e) => _MakeDto.fromJson(Map<String, dynamic>.from(e))).toList();

      if (!mounted) return;
      setState(() => _makes = makes);
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _error = 'Request timed out. Please retry.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load makes. Please retry.');
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
      });
    }
  }

  Future<void> _runBusy(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
    } catch (_) {
      _safeTopSnack('Action failed. Please try again.', variant: 'error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addMake() async {
    final name = await _askNameDialog(title: 'Add Make');
    if (name == null) return;

    await _runBusy(() async {
      try {
        await apiClient.postJson('/admin/makes', {'name': name.toUpperCase()});
        await _load();
        _safeTopSnack('Make added.', variant: 'success');
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('409') || msg.contains('conflict') || msg.contains('already')) {
          _safeTopSnack('Make already exists.', variant: 'warning');
          return;
        }
        rethrow;
      }
    });
  }

  Future<void> _addModel(_MakeDto make) async {
    final name = await _askNameDialog(title: 'Add Model for ${make.name}');
    if (name == null) return;

    await _runBusy(() async {
      try {
        await apiClient.postJson('/admin/models', {
          'name': name.toUpperCase(),
          'makeId': make.id,
        });
        await _load();
        _safeTopSnack('Model added.', variant: 'success');
      } catch (e) {
        // ✅ 409 Conflict = duplicate model (most likely)
        final msg = e.toString().toLowerCase();
        if (msg.contains('409') || msg.contains('conflict') || msg.contains('already')) {
          _safeTopSnack('Model already exists for ${make.name}.', variant: 'warning');
          return;
        }
        rethrow;
      }
    });
  }

  // ✅ FIX: no TextEditingController, no GlobalKey<FormState> => prevents dispose + duplicate key issues on web
  Future<String?> _askNameDialog({required String title}) async {
    if (_dialogOpen) return null;
    _dialogOpen = true;

    String value = '';
    String? errorText;
    bool saving = false;

    try {
      final res = await showDialog<String>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setStateDialog) {
              void submit() {
                if (saving) return;
                final trimmed = value.trim();
                if (trimmed.isEmpty) {
                  setStateDialog(() => errorText = 'Name is required');
                  return;
                }
                saving = true;
                Navigator.of(ctx).pop(trimmed);
              }

              return AlertDialog(
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                content: TextField(
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    UpperCaseTextFormatter(),
                    FilteringTextInputFormatter.allow(RegExp(r"[A-Z0-9\s\-\.\&]")),
                    LengthLimitingTextInputFormatter(60),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: const OutlineInputBorder(),
                    errorText: errorText,
                  ),
                  onChanged: (v) {
                    value = v;
                    if (errorText != null) {
                      setStateDialog(() => errorText = null);
                    }
                  },
                  onSubmitted: (_) => submit(),
                ),
                actions: [
                  TextButton(
                    onPressed: saving ? null : () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: saving ? null : submit,
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
      return res;
    } finally {
      _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Vehicle Catalog (Makes & Models)',
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            Row(
              children: [
                Text(
                  'Makes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: (_busy || _loading || _refreshing) ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_refreshing) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
            ],

            if (_loading && _makes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 50),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _makes.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.black54))),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _busy ? null : _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_makes.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No makes found. Add one below.', style: TextStyle(color: Colors.black54)),
                ),
              )
            else
              ..._makes.map((make) {
                return Card(
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(make.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                        _ActiveChip(isActive: make.isActive),
                      ],
                    ),
                    subtitle: Text('${make.models.length} model(s)', style: const TextStyle(color: Colors.black54)),
                    children: [
                      if (make.models.isEmpty)
                        const ListTile(
                          title: Text('No models yet', style: TextStyle(color: Colors.black54)),
                        )
                      else
                        ...make.models.map(
                          (m) => ListTile(
                            leading: const Icon(Icons.directions_car_outlined),
                            title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            trailing: _ActiveChip(isActive: m.isActive),
                          ),
                        ),
                      const Divider(height: 1),
                      ListTile(
                        enabled: !_busy && !_dialogOpen,
                        leading: const Icon(Icons.add),
                        title: const Text('Add Model', style: TextStyle(fontWeight: FontWeight.w800)),
                        onTap: () => _addModel(make),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                enabled: !_busy && !_dialogOpen,
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Add Make', style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('Create a new vehicle make (brand)', style: TextStyle(color: Colors.black54)),
                onTap: _addMake,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  final bool isActive;
  const _ActiveChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final bg = isActive ? Colors.green.withOpacity(0.12) : Colors.grey.withOpacity(0.12);
    final border = isActive ? Colors.green.withOpacity(0.25) : Colors.grey.withOpacity(0.25);
    return Chip(
      label: Text(isActive ? 'ACTIVE' : 'INACTIVE'),
      backgroundColor: bg,
      side: BorderSide(color: border),
      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}

class _MakeDto {
  final String id;
  final String name;
  final bool isActive;
  final List<_ModelDto> models;

  const _MakeDto({
    required this.id,
    required this.name,
    required this.isActive,
    required this.models,
  });

  factory _MakeDto.fromJson(Map<String, dynamic> j) {
    final modelsRaw = (j['models'] is List) ? List<dynamic>.from(j['models']) : const <dynamic>[];
    return _MakeDto(
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      isActive: (j['isActive'] == true),
      models: modelsRaw.map((e) => _ModelDto.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}

class _ModelDto {
  final String id;
  final String name;
  final bool isActive;

  const _ModelDto({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory _ModelDto.fromJson(Map<String, dynamic> j) {
    return _ModelDto(
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      isActive: (j['isActive'] == true),
    );
  }
}
