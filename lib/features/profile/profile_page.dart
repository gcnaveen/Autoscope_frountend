import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/service_locator.dart';
import '../../models/role.dart';
import '../shared/app_shell.dart';
import '../shared/top_snackbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  bool saving = false;

  @override
  void initState() {
    super.initState();

    final s = authService.session.value;
    nameCtrl.text = s?.email.split('@').first ?? 'Demo User';
    phoneCtrl.text = '';
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  void _safeBack() {
    final r = GoRouter.of(context);

    if (r.canPop()) {
      r.pop();
      return;
    }

    // No stack to pop (common on web refresh / direct URL) -> go to role home
    final s = authService.session.value;
    if (s == null) {
      context.go('/'); // public landing
      return;
    }

    switch (s.role) {
      case Role.admin:
        context.go('/dashboard/admin');
        break;
      case Role.user:
        context.go('/dashboard/user');
        break;
      case Role.inspector:
        context.go('/dashboard/inspector');
        break;
    }
  }

  Future<void> _save() async {
    setState(() => saving = true);

    try {
      // TODO: call API later to update profile

      if (!mounted) return;
      showTopSnack(context, 'Profile updated.', variant: 'success');
    } catch (e) {
      if (!mounted) return;
      showTopSnack(context, 'Update Failed', variant: 'error');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = authService.session.value?.email ?? 'unknown@email.com';

    return AppShell(
      title: 'My Profile',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Account', style: Theme.of(context).textTheme.titleLarge),
                        ),
                        TextButton.icon(
                          onPressed: _safeBack,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Email: $email', style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 18),

                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: saving ? null : _save,
                        child: Text(saving ? 'Saving...' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
