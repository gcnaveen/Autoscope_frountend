import 'package:flutter/material.dart';

import '../../../shared/app_shell.dart';
import '../../../shared/widgets/pagination_bar.dart';
import '../../../../models/app_user.dart';
import '../../../../services/service_locator.dart';
import '../../../shared/top_snackbar.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
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
        role: 'user',
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

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 720;

    return AppShell(
      title: 'Users',
      child: ListView(
        controller: _scrollCtrl,
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
                  onPressed: _loading ? null : _reload,
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () => showTopSnack(context, 'Export will be added later.', variant: 'warning'),
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
                      onPressed: _loading ? null : _reload,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => showTopSnack(context, 'Export will be added later.', variant: 'warning'),
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
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search users by name/email/phone...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_loading)
                    const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Text('Failed to load users: $_error', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          FilledButton(onPressed: _reload, child: const Text('Retry')),
                        ],
                      ),
                    )
                  else if (_items.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('No users found.'))
                  else ...[
                    ..._items.map((u) => _UserCard(user: u)),
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

class _UserCard extends StatelessWidget {
  final AppUser user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 720;

    final email = user.email.isEmpty ? '—' : user.email;
    final name = user.fullName;
    final phone = user.phone?.trim() ?? '—';
    final status = user.status.isEmpty ? '—' : user.status;
    final active = status.toLowerCase() == 'active';
    final id = user.id;

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