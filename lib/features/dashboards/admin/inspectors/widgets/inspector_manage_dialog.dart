import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../../models/app_user.dart';
import '../../../../../services/service_locator.dart';
import '../../../../shared/top_snackbar.dart';

class InspectorManageDialog extends StatefulWidget {
  final AppUser inspector;
  const InspectorManageDialog({super.key, required this.inspector});

  @override
  State<InspectorManageDialog> createState() => _InspectorManageDialogState();
}

class _InspectorManageDialogState extends State<InspectorManageDialog> {
  late final TextEditingController firstCtrl;
  late final TextEditingController lastCtrl;
  late final TextEditingController phoneCtrl;

  final TextEditingController passCtrl = TextEditingController();

  bool saving = false;
  bool resettingPass = false;
  bool obscure = true;

  late String status;

  @override
  void initState() {
    super.initState();
    firstCtrl = TextEditingController(text: widget.inspector.firstName ?? '');
    lastCtrl = TextEditingController(text: widget.inspector.lastName ?? '');
    phoneCtrl = TextEditingController(text: widget.inspector.phone ?? '');
    status = widget.inspector.status.isNotEmpty ? widget.inspector.status : 'active';
    passCtrl.text = _genPassword();
  }

  @override
  void dispose() {
    firstCtrl.dispose();
    lastCtrl.dispose();
    phoneCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  String _genPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789@#%';
    final r = Random.secure();
    return List.generate(12, (_) => chars[r.nextInt(chars.length)]).join();
  }

  InputDecoration _dec(String label, {IconData? icon, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      suffixIcon: suffix,
      border: const OutlineInputBorder(),
      isDense: true,
    );
  }

  Future<void> _saveProfile() async {
    final id = widget.inspector.id.trim();
    if (id.isEmpty) {
      showTopSnack(context, 'Inspector id missing', variant: 'error');
      return;
    }

    setState(() => saving = true);
    try {
      final updated = await usersService.updateUser(
        id: id,
        firstName: firstCtrl.text,
        lastName: lastCtrl.text,
        phone: phoneCtrl.text,
        status: status,
      );

      if (!mounted) return;
      showTopSnack(context, 'Inspector updated', variant: 'success');
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      showTopSnack(context, 'Update failed: $e', variant: 'error');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _resetPassword() async {
    final id = widget.inspector.id.trim();
    final pwd = passCtrl.text.trim();

    if (id.isEmpty) {
      showTopSnack(context, 'Inspector id missing', variant: 'error');
      return;
    }
    if (pwd.length < 8) {
      showTopSnack(context, 'Password must be at least 8 characters', variant: 'warning');
      return;
    }

    setState(() => resettingPass = true);
    try {
      await usersService.updateUser(
        id: id,
        password: pwd, // ✅ password via update API
      );

      if (!mounted) return;
      showTopSnack(context, 'Password updated', variant: 'success');
    } catch (e) {
      if (!mounted) return;
      showTopSnack(context, 'Password update failed: $e', variant: 'error');
    } finally {
      if (mounted) setState(() => resettingPass = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.inspector;
    final assigned = u.isAssigned == true;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(18),
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
                    child: const Icon(Icons.badge_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.fullName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(u.email, style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: (saving || resettingPass) ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Chips row (Assigned + Status)
              Row(
                children: [
                  Chip(
                    label: Text(assigned ? 'assigned' : 'not assigned'),
                    backgroundColor: assigned
                        ? Colors.purple.withOpacity(0.12)
                        : Colors.grey.withOpacity(0.12),
                    side: BorderSide(
                      color: assigned
                          ? Colors.purple.withOpacity(0.20)
                          : Colors.grey.withOpacity(0.20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(u.status),
                    backgroundColor: u.status.toLowerCase() == 'active'
                        ? Colors.green.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                    side: BorderSide(
                      color: u.status.toLowerCase() == 'active'
                          ? Colors.green.withOpacity(0.20)
                          : Colors.orange.withOpacity(0.20),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Editable fields
              LayoutBuilder(
                builder: (context, c) {
                  final twoCol = c.maxWidth >= 620;

                  final first = TextField(
                    controller: firstCtrl,
                    decoration: _dec('First name', icon: Icons.person_outline),
                  );

                  final last = TextField(
                    controller: lastCtrl,
                    decoration: _dec('Last name', icon: Icons.person_outline),
                  );

                  return Column(
                    children: [
                      if (twoCol)
                        Row(
                          children: [
                            Expanded(child: first),
                            const SizedBox(width: 12),
                            Expanded(child: last),
                          ],
                        )
                      else ...[
                        first,
                        const SizedBox(height: 12),
                        last,
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneCtrl,
                        decoration: _dec('Phone', icon: Icons.phone_outlined),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: status,
                        autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
                        decoration: _dec('Status', icon: Icons.toggle_on_outlined),
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('active')),
                          DropdownMenuItem(value: 'inactive', child: Text('inactive')),
                        ],
                        onChanged: (v) => setState(() => status = v ?? 'active'),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 14),

              // Reset password section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reset password', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passCtrl,
                      obscureText: obscure,
                      decoration: _dec(
                        'New password',
                        icon: Icons.lock_outline,
                        suffix: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: obscure ? 'Show' : 'Hide',
                              onPressed: () => setState(() => obscure = !obscure),
                              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                            ),
                            IconButton(
                              tooltip: 'Generate',
                              onPressed: () => setState(() => passCtrl.text = _genPassword()),
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: resettingPass ? null : _resetPassword,
                        child: Text(resettingPass ? 'Updating…' : 'Update Password'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Footer buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: (saving || resettingPass) ? null : () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: (saving || resettingPass) ? null : _saveProfile,
                      child: Text(saving ? 'Saving…' : 'Save changes'),
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
