import 'package:flutter/material.dart';
import '../../../../../models/app_user.dart';
import '../../../../../services/service_locator.dart';
import '../../../../shared/top_snackbar.dart';

class InspectionRequestManageDialog extends StatefulWidget {
  final String requestMongoId; // _id
  final String requestDisplayId; // Req-001
  final String status;
  final String? assignedInspectorId; // string id (optional)
  final Map<String, dynamic>? assignedInspectorObj; // object (optional)

  const InspectionRequestManageDialog({
    super.key,
    required this.requestMongoId,
    required this.requestDisplayId,
    required this.status,
    this.assignedInspectorId,
    this.assignedInspectorObj,
  });

  bool get alreadyAssigned => assignedInspectorId != null;

  @override
  State<InspectionRequestManageDialog> createState() =>
      _InspectionRequestManageDialogState();
}

class _InspectionRequestManageDialogState
    extends State<InspectionRequestManageDialog> {
  AppUser? _selected;
  AppUser? _currentInspector;
  bool _saving = false;

  late Future<List<AppUser>> _inspectorsFuture;

  @override
  void initState() {
    super.initState();
    _currentInspector = _buildAssignedFromObj();
    _inspectorsFuture = _loadInspectors();
  }

  AppUser? _buildAssignedFromObj() {
    final obj = widget.assignedInspectorObj;
    if (obj == null) return null;

    final id = (obj['_id'] ?? obj['id'] ?? '').toString();
    final email = (obj['email'] ?? '').toString();

    if (id.isEmpty && email.isEmpty) return null;

    return AppUser(
      id: id,
      email: email,
      firstName: obj['firstName']?.toString(),
      lastName: obj['lastName']?.toString(),
      role: 'inspector',
      status: 'active',
      phone: obj['phone']?.toString(),
      availableStatus: obj['availableStatus']?.toString(),
      isAssigned: obj['is_assigned'] == true,
      otpVerified: obj['otpVerified'] == true,
      createdAt: null,
      updatedAt: null,
    );
  }

  Future<List<AppUser>> _loadInspectors() async {
    final all = await usersService.listUsers();

    final inspectors = all
        .where((u) =>
            u.role.toLowerCase() == 'inspector' &&
            u.status.toLowerCase() == 'active')
        .toList();

    // fallback: if current inspector missing, match by id
    if (_currentInspector == null && widget.assignedInspectorId != null) {
      try {
        _currentInspector =
            inspectors.firstWhere((u) => u.id == widget.assignedInspectorId);
      } catch (_) {}
    }

    // sort
    inspectors.sort((a, b) =>
        a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

    return inspectors;
  }

  void _snack(String msg, String variant) {
    showTopSnack(context, msg, variant: variant);
  }

  Future<void> _submit() async {
    if (_selected == null) return;

    setState(() => _saving = true);
    try {
      await inspectionRequestsService.assignRequest(
        requestId: widget.requestMongoId,
        inspectorId: _selected!.id,
      );

      if (!mounted) return;
      _snack(
        widget.alreadyAssigned
            ? 'Inspector reassigned successfully'
            : 'Inspector assigned successfully',
        'success',
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _snack('Operation failed: $e', 'error');
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
    final title = widget.alreadyAssigned ? 'Reassign Inspector' : 'Assign Inspector';

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Manage • ${widget.requestDisplayId}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _saving ? null : () => Navigator.pop(context, false),
                  )
                ],
              ),

              const SizedBox(height: 8),
              const Divider(),

              Align(
                alignment: Alignment.centerLeft,
                child: Text('Assigned Inspector',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 8),
              _assignedInspectorCard(),

              const SizedBox(height: 18),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 10),

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
                    return const Text('No active inspectors available.');
                  }

                  // Don’t show current inspector in dropdown
                  final options = list.where((u) {
                    if (_currentInspector == null) return true;
                    return u.id != _currentInspector!.id;
                  }).toList();

                  return DropdownButtonFormField<AppUser>(
                    value: _selected,
                    items: options
                        .map(
                          (u) => DropdownMenuItem(
                            value: u,
                            child: Text('${u.fullName} (${u.email})'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selected = v),
                    decoration: const InputDecoration(
                      labelText: 'Select Inspector',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving || _selected == null ? null : _submit,
                      child: Text(_saving
                          ? 'Saving...'
                          : widget.alreadyAssigned
                              ? 'Reassign'
                              : 'Assign'),
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
