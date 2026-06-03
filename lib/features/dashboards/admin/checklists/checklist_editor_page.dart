import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/app_shell.dart';
import '../../../shared/top_snackbar.dart';
import '../../../../services/service_locator.dart';


class ChecklistEditorPage extends StatefulWidget {
  final bool isEdit;
  final String? templateId;

  const ChecklistEditorPage.create({super.key})
      : isEdit = false,
        templateId = null;

  const ChecklistEditorPage.edit({super.key, required this.templateId}) : isEdit = true;

  @override
  State<ChecklistEditorPage> createState() => _ChecklistEditorPageState();
}

class _ChecklistEditorPageState extends State<ChecklistEditorPage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  bool _dirty = false;

  final List<_SectionNode> _sections = [];
  int _selectedSectionIndex = 0;


  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_markDirty);
    _descCtrl.addListener(_markDirty);

    final defaultSection = _SectionNode(typeName: 'General')
      ..items.add(_ItemNode(label: 'New Item'));
    defaultSection.typeNameCtrl.addListener(_markDirty);
    defaultSection.maxVideosCtrl.addListener(_markDirty);
    defaultSection.weightageCtrl.addListener(_onWeightageChange);
    defaultSection.items.first.labelCtrl.addListener(_markDirty);
    defaultSection.items.first.descCtrl.addListener(_markDirty);
    defaultSection.items.first.weightageCtrl.addListener(_onWeightageChange);
    _sections.add(defaultSection);

    if (widget.isEdit) {
      _loadTemplate();
    } else {
      _dirty = false;
    }
  }

  void _markDirty() {
    if (_loading) return;
    if (!_dirty) setState(() => _dirty = true);
  }

  void _onWeightageChange() {
    if (_loading) return;
    setState(() => _dirty = true);
  }

  double get _sectionWeightageTotal => _sections.fold(
      0.0, (s, n) => s + (double.tryParse(n.weightageCtrl.text.trim()) ?? 0));

  double _itemWeightageTotal(int idx) => _sections[idx].items.fold(
      0.0, (s, it) => s + (double.tryParse(it.weightageCtrl.text.trim()) ?? 0));

  Widget _buildWeightageTotal(double total, String label) {
    final exact = total == 100;
    final color = exact ? Colors.green.shade700 : Colors.red.shade700;
    final bg    = exact ? Colors.green.shade50   : Colors.red.shade50;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.black45)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
            child: Text(
              '${total % 1 == 0 ? total.toInt() : total.toStringAsFixed(1)}% / 100%',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }

  void _showPreview() {
    showDialog<void>(
      context: context,
      builder: (_) => _TemplatePreviewDialog(
        templateName: _nameCtrl.text.trim().isEmpty
            ? 'Untitled Template'
            : _nameCtrl.text.trim(),
        sections: _sections,
      ),
    );
  }

  Future<void> _loadTemplate() async {
    setState(() {
      _loading = true;
      _dirty = false;
    });
    try {
      final tpl = await checklistTemplatesService.getTemplateById(widget.templateId!);
      _nameCtrl.text = (tpl['name'] ?? '').toString();
      _descCtrl.text = (tpl['description'] ?? '').toString();
      _sections.clear();

      final types = (tpl['types'] as List?) ?? const [];
      for (final t in types) {
        final m = t as Map<String, dynamic>;
        final s = _SectionNode(
          typeName: (m['typeName'] ?? 'Section').toString(),
          allowOverallRemarks: (m['allowOverallRemarks'] ?? true) as bool,
          allowOverallPhotos: (m['allowOverallPhotos'] ?? true) as bool,
          allowVideos: (m['allowVideos'] ?? false) as bool,
          maxVideos: (m['maxVideos'] is num)
              ? (m['maxVideos'] as num).toInt()
              : int.tryParse('${m['maxVideos']}') ?? 2,
          weightage: (m['weightage'] is num)
              ? (m['weightage'] as num).toDouble()
              : double.tryParse('${m['weightage']}') ?? 0,
        );
        s.typeNameCtrl.addListener(_markDirty);
        s.maxVideosCtrl.addListener(_markDirty);
        s.weightageCtrl.addListener(_onWeightageChange);

        final items = (m['checklistItems'] as List?) ?? const [];
        for (final it in items) {
          final im = it as Map<String, dynamic>;
          final node = _ItemNode(
            label: (im['label'] ?? '').toString(),
            description: (im['description'] ?? '').toString(),
            isRequired: (im['isRequired'] ?? true) as bool,
            weightage: (im['weightage'] is num)
                ? (im['weightage'] as num).toDouble()
                : double.tryParse('${im['weightage']}') ?? 0,
          );
          node.labelCtrl.addListener(_markDirty);
          node.descCtrl.addListener(_markDirty);
          node.weightageCtrl.addListener(_onWeightageChange);
          s.items.add(node);
        }

        if (s.items.isEmpty) {
          final node = _ItemNode(label: 'New Item');
          node.labelCtrl.addListener(_markDirty);
          node.descCtrl.addListener(_markDirty);
          node.weightageCtrl.addListener(_onWeightageChange);
          s.items.add(node);
        }

        _sections.add(s);
      }

      if (_sections.isEmpty) {
        final s = _SectionNode(typeName: 'General');
        s.typeNameCtrl.addListener(_markDirty);
        s.maxVideosCtrl.addListener(_markDirty);
        s.weightageCtrl.addListener(_onWeightageChange);
        final node = _ItemNode(label: 'New Item');
        node.labelCtrl.addListener(_markDirty);
        node.descCtrl.addListener(_markDirty);
        node.weightageCtrl.addListener(_onWeightageChange);
        s.items.add(node);
        _sections.add(s);
      }

      if (!mounted) return;
      setState(() => _dirty = false);
    } catch (e) {
      if (!mounted) return;
      showTopSnack(context, 'Load failed: $e', variant: 'error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Section actions ───────────────────────────────────────────────────────

  void _addSection() {
    setState(() {
      final s = _SectionNode(typeName: 'New Section')..items.add(_ItemNode(label: 'New Item'));
      s.typeNameCtrl.addListener(_markDirty);
      s.maxVideosCtrl.addListener(_markDirty);
      s.weightageCtrl.addListener(_onWeightageChange);
      s.items.first.labelCtrl.addListener(_markDirty);
      s.items.first.descCtrl.addListener(_markDirty);
      s.items.first.weightageCtrl.addListener(_onWeightageChange);
      _sections.add(s);
      _selectedSectionIndex = _sections.length - 1;
      _dirty = true;
    });
  }

  void _deleteSection(int index) {
    if (_sections.length <= 1) return;
    setState(() {
      _sections[index].dispose();
      _sections.removeAt(index);
      if (_selectedSectionIndex >= _sections.length) {
        _selectedSectionIndex = _sections.length - 1;
      }
      _dirty = true;
    });
  }

  Future<void> _showAddItemDialog(int sectionIndex) async {
    final labelCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isRequired = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: const Text('Add Item'),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            content: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: labelCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Item Name *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setLocal(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Required'),
                    value: isRequired,
                    onChanged: (v) => setLocal(() => isRequired = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: labelCtrl.text.trim().isEmpty
                    ? null
                    : () {
                        final node = _ItemNode(
                          label: labelCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          isRequired: isRequired,
                        );
                        node.labelCtrl.addListener(_markDirty);
                        node.descCtrl.addListener(_markDirty);
                        node.weightageCtrl.addListener(_onWeightageChange);
                        setState(() {
                          _sections[sectionIndex].items.add(node);
                          _dirty = true;
                        });
                        Navigator.of(ctx).pop();
                      },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );

    labelCtrl.dispose();
    descCtrl.dispose();
  }

  void _deleteItem(int sectionIndex, int itemIndex) {
    final s = _sections[sectionIndex];
    if (s.items.length <= 1) return;
    setState(() {
      s.items.removeAt(itemIndex);
      _dirty = true;
    });
  }

  Future<String?> _askUnsavedChanges() => showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('You have unsaved changes. Save before leaving?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('discard'),
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('cancel'),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop('save'),
              child: const Text('Save'),
            ),
          ],
        ),
      );

  // Called by PopScope (back/system navigation).
  Future<void> _showUnsavedChangesDialog() async {
    final action = await _askUnsavedChanges();
    if (!mounted) return;
    if (action == 'discard') {
      if (context.canPop()) context.pop(false);
    } else if (action == 'save') {
      await _save();
      if (mounted && context.canPop()) context.pop(true);
    }
  }

  // Called by breadcrumb taps — returns true to allow navigation, false to stay.
  Future<bool> _guardBreadcrumbNavigation() async {
    final action = await _askUnsavedChanges();
    if (!mounted) return false;
    if (action == 'discard') return true;
    if (action == 'save') {
      await _save();
      return true;
    }
    return false;
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  bool _validate() {
    if (_nameCtrl.text.trim().isEmpty) {
      showTopSnack(context, 'Template name is required', variant: 'warning');
      return false;
    }
    for (final s in _sections) {
      if (s.typeNameCtrl.text.trim().isEmpty) {
        showTopSnack(context, 'Section name cannot be empty', variant: 'warning');
        return false;
      }
      if (s.items.isEmpty) {
        showTopSnack(context, 'Each section needs at least 1 checklist item', variant: 'warning');
        return false;
      }
      for (final it in s.items) {
        if (it.labelCtrl.text.trim().isEmpty) {
          showTopSnack(context, 'Item label cannot be empty', variant: 'warning');
          return false;
        }
      }
    }
    final secTotal = _sectionWeightageTotal;
    if (secTotal != 100) {
      showTopSnack(context,
          'Section weightages total ${secTotal % 1 == 0 ? secTotal.toInt() : secTotal.toStringAsFixed(1)}% — must equal exactly 100%',
          variant: 'error');
      return false;
    }
    for (int i = 0; i < _sections.length; i++) {
      final t = _itemWeightageTotal(i);
      if (t != 100) {
        showTopSnack(context,
            'Item weightages in "${_sections[i].typeNameCtrl.text}" total ${t % 1 == 0 ? t.toInt() : t.toStringAsFixed(1)}% — must equal exactly 100%',
            variant: 'error');
        return false;
      }
    }
    return true;
  }

  Map<String, dynamic> _buildBody() {
    return {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'types': [
        for (final s in _sections)
          {
            'typeName': s.typeNameCtrl.text.trim(),
            'weightage': double.tryParse(s.weightageCtrl.text.trim()) ?? 0,
            'checklistItems': [
              for (int i = 0; i < s.items.length; i++)
                {
                  'position': i + 1,
                  'label': s.items[i].labelCtrl.text.trim(),
                  'description': s.items[i].descCtrl.text.trim(),
                  'isRequired': s.items[i].isRequired,
                  'weightage': double.tryParse(s.items[i].weightageCtrl.text.trim()) ?? 0,
                },
            ],
            'allowOverallRemarks': s.allowOverallRemarks,
            'allowOverallPhotos': s.allowOverallPhotos,
            'allowVideos': s.allowVideos,
            'maxVideos': int.tryParse(s.maxVideosCtrl.text.trim()) ?? s.maxVideos,
          },
      ],
    };
  }

  Future<void> _save() async {
    if (!_dirty || !_validate()) return;
    setState(() => _saving = true);
    try {
      final body = _buildBody();
      if (widget.isEdit) {
        await checklistTemplatesService.updateTemplate(id: widget.templateId!, body: body);
      } else {
        await checklistTemplatesService.createTemplate(
          name: body['name'] as String,
          description: body['description'] as String,
          types: List<Map<String, dynamic>>.from(body['types'] as List),
        );
      }
      if (!mounted) return;
      setState(() => _dirty = false);
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      showTopSnack(context, 'Save failed: $e', variant: 'error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    for (final s in _sections) { s.dispose(); }
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final saveEnabled = !_loading && !_saving && _dirty;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showUnsavedChangesDialog();
      },
      child: AppShell(
      title: widget.isEdit ? 'Edit Checklist Template' : 'New Checklist Template',
      onBeforeNavigate: _dirty ? _guardBreadcrumbNavigation : null,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
                  children: [
                    // Inline header: editable name + description + save
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: _nameCtrl,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                  decoration: InputDecoration(
                                    hintText: widget.isEdit
                                        ? 'Template name'
                                        : 'New template name',
                                    hintStyle: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black26),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                TextField(
                                  controller: _descCtrl,
                                  maxLines: 1,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.black54),
                                  decoration: const InputDecoration(
                                    hintText: 'Add a description (optional)',
                                    hintStyle: TextStyle(
                                        fontSize: 13, color: Colors.black26),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: _sections.isEmpty ? null : _showPreview,
                            icon: const Icon(Icons.visibility_outlined, size: 18),
                            label: const Text('Preview'),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: saveEnabled ? '' : 'Nothing updated',
                            child: FilledButton.icon(
                              onPressed: saveEnabled ? _save : null,
                              icon: const Icon(Icons.save_outlined),
                              label: Text(_saving ? 'Saving...' : 'Save'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Side panel + checklist
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildLeftPanel(),
                              const VerticalDivider(width: 1),
                              Expanded(child: _buildChecklistArea()),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    final hasSections = _sections.isNotEmpty;

    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Sections ─────────────────────────────────────────────────────
          _PanelHeader(
            title: 'SECTIONS',
            trailing: IconButton(
              icon: const Icon(Icons.add, size: 18),
              tooltip: 'Add Section',
              onPressed: _addSection,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            ),
          ),
          Expanded(
            flex: 3,
            child: !hasSections
                ? const SizedBox.shrink()
                : ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: _sections.length,
                    onReorder: (oldI, newI) {
                      setState(() {
                        if (newI > oldI) newI -= 1;
                        final moved = _sections.removeAt(oldI);
                        _sections.insert(newI, moved);
                        if (_selectedSectionIndex == oldI) {
                          _selectedSectionIndex = newI;
                        } else if (_selectedSectionIndex > oldI &&
                            _selectedSectionIndex <= newI) {
                          _selectedSectionIndex--;
                        } else if (_selectedSectionIndex < oldI &&
                            _selectedSectionIndex >= newI) {
                          _selectedSectionIndex++;
                        }
                        _dirty = true;
                      });
                    },
                    itemBuilder: (ctx, i) {
                      final s = _sections[i];
                      return _SectionListTile(
                        key: ValueKey(s.uid),
                        index: i,
                        section: s,
                        isSelected: i == _selectedSectionIndex,
                        canDelete: _sections.length > 1,
                        onTap: () => setState(() => _selectedSectionIndex = i),
                        onDelete: () => _deleteSection(i),
                        onWeightageChanged: _onWeightageChange,
                      );
                    },
                  ),
          ),
          _buildWeightageTotal(_sectionWeightageTotal, 'Section total'),
        ],
      ),
    );
  }

  Widget _buildChecklistArea() {
    if (_sections.isEmpty) return const SizedBox.shrink();
    final s = _sections[_selectedSectionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section name + settings bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: s.typeNameCtrl,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Section name',
                  ),
                  onChanged: (_) => _markDirty(),
                ),
              ),
              IconButton(
                icon: Icon(s.expanded ? Icons.expand_less : Icons.expand_more),
                tooltip: 'Section settings',
                onPressed: () => setState(() => s.expanded = !s.expanded),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _showAddItemDialog(_selectedSectionIndex),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Item'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),

        if (s.expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 12, 10),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  label: const Text('Overall remarks'),
                  selected: s.allowOverallRemarks,
                  onSelected: (v) =>
                      setState(() {s.allowOverallRemarks = v; _dirty = true;}),
                ),
                FilterChip(
                  label: const Text('Overall photos'),
                  selected: s.allowOverallPhotos,
                  onSelected: (v) =>
                      setState(() {s.allowOverallPhotos = v; _dirty = true;}),
                ),
                FilterChip(
                  label: const Text('Videos'),
                  selected: s.allowVideos,
                  onSelected: (v) =>
                      setState(() {s.allowVideos = v; _dirty = true;}),
                ),
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: s.maxVideosCtrl,
                    enabled: s.allowVideos,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Max videos', isDense: true),
                  ),
                ),
              ],
            ),
          ),

        const Divider(height: 1),

        // Scrollable content: checklist items
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  key: ValueKey('items_${s.uid}'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: s.items.length,
                  onReorder: (oldI, newI) {
                    setState(() {
                      if (newI > oldI) newI -= 1;
                      final moved = s.items.removeAt(oldI);
                      s.items.insert(newI, moved);
                      _dirty = true;
                    });
                  },
                  itemBuilder: (ctx, iIndex) {
                    final it = s.items[iIndex];
                    return _ItemRow(
                      key: ValueKey(it.uid),
                      index: iIndex,
                      item: it,
                      canDelete: s.items.length > 1,
                      onDelete: () => _deleteItem(_selectedSectionIndex, iIndex),
                      onChanged: _markDirty,
                      showDelete: true,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        _buildWeightageTotal(
            _itemWeightageTotal(_selectedSectionIndex), 'Items total'),
      ],
    );
  }
}

