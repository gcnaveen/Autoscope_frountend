import 'package:flutter/material.dart';

import '../../../shared/app_shell.dart';
import '../../../shared/widgets/pagination_bar.dart';
import '../../../shared/widgets/web_file_pick_web.dart';
import '../../../shared/top_snackbar.dart';
import '../../../../services/service_locator.dart';

import 'widgets/vehicle_spec_form_dialog.dart';

/// Admin management page for the vehicle-specs catalog (make/model/variant/
/// engine rows used to auto-fill parts of the inspector's inspection form).
/// This catalog can have thousands of rows (unlike the small makes/models
/// list in vehicle_catalog_page.dart), so it's a paginated searchable table
/// instead of an expansion-tile tree — structured like users_page.dart /
/// inspectors_page.dart (search + PaginationBar), with vehicle_catalog_page's
/// _loading/_busy/_refreshing/_error + _safeTopSnack + _runBusy conventions.
class VehicleSpecsPage extends StatefulWidget {
  const VehicleSpecsPage({super.key});

  @override
  State<VehicleSpecsPage> createState() => _VehicleSpecsPageState();
}

class _VehicleSpecsPageState extends State<VehicleSpecsPage> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<_SpecRow> _items = [];
  int _page = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  static const int _pageSize = 20;

  bool _loading = true; // initial load
  bool _busy = false; // row add/edit/delete in-flight
  bool _refreshing = false;
  bool _importing = false;
  String? _error;

  int _searchVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadPage(1);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _safeTopSnack(String msg, {required String variant}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showTopSnack(context, msg, variant: variant);
    });
  }

  Future<void> _loadPage(int page, {bool silent = false}) async {
    if (silent) {
      setState(() => _refreshing = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final result = await vehicleSpecsService.listVehicleSpecsPaged(
        page: page,
        limit: _pageSize,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _items = result.items.map(_SpecRow.fromJson).toList();
        _page = page;
        _totalPages = result.totalPages;
        _totalItems = result.total;
        _loading = false;
        _refreshing = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _refreshing = false;
      });
    }
  }

  void _reload() {
    _loadPage(_page, silent: true);
  }

  void _goToPage(int p) {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
    _loadPage(p);
  }

  void _onSearchChanged(String _) async {
    final ver = ++_searchVersion;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted || _searchVersion != ver) return;
    _loadPage(1);
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

  Future<void> _openAddDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const VehicleSpecFormDialog(),
    );
    if (ok == true) _loadPage(1);
  }

  Future<void> _openEditDialog(_SpecRow row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => VehicleSpecFormDialog(initial: row.toJson()),
    );
    if (ok == true) _loadPage(_page, silent: true);
  }

  Future<bool> _confirmDelete(_SpecRow row) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vehicle Spec', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          'Delete "${row.make} ${row.model} ${row.variant}"? This cannot be undone.',
        ),
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
  }

  Future<void> _deleteRow(_SpecRow row) async {
    final confirmed = await _confirmDelete(row);
    if (!confirmed) return;

    await _runBusy(() async {
      await vehicleSpecsService.deleteVehicleSpec(row.id);
      _safeTopSnack('Vehicle spec deleted.', variant: 'success');
      final isLastOnPage = _items.length == 1 && _page > 1;
      await _loadPage(isLastOnPage ? _page - 1 : _page, silent: !isLastOnPage);
    });
  }

  Future<void> _importCsv() async {
    if (_importing) return;

    final picked = await pickFileFromWebInput(accept: '.csv');
    if (picked == null) return;

    setState(() => _importing = true);
    try {
      final result = await vehicleSpecsService.importVehicleSpecsCsv(
        bytes: picked.bytes,
        filename: picked.name,
      );

      if (!mounted) return;

      final imported = result['imported'] ?? result['importedCount'] ?? result['inserted'];
      final failed = result['failed'] ?? result['failedCount'] ?? result['errors'];
      final msg = imported != null
          ? 'Import complete: $imported row(s) imported${failed != null ? ', $failed failed' : ''}.'
          : 'CSV import completed.';

      showTopSnack(context, msg, variant: 'success');
      await _loadPage(1);
    } catch (e) {
      if (!mounted) return;
      showTopSnack(context, 'CSV import failed: $e', variant: 'error');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 760;

    return AppShell(
      title: 'Vehicle Specs (Auto-fill)',
      child: ListView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          if (!isMobile)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Vehicle Specs (Auto-fill)',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: (_loading || _refreshing) ? null : _reload,
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _importing ? null : _importCsv,
                  icon: _importing
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_file_outlined),
                  label: Text(_importing ? 'Importing…' : 'Bulk Import CSV'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _busy ? null : _openAddDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Row'),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Vehicle Specs (Auto-fill)',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: (_loading || _refreshing) ? null : _reload,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _importing ? null : _importCsv,
                        icon: _importing
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.upload_file_outlined),
                        label: Text(_importing ? 'Importing…' : 'Import CSV'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _openAddDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Row'),
                      ),
                    ),
                  ],
                ),
              ],
            ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search by make / model / variant...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_refreshing) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                  ],

                  if (_loading)
                    const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                  else if (_error != null && _items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Text('Failed to load vehicle specs:\n$_error',
                              style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          FilledButton(onPressed: _reload, child: const Text('Retry')),
                        ],
                      ),
                    )
                  else if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(Icons.settings_suggest_outlined, size: 42, color: Colors.black26),
                          SizedBox(height: 10),
                          Text('No vehicle specs found.', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    )
                  else ...[
                    ..._items.map(
                      (row) => _SpecCard(
                        row: row,
                        isMobile: isMobile,
                        busy: _busy,
                        onEdit: () => _openEditDialog(row),
                        onDelete: () => _deleteRow(row),
                      ),
                    ),
                    if (_totalPages > 1) ...[
                      const SizedBox(height: 12),
                      PaginationBar(
                        currentPage: _page,
                        totalPages: _totalPages,
                        totalItems: _totalItems,
                        pageSize: _pageSize,
                        onPrev: _page > 1 ? () => _goToPage(_page - 1) : null,
                        onNext: _page < _totalPages ? () => _goToPage(_page + 1) : null,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecCard extends StatelessWidget {
  final _SpecRow row;
  final bool isMobile;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SpecCard({
    required this.row,
    required this.isMobile,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final driveTypes = row.driveTypes.isEmpty ? '—' : row.driveTypes.join('/');

    if (!isMobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
          elevation: 0,
          color: Colors.black.withValues(alpha: 0.02),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(row.make.isEmpty ? '—' : row.make,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(row.model.isEmpty ? '—' : row.model,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(row.variant.isEmpty ? '—' : row.variant,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(row.engineDisplay.isEmpty ? '—' : row.engineDisplay,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                ),
                Expanded(
                  child: Text(row.cylinders?.toString() ?? '—',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(row.fuelType.isEmpty ? '—' : row.fuelType,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(driveTypes,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(row.bodyType.isEmpty ? '—' : row.bodyType,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(row.specs.isEmpty ? '—' : row.specs,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                ),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: busy ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: busy ? null : onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile: card layout, actions below.
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        color: Colors.black.withValues(alpha: 0.02),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${row.make.isEmpty ? '—' : row.make} ${row.model} ${row.variant}'.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                row.engineDisplay.isEmpty ? '—' : row.engineDisplay,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (row.cylinders != null) _tag('${row.cylinders} cyl'),
                  if (row.fuelType.isNotEmpty) _tag(row.fuelType),
                  if (driveTypes != '—') _tag(driveTypes),
                  if (row.bodyType.isNotEmpty) _tag(row.bodyType),
                  if (row.specs.isNotEmpty) _tag(row.specs),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onDelete,
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String text) {
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey.withValues(alpha: 0.12),
      side: BorderSide(color: Colors.grey.withValues(alpha: 0.20)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _SpecRow {
  final String id;
  final String make;
  final String model;
  final String variant;
  final String subVariant;
  final String engineDisplay;
  final int? engineCc;
  final int? cylinders;
  final String fuelType;
  final List<String> driveTypes;
  final String bodyType;
  final String specs;

  const _SpecRow({
    required this.id,
    required this.make,
    required this.model,
    required this.variant,
    required this.subVariant,
    required this.engineDisplay,
    required this.engineCc,
    required this.cylinders,
    required this.fuelType,
    required this.driveTypes,
    required this.bodyType,
    required this.specs,
  });

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  factory _SpecRow.fromJson(Map<String, dynamic> j) {
    final rawDrive = j['driveTypes'];
    return _SpecRow(
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      make: (j['make'] ?? '').toString(),
      model: (j['model'] ?? '').toString(),
      variant: (j['variant'] ?? '').toString(),
      subVariant: (j['subVariant'] ?? '').toString(),
      engineDisplay: (j['engineDisplay'] ?? '').toString(),
      engineCc: _asInt(j['engineCc']),
      cylinders: _asInt(j['cylinders']),
      fuelType: (j['fuelType'] ?? '').toString(),
      driveTypes: rawDrive is List
          ? rawDrive.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
          : const [],
      bodyType: (j['bodyType'] ?? '').toString(),
      specs: (j['specs'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'make': make,
        'model': model,
        'variant': variant,
        'subVariant': subVariant,
        'engineDisplay': engineDisplay,
        'engineCc': engineCc,
        'cylinders': cylinders,
        'fuelType': fuelType,
        'driveTypes': driveTypes,
        'bodyType': bodyType,
        'specs': specs,
      };
}
