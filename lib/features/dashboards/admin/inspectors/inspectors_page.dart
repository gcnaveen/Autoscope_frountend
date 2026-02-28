import 'package:flutter/material.dart';

import '../../../shared/app_shell.dart';
import '../../../../models/app_user.dart';
import '../../../../services/service_locator.dart';

import 'widgets/add_inspector_dialog.dart';
import 'widgets/inspector_manage_dialog.dart';

class InspectorsPage extends StatefulWidget {
  const InspectorsPage({super.key});

  @override
  State<InspectorsPage> createState() => _InspectorsPageState();
}

class _InspectorsPageState extends State<InspectorsPage> {
  late Future<List<AppUser>> _future;
  final _searchCtrl = TextEditingController();

  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<AppUser>> _load() async {
    final all = await usersService.listUsers();

    return all.where((u) {
      final role = u.role.toString().toLowerCase();
      return role == 'inspector' || role.contains('inspector');
    }).toList();
  }

  void _reload() {
    setState(() {
      _tick++;
      _future = _load();
    });
  }

  Future<void> _openAddInspectorDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const AddInspectorDialog(),
    );

    if (ok == true) _reload();
  }

  Future<void> _openManageInspector(AppUser u) async {
    final updated = await showDialog<AppUser>(
      context: context,
      builder: (_) => InspectorManageDialog(inspector: u),
    );

    if (updated != null) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchCtrl.text.trim().toLowerCase();
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 720;

    return AppShell(
      title: 'Inspectors',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              if (!isMobile)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Inspectors',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _openAddInspectorDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Inspector'),
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
                            'Inspectors',
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
                      child: FilledButton.icon(
                        onPressed: _openAddInspectorDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Inspector'),
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
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search inspectors by name/email/phone...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      FutureBuilder<List<AppUser>>(
                        key: ValueKey(_tick),
                        future: _future,
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(18),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (snap.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  Text(
                                    'Failed to load inspectors:\n${snap.error}',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
                                  FilledButton.tonal(
                                    onPressed: _reload,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          }

                          final list = snap.data ?? [];

                          final filtered = q.isEmpty
                              ? list
                              : list.where((u) {
                                  final name = u.fullName.toLowerCase();
                                  final email = u.email.toLowerCase();
                                  final phone = (u.phone ?? '').toLowerCase();
                                  return name.contains(q) || email.contains(q) || phone.contains(q);
                                }).toList();

                          if (filtered.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  Icon(Icons.badge_outlined, size: 42, color: Colors.black26),
                                  SizedBox(height: 10),
                                  Text('No inspectors found.', style: TextStyle(color: Colors.black54)),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: filtered
                                .map(
                                  (x) => _InspectorCard(
                                    u: x,
                                    onManage: () => _openManageInspector(x),
                                  ),
                                )
                                .toList(),
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

class _InspectorCard extends StatelessWidget {
  final AppUser u;
  final VoidCallback onManage;

  const _InspectorCard({required this.u, required this.onManage});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 720;

    final statusRaw = (u.availableStatus ?? u.status).toString();
    final status = statusRaw.isEmpty ? 'unknown' : statusRaw;

    final isAvailable = status.toLowerCase().contains('available') || status.toLowerCase().contains('active');
    final assigned = u.isAssigned == true;

    final email = (u.email).trim();
    final phone = (u.phone ?? '').trim();

    if (!isMobile) {
      // Desktop: keep old ListTile look
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          elevation: 0,
          color: Colors.black.withOpacity(0.02),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF1E5EFF).withOpacity(0.10),
              foregroundColor: const Color(0xFF1E5EFF),
              child: const Icon(Icons.badge_outlined),
            ),
            title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text('$email\n${phone.isEmpty ? '-' : phone}'),
            isThreeLine: true,
            trailing: Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(assigned ? 'assigned' : 'not assigned'),
                  backgroundColor: assigned ? Colors.purple.withOpacity(0.12) : Colors.grey.withOpacity(0.12),
                  side: BorderSide(
                    color: assigned ? Colors.purple.withOpacity(0.20) : Colors.grey.withOpacity(0.20),
                  ),
                ),
                Chip(
                  label: Text(status),
                  backgroundColor: isAvailable ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                  side: BorderSide(
                    color: isAvailable ? Colors.green.withOpacity(0.20) : Colors.orange.withOpacity(0.20),
                  ),
                ),
                FilledButton.tonal(onPressed: onManage, child: const Text('Manage')),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile: no trailing. Actions move below (prevents vertical letters)
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
                    child: const Icon(Icons.badge_outlined),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email.isEmpty ? '-' : email,
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
                  Chip(
                    label: Text(assigned ? 'assigned' : 'not assigned'),
                    backgroundColor: assigned ? Colors.purple.withOpacity(0.12) : Colors.grey.withOpacity(0.12),
                    side: BorderSide(
                      color: assigned ? Colors.purple.withOpacity(0.20) : Colors.grey.withOpacity(0.20),
                    ),
                  ),
                  Chip(
                    label: Text(status),
                    backgroundColor: isAvailable ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                    side: BorderSide(
                      color: isAvailable ? Colors.green.withOpacity(0.20) : Colors.orange.withOpacity(0.20),
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    child: FilledButton.tonal(onPressed: onManage, child: const Text('Manage')),
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