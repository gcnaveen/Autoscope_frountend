import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/dropdown_config_service.dart';
import '../../../../services/service_locator.dart';
import '../../../shared/app_shell.dart';

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
  List<CustomField> _customFields = [];
  bool _loading = true;
  bool _saving = false;
  final Map<String, TextEditingController> _addCtrls = {};

  static const _fields = [
    ('gradeVariant', 'Grade / Variant'),
    ('cylinderSize', 'Cylinder Size'),
    ('transmission', 'Transmission'),
    ('fuelType', 'Fuel Type'),
    ('driveTrain', 'Drive Train'),
    ('specs', 'Specs'),
    ('seats', 'Seats'),
    ('interiorColor', 'Interior Color'),
    ('exteriorColor', 'Exterior Color'),
    ('upholstery', 'Upholstery'),
    ('numberOfKeys', 'Number of Keys'),
    ('doors', 'Doors'),
    ('wheelSize', 'Wheel Size'),
    ('wheelType', 'Wheel Type'),
    ('servicedWith', 'Serviced With'),
  ];

  @override
  void initState() {
    super.initState();
    for (final (key, _) in _fields) {
      _addCtrls[key] = TextEditingController();
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in _addCtrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final config = await dropdownConfigService.load();
    final custom = await dropdownConfigService.loadCustomFields();
    if (!mounted) return;
    setState(() {
      _config = {for (final e in config.entries) e.key: List<String>.from(e.value)};
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved'), duration: Duration(seconds: 1)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addOption(String key) {
    final ctrl = _addCtrls[key]!;
    final text = ctrl.text.trim().toUpperCase();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Option cannot be empty')),
      );
      return;
    }
    if (_config![key]!.contains(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$text" already exists')),
      );
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
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset to Default'),
        content: Text(
          'Replace all options for "${DropdownConfigService.fieldLabels[key]}" with built-in defaults?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true || !mounted) return;
      setState(() {
        _config![key] = List<String>.from(DropdownConfigService.defaults[key]!);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved'), duration: Duration(seconds: 1)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addCustomField() {
    showDialog<CustomField>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _FieldFormDialog(existing: null),
    ).then((field) {
      if (field == null || !mounted) return;
      setState(() => _customFields = [..._customFields, field]);
      _saveCustomFields();
    });
  }

  void _editCustomField(CustomField field) {
    showDialog<CustomField>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _FieldFormDialog(existing: field),
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
    return AppShell(
      title: 'Configure Inputs',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
                  children: [
                    _InfoCard(saving: _saving),
                    const SizedBox(height: 16),

                    // ── Built-in dropdown fields ───────────────────────────
                    for (final (key, label) in _fields) ...[
                      _DropdownFieldCard(
                        label: label,
                        options: _config![key] ?? [],
                        addCtrl: _addCtrls[key]!,
                        onAdd: () => _addOption(key),
                        onRemove: (i) => _removeOption(key, i),
                        onReset: () => _resetToDefault(key),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Custom fields ──────────────────────────────────────
                    const SizedBox(height: 8),
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
                    else
                      for (final f in _customFields) ...[
                        _CustomFieldCard(
                          field: f,
                          onEdit: () => _editCustomField(f),
                          onDelete: () => _deleteCustomField(f.id),
                        ),
                        const SizedBox(height: 10),
                      ],
                  ],
                ),
        ),
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
  final TextEditingController addCtrl;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final VoidCallback onReset;

  const _DropdownFieldCard({
    required this.label,
    required this.options,
    required this.addCtrl,
    required this.onAdd,
    required this.onRemove,
    required this.onReset,
  });

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                ),
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restore, size: 16),
                  label: const Text('Reset', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (options.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('No options. Add one below.', style: TextStyle(color: Colors.black38)),
              )
            else
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  for (int i = 0; i < options.length; i++)
                    Chip(
                      label: Text(options[i],
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      deleteIcon: const Icon(Icons.close, size: 15),
                      onDeleted: () => onRemove(i),
                      backgroundColor: const Color(0xFF1E5EFF).withValues(alpha: 0.07),
                      side: BorderSide(color: const Color(0xFF1E5EFF).withValues(alpha: 0.18)),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                ],
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: addCtrl,
                    inputFormatters: [
                      _UpperCaseFormatter(),
                      LengthLimitingTextInputFormatter(60),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'New option…',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => onAdd(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
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
    return Card(
      elevation: 0,
      color: Colors.black.withValues(alpha: 0.02),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1E5EFF).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                field.type == 'dropdown' ? Icons.arrow_drop_down_circle_outlined : Icons.text_fields_outlined,
                color: const Color(0xFF1E5EFF), size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(field.label,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      const SizedBox(width: 8),
                      if (field.required)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Required',
                              style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${field.type == 'dropdown' ? 'Dropdown' : 'Text'} · $sectionLabel',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  if (field.type == 'dropdown' && field.options.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6, runSpacing: 4,
                      children: field.options
                          .map((o) => Chip(
                                label: Text(o,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor:
                                    const Color(0xFF1E5EFF).withValues(alpha: 0.06),
                                side: BorderSide(
                                    color: const Color(0xFF1E5EFF).withValues(alpha: 0.15)),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add / Edit field dialog ───────────────────────────────────────────────

class _FieldFormDialog extends StatefulWidget {
  final CustomField? existing;
  const _FieldFormDialog({required this.existing});

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
    _section = f?.section ?? 'vehicle_details';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Option cannot be empty')),
      );
      return;
    }
    if (_options.contains(t)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$t" already exists')),
      );
      return;
    }
    setState(() => _options.add(t));
    _optionCtrl.clear();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_type == 'dropdown' && _options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one option for a dropdown field')),
      );
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
                    value: _type,
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
                    value: _section,
                    decoration: const InputDecoration(
                      labelText: 'Form Section',
                      border: OutlineInputBorder(),
                    ),
                    items: sectionLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _section = v ?? 'vehicle_details'),
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
