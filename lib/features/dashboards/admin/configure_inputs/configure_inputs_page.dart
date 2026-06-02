import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/dropdown_config_service.dart';
import '../../../../services/service_locator.dart';
import '../../../shared/app_shell.dart';
import '../../../shared/top_snackbar.dart';

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final upper = next.text.toUpperCase();
    final base   = next.selection.baseOffset.clamp(0, upper.length);
    final extent = next.selection.extentOffset.clamp(0, upper.length);
    return next.copyWith(
      text: upper,
      selection: TextSelection(baseOffset: base, extentOffset: extent),
      composing: TextRange.empty,
    );
  }
}

class ConfigureInputsPage extends StatefulWidget {
  const ConfigureInputsPage({super.key});

  @override
  State<ConfigureInputsPage> createState() => _ConfigureInputsPageState();
}

class _ConfigureInputsPageState extends State<ConfigureInputsPage> {
  Map<String, List<String>>? _config;
  Map<String, String> _statusMap = {};
  List<CustomField> _customFields = [];
  bool _loading = true;
  bool _saving = false;
  final Map<String, TextEditingController> _addCtrls = {};

  // ── Search + filter state ───────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all' | 'active' | 'inactive'

  // Populated from the service after load(); empty until then.
  List<(String, String)> _fields = const [];

  List<(String, String)> get _filteredBuiltIn => _fields.where((field) {
    final key   = field.$1;
    final label = field.$2;
    final matchesSearch  = _searchQuery.isEmpty ||
        label.toLowerCase().contains(_searchQuery.toLowerCase());
    final matchesStatus  = _statusFilter == 'all' ||
        (_statusMap[key] ?? 'active') == _statusFilter;
    return matchesSearch && matchesStatus;
  }).toList();

  List<CustomField> get _filteredCustom => _searchQuery.isEmpty
      ? _customFields
      : _customFields
          .where((f) => f.label.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final c in _addCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    dropdownConfigService.clearCache();
    final config = await dropdownConfigService.load();
    final custom = await dropdownConfigService.loadCustomFields();
    if (!mounted) return;

    final fieldDefs = dropdownConfigService.fieldDefinitions;
    final newFields = fieldDefs.map((d) => (d.key, d.label)).toList();

    // Sync text controllers: create for new keys, dispose removed keys
    final newKeys = newFields.map((f) => f.$1).toSet();
    final oldKeys = Set<String>.from(_addCtrls.keys);
    for (final k in oldKeys.difference(newKeys)) {
      _addCtrls.remove(k)?.dispose();
    }
    for (final k in newKeys.difference(oldKeys)) {
      _addCtrls[k] = TextEditingController();
    }

    setState(() {
      _fields = newFields;
      _config = {for (final e in config.entries) e.key: List<String>.from(e.value)};
      _statusMap = Map<String, String>.from(dropdownConfigService.statusMap);
      _customFields = custom;
      _loading = false;
    });
  }

  // ── Dropdown option helpers ─────────────────────────────────────────────────

