import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/app_shell.dart';
import '../../../../services/service_locator.dart';
import '../../../shared/top_snackbar.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late Future<List<Map<String, dynamic>>> _future;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadUsers() async {
    final res = await apiClient.getJson('/users');

    List<dynamic> items = [];

    if (res is Map<String, dynamic>) {
      // Your backend: data.users
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        final u = data['users'];
        if (u is List) items = u;
      }

      // Fallbacks
      if (items.isEmpty && res['users'] is List) items = res['users'] as List;
      if (items.isEmpty && res['items'] is List) items = res['items'] as List;
    }

    // Convert to List<Map<String,dynamic>>
    final list = items
        .whereType<Map>()
        .map((x) => Map<String, dynamic>.from(x))
        .toList();

    // Users page should show ONLY role=user (not inspectors/admin)
    final onlyUsers = list.where((u) {
      final role = (u['role'] ?? '').toString().toLowerCase();
      return role == 'user';
    }).toList();

    return onlyUsers;
  }

  void _reload() {
    setState(() {
      _future = _loadUsers();
    });
  }

  String _fullName(Map<String, dynamic> u) {
    final fn = (u['firstName'] ?? '').toString().trim();
    final ln = (u['lastName'] ?? '').toString().trim();
    final name = ('$fn $ln').trim();
    if (name.isNotEmpty) return name;

    final email = (u['email'] ?? '').toString().trim();
    if (email.isNotEmpty && email.contains('@')) return email.split('@').first;

    return '—';
  }

  String _status(Map<String, dynamic> u) {
    final s = (u['status'] ?? '').toString().trim();
    return s.isEmpty ? '—' : s;
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Users',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Users',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      // Keep this as later (CSV export etc)
                      showTopSnack(context, 'Export will be added later.', variant: 'warning');
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(content: Text('Export will be added later.')),
                      // );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Export'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search users by name/email/phone...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _future,
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (snap.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  Text(
                                    'Failed to load users: ${snap.error}',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 10),
                                  FilledButton(
                                    onPressed: _reload,
                                    child: const Text('Retry'),
                                  )
                                ],
                              ),
                            );
                          }

                          final list = snap.data ?? [];
                          final q = _searchCtrl.text.trim().toLowerCase();

                          final filtered = q.isEmpty
                              ? list
                              : list.where((u) {
                                  final name = _fullName(u).toLowerCase();
                                  final email = (u['email'] ?? '').toString().toLowerCase();
                                  final phone = (u['phone'] ?? '').toString().toLowerCase();
                                  return name.contains(q) || email.contains(q) || phone.contains(q);
                                }).toList();

                          if (filtered.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text('No users found.'),
                            );
                          }

                          return Column(
                            children: filtered.map((u) => _UserCard(u: u)).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> u;
  const _UserCard({required this.u});

  @override
  Widget build(BuildContext context) {
    final email = (u['email'] ?? '—').toString();
    final fn = (u['firstName'] ?? '').toString().trim();
    final ln = (u['lastName'] ?? '').toString().trim();
    final name = ('$fn $ln').trim().isEmpty ? '—' : ('$fn $ln').trim();

    final phone = (u['phone'] ?? '—').toString();
    final status = (u['status'] ?? '—').toString();
    final active = status.toLowerCase() == 'active';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        color: Colors.black.withOpacity(0.02),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF1E5EFF).withOpacity(0.10),
            foregroundColor: const Color(0xFF1E5EFF),
            child: const Icon(Icons.person),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text('$email\n$phone'),
          isThreeLine: true,
          trailing: Wrap(
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                label: Text(status),
                backgroundColor: active
                    ? Colors.green.withOpacity(0.12)
                    : Colors.grey.withOpacity(0.15),
                side: BorderSide(
                  color: active
                      ? Colors.green.withOpacity(0.20)
                      : Colors.grey.withOpacity(0.20),
                ),
              ),
              IconButton(
                tooltip: 'View',
                onPressed: () {
                  // Optional: if you later add /dashboard/admin/users/:id
                  final id = (u['_id'] ?? u['id'] ?? '').toString();
                  if (id.isEmpty) return;
                  // context.go('/dashboard/admin/users/$id');
                  showTopSnack(context, 'User id: $id', variant: 'success');
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   SnackBar(content: Text('User id: $id')),
                  // );
                },
                icon: const Icon(Icons.open_in_new),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
