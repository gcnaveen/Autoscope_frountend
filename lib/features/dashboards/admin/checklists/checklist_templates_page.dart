import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/app_shell.dart';
import '../../../shared/top_snackbar.dart';
import '../../../../services/service_locator.dart';
import '../../../../services/dropdown_config_service.dart';

class ChecklistTemplatesPage extends StatefulWidget {
  const ChecklistTemplatesPage({super.key});

  @override
  State<ChecklistTemplatesPage> createState() => _ChecklistTemplatesPageState();
}

class _ChecklistTemplatesPageState extends State<ChecklistTemplatesPage> {
  late Future<Map<String, dynamic>> _future;
  bool _busy = false;

  int _page = 1;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _future = checklistTemplatesService.listAllAdmin(page: _page, limit: _limit);
  }

  void _reload() {
    setState(() {
      _future = checklistTemplatesService.listAllAdmin(page: _page, limit: _limit);
    });
  }

  int _countItems(Map<String, dynamic> t) {
    final types = (t['types'] as List?) ?? const [];
    int items = 0;

    for (final ty in types) {
      final m = ty as Map<String, dynamic>;
      final list = (m['checklistItems'] as List?) ?? const [];
      items += list.length;
    }
    return items;
  }

  String _getId(Map<String, dynamic> t) => (t['id'] ?? t['_id'] ?? '').toString();
  String _getName(Map<String, dynamic> t) => (t['name'] ?? '').toString();

  Future<void> _goEdit(String id) async {
    final changed = await context.push<bool>('/dashboard/admin/checklists/$id/edit');
    if (changed == true) _reload();
  }

  void _toastOk(String msg) => showTopSnack(context, msg);
  void _toastWarn(String msg) => showTopSnack(context, msg, variant: 'warning');
  void _toastErr(String msg) => showTopSnack(context, msg, variant: 'error');

  Future<void> _cloneTemplate({required String id, required String name}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clone template?'),
        content: Text('This will create a copy of "$name".'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Clone')),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final cloned = await checklistTemplatesService.cloneTemplate(id);
      _reload();

      if (!mounted) return;

      final newId = _getId(cloned);
      final newName = _getName(cloned);

      _toastOk(
        newId.isNotEmpty ? 'Cloned: ${newName.isNotEmpty ? newName : "New template"}' : 'Template cloned successfully',
      );
    } catch (e) {
      if (!mounted) return;
      _toastErr('Clone failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteTemplate({
    required String id,
    required String name,
    required bool allowDelete,
  }) async {
    if (!allowDelete) {
      if (!mounted) return;
      _toastWarn('Cannot delete the last remaining template.');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete template?'),
        content: Text('This will permanently delete "$name".'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await checklistTemplatesService.deleteTemplate(id);
      _reload();
      if (!mounted) return;
      _toastOk('Deleted: $name');
    } catch (e) {
      if (!mounted) return;
      _toastErr('Delete failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmSwitchActive({
    required String currentActiveName,
    required String nextName,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Switch active template?'),
        content: Text('This will deactivate "$currentActiveName" and activate "$nextName". Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes, switch')),
        ],
      ),
    );

    return ok == true;
  }

  Future<void> _handleToggleActive({
    required List<Map<String, dynamic>> templates,
    required Map<String, dynamic> target,
    required bool newValue,
  }) async {
    final targetId = _getId(target);
    if (targetId.isEmpty) return;

    final total = templates.length;
    final targetName = _getName(target);
    final targetIsActive = (target['isActive'] ?? false) as bool;

    if (total == 1 && newValue == false) {
      if (!mounted) return;
      _toastWarn('At least one template must remain active.');
      return;
    }

    if (newValue == false) {
      final activeCount = templates.where((x) => (x['isActive'] ?? false) == true).length;
      if (activeCount <= 1 && targetIsActive) {
        if (!mounted) return;
        _toastWarn('At least one template must remain active.');
        return;
      }

      setState(() => _busy = true);
      try {
        await checklistTemplatesService.setActive(targetId, false);
        _reload();
      } catch (e) {
        if (!mounted) return;
        _toastErr('Update failed: $e');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    final currentActive = templates.firstWhere(
      (x) => (x['isActive'] ?? false) == true,
      orElse: () => <String, dynamic>{},
    );

    final currentActiveId = _getId(currentActive);
    final currentActiveName = _getName(currentActive);

    if (currentActiveId.isNotEmpty && currentActiveId != targetId) {
      final ok = await _confirmSwitchActive(
        currentActiveName: currentActiveName.isEmpty ? 'Current template' : currentActiveName,
        nextName: targetName.isEmpty ? 'Selected template' : targetName,
      );
      if (!ok) return;

      setState(() => _busy = true);
      try {
        await checklistTemplatesService.setActive(currentActiveId, false);
        await checklistTemplatesService.setActive(targetId, true);
        _reload();
      } catch (e) {
        if (!mounted) return;
        _toastErr('Update failed: $e');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    if (!targetIsActive) {
      setState(() => _busy = true);
      try {
        await checklistTemplatesService.setActive(targetId, true);
        _reload();
      } catch (e) {
        if (!mounted) return;
        _toastErr('Update failed: $e');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  Future<void> _showTemplatePreview(String id, String name) async {
    setState(() => _busy = true);
    try {
      final results = await Future.wait([
        checklistTemplatesService.getTemplateById(id),
        dropdownConfigService.load(),
        dropdownConfigService.loadCustomFields(),
      ]);
      if (!mounted) return;

      final template = results[0] as Map<String, dynamic>;
      final dropdowns = results[1] as Map<String, List<String>>;
      final customFields = results[2] as List<CustomField>;

      await showDialog<void>(
        context: context,
        builder: (_) => _TemplateListPreviewDialog(
          templateName: name,
          template: template,
          configuredDropdowns: dropdowns,
          customFields: customFields,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _toastErr('Failed to load preview: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 720;

    return AppShell(
      title: 'Checklist Templates',
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 34),
                        const SizedBox(height: 10),
                        const Text(
                          'Failed to load templates',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${snap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _busy ? null : _reload,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          final data = snap.data ?? {};
          final templates = (data['templates'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
          final pagination = (data['pagination'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

          final allowDelete = templates.length > 1;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  if (!isMobile)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Checklist Templates',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _busy
                              ? null
                              : () async {
                                  final changed = await context.push<bool>('/dashboard/admin/checklists/new');
                                  if (changed == true) _reload();
                                },
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Checklist Templates',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _busy
                                ? null
                                : () async {
                                    final changed = await context.push<bool>('/dashboard/admin/checklists/new');
                                    if (changed == true) _reload();
                                  },
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          if (templates.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(18),
                              child: Text('No templates found. Click Add to create one.'),
                            ),
                          ...templates.map((t) {
                            final id = _getId(t);
                            final name = _getName(t);
                            final desc = (t['description'] ?? '').toString();
                            final isActive = (t['isActive'] ?? false) as bool;
                            final version = (t['version'] ?? 1).toString();
                            final typesCount = ((t['types'] as List?) ?? const []).length;
                            final itemsCount = _countItems(t);

                            final onlyOneTemplate = templates.length == 1;
                            final activeCount = templates.where((x) => (x['isActive'] ?? false) == true).length;
                            final cannotTurnOff = isActive && (onlyOneTemplate || activeCount <= 1);

                            final switchDisabled = id.isEmpty || _busy;
                            final switchValue = isActive;

                            final switchOnChanged = switchDisabled
                                ? null
                                : (bool v) async {
                                    if (v == false && cannotTurnOff) {
                                      _toastWarn('At least one template must remain active.');
                                      return;
                                    }
                                    if (v == true && isActive == true) return;
                                    await _handleToggleActive(templates: templates, target: t, newValue: v);
                                  };

                            return _TemplateCard(
                              isMobile: isMobile,
                              name: name,
                              desc: desc,
                              isActive: isActive,
                              version: version,
                              itemsCount: itemsCount,
                              typesCount: typesCount,
                              showActiveLabel: !isMobile, // desktop shows label near switch
                              switchValue: switchValue,
                              switchOnChanged: switchOnChanged,
                              onEdit: id.isEmpty ? null : () => _goEdit(id),
                              onPreview: (id.isEmpty || _busy) ? null : () => _showTemplatePreview(id, name),
                              onClone: (id.isEmpty || _busy) ? null : () => _cloneTemplate(id: id, name: name),
                              onDelete: (id.isEmpty || _busy)
                                  ? null
                                  : () => _deleteTemplate(id: id, name: name, allowDelete: allowDelete),
                              allowDelete: allowDelete,
                            );
                          }),
                          const SizedBox(height: 8),
                          _PaginationBar(
                            pagination: pagination,
                            page: _page,
                            onPrev: (pagination['hasPreviousPage'] == true && _page > 1)
                                ? () {
                                    _page -= 1;
                                    _reload();
                                  }
                                : null,
                            onNext: (pagination['hasNextPage'] == true)
                                ? () {
                                    _page += 1;
                                    _reload();
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
          );
        },
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final bool isMobile;

  final String name;
  final String desc;
  final bool isActive;
  final String version;
  final int itemsCount;
  final int typesCount;

  final bool showActiveLabel;
  final bool switchValue;
  final ValueChanged<bool>? switchOnChanged;

  final VoidCallback? onEdit;
  final VoidCallback? onPreview;
  final VoidCallback? onClone;
  final VoidCallback? onDelete;

  final bool allowDelete;

  const _TemplateCard({
    required this.isMobile,
    required this.name,
    required this.desc,
    required this.isActive,
    required this.version,
    required this.itemsCount,
    required this.typesCount,
    required this.showActiveLabel,
    required this.switchValue,
    required this.switchOnChanged,
    required this.onEdit,
    required this.onPreview,
    required this.onClone,
    required this.onDelete,
    required this.allowDelete,
  });

  @override
  Widget build(BuildContext context) {
    final meta = '$itemsCount items • $typesCount sections • v$version';
    final hasDesc = desc.trim().isNotEmpty;

    if (!isMobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          elevation: 0,
          color: Colors.black.withOpacity(0.02),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF1E5EFF).withOpacity(0.10),
              foregroundColor: const Color(0xFF1E5EFF),
              child: const Icon(Icons.playlist_add_check_outlined),
            ),
            title: Row(
              children: [
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900))),
                const SizedBox(width: 8),
                _StatusChip(active: isActive),
              ],
            ),
            subtitle: Text('$meta${hasDesc ? '\n$desc' : ''}'),
            isThreeLine: hasDesc,
            trailing: Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (showActiveLabel) Text(isActive ? 'Active' : 'Inactive'),
                Switch(value: switchValue, onChanged: switchOnChanged),
                FilledButton.tonal(onPressed: onEdit, child: const Text('Edit')),
                IconButton(
                  tooltip: 'Preview',
                  onPressed: onPreview,
                  icon: const Icon(Icons.visibility_outlined),
                ),
                IconButton(
                  tooltip: 'Clone',
                  onPressed: onClone,
                  icon: const Icon(Icons.copy_outlined),
                ),
                IconButton(
                  tooltip: allowDelete ? 'Delete' : 'Cannot delete the last template',
                  onPressed: allowDelete ? onDelete : null,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile layout: title stays wide, actions go below (no vertical text)
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        color: Colors.black.withOpacity(0.02),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1E5EFF).withOpacity(0.10),
                    foregroundColor: const Color(0xFF1E5EFF),
                    child: const Icon(Icons.playlist_add_check_outlined),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(active: isActive),
                ],
              ),
              const SizedBox(height: 8),
              Text(meta, style: const TextStyle(color: Colors.black54)),
              if (hasDesc) ...[
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(color: Colors.black54)),
              ],
              const SizedBox(height: 10),

              // switch row
              Row(
                children: [
                  Text(isActive ? 'Active' : 'Inactive', style: const TextStyle(color: Colors.black54)),
                  const Spacer(),
                  Switch(value: switchValue, onChanged: switchOnChanged),
                ],
              ),
              const SizedBox(height: 6),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    height: 36,
                    child: FilledButton.tonal(onPressed: onEdit, child: const Text('Edit')),
                  ),
                  IconButton(
                    tooltip: 'Preview',
                    onPressed: onPreview,
                    icon: const Icon(Icons.visibility_outlined),
                  ),
                  IconButton(
                    tooltip: 'Clone',
                    onPressed: onClone,
                    icon: const Icon(Icons.copy_outlined),
                  ),
                  IconButton(
                    tooltip: allowDelete ? 'Delete' : 'Cannot delete the last template',
                    onPressed: allowDelete ? onDelete : null,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;
  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active ? Colors.green.withOpacity(0.10) : Colors.orange.withOpacity(0.12),
        border: Border.all(color: active ? Colors.green.withOpacity(0.25) : Colors.orange.withOpacity(0.25)),
      ),
      child: Text(
        active ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: active ? Colors.green.shade800 : Colors.orange.shade900,
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final Map<String, dynamic> pagination;
  final int page;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.pagination,
    required this.page,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = pagination['totalPages'];
    final totalCount = pagination['totalCount'];

    final w = MediaQuery.sizeOf(context).width;
    final isNarrow = w < 520;

    final label =
        'Page $page${totalPages != null ? ' / $totalPages' : ''}${totalCount != null ? ' • $totalCount total' : ''}';

    if (!isNarrow) {
      return Row(
        children: [
          Text(label),
          const Spacer(),
          FilledButton.tonal(onPressed: onPrev, child: const Text('Prev')),
          const SizedBox(width: 8),
          FilledButton.tonal(onPressed: onNext, child: const Text('Next')),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: FilledButton.tonal(onPressed: onPrev, child: const Text('Prev'))),
            const SizedBox(width: 8),
            Expanded(child: FilledButton.tonal(onPressed: onNext, child: const Text('Next'))),
          ],
        ),
      ],
    );
  }
}

// ─── Template preview dialog (works from raw map data) ───────────────────────

class _TemplateListPreviewDialog extends StatefulWidget {
  final String templateName;
  final Map<String, dynamic> template;
  final Map<String, List<String>> configuredDropdowns;
  final List<CustomField> customFields;

  const _TemplateListPreviewDialog({
    required this.templateName,
    required this.template,
    required this.configuredDropdowns,
    required this.customFields,
  });

  @override
  State<_TemplateListPreviewDialog> createState() => _TemplateListPreviewDialogState();
}

class _TemplateListPreviewDialogState extends State<_TemplateListPreviewDialog> {
  int _tab = 0;

  List<Map<String, dynamic>> get _sections {
    final types = (widget.template['types'] as List?) ?? const [];
    return types.whereType<Map>().map((x) => Map<String, dynamic>.from(x)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    final safeTab = _tab.clamp(0, sections.isEmpty ? 0 : sections.length - 1);

    return Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
              color: const Color(0xFF1E5EFF).withValues(alpha: 0.06),
              child: Row(
                children: [
                  const Icon(Icons.visibility_outlined, color: Color(0xFF1E5EFF)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Preview', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        Text(
                          widget.templateName,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (sections.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No sections in this template.', style: TextStyle(color: Colors.black45)),
                ),
              )
            else ...[
              // Section tabs
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (int i = 0; i < sections.length; i++)
                      ChoiceChip(
                        label: Text((sections[i]['typeName'] ?? 'Section ${i + 1}').toString()),
                        selected: safeTab == i,
                        onSelected: (_) => setState(() => _tab = i),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _buildSectionContent(sections[safeTab], safeTab)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent(Map<String, dynamic> section, int tabIndex) {
    final inputFields =
        (section['inputFields'] as List?)?.map((x) => x.toString()).toList() ?? [];

    final rawItems = (section['checklistItems'] as List?)?.whereType<Map>().toList() ?? [];
    final items = rawItems.map((x) => Map<String, dynamic>.from(x)).toList();
    items.sort((a, b) {
      final pa = (a['position'] is num) ? (a['position'] as num).toInt() : 0;
      final pb = (b['position'] is num) ? (b['position'] as num).toInt() : 0;
      return pa.compareTo(pb);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (inputFields.isNotEmpty) ...[
            const Text(
              'INPUT FIELDS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black38, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            for (final key in inputFields) _buildFieldWidget(key),
            if (items.isNotEmpty) const Divider(height: 28),
          ],
          if (items.isNotEmpty) ...[
            const Text(
              'CHECKLIST ITEMS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black38, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < items.length; i++) _buildItemRow(items[i], i),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldWidget(String key) {
    // Built-in field
    if (DropdownConfigService.fieldLabels.containsKey(key)) {
      final label = DropdownConfigService.fieldLabels[key]!;
      final options = widget.configuredDropdowns[key] ?? [];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: options.isNotEmpty
            ? DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                onChanged: (_) {},
              )
            : TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
      );
    }

    // Custom field
    final matches = widget.customFields.where((f) => f.payloadKey == key);
    if (matches.isNotEmpty) {
      final cf = matches.first;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: cf.type == 'dropdown' && cf.options.isNotEmpty
            ? DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: cf.label,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: cf.options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                onChanged: (_) {},
              )
            : TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: cf.label,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
      );
    }

    // Fallback: unknown key
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: key,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item, int itemIndex) {
    final label = (item['label'] ?? 'Item').toString();
    final description = item['description']?.toString() ?? '';
    final isRequired = item['isRequired'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.06),
            ),
            child: Center(
              child: Text(
                '${itemIndex + 1}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                    if (isRequired)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Required',
                          style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(description, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}