  Future<void> _saveDropdowns() async {
    if (_config == null) return;
    setState(() => _saving = true);
    try {
      await dropdownConfigService.save(_config!);
      dropdownConfigService.clearCache();
      if (mounted) showTopSnack(context, 'Saved', variant: 'success');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setStatus(String key, String status) async {
    setState(() => _statusMap[key] = status);
    setState(() => _saving = true);
    try {
      await dropdownConfigService.setStatus(key, status);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addOption(String key) {
    final ctrl = _addCtrls[key]!;
    final text = ctrl.text.trim().toUpperCase();
    if (text.isEmpty) {
      showTopSnack(context, 'Option cannot be empty', variant: 'warning');
      return;
    }
    if (_config![key]!.contains(text)) {
      showTopSnack(context, '"$text" already exists', variant: 'warning');
      return;
    }
    setState(() {
      _config![key] = [..._config![key]!, text];
      ctrl.clear();
    });
    _saveDropdowns();
  }

  void _removeOption(String key, int index) {
    setState(() {
      final list = List<String>.from(_config![key]!);
      list.removeAt(index);
      _config![key] = list;
    });
    _saveDropdowns();
  }

  void _resetToDefault(String key) {
    final fieldDef = dropdownConfigService.fieldDefinitions.firstWhere(
      (d) => d.key == key,
      orElse: () => FieldDefinition(
        key: key,
        label: DropdownConfigService.fieldLabels[key] ?? key,
        defaultOptions: List<String>.from(DropdownConfigService.defaults[key] ?? []),
      ),
    );
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset to Default'),
        content: Text(
          'Replace all options for "${fieldDef.label}" with built-in defaults?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true || !mounted) return;
      final resetTo = fieldDef.defaultOptions.isNotEmpty
          ? fieldDef.defaultOptions
          : (DropdownConfigService.defaults[key] ?? []);
      setState(() {
        _config![key] = List<String>.from(resetTo);
      });
      _saveDropdowns();
    });
  }

  // ── Custom field helpers ────────────────────────────────────────────────────

  Future<void> _saveCustomFields() async {
    setState(() => _saving = true);
    try {
      await dropdownConfigService.saveCustomFields(_customFields);
      dropdownConfigService.clearCustomFieldsCache();
      if (mounted) showTopSnack(context, 'Saved', variant: 'success');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addCustomField() {
    showDialog<CustomField>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _FieldFormDialog(
        existing: null,
        sectionLabels: dropdownConfigService.currentSectionLabels,
      ),
    ).then((field) {
      if (field == null || !mounted) return;
      setState(() => _customFields = [field, ..._customFields]);
      _saveCustomFields();
    });
  }

  void _editCustomField(CustomField field) {
    showDialog<CustomField>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _FieldFormDialog(
        existing: field,
        sectionLabels: dropdownConfigService.currentSectionLabels,
      ),
    ).then((updated) {
      if (updated == null || !mounted) return;
      setState(() {
        _customFields = _customFields.map((f) => f.id == updated.id ? updated : f).toList();
      });
      _saveCustomFields();
    });
  }

  void _deleteCustomField(String id) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Field'),
        content: const Text('Remove this custom field? Existing inspection data will not be affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true || !mounted) return;
      setState(() => _customFields = _customFields.where((f) => f.id != id).toList());
      _saveCustomFields();
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 720;

    return AppShell(
      title: 'Configure Inputs',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
              children: [
                _InfoCard(saving: _saving),
                const SizedBox(height: 12),

                _SearchBar(
                  controller: _searchCtrl,
                  query: _searchQuery,
                  statusFilter: _statusFilter,
                  totalCount: _fields.length + _customFields.length,
                  filteredCount: _filteredBuiltIn.length + _filteredCustom.length,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  onClear: () => setState(() {
                    _searchCtrl.clear();
                    _searchQuery = '';
                  }),
                  onStatusFilter: (s) => setState(() => _statusFilter = s),
                ),
                const SizedBox(height: 20),

                // ── Custom fields ──────────────────────────────────────────
                _SectionHeader(
                  title: 'Custom Fields',
                  subtitle: 'Add new fields that appear in the inspection form.',
                  trailing: FilledButton.icon(
                    onPressed: _addCustomField,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New Field'),
                  ),
                ),
                const SizedBox(height: 12),

                if (_customFields.isEmpty)
                  Card(
                    elevation: 0,
                    color: Colors.black.withValues(alpha: 0.02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No custom fields yet. Tap "Add New Field" to create one.',
                          style: TextStyle(color: Colors.black45),
                        ),
                      ),
                    ),
                  )
                else if (_filteredCustom.isEmpty)
                  _EmptySearch(message: 'No custom fields match "$_searchQuery".')
                else
                  for (final f in _filteredCustom) ...[
                    _CustomFieldCard(
                      field: f,
                      onEdit: () => _editCustomField(f),
                      onDelete: () => _deleteCustomField(f.id),
                    ),
                    const SizedBox(height: 10),
                  ],

                // ── Built-in dropdown fields ───────────────────────────────
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Dropdown Fields',
                  subtitle: 'Configure options for each dropdown shown in the inspection form.',
                  trailing: const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),

                if (_filteredBuiltIn.isEmpty && (_searchQuery.isNotEmpty || _statusFilter != 'all'))
                  _EmptySearch(message: 'No dropdown fields match your search or filter.')
                else
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      final cols = isMobile ? 1 : constraints.maxWidth > 1100 ? 3 : 2;
                      const gap = 12.0;
                      final itemWidth =
                          (constraints.maxWidth - (cols - 1) * gap) / cols;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final (key, label) in _filteredBuiltIn)
                            SizedBox(
                              width: itemWidth,
                              height: 230,
                              child: _DropdownFieldCard(
                                label: label,
                                options: _config![key] ?? [],
                                status: _statusMap[key] ?? 'active',
                                addCtrl: _addCtrls[key]!,
                                onAdd: () => _addOption(key),
                                onRemove: (i) => _removeOption(key, i),
                                onReset: () => _resetToDefault(key),
                                onStatusChanged: (active) =>
                                    _setStatus(key, active ? 'active' : 'inactive'),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ),
    );
  }
}

// ─── Section header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  const _SectionHeader({required this.title, required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        trailing,
      ],
    );
  }
}

