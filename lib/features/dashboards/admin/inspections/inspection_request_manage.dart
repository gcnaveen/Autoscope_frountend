// import 'package:flutter/material.dart';
// import '../../../../services/service_locator.dart';
// import '../../../shared/top_snackbar.dart';
// import '../../../../models/app_user.dart';

// class InspectionRequestManageDialog extends StatefulWidget {
//   final String requestMongoId;
//   final String requestDisplayId;
//   final bool alreadyAssigned;
//   final String? assignedInspectorId; // 👈 pass this

//   const InspectionRequestManageDialog({
//     super.key,
//     required this.requestMongoId,
//     required this.requestDisplayId,
//     required this.alreadyAssigned,
//     this.assignedInspectorId,
//   });

//   @override
//   State<InspectionRequestManageDialog> createState() =>
//       _InspectionRequestManageDialogState();
// }

// class _InspectionRequestManageDialogState
//     extends State<InspectionRequestManageDialog> {
//   AppUser? _selected;
//   AppUser? _currentInspector;

//   bool _saving = false;
//   late Future<List<AppUser>> _inspectorsFuture;

//   @override
//   void initState() {
//     super.initState();
//     _inspectorsFuture = _loadInspectors();
//   }

//   Future<List<AppUser>> _loadInspectors() async {
//     final all = await usersService.listUsers();
//     final inspectors = all
//         .where((u) =>
//             u.role == 'inspector' &&
//             u.status.toLowerCase() == 'active')
//         .toList();

//     // 🔹 find currently assigned inspector
//     if (widget.assignedInspectorId != null) {
//       try {
//         _currentInspector = inspectors.firstWhere(
//           (u) => u.id == widget.assignedInspectorId,
//         );
//       } catch (_) {
//         _currentInspector = null;
//       }
//     }

//     return inspectors;
//   }

//   Future<void> _submit() async {
//     if (_selected == null) return;

//     setState(() => _saving = true);
//     try {
//       await inspectionRequestsService.assignRequest(
//         requestId: widget.requestMongoId,
//         inspectorId: _selected!.id,
//       );

