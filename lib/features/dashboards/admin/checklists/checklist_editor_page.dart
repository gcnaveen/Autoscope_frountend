import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/app_shell.dart';
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

  @override
  void initState() {
    super.initState();

    _nameCtrl.addListener(_markDirty);
    _descCtrl.addListener(_markDirty);

    // Defaults for create
    _nameCtrl.text = '';
    _descCtrl.text = '';
    _sections.add(
      _SectionNode(typeName: 'General')
        ..items.add(_ItemNode(label: 'New Item')),
    );

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
          maxVideos: (m['maxVideos'] ?? 2) is int
              ? (m['maxVideos'] ?? 2) as int
              : int.tryParse('${m['maxVideos']}') ?? 2,
        );

        // mark dirty on section controller changes
        s.typeNameCtrl.addListener(_markDirty);
        s.maxVideosCtrl.addListener(_markDirty);

        final items = (m['checklistItems'] as List?) ?? const [];
        for (final it in items) {
          final im = it as Map<String, dynamic>;
          final node = _ItemNode(
            label: (im['label'] ?? '').toString(),
            description: (im['description'] ?? '').toString(),
            isRequired: (im['isRequired'] ?? true) as bool,
          );

          node.labelCtrl.addListener(_markDirty);
          node.descCtrl.addListener(_markDirty);

          s.items.add(node);
        }

        if (s.items.isEmpty) {
          final node = _ItemNode(label: 'New Item');
          node.labelCtrl.addListener(_markDirty);
          node.descCtrl.addListener(_markDirty);
          s.items.add(node);
        }

        _sections.add(s);
      }

      if (_sections.isEmpty) {
        final s = _SectionNode(typeName: 'General');
        s.typeNameCtrl.addListener(_markDirty);
        s.maxVideosCtrl.addListener(_markDirty);

        final node = _ItemNode(label: 'New Item');
        node.labelCtrl.addListener(_markDirty);
        node.descCtrl.addListener(_markDirty);
        s.items.add(node);

        _sections.add(s);
      }

      if (!mounted) return;
      setState(() => _dirty = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Load failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------- actions ----------------

  void _addSection() {
    setState(() {
      final s = _SectionNode(typeName: 'New Section')..items.add(_ItemNode(label: 'New Item'));
      s.typeNameCtrl.addListener(_markDirty);
      s.maxVideosCtrl.addListener(_markDirty);

      // listeners for default item
      s.items.first.labelCtrl.addListener(_markDirty);
      s.items.first.descCtrl.addListener(_markDirty);

      _sections.add(s);
      _dirty = true;
    });
  }

  void _deleteSection(int sectionIndex) {
    if (_sections.length <= 1) return;
    setState(() {
      _sections.removeAt(sectionIndex);
      _dirty = true;
    });
  }

  void _addItem(int sectionIndex) {
    setState(() {
      final node = _ItemNode(label: 'New Item');
      node.labelCtrl.addListener(_markDirty);
      node.descCtrl.addListener(_markDirty);

      _sections[sectionIndex].items.add(node);
      _dirty = true;
    });
  }

  void _deleteItem(int sectionIndex, int itemIndex) {
    final s = _sections[sectionIndex];
    if (s.items.length <= 1) return;
    setState(() {
      s.items.removeAt(itemIndex);
      _dirty = true;
    });
  }

  // ---------------- save ----------------

  bool _validate() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template name is required')));
      return false;
    }

    for (final s in _sections) {
      if (s.typeNameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Section name cannot be empty')));
        return false;
      }
      if (s.items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Each section needs at least 1 item')));
        return false;
      }
      for (final it in s.items) {
        if (it.labelCtrl.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item name cannot be empty')));
          return false;
        }
      }
    }
    return true;
  }

  Map<String, dynamic> _buildBody() {
    final types = <Map<String, dynamic>>[];

    for (final s in _sections) {
      final items = <Map<String, dynamic>>[];

      for (int i = 0; i < s.items.length; i++) {
        final it = s.items[i];
        items.add({
          'position': i + 1,
          'label': it.labelCtrl.text.trim(),
          'description': it.descCtrl.text.trim(),
          'isRequired': it.isRequired,
        });
      }

      final mv = int.tryParse(s.maxVideosCtrl.text.trim()) ?? s.maxVideos;

      types.add({
        'typeName': s.typeNameCtrl.text.trim(),
        'checklistItems': items,
        'allowOverallRemarks': s.allowOverallRemarks,
        'allowOverallPhotos': s.allowOverallPhotos,
        'allowVideos': s.allowVideos,
        'maxVideos': mv,
      });
    }

    return {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'types': types,
    };
  }

  Future<void> _save() async {
    if (!_dirty) return;
    if (!_validate()) return;

    setState(() => _saving = true);
    try {
      final body = _buildBody();

      if (widget.isEdit) {
        await checklistTemplatesService.updateTemplate(
          id: widget.templateId!,
          body: {
            'name': body['name'],
            'description': body['description'],
            'types': body['types'],
          },
        );
      } else {
        await checklistTemplatesService.createTemplate(
          name: body['name'],
          description: body['description'],
          types: List<Map<String, dynamic>>.from(body['types']),
        );
      }

      if (!mounted) return;
      setState(() => _dirty = false);
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    for (final s in _sections) {
      s.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saveEnabled = !_loading && !_saving && _dirty;

    return AppShell(
      title: widget.isEdit ? 'Edit Checklist Template' : 'New Checklist Template',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // ---- TOP AREA (always visible) ----
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.isEdit ? 'Edit Template' : 'Create Template',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
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

                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              TextField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(labelText: 'Template name'),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _descCtrl,
                                maxLines: 2,
                                decoration: const InputDecoration(labelText: 'Description (optional)'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                      child: Row(
                        children: [
                          Text('Checklist', style: Theme.of(context).textTheme.titleLarge),
                          const Spacer(),
                          FilledButton.tonalIcon(
                            onPressed: _addSection,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Section'),
                          ),
                        ],
                      ),
                    ),

                    // ---- ONLY THIS AREA SCROLLS ----
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        child: Card(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: ReorderableListView.builder(
                              buildDefaultDragHandles: false,
                              key: const PageStorageKey('sections_reorderable'),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _sections.length,
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (newIndex > oldIndex) newIndex -= 1;
                                  final moved = _sections.removeAt(oldIndex);
                                  _sections.insert(newIndex, moved);
                                  _dirty = true;
                                });
                              },
                              itemBuilder: (context, sIndex) {
                                final s = _sections[sIndex];

                                return Container(
                                  key: ValueKey(s.uid),
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _SectionRow(
                                        index: sIndex,
                                        section: s,
                                        canDelete: _sections.length > 1,
                                        onDelete: () => _deleteSection(sIndex),
                                        onAddItem: () => _addItem(sIndex),
                                        onToggleDetails: () => setState(() => s.expanded = !s.expanded),
                                        onChanged: _markDirty,
                                        showDelete: true,
                                      ),

                                      if (s.expanded)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 34, top: 8, bottom: 8),
                                          child: Wrap(
                                            spacing: 12,
                                            runSpacing: 10,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              FilterChip(
                                                label: const Text('Overall remarks'),
                                                selected: s.allowOverallRemarks,
                                                onSelected: (v) => setState(() {
                                                  s.allowOverallRemarks = v;
                                                  _dirty = true;
                                                }),
                                              ),
                                              FilterChip(
                                                label: const Text('Overall photos'),
                                                selected: s.allowOverallPhotos,
                                                onSelected: (v) => setState(() {
                                                  s.allowOverallPhotos = v;
                                                  _dirty = true;
                                                }),
                                              ),
                                              FilterChip(
                                                label: const Text('Videos'),
                                                selected: s.allowVideos,
                                                onSelected: (v) => setState(() {
                                                  s.allowVideos = v;
                                                  _dirty = true;
                                                }),
                                              ),
                                              SizedBox(
                                                width: 160,
                                                child: TextField(
                                                  controller: s.maxVideosCtrl,
                                                  enabled: s.allowVideos,
                                                  keyboardType: TextInputType.number,
                                                  decoration: const InputDecoration(
                                                    labelText: 'Max videos',
                                                    isDense: true,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      Padding(
                                        padding: const EdgeInsets.only(left: 34),
                                        child: ReorderableListView.builder(
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
                                          itemBuilder: (context, iIndex) {
                                            final it = s.items[iIndex];
                                            return _ItemRow(
                                              key: ValueKey(it.uid),
                                              index: iIndex,
                                              item: it,
                                              canDelete: s.items.length > 1,
                                              onDelete: () => _deleteItem(sIndex, iIndex),
                                              onToggleDetails: () => setState(() => it.expanded = !it.expanded),
                                              onChanged: _markDirty,
                                              showDelete: true,
                                            );
                                          },
                                        ),
                                      ),

                                      const Divider(height: 18),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ---------------- UI rows ----------------

class _MiniIconButton extends StatelessWidget {
  final String? tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final double iconSize;

  const _MiniIconButton({
    super.key,
    this.tooltip,
    required this.onPressed,
    required this.icon,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 38, height: 38),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final int index;
  final _SectionNode section;
  final bool canDelete;
  final bool showDelete;
  final VoidCallback onDelete;
  final VoidCallback onAddItem;
  final VoidCallback onToggleDetails;
  final VoidCallback onChanged;

  const _SectionRow({
    required this.index,
    required this.section,
    required this.canDelete,
    required this.onDelete,
    required this.onAddItem,
    required this.onToggleDetails,
    required this.onChanged,
    required this.showDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ReorderableDragStartListener(
          index: index,
          child: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.drag_indicator, color: Colors.black45, size: 20),
          ),
        ),
        SizedBox(
          width: 26,
          child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        Expanded(
          child: TextField(
            controller: section.typeNameCtrl,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'Section name',
            ),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
            onChanged: (_) => onChanged(),
          ),
        ),

        _MiniIconButton(
          tooltip: section.expanded ? 'Hide section settings' : 'Show section settings',
          onPressed: onToggleDetails,
          icon: section.expanded ? Icons.expand_less : Icons.expand_more,
        ),

        _MiniIconButton(
          tooltip: 'Add item',
          onPressed: onAddItem,
          icon: Icons.add,
        ),

        if (canDelete && showDelete)
          _MiniIconButton(
            tooltip: 'Delete section',
            onPressed: onDelete,
            icon: Icons.delete_outline,
          ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final int index;
  final _ItemNode item;
  final bool canDelete;
  final bool showDelete;
  final VoidCallback onDelete;
  final VoidCallback onToggleDetails;
  final VoidCallback onChanged;

  const _ItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.canDelete,
    required this.onDelete,
    required this.onToggleDetails,
    required this.onChanged,
    required this.showDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.drag_indicator, color: Colors.black38, size: 18),
              ),
            ),
            SizedBox(
              width: 26,
              child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            Expanded(
              child: TextField(
                controller: item.labelCtrl,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Item name',
                ),
                onChanged: (_) => onChanged(),
              ),
            ),

            _MiniIconButton(
              tooltip: item.expanded ? 'Hide details' : 'Show details',
              onPressed: onToggleDetails,
              icon: item.expanded ? Icons.expand_less : Icons.expand_more,
              iconSize: 20,
            ),

            if (canDelete && showDelete)
              _MiniIconButton(
                tooltip: 'Delete item',
                onPressed: onDelete,
                icon: Icons.delete_outline,
                iconSize: 20,
              ),
          ],
        ),
        if (item.expanded)
          Padding(
            padding: const EdgeInsets.only(left: 54, right: 8, bottom: 8),
            child: Column(
              children: [
                TextField(
                  controller: item.descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    isDense: true,
                  ),
                  onChanged: (_) => onChanged(),
                ),
                Row(
                  children: [
                    Switch(
                      value: item.isRequired,
                      onChanged: (v) {
                        item.isRequired = v;
                        onChanged();
                      },
                    ),
                    const Text('Required'),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------- nodes ----------------

class _SectionNode {
  final String uid = UniqueKey().toString();

  bool expanded = false;

  bool allowOverallRemarks;
  bool allowOverallPhotos;
  bool allowVideos;
  int maxVideos;

  final TextEditingController typeNameCtrl;
  final TextEditingController maxVideosCtrl;

  final List<_ItemNode> items = [];

  _SectionNode({
    required String typeName,
    this.allowOverallRemarks = true,
    this.allowOverallPhotos = true,
    this.allowVideos = false,
    this.maxVideos = 2,
  })  : typeNameCtrl = TextEditingController(text: typeName),
        maxVideosCtrl = TextEditingController(text: maxVideos.toString());

  void dispose() {
    typeNameCtrl.dispose();
    maxVideosCtrl.dispose();
    for (final it in items) {
      it.dispose();
    }
  }
}

class _ItemNode {
  final String uid = UniqueKey().toString();

  bool expanded = false;

  bool isRequired;
  final TextEditingController labelCtrl;
  final TextEditingController descCtrl;

  _ItemNode({
    required String label,
    String description = '',
    this.isRequired = true,
  })  : labelCtrl = TextEditingController(text: label),
        descCtrl = TextEditingController(text: description);

  void dispose() {
    labelCtrl.dispose();
    descCtrl.dispose();
  }
}