// ─── Info header card ──────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final bool saving;
  const _InfoCard({required this.saving});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 44, width: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1E5EFF).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune_outlined, color: Color(0xFF1E5EFF)),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Configure Inputs', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  SizedBox(height: 4),
                  Text(
                    'Manage dropdown options and add custom fields to the inspection form.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            if (saving) ...[
              const SizedBox(width: 12),
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Dropdown field card ───────────────────────────────────────────────────

class _DropdownFieldCard extends StatelessWidget {
  final String label;
  final List<String> options;
  final String status;
  final TextEditingController addCtrl;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final VoidCallback onReset;
  final void Function(bool active) onStatusChanged;

  const _DropdownFieldCard({
    required this.label,
    required this.options,
    required this.status,
    required this.addCtrl,
    required this.onAdd,
    required this.onRemove,
    required this.onReset,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.025),
              border: Border(
                bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? Colors.green.shade500 : Colors.black26,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
                Tooltip(
                  message: isActive ? 'Visible in form' : 'Hidden from form',
                  child: Transform.scale(
                    scale: 0.78,
                    alignment: Alignment.centerRight,
                    child: Switch(
                      value: isActive,
                      onChanged: onStatusChanged,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Reset to defaults',
                  child: IconButton(
                    onPressed: onReset,
                    icon: Icon(Icons.restore, size: 16, color: Colors.orange.shade600),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),

          // ── Options (scrollable, fills available space) ────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: options.isEmpty
                  ? const Text(
                      'No options yet.',
                      style: TextStyle(color: Colors.black38, fontSize: 12),
                    )
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (int i = 0; i < options.length; i++)
                          _OptionChip(
                            label: options[i],
                            onDelete: () => onRemove(i),
                          ),
                      ],
                    ),
            ),
          ),

          // ── Add input ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: addCtrl,
                    style: const TextStyle(fontSize: 13),
                    inputFormatters: [
                      _UpperCaseFormatter(),
                      LengthLimitingTextInputFormatter(60),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Add option…',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    ),
                    onSubmitted: (_) => onAdd(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 38,
                  child: FilledButton(
                    onPressed: onAdd,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.add, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Option chip ───────────────────────────────────────────────────────────

class _OptionChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;

  const _OptionChip({required this.label, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 4, 6, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5EFF).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1E5EFF).withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.close,
              size: 13,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom field display card ─────────────────────────────────────────────

class _CustomFieldCard extends StatelessWidget {
  final CustomField field;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomFieldCard({required this.field, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final sectionLabel = sectionLabels[field.section] ?? field.section;
    final isDropdown = field.type == 'dropdown';

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.025),
              border: Border(
                bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E5EFF).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    isDropdown ? Icons.arrow_drop_down_circle_outlined : Icons.text_fields_outlined,
                    color: const Color(0xFF1E5EFF), size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    field.label,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
                if (field.required)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Required',
                        style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w700)),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isDropdown ? 'Dropdown' : 'Text input'} · $sectionLabel',
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
                if (isDropdown && field.options.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: field.options
                        .map((o) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E5EFF).withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: const Color(0xFF1E5EFF).withValues(alpha: 0.20)),
                              ),
                              child: Text(o,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A1A))),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add / Edit field dialog ───────────────────────────────────────────────

class _FieldFormDialog extends StatefulWidget {
  final CustomField? existing;
  final Map<String, String> sectionLabels;
  const _FieldFormDialog({required this.existing, required this.sectionLabels});

  @override
  State<_FieldFormDialog> createState() => _FieldFormDialogState();
}

class _FieldFormDialogState extends State<_FieldFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late String _type;
  late String _section;
  late bool _required;
  late List<String> _options;
  final _optionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final f = widget.existing;
    _labelCtrl = TextEditingController(text: f?.label ?? '');
    _type = f?.type ?? 'text';
    _section = f?.section ?? widget.sectionLabels.keys.firstOrNull ?? 'vehicle_details';
    _required = f?.required ?? false;
    _options = List<String>.from(f?.options ?? []);
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _optionCtrl.dispose();
    super.dispose();
  }

  void _addOption() {
    final t = _optionCtrl.text.trim().toUpperCase();
    if (t.isEmpty) {
      showTopSnack(context, 'Option cannot be empty', variant: 'warning');
      return;
    }
    if (_options.contains(t)) {
      showTopSnack(context, '"$t" already exists', variant: 'warning');
      return;
    }
    setState(() => _options.add(t));
    _optionCtrl.clear();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_type == 'dropdown' && _options.isEmpty) {
      showTopSnack(context, 'Add at least one option for a dropdown field', variant: 'warning');
      return;
    }
    final id = widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    Navigator.pop(
      context,
      CustomField(
        id: id,
        label: _labelCtrl.text.trim(),
        type: _type,
        section: _section,
        options: _type == 'dropdown' ? _options : [],
        required: _required,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEdit ? 'Edit Field' : 'New Custom Field',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 20),

                  // Label
                  TextFormField(
                    controller: _labelCtrl,
                    inputFormatters: [LengthLimitingTextInputFormatter(60)],
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Field Label *',
                      hintText: 'e.g. Paint Type',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Label is required';
                      if (v.trim().length < 2) return 'Label must be at least 2 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Type
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Field Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'text', child: Text('Text Input')),
                      DropdownMenuItem(value: 'dropdown', child: Text('Dropdown')),
                    ],
                    onChanged: (v) => setState(() => _type = v ?? 'text'),
                  ),
                  const SizedBox(height: 16),

                  // Section
                  DropdownButtonFormField<String>(
                    initialValue: _section,
                    decoration: const InputDecoration(
                      labelText: 'Form Section',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.sectionLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() =>
                        _section = v ?? widget.sectionLabels.keys.firstOrNull ?? 'vehicle_details'),
                  ),
                  const SizedBox(height: 16),

                  // Required toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Required field',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Inspector must fill this before submitting'),
                    value: _required,
                    onChanged: (v) => setState(() => _required = v),
                  ),

                  // Dropdown options (only when type == dropdown)
                  if (_type == 'dropdown') ...[
                    const Divider(height: 24),
                    const Text('Options',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    const SizedBox(height: 10),
                    if (_options.isEmpty)
                      const Text('No options yet.', style: TextStyle(color: Colors.black38))
                    else
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          for (int i = 0; i < _options.length; i++)
                            Chip(
                              label: Text(_options[i],
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              deleteIcon: const Icon(Icons.close, size: 15),
                              onDeleted: () => setState(() => _options.removeAt(i)),
                              backgroundColor:
                                  const Color(0xFF1E5EFF).withValues(alpha: 0.07),
                              side: BorderSide(
                                  color: const Color(0xFF1E5EFF).withValues(alpha: 0.18)),
                            ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _optionCtrl,
                            inputFormatters: [
                              _UpperCaseFormatter(),
                              LengthLimitingTextInputFormatter(60),
                            ],
                            decoration: const InputDecoration(
                              hintText: 'Add option…',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onSubmitted: (_) => _addOption(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _addOption,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _submit,
                        child: Text(isEdit ? 'Save Changes' : 'Add Field'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Search + filter bar ───────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final String statusFilter;
  final int totalCount;
  final int filteredCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onStatusFilter;

  const _SearchBar({
    required this.controller,
    required this.query,
    required this.statusFilter,
    required this.totalCount,
    required this.filteredCount,
    required this.onChanged,
    required this.onClear,
    required this.onStatusFilter,
  });

  @override
  Widget build(BuildContext context) {
    final isFiltered = query.isNotEmpty || statusFilter != 'all';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Search fields…',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onClear,
                    tooltip: 'Clear search',
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final (value, label) in [
              ('all', 'All'),
              ('active', 'Active'),
              ('inactive', 'Inactive'),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(label),
                  selected: statusFilter == value,
                  onSelected: (_) => onStatusFilter(value),
                  showCheckmark: false,
                  selectedColor: const Color(0xFF1E5EFF).withValues(alpha: 0.12),
                  side: BorderSide(
                    color: statusFilter == value
                        ? const Color(0xFF1E5EFF)
                        : Colors.black.withValues(alpha: 0.15),
                  ),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: statusFilter == value
                        ? const Color(0xFF1E5EFF)
                        : Colors.black54,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            const Spacer(),
            if (isFiltered)
              Text(
                '$filteredCount of $totalCount fields',
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
          ],
        ),
      ],
    );
  }
}

// ─── Empty search state ────────────────────────────────────────────────────

class _EmptySearch extends StatelessWidget {
  final String message;
  const _EmptySearch({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.black.withValues(alpha: 0.02),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 36, color: Colors.black.withValues(alpha: 0.2)),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black45, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