// ─── Left panel widgets ────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  final String title;
  final Widget trailing;

  const _PanelHeader({
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: Colors.black54,
                    letterSpacing: 0.5)),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _SectionListTile extends StatelessWidget {
  final int index;
  final _SectionNode section;
  final bool isSelected;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onWeightageChanged;

  const _SectionListTile({
    super.key,
    required this.index,
    required this.section,
    required this.isSelected,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
    required this.onWeightageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: section.typeNameCtrl,
      builder: (ctx, _) => Material(
        color: isSelected
            ? const Color(0xFF1E5EFF).withValues(alpha: 0.08)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.drag_indicator, color: Colors.black26, size: 16),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1E5EFF)
                        : Colors.black.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : Colors.black54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    section.typeNameCtrl.text.isEmpty
                        ? 'Untitled'
                        : section.typeNameCtrl.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF1E5EFF)
                          : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _WeightageChip(
                  controller: section.weightageCtrl,
                  onChanged: onWeightageChanged,
                ),
                const SizedBox(width: 2),
                if (canDelete)
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints.tightFor(width: 26, height: 26),
                      icon: const Icon(Icons.close, size: 13, color: Colors.black38),
                      tooltip: 'Delete section',
                      onPressed: onDelete,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Item row ─────────────────────────────────────────────────────────────

// ─── Weightage chip ───────────────────────────────────────────────────────────
// Compact pill used in section tiles. Shows "—" when empty, "25%" when set.

class _WeightageChip extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _WeightageChip({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 26,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E5EFF),
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          suffixText: '%',
          suffixStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E5EFF),
          ),
          hintText: '—',
          hintStyle: const TextStyle(
              fontSize: 12, color: Colors.black26, fontWeight: FontWeight.w400),
          filled: true,
          fillColor: const Color(0xFF1E5EFF).withValues(alpha: 0.07),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF1E5EFF), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
                color: const Color(0xFF1E5EFF).withValues(alpha: 0.35), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF1E5EFF), width: 1.5),
          ),
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final String? tooltip;
  final VoidCallback? onPressed;
  final IconData icon;

  const _MiniIconButton({
    this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 38, height: 38),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final int index;
  final _ItemNode item;
  final bool canDelete;
  final bool showDelete;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _ItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.canDelete,
    required this.onDelete,
    required this.onChanged,
    required this.showDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(top: 10, right: 8),
              child: Icon(Icons.drag_indicator, color: Colors.black38, size: 18),
            ),
          ),
          SizedBox(
            width: 26,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: item.labelCtrl,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Item name',
                  ),
                  onChanged: (_) => onChanged(),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: TextField(
                    controller: item.descCtrl,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                    decoration: const InputDecoration(
                      hintText: 'Add a description (optional)',
                      hintStyle:
                          TextStyle(fontSize: 13, color: Colors.black26),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
          ),
          // Weightage field
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Wt',
                  style: TextStyle(fontSize: 10, color: Colors.black38)),
              const SizedBox(height: 2),
              _WeightageChip(
                controller: item.weightageCtrl,
                onChanged: onChanged,
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Required toggle
          Tooltip(
            message: item.isRequired ? 'Required' : 'Optional',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Required',
                  style: TextStyle(
                    fontSize: 12,
                    color: item.isRequired ? Colors.black54 : Colors.black26,
                  ),
                ),
                Switch(
                  value: item.isRequired,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) {
                    item.isRequired = v;
                    onChanged();
                  },
                ),
              ],
            ),
          ),
          if (canDelete && showDelete)
            _MiniIconButton(
              tooltip: 'Delete item',
              onPressed: onDelete,
              icon: Icons.delete_outline,
            ),
        ],
      ),
    );
  }
}

