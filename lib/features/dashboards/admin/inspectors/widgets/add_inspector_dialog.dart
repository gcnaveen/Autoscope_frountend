import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../../services/service_locator.dart';

import '../../../../shared/top_snackbar.dart'; // adjust path if different

class AddInspectorDialog extends StatefulWidget {
  const AddInspectorDialog({super.key});

  @override
  State<AddInspectorDialog> createState() => _AddInspectorDialogState();
}

class _AddInspectorDialogState extends State<AddInspectorDialog> {
  final _formKey = GlobalKey<FormState>();

  final emailCtrl = TextEditingController();
  final firstCtrl = TextEditingController();
  final lastCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  bool saving = false;
  bool obscure = true;

  @override
  void initState() {
    super.initState();
    passwordCtrl.text = _genPassword();
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    firstCtrl.dispose();
    lastCtrl.dispose();
    phoneCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, String variant) {
    showTopSnack(context, msg, variant: variant);
  }

  String _genPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789@#%';
    final r = Random.secure();
    return List.generate(12, (_) => chars[r.nextInt(chars.length)]).join();
  }

  InputDecoration _dec(String label, {String? hint, IconData? icon, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      suffixIcon: suffix,
      border: const OutlineInputBorder(),
      isDense: true,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);
    try {
      await usersService.createInspector(
        email: emailCtrl.text,
        firstName: firstCtrl.text,
        lastName: lastCtrl.text,
        phone: phoneCtrl.text,
        password: passwordCtrl.text,
      );

      if (!mounted) return;
      _snack('Inspector created successfully', 'success');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to create inspector: $e', 'error');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // header
                Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1220),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.person_add_alt_1, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Add Inspector', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          SizedBox(height: 2),
                          Text('Create inspector account and temporary password', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: saving ? null : () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                LayoutBuilder(
                  builder: (context, c) {
                    final twoCol = c.maxWidth >= 560;

                    final first = TextFormField(
                      controller: firstCtrl,
                      decoration: _dec('First name', hint: 'Jane', icon: Icons.person_outline),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    );

                    final last = TextFormField(
                      controller: lastCtrl,
                      decoration: _dec('Last name', hint: 'Smith', icon: Icons.person_outline),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    );

                    return Column(
                      children: [
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _dec('Email', hint: 'inspector@example.com', icon: Icons.email_outlined),
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.isEmpty) return 'Required';
                            if (!s.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

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

                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: _dec('Phone', hint: '+1234567890', icon: Icons.phone_outlined),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),

                        const SizedBox(height: 12),

                        TextFormField(
                          controller: passwordCtrl,
                          obscureText: obscure,
                          decoration: _dec(
                            'Temporary password',
                            hint: 'Auto-generated',
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
                                  tooltip: 'Regenerate',
                                  onPressed: () => setState(() => passwordCtrl.text = _genPassword()),
                                  icon: const Icon(Icons.refresh),
                                ),
                              ],
                            ),
                          ),
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.length < 8) return 'Minimum 8 characters';
                            return null;
                          },
                        ),

                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Inspector can change password later from Profile → Security.',
                            style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 12),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

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
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
