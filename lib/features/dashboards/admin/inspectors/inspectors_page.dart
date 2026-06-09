import 'package:flutter/material.dart';

import '../../../shared/app_shell.dart';
import '../../../shared/widgets/pagination_bar.dart';
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
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<AppUser> _items = [];
  int _page = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  static const int _pageSize = 20;
  bool _loading = true;
  String? _error;

  int _searchVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadPage(1);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPage(int page) async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await usersService.listUsersPaged(
        page: page,
        limit: _pageSize,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        role: 'inspector',
      );
      if (!mounted) return;
      setState(() {
        _items = result.users;
        _page = page;
        _totalPages = result.totalPages;
        _totalItems = result.total;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _reload() {
    _searchCtrl.clear();
    _loadPage(1);
  }

  void _goToPage(int p) {
    _searchCtrl.clear();
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
    _loadPage(p);
  }

  void _onSearchChanged(String _) async {
    final ver = ++_searchVersion;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted || _searchVersion != ver) return;
    _loadPage(1);
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
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 720;

    return AppShell(
      title: 'Inspectors',
      child: ListView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          if (!isMobile)
            Row(
              children: [
                Expanded(
                  child: Text('Inspectors',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                ),
                IconButton(tooltip: 'Refresh', onPressed: _loading ? null : _reload, icon: const Icon(Icons.refresh)),
                const SizedBox(width: 10),
                FilledButton.icon(onPressed: _openAddInspectorDialog, icon: const Icon(Icons.add), label: const Text('Add Inspector')),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Inspectors',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    ),
                    IconButton(tooltip: 'Refresh', onPressed: _loading ? null : _reload, icon: const Icon(Icons.refresh)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(onPressed: _openAddInspectorDialog, icon: const Icon(Icons.add), label: const Text('Add Inspector')),
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
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search inspectors by name/email/phone...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_loading)
                    const Padding(padding: EdgeInsets.all(18), child: Center(child: CircularProgressIndicator()))
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Text('Failed to load inspectors:\n$_error', textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          FilledButton.tonal(onPressed: _reload, child: const Text('Retry')),
                        ],
                      ),
                    )
                  else if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Icon(Icons.badge_outlined, size: 42, color: Colors.black26),
                          SizedBox(height: 10),
                          Text('No inspectors found.', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    )
                  else ...[
                    ..._items.map((x) => _InspectorCard(u: x, onManage: () => _openManageInspector(x))),
                    if (_totalPages > 1) ...[
                      const SizedBox(height: 12),
                      PaginationBar(
                        currentPage: _page,
                        totalPages: _totalPages,
                        totalItems: _totalItems,
                        pageSize: _pageSize,
                        onPrev: _page > 1 ? () => _goToPage(_page - 1) : null,
                        onNext: _page < _totalPages ? () => _goToPage(_page + 1) : null,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
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
                  child: const Icon(Icons.badge_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(u.fullName,
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
                Chip(
                  label: Text(assigned ? 'assigned' : 'not assigned'),
                  backgroundColor: assigned ? Colors.purple.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.12),
                  side: BorderSide(
                    color: assigned ? Colors.purple.withValues(alpha: 0.20) : Colors.grey.withValues(alpha: 0.20),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(status),
                  backgroundColor: isAvailable ? Colors.green.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                  side: BorderSide(
                    color: isAvailable ? Colors.green.withValues(alpha: 0.20) : Colors.orange.withValues(alpha: 0.20),
                  ),
                ),
                const SizedBox(width: 8),
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