import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/app_shell.dart';
import '../../../../services/emirates_service.dart';
import '../../../../services/service_locator.dart';
import '../../../shared/top_snackbar.dart';

class EmiratesPage extends StatefulWidget {
  const EmiratesPage({super.key});

  @override
  State<EmiratesPage> createState() => _EmiratesPageState();
}

class _EmiratesPageState extends State<EmiratesPage> {
  bool _loading = false;
  bool _busy = false;
  bool _refreshing = false;
  bool _dialogOpen = false;
  String? _error;

  List<EmirateDto> _emirates = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _safeSnack(String msg, {required String variant}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showTopSnack(context, msg, variant: variant);
    });
  }

  Future<void> _load() async {
    if (_loading || _refreshing) return;
    final isInitial = _emirates.isEmpty;
    setState(() {
      _error = null;
      if (isInitial) _loading = true; else _refreshing = true;
    });
    try {
      final list = await emiratesService
          .listEmirates()
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() => _emirates = list);
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _error = 'Request timed out. Please retry.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load emirates. Please retry.');
    } finally {
      if (mounted) setState(() { _loading = false; _refreshing = false; });
    }
  }

  Future<void> _runBusy(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
    } catch (_) {
      _safeSnack('Action failed. Please try again.', variant: 'error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addEmirate() async {
    final name = await _askName(title: 'Add Emirate');
    if (name == null) return;
    await _runBusy(() async {
      try {
        await emiratesService.addEmirate(name);
        await _load();
        _safeSnack('Emirate added.', variant: 'success');
      } catch (e) {
        final m = e.toString().toLowerCase();
        if (m.contains('409') || m.contains('conflict') || m.contains('already')) {
          _safeSnack('Emirate already exists.', variant: 'warning');
          return;
        }
        rethrow;
      }
    });
  }

  Future<void> _deleteEmirate(EmirateDto e) async {
    if (!await _confirm(
      title: 'Delete Emirate',
      body: 'Remove "${e.name}" and all its areas?',
    )) return;
    await _runBusy(() async {
      await emiratesService.deleteEmirate(e.id);
      await _load();
      _safeSnack('Emirate deleted.', variant: 'success');
    });
  }

  Future<void> _addArea(EmirateDto emirate) async {
    final name = await _askName(title: 'Add Area to ${emirate.name}');
    if (name == null) return;
    await _runBusy(() async {
      try {
        await emiratesService.addArea(emirate.id, name);
        await _load();
        _safeSnack('Area added.', variant: 'success');
      } catch (e) {
        final m = e.toString().toLowerCase();
        if (m.contains('409') || m.contains('conflict') || m.contains('already')) {
          _safeSnack('Area already exists for ${emirate.name}.', variant: 'warning');
          return;
        }
        rethrow;
      }
    });
  }

  Future<void> _deleteArea(AreaDto area) async {
    if (!await _confirm(title: 'Delete Area', body: 'Remove "${area.name}"?')) return;
    await _runBusy(() async {
      await emiratesService.deleteArea(area.id);
      await _load();
      _safeSnack('Area deleted.', variant: 'success');
    });
  }

  Future<String?> _askName({required String title}) async {
    if (_dialogOpen) return null;
    _dialogOpen = true;
    String value = '';
    String? err;
    bool saving = false;
    try {
      return await showDialog<String>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setD) {
            void submit() {
              if (saving) return;
              final t = value.trim();
              if (t.isEmpty) { setD(() => err = 'Name is required'); return; }
              saving = true;
              Navigator.of(ctx).pop(t);
            }

            return AlertDialog(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              content: TextField(
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  _UpperCase(),
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9\s\-\.\(\)\/]')),
                  LengthLimitingTextInputFormatter(80),
                ],
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: const OutlineInputBorder(),
                  errorText: err,
                ),
                onChanged: (v) { value = v; if (err != null) setD(() => err = null); },
                onSubmitted: (_) => submit(),
              ),
              actions: [
                TextButton(onPressed: saving ? null : () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                FilledButton(onPressed: saving ? null : submit, child: const Text('Save')),
              ],
            );
          },
        ),
      );
    } finally {
      _dialogOpen = false;
    }
  }

  Future<bool> _confirm({required String title, required String body}) async {
    if (_dialogOpen) return false;
    _dialogOpen = true;
    try {
      final res = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      return res == true;
    } finally {
      _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Emirates & Areas',
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Emirates & Areas',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      const Text(
                        'Configure the emirate and area options shown in the inspection request form.',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: (_busy || _loading || _refreshing) ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_refreshing) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
            ],

            if (_loading && _emirates.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 50),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _emirates.isEmpty)
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
            else if (_emirates.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No emirates found. Add one below.',
                      style: TextStyle(color: Colors.black54)),
                ),
              )
            else
              ..._emirates.map(
                (emirate) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(emirate.name,
                              style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                        _StatusChip(isActive: emirate.isActive),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Delete emirate',
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          onPressed: (_busy || _dialogOpen)
                              ? null
                              : () => _deleteEmirate(emirate),
                        ),
                      ],
                    ),
                    subtitle: Text('${emirate.areas.length} area(s)',
                        style: const TextStyle(color: Colors.black54)),
                    children: [
                      if (emirate.areas.isEmpty)
                        const ListTile(
                          title: Text('No areas yet.',
                              style: TextStyle(color: Colors.black54)),
                        )
                      else
                        ...emirate.areas.map(
                          (area) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined, size: 18),
                            title: Text(area.name,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _StatusChip(isActive: area.isActive),
                                const SizedBox(width: 4),
                                IconButton(
                                  tooltip: 'Delete area',
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16, color: Colors.red),
                                  onPressed: (_busy || _dialogOpen)
                                      ? null
                                      : () => _deleteArea(area),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const Divider(height: 1),
                      ListTile(
                        enabled: !_busy && !_dialogOpen,
                        leading: const Icon(Icons.add),
                        title: const Text('Add Area',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        onTap: () => _addArea(emirate),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),
            Card(
              child: ListTile(
                enabled: !_busy && !_dialogOpen,
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Add Emirate',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text(
                    'Create a new emirate (e.g. ABU DHABI, DUBAI)',
                    style: TextStyle(color: Colors.black54)),
                onTap: _addEmirate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(isActive ? 'ACTIVE' : 'INACTIVE'),
    backgroundColor: isActive
        ? Colors.green.withValues(alpha: 0.12)
        : Colors.grey.withValues(alpha: 0.12),
    side: BorderSide(
      color: isActive
          ? Colors.green.withValues(alpha: 0.25)
          : Colors.grey.withValues(alpha: 0.25),
    ),
    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
    padding: EdgeInsets.zero,
  );
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) =>
      n.copyWith(text: n.text.toUpperCase(), selection: n.selection);
}
