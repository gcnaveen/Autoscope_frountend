import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../services/service_locator.dart';
import '../../../models/role.dart';
import '../../shared/top_snackbar.dart'; // adjust to your helper file

class PasswordLoginForm extends StatefulWidget {
  const PasswordLoginForm({super.key});

  @override
  State<PasswordLoginForm> createState() => _PasswordLoginFormState();
}

class _PasswordLoginFormState extends State<PasswordLoginForm> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool loading = false;
  bool obscure = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  String _roleHome(Role role) {
    switch (role) {
      case Role.admin:
        return '/dashboard/admin';
      case Role.inspector:
        return '/dashboard/inspector';
      case Role.user:
        return '/dashboard/user';
    }
  }

  void _snack(String msg, String status) {
    showTopSnack(context, msg, variant: status);
  }

  Future<void> _login() async {
    final e = email.text.trim().toLowerCase();
    final p = password.text.trim();

    if (e.isEmpty || p.isEmpty) {
      _snack('Enter email and password', 'warning');
      return;
    }

    setState(() => loading = true);

    try {
      final s = await authService.loginWithPassword(email: e, password: p);
      if (!mounted) return;

      if (s == null) {
        _snack('Login failed', 'error');
        return;
      }

      context.go(_roleHome(s.role));
      _snack('Welcome ${s.role.name}', 'success');
    } catch (err) {
      if (!mounted) return;
      _snack('Login failed: $err', 'error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'admin@domain.com',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: password,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => obscure = !obscure),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton(
            onPressed: loading ? null : _login,
            child: Text(loading ? 'Logging in…' : 'Login'),
          ),
        ),
      ],
    );
  }
}
