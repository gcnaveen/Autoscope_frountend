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
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        final u = data['users'];
        if (u is List) items = u;
      }

      if (items.isEmpty && res['users'] is List) items = res['users'] as List;
      if (items.isEmpty && res['items'] is List) items = res['items'] as List;
    }

    final list = items.whereType<Map>().map((x) => Map<String, dynamic>.from(x)).toList();

    // Only role=user
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

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 720;

    return AppShell(
      title: 'Users',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              if (!isMobile)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Users',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
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
                        showTopSnack(context, 'Export will be added later.', variant: 'warning');
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Export'),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Users',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh',
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          showTopSnack(context, 'Export will be added later.', variant: 'warning');
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                      ),
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
                                    textAlign: TextAlign.center,
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
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> u;
  const _UserCard({required this.u});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 720;

    final email = (u['email'] ?? '—').toString().trim();
    final fn = (u['firstName'] ?? '').toString().trim();
    final ln = (u['lastName'] ?? '').toString().trim();
    final name = ('$fn $ln').trim().isEmpty ? '—' : ('$fn $ln').trim();

    final phone = (u['phone'] ?? '—').toString().trim();
    final status = (u['status'] ?? '—').toString().trim();
    final active = status.toLowerCase() == 'active';

    final id = (u['_id'] ?? u['id'] ?? '').toString().trim();

    Widget statusChip() {
      return Chip(
        label: Text(status.isEmpty ? '—' : status),
        backgroundColor: active ? Colors.green.withOpacity(0.12) : Colors.grey.withOpacity(0.15),
        side: BorderSide(
          color: active ? Colors.green.withOpacity(0.20) : Colors.grey.withOpacity(0.20),
        ),
      );
    }

    void onView() {
      if (id.isEmpty) return;
      showTopSnack(context, 'User id: $id', variant: 'success');
    }

    if (!isMobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
          elevation: 0,
          color: Colors.black.withValues(alpha: 0.02),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1E5EFF).withValues(alpha: 0.10),
                  foregroundColor: const Color(0xFF1E5EFF),
                  child: const Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
                Expanded(
                  flex: 4,
                  child: Text(email.isEmpty ? '—' : email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(phone.isEmpty ? '—' : phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54)),
                ),
                const SizedBox(width: 12),
                statusChip(),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'View',
                  onPressed: onView,
                  icon: const Icon(Icons.open_in_new),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile layout: actions below (prevents vertical letters)
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        color: Colors.black.withOpacity(0.02),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1E5EFF).withOpacity(0.10),
                    foregroundColor: const Color(0xFF1E5EFF),
                    child: const Icon(Icons.person),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email.isEmpty ? '—' : email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  statusChip(),
                  IconButton(
                    tooltip: 'View',
                    onPressed: onView,
                    icon: const Icon(Icons.open_in_new),
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