import 'package:flutter/material.dart';
import '../../../../services/service_locator.dart';
import '../../../shared/top_snackbar.dart';
import '../../../../models/app_user.dart';

class InspectionRequestManageDialog extends StatefulWidget {
  final String requestMongoId;
  final String requestDisplayId;
  final bool alreadyAssigned;
  final String? assignedInspectorId; // 👈 pass this

  const InspectionRequestManageDialog({
    super.key,
    required this.requestMongoId,
    required this.requestDisplayId,
    required this.alreadyAssigned,
    this.assignedInspectorId,
  });

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
    _inspectorsFuture = _loadInspectors();
  }

  Future<List<AppUser>> _loadInspectors() async {
    final all = await usersService.listUsers();
    final inspectors = all
        .where((u) =>
            u.role == 'inspector' &&
            u.status.toLowerCase() == 'active')
        .toList();

    // 🔹 find currently assigned inspector
    if (widget.assignedInspectorId != null) {
      try {
        _currentInspector = inspectors.firstWhere(
          (u) => u.id == widget.assignedInspectorId,
        );
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
      await inspectionRequestsService.assignRequest(
        requestId: widget.requestMongoId,
        inspectorId: _selected!.id,
      );

      if (!mounted) return;
      showTopSnack(
        context,
        widget.alreadyAssigned
            ? 'Inspector reassigned successfully'
            : 'Inspector assigned successfully',
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
        constraints: const BoxConstraints(maxWidth: 540),
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
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
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

              // 🔹 Assigned inspector info
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

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.alreadyAssigned
                      ? 'Reassign Inspector'
                      : 'Assign Inspector',
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
                        .where((u) =>
                            _currentInspector == null ||
                            u.id != _currentInspector!.id)
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

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving || _selected == null
                          ? null
                          : _submit,
                      child: Text(
                        _saving
                            ? 'Saving...'
                            : widget.alreadyAssigned
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