// ─── Nodes ────────────────────────────────────────────────────────────────

class _SectionNode {
  final String uid = UniqueKey().toString();

  bool expanded = false;
  bool allowOverallRemarks;
  bool allowOverallPhotos;
  bool allowVideos;
  int maxVideos;

  final TextEditingController typeNameCtrl;
  final TextEditingController maxVideosCtrl;
  final TextEditingController weightageCtrl;

  final List<_ItemNode> items = [];

  _SectionNode({
    required String typeName,
    this.allowOverallRemarks = true,
    this.allowOverallPhotos = true,
    this.allowVideos = false,
    this.maxVideos = 2,
    double weightage = 0,
  })  : typeNameCtrl = TextEditingController(text: typeName),
        maxVideosCtrl = TextEditingController(text: maxVideos.toString()),
        weightageCtrl = TextEditingController(
            text: weightage > 0
                ? (weightage % 1 == 0
                    ? weightage.toInt().toString()
                    : weightage.toStringAsFixed(1))
                : '');

  void dispose() {
    typeNameCtrl.dispose();
    maxVideosCtrl.dispose();
    weightageCtrl.dispose();
    for (final it in items) { it.dispose(); }
  }
}

class _ItemNode {
  final String uid = UniqueKey().toString();
  bool expanded = false;
  bool isRequired;
  final TextEditingController labelCtrl;
  final TextEditingController descCtrl;
  final TextEditingController weightageCtrl;