//       if (!mounted) return;
//       showTopSnack(
//         context,
//         widget.alreadyAssigned
//             ? 'Inspector reassigned successfully'
//             : 'Inspector assigned successfully',
//         variant: 'success',
//       );
//       Navigator.pop(context, true);
//     } catch (e) {
//       showTopSnack(context, 'Operation failed: $e', variant: 'error');
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   Widget _assignedInspectorCard() {
//     if (_currentInspector == null) {
//       return Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.orange.withOpacity(0.08),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: const Text(
//           'No inspector assigned yet.',
//           style: TextStyle(fontWeight: FontWeight.w600),
//         ),
//       );
//     }

//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.green.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             backgroundColor: Colors.green.withOpacity(0.15),
//             foregroundColor: Colors.green,
//             child: const Icon(Icons.badge_outlined),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   _currentInspector!.fullName,
//                   style: const TextStyle(fontWeight: FontWeight.w900),
//                 ),
//                 Text(
//                   _currentInspector!.email,
//                   style: const TextStyle(color: Colors.black54),
//                 ),
//               ],
//             ),
//           ),
//           Chip(
//             label: Text(_currentInspector!.status),
//             backgroundColor: Colors.green.withOpacity(0.12),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       insetPadding: const EdgeInsets.all(16),
//       child: ConstrainedBox(
//         constraints: const BoxConstraints(maxWidth: 540),
//         child: Padding(
//           padding: const EdgeInsets.all(18),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Header
//               Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       'Manage • ${widget.requestDisplayId}',
//                       style: Theme.of(context)
//                           .textTheme
//                           .titleLarge
//                           ?.copyWith(fontWeight: FontWeight.w900),
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () => Navigator.pop(context),
//                   )
//                 ],
//               ),

//               const SizedBox(height: 10),
//               const Divider(),

//               // 🔹 Assigned inspector info
//               Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   'Assigned Inspector',
//                   style: const TextStyle(fontWeight: FontWeight.w800),
//                 ),
//               ),
//               const SizedBox(height: 6),
//               _assignedInspectorCard(),

//               const SizedBox(height: 16),

//               Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   widget.alreadyAssigned
//                       ? 'Reassign Inspector'
//                       : 'Assign Inspector',
//                   style: const TextStyle(fontWeight: FontWeight.w800),
//                 ),
//               ),
//               const SizedBox(height: 8),

//               FutureBuilder<List<AppUser>>(
//                 future: _inspectorsFuture,
//                 builder: (context, snap) {
//                   if (snap.connectionState == ConnectionState.waiting) {
//                     return const LinearProgressIndicator();
//                   }

//                   if (snap.hasError) {
//                     return const Text('Failed to load inspectors');
//                   }

//                   final list = snap.data ?? [];
//                   if (list.isEmpty) {
//                     return const Text('No available inspectors');
//                   }

//                   return DropdownButtonFormField<AppUser>(
//                     value: _selected,
//                     items: list
//                         .where((u) =>
//                             _currentInspector == null ||
//                             u.id != _currentInspector!.id)
//                         .map(
//                           (u) => DropdownMenuItem(
//                             value: u,
//                             child: Text('${u.fullName} (${u.email})'),
//                           ),
//                         )
//                         .toList(),
//                     onChanged: (v) => setState(() => _selected = v),
//                     decoration: const InputDecoration(
//                       labelText: 'Select Inspector',
//                       border: OutlineInputBorder(),
//                     ),
//                   );
//                 },
//               ),

//               const SizedBox(height: 18),

//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: _saving
//                           ? null
//                           : () => Navigator.pop(context),
//                       child: const Text('Cancel'),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: FilledButton(
//                       onPressed: _saving || _selected == null
//                           ? null
//                           : _submit,
//                       child: Text(
//                         _saving
//                             ? 'Saving...'
//                             : widget.alreadyAssigned
//                                 ? 'Reassign'
//                                 : 'Assign',
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


// inspection_request_manage_dialog.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../services/service_locator.dart';
import '../../../shared/top_snackbar.dart';
import '../../../../models/app_user.dart';

class InspectionRequestManageDialog extends StatefulWidget {
  final String requestMongoId;
  final String requestDisplayId;
  final String status;
  final String? assignedInspectorId;

  final String? initialVehicleMake;
  final String? initialVehicleModel;

  const InspectionRequestManageDialog({
    super.key,
    required this.requestMongoId,
    required this.requestDisplayId,
    required this.status,
    this.assignedInspectorId,
    this.initialVehicleMake,
    this.initialVehicleModel,
  });

  @override
  State<InspectionRequestManageDialog> createState() => _InspectionRequestManageDialogState();
}

class _InspectionRequestManageDialogState extends State<InspectionRequestManageDialog> {
  AppUser? _selected;
  AppUser? _currentInspector;

  bool _saving = false;
  late Future<List<AppUser>> _inspectorsFuture;

  final _makeModelKey = GlobalKey<MakeModelPickerState>();

  bool get _alreadyAssigned {
    final s = widget.status.toLowerCase().trim();
    return widget.assignedInspectorId != null || s == 'assigned';
  }

  @override
  void initState() {
    super.initState();
    _inspectorsFuture = _loadInspectors();
  }

  Future<List<AppUser>> _loadInspectors() async {
    final all = await usersService.listUsers();
    final inspectors = all
        .where((u) => u.role == 'inspector' && u.status.toLowerCase() == 'active')
        .toList();

    if (widget.assignedInspectorId != null) {
      try {
        _currentInspector = inspectors.firstWhere((u) => u.id == widget.assignedInspectorId);
      } catch (_) {
        _currentInspector = null;
      }
    }

    return inspectors;
  }

  Future<void> _submit() async {
    if (_selected == null) return;

    setState(() => _saving = true);
    try {
      // ✅ If user selected OTHER make/model, create them here (handles 409 internally)
      try {
        await _makeModelKey.currentState?.resolveAndMaybeCreate();
      } catch (e) {
        showTopSnack(context, e.toString(), variant: 'error');
        setState(() => _saving = false);
        return;
      }

      // ✅ Assign / Reassign inspector (existing behavior)
      await inspectionRequestsService.assignRequest(
        requestId: widget.requestMongoId,
        inspectorId: _selected!.id,
      );

      if (!mounted) return;
      showTopSnack(
        context,
        _alreadyAssigned ? 'Inspector reassigned successfully' : 'Inspector assigned successfully',
        variant: 'success',
      );
      Navigator.pop(context, true);
    } catch (e) {
      showTopSnack(context, 'Operation failed: $e', variant: 'error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _assignedInspectorCard() {
    if (_currentInspector == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No inspector assigned yet.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.withOpacity(0.15),
            foregroundColor: Colors.green,
            child: const Icon(Icons.badge_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentInspector!.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  _currentInspector!.email,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Chip(
            label: Text(_currentInspector!.status),
            backgroundColor: Colors.green.withOpacity(0.12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Manage • ${widget.requestDisplayId}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 10),
              const Divider(),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Assigned inspector info
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Assigned Inspector',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _assignedInspectorCard(),

                      const SizedBox(height: 16),

                      // ✅ Vehicle Make/Model
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Vehicle Make & Model',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 8),
                      MakeModelPicker(
                        key: _makeModelKey,
                        enabled: !_saving,
                        initialMakeName: widget.initialVehicleMake,
                        initialModelName: widget.initialVehicleModel,
                      ),

                      const SizedBox(height: 18),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _alreadyAssigned ? 'Reassign Inspector' : 'Assign Inspector',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 8),

                      FutureBuilder<List<AppUser>>(
                        future: _inspectorsFuture,
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const LinearProgressIndicator();
                          }

                          if (snap.hasError) {
                            return const Text('Failed to load inspectors');
                          }

                          final list = snap.data ?? [];
                          if (list.isEmpty) {
                            return const Text('No available inspectors');
                          }

                          return DropdownButtonFormField<AppUser>(
                            value: _selected,
                            items: list
                                .where((u) => _currentInspector == null || u.id != _currentInspector!.id)
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u,
                                    child: Text('${u.fullName} (${u.email})'),
                                  ),
                                )
                                .toList(),
                            onChanged: _saving ? null : (v) => setState(() => _selected = v),
                            decoration: const InputDecoration(
                              labelText: 'Select Inspector',
                              border: OutlineInputBorder(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving || _selected == null ? null : _submit,
                      child: Text(
                        _saving
                            ? 'Saving...'
                            : _alreadyAssigned
                                ? 'Reassign'
                                : 'Assign',
                      ),
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
}

/* =========================================================
   MAKE + MODEL PICKER (API integrated) + OTHER + create
========================================================= */

const String _kOther = '__OTHER__';

class MakeModelPicker extends StatefulWidget {
  final String? initialMakeName;
  final String? initialModelName;
  final bool enabled;

  const MakeModelPicker({
    super.key,
    required this.initialMakeName,
    required this.initialModelName,
    required this.enabled,
  });

  @override
  State<MakeModelPicker> createState() => MakeModelPickerState();
}

class MakeModelPickerState extends State<MakeModelPicker> {
  bool _loadingMakes = true;
  bool _loadingModels = false;

  List<_MakeOpt> _makes = const [];
  List<_ModelOpt> _models = const [];

  String? _makeId;
  String? _modelId;

  final _otherMakeCtrl = TextEditingController();
  final _otherModelCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMakes();
  }

  @override
  void dispose() {
    _otherMakeCtrl.dispose();
    _otherModelCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMakes() async {
    setState(() => _loadingMakes = true);
    try {
      final res = await apiClient.getJson('/admin/makes').timeout(const Duration(seconds: 20));
      final list = (res is Map && res['data'] is List) ? List.from(res['data']) : <dynamic>[];

      final makes = list
          .whereType<Map>()
          .map((m) => _MakeOpt.fromJson(Map<String, dynamic>.from(m)))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      _makes = makes;

      final initMake = (widget.initialMakeName ?? '').trim().toUpperCase();
      if (initMake.isNotEmpty) {
        final match = _makes.where((x) => x.name == initMake).toList();
        if (match.isNotEmpty) {
          _makeId = match.first.id;
          await _loadModelsForMake(_makeId!);

          final initModel = (widget.initialModelName ?? '').trim().toUpperCase();
          if (initModel.isNotEmpty) {
            final mm = _models.where((x) => x.name == initModel).toList();
            if (mm.isNotEmpty) _modelId = mm.first.id;
          }
        }
      }
    } finally {
      if (mounted) setState(() => _loadingMakes = false);
    }
  }

  Future<void> _loadModelsForMake(String makeId) async {
    setState(() {
      _loadingModels = true;
      _models = const [];
      _modelId = null;
    });

    try {
      final res = await apiClient.getJson('/admin/makes/$makeId').timeout(const Duration(seconds: 20));

      final data = (res is Map && res['data'] is Map) ? Map<String, dynamic>.from(res['data']) : <String, dynamic>{};
      final modelsRaw = (data['models'] is List) ? List.from(data['models']) : <dynamic>[];

      final models = modelsRaw
          .whereType<Map>()
          .map((m) => _ModelOpt.fromJson(Map<String, dynamic>.from(m)))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      if (!mounted) return;
      setState(() => _models = models);
    } finally {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  /// Called by dialog submit:
  /// - if OTHER selected -> create make/model (handles 409)
  Future<void> resolveAndMaybeCreate() async {
    // If user didn't touch vehicle section, don't block assign
    if (_makeId == null && _modelId == null) return;

    if ((_makeId ?? '').isEmpty) throw 'Please select MAKE';
    if ((_modelId ?? '').isEmpty) throw 'Please select MODEL';

    String makeId = _makeId!;
    if (makeId == _kOther) {
      final name = _otherMakeCtrl.text.trim().toUpperCase();
      if (name.isEmpty) throw 'Enter OTHER MAKE';
      makeId = await _createOrGetMakeId(name);

      // after make created, load its models (likely empty)
      await _loadModelsForMake(makeId);
    }

    String modelId = _modelId!;
    if (modelId == _kOther) {
      final name = _otherModelCtrl.text.trim().toUpperCase();
      if (name.isEmpty) throw 'Enter OTHER MODEL';
      await _createOrGetModelId(name, makeId);
    }
  }

  Future<String> _createOrGetMakeId(String nameUpper) async {
    try {
      final res = await apiClient.postJson('/admin/makes', {'name': nameUpper});
      final id = _extractId(res);
      if (id != null && id.isNotEmpty) return id;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (!(msg.contains('409') || msg.contains('conflict') || msg.contains('already'))) rethrow;
    }

    await _loadMakes();
    final match = _makes.where((x) => x.name == nameUpper).toList();
    if (match.isEmpty) throw 'Failed to create make';
    return match.first.id;
  }

  Future<String> _createOrGetModelId(String nameUpper, String makeId) async {
    try {
      final res = await apiClient.postJson('/admin/models', {'name': nameUpper, 'makeId': makeId});
      final id = _extractId(res);
      if (id != null && id.isNotEmpty) return id;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (!(msg.contains('409') || msg.contains('conflict') || msg.contains('already'))) rethrow;
    }

    await _loadModelsForMake(makeId);
    final match = _models.where((x) => x.name == nameUpper).toList();
    if (match.isEmpty) throw 'Failed to create model';
    return match.first.id;
  }

  String? _extractId(dynamic res) {
    if (res is! Map) return null;

    dynamic data = res['data'];
    if (data is Map) {
      final id = (data['id'] ?? data['_id'])?.toString();
      if (id != null && id.trim().isNotEmpty) return id.trim();
    }

    final top = (res['id'] ?? res['_id'])?.toString();
    if (top != null && top.trim().isNotEmpty) return top.trim();

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingMakes) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }

    final makeItems = [
      ..._makes.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))),
      const DropdownMenuItem(value: _kOther, child: Text('OTHER')),
    ];

    final modelItems = [
      ..._models.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))),
      const DropdownMenuItem(value: _kOther, child: Text('OTHER')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _makeId,
          items: makeItems,
          onChanged: widget.enabled
              ? (v) async {
                  setState(() {
                    _makeId = v;
                    _models = const [];
                    _modelId = null;
                    _otherMakeCtrl.clear();
                    _otherModelCtrl.clear();
                  });

                  if (v != null && v != _kOther) {
                    await _loadModelsForMake(v);
                  }
                }
              : null,
          decoration: const InputDecoration(
            labelText: 'Make',
            border: OutlineInputBorder(),
          ),
        ),

        if (_makeId == _kOther) ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: _otherMakeCtrl,
            enabled: widget.enabled,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(60)],
            decoration: const InputDecoration(
              labelText: 'Other Make',
              border: OutlineInputBorder(),
            ),
          ),
        ],

        const SizedBox(height: 12),

        if (_loadingModels)
          const LinearProgressIndicator()
        else
          DropdownButtonFormField<String>(
            value: _modelId,
            items: modelItems,
            onChanged: widget.enabled
                ? (v) => setState(() {
                      _modelId = v;
                      _otherModelCtrl.clear();
                    })
                : null,
            decoration: const InputDecoration(
              labelText: 'Model',
              border: OutlineInputBorder(),
            ),
          ),

        if (_modelId == _kOther) ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: _otherModelCtrl,
            enabled: widget.enabled,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(60)],
            decoration: const InputDecoration(
              labelText: 'Other Model',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ],
    );
  }
}

class _MakeOpt {
  final String id;
  final String name;

  _MakeOpt({required this.id, required this.name});

  factory _MakeOpt.fromJson(Map<String, dynamic> j) => _MakeOpt(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        name: (j['name'] ?? '').toString().trim().toUpperCase(),
      );
}

class _ModelOpt {
  final String id;
  final String name;

  _ModelOpt({required this.id, required this.name});

  factory _ModelOpt.fromJson(Map<String, dynamic> j) => _ModelOpt(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        name: (j['name'] ?? '').toString().trim().toUpperCase(),
      );
}

/// Uppercase formatter (same as page)
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
