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
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final s = authService.session.value;
    final id = s?.id;

    if (id == null || id.trim().isEmpty) {
      // No id captured on the session (e.g. stale session from before this
      // field existed) -> fall back to the email prefix so the page is not blank.
      nameCtrl.text = s?.email.split('@').first ?? '';
      phoneCtrl.text = '';
      if (mounted) setState(() => loading = false);
      return;
    }

    try {
      final user = await usersService.getUserById(id);
      final fullName = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
      nameCtrl.text = fullName.isNotEmpty ? fullName : (s?.email.split('@').first ?? '');
      phoneCtrl.text = user?.phone ?? '';
    } catch (e) {
      // Keep a lightweight fallback rather than pretending the fetch succeeded.
      nameCtrl.text = s?.email.split('@').first ?? '';
      phoneCtrl.text = '';
      if (mounted) {
        showTopSnack(context, 'Could not load profile details.', variant: 'error');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
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
    final s = authService.session.value;
    final id = s?.id;

    if (id == null || id.trim().isEmpty) {
      showTopSnack(context, 'Update Failed', variant: 'error');
      return;
    }

    setState(() => saving = true);

    try {
      final parts = nameCtrl.text.trim().split(RegExp(r'\s+'));
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      await usersService.updateUser(
        id: id,
        firstName: firstName,
        lastName: lastName,
        phone: phoneCtrl.text.trim(),
      );

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
                      enabled: !loading,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      enabled: !loading,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: (saving || loading) ? null : _save,
                        child: Text(saving ? 'Saving...' : (loading ? 'Loading...' : 'Save')),
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