  _ItemNode({
    required String label,
    String description = '',
    this.isRequired = true,
    double weightage = 0,
  })  : labelCtrl = TextEditingController(text: label),
        descCtrl = TextEditingController(text: description),
        weightageCtrl = TextEditingController(
            text: weightage > 0
                ? (weightage % 1 == 0
                    ? weightage.toInt().toString()
                    : weightage.toStringAsFixed(1))
                : '');

  void dispose() {
    labelCtrl.dispose();
    descCtrl.dispose();
    weightageCtrl.dispose();
  }
}

// ─── Template Preview Dialog ───────────────────────────────────────────────

class _TemplatePreviewDialog extends StatefulWidget {
  final String templateName;
  final List<_SectionNode> sections;

  const _TemplatePreviewDialog({
    required this.templateName,
    required this.sections,
  });

  @override
  State<_TemplatePreviewDialog> createState() => _TemplatePreviewDialogState();
}

class _TemplatePreviewDialogState extends State<_TemplatePreviewDialog> {
  int _currentSection = 0;

  @override
  Widget build(BuildContext context) {
    final sections = widget.sections;
    final s = sections[_currentSection];
    final isFirst = _currentSection == 0;
    final isLast = _currentSection == sections.length - 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 740, maxHeight: 720),
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                    bottom: BorderSide(
                        color: Colors.black.withValues(alpha: 0.08))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E5EFF).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('PREVIEW',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E5EFF),
                            letterSpacing: 0.5)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.templateName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close preview',
                  ),
                ],
              ),
            ),

            // ── Section tabs ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (int i = 0; i < sections.length; i++)
                    GestureDetector(
                      onTap: () => setState(() => _currentSection = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: i == _currentSection
                              ? const Color(0xFF1E5EFF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: i == _currentSection
                                ? const Color(0xFF1E5EFF)
                                : Colors.black.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          sections[i].typeNameCtrl.text.isEmpty
                              ? 'Section ${i + 1}'
                              : sections[i].typeNameCtrl.text,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: i == _currentSection ? Colors.white : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Section content ────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section title
                    Text(
                      s.typeNameCtrl.text.isEmpty
                          ? 'Section ${_currentSection + 1}'
                          : s.typeNameCtrl.text,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    const SizedBox(height: 16),

                    // Checklist items
                    for (int i = 0; i < s.items.length; i++) ...[
                      _buildChecklistItem(s, i),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // ── Footer navigation ──────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Section ${_currentSection + 1} of ${sections.length}',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black45),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: isFirst
                        ? null
                        : () =>
                            setState(() => _currentSection--),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Previous'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: isLast
                        ? null
                        : () =>
                            setState(() => _currentSection++),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Next'),
                    iconAlignment: IconAlignment.end,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(_SectionNode s, int idx) {
    final it = s.items[idx];
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
                '${idx + 1}',
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
                      child: Text(
                        it.labelCtrl.text.isEmpty ? '(no label)' : it.labelCtrl.text,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    if (it.isRequired)
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
                if (it.descCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(it.descCtrl.text, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
