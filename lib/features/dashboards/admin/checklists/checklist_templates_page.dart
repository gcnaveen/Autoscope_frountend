import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/app_shell.dart';
import '../../../shared/top_snackbar.dart';
import '../../../../services/service_locator.dart';

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

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: ListView(
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
              ),
            ),
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