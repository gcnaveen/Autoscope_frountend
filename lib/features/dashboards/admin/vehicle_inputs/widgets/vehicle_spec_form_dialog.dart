import 'package:flutter/material.dart';

import '../../../../../services/service_locator.dart';
import '../../../../shared/top_snackbar.dart';

/// Add/Edit dialog for a single vehicle-specs catalog row.
/// Follows the Form + GlobalKey<FormState> pattern used by
/// add_inspector_dialog.dart (multi-field admin entry form), rather than the
/// single-TextField _askNameDialog pattern used by vehicle_catalog_page.dart,
/// since this form has ~9 fields.
class VehicleSpecFormDialog extends StatefulWidget {
  /// null => Add mode. Non-null => Edit mode (must include 'id').
  final Map<String, dynamic>? initial;

  const VehicleSpecFormDialog({super.key, this.initial});

  @override
  State<VehicleSpecFormDialog> createState() => _VehicleSpecFormDialogState();
}

class _VehicleSpecFormDialogState extends State<VehicleSpecFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController makeCtrl;
  late final TextEditingController modelCtrl;
  late final TextEditingController variantCtrl;
  late final TextEditingController subVariantCtrl;
  late final TextEditingController engineDisplayCtrl;
  late final TextEditingController engineCcCtrl;
  late final TextEditingController cylindersCtrl;
  late final TextEditingController fuelTypeCtrl;
  late final TextEditingController bodyTypeCtrl;
  late final TextEditingController specsCtrl;

  static const List<String> _driveTypeOptions = ['FWD', 'RWD', 'AWD', '4WD'];
  late Set<String> _driveTypes;

  bool saving = false;

  bool get isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final j = widget.initial ?? const {};

    makeCtrl = TextEditingController(text: (j['make'] ?? '').toString());
    modelCtrl = TextEditingController(text: (j['model'] ?? '').toString());
    variantCtrl = TextEditingController(text: (j['variant'] ?? '').toString());
    subVariantCtrl = TextEditingController(text: (j['subVariant'] ?? '').toString());
    engineDisplayCtrl = TextEditingController(text: (j['engineDisplay'] ?? '').toString());
    engineCcCtrl = TextEditingController(
      text: j['engineCc'] == null ? '' : j['engineCc'].toString(),
    );
    cylindersCtrl = TextEditingController(
      text: j['cylinders'] == null ? '' : j['cylinders'].toString(),
    );
    fuelTypeCtrl = TextEditingController(text: (j['fuelType'] ?? '').toString());
    bodyTypeCtrl = TextEditingController(text: (j['bodyType'] ?? '').toString());
    specsCtrl = TextEditingController(text: (j['specs'] ?? '').toString());

    final rawDrive = j['driveTypes'];
    _driveTypes = <String>{
      if (rawDrive is List) ...rawDrive.map((e) => e.toString().trim().toUpperCase()),
    }..removeWhere((e) => e.isEmpty);
  }

  @override
  void dispose() {
    makeCtrl.dispose();
    modelCtrl.dispose();
    variantCtrl.dispose();
    subVariantCtrl.dispose();
    engineDisplayCtrl.dispose();
    engineCcCtrl.dispose();
    cylindersCtrl.dispose();
    fuelTypeCtrl.dispose();
    bodyTypeCtrl.dispose();
    specsCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: const OutlineInputBorder(),
      isDense: true,
    );
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'make': makeCtrl.text.trim(),
      'model': modelCtrl.text.trim(),
      'variant': variantCtrl.text.trim(),
      'subVariant': subVariantCtrl.text.trim(),
      'engineDisplay': engineDisplayCtrl.text.trim(),
      'engineCc': int.tryParse(engineCcCtrl.text.trim()),
      'cylinders': int.tryParse(cylindersCtrl.text.trim()),
      'fuelType': fuelTypeCtrl.text.trim(),
      'driveTypes': _driveTypes.toList(),
      'bodyType': bodyTypeCtrl.text.trim(),
      'specs': specsCtrl.text.trim(),
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);
    try {
      final payload = _buildPayload();
      if (isEdit) {
        final id = (widget.initial!['id'] ?? '').toString();
        await vehicleSpecsService.updateVehicleSpec(id, payload);
      } else {
        await vehicleSpecsService.createVehicleSpec(payload);
      }

      if (!mounted) return;
      showTopSnack(context, isEdit ? 'Vehicle spec updated' : 'Vehicle spec added', variant: 'success');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showTopSnack(context, 'Save failed: $e', variant: 'error');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1220),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.settings_suggest_outlined, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? 'Edit Vehicle Spec' : 'Add Vehicle Spec',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Used to auto-fill vehicle details during inspection',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: saving ? null : () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, c) {
                      final twoCol = c.maxWidth >= 560;

                      Widget row(Widget a, Widget b) {
                        return twoCol
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: a),
                                  const SizedBox(width: 12),
                                  Expanded(child: b),
                                ],
                              )
                            : Column(children: [a, const SizedBox(height: 12), b]);
                      }

                      return Column(
                        children: [
                          row(
                            TextFormField(
                              controller: makeCtrl,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: _dec('Make', hint: 'Toyota', icon: Icons.directions_car_outlined),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            TextFormField(
                              controller: modelCtrl,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: _dec('Model', hint: 'Corolla'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          row(
                            TextFormField(
                              controller: variantCtrl,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              decoration: _dec('Variant', hint: 'GLI'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            TextFormField(
                              controller: subVariantCtrl,
                              decoration: _dec('Sub Variant', hint: 'Optional'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          row(
                            TextFormField(
                              controller: engineDisplayCtrl,
                              decoration: _dec('Engine Display', hint: '1.8L Hybrid'),
                            ),
                            TextFormField(
                              controller: fuelTypeCtrl,
                              decoration: _dec('Fuel Type', hint: 'Petrol/Hybrid'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          row(
                            TextFormField(
                              controller: engineCcCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _dec('Engine CC', hint: '1800'),
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) return null;
                                return int.tryParse(s) == null ? 'Numbers only' : null;
                              },
                            ),
                            TextFormField(
                              controller: cylindersCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _dec('Cylinders', hint: '4'),
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) return null;
                                return int.tryParse(s) == null ? 'Numbers only' : null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          row(
                            TextFormField(
                              controller: bodyTypeCtrl,
                              decoration: _dec('Body Type', hint: 'Sedan'),
                            ),
                            TextFormField(
                              controller: specsCtrl,
                              decoration: _dec('Specs', hint: 'JAPANESE'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Drive Types',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _driveTypeOptions.map((opt) {
                      final selected = _driveTypes.contains(opt);
                      return FilterChip(
                        label: Text(opt),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _driveTypes.add(opt);
                          } else {
                            _driveTypes.remove(opt);
                          }
                        }),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: saving ? null : () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: saving ? null : _submit,
                          child: saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(isEdit ? 'Save changes' : 'Add'),
                        ),
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
