import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/app_shell.dart';
import '../../shared/widgets/pagination_bar.dart';
import '../../../services/service_locator.dart';

class InspectorDashboardPage extends StatefulWidget {
  const InspectorDashboardPage({super.key});

  @override
  State<InspectorDashboardPage> createState() => _InspectorDashboardPageState();
}

class _InspectorDashboardPageState extends State<InspectorDashboardPage> {
  final _scrollCtrl = ScrollController();

  List<Map<String, dynamic>> _jobs = [];
  int _page = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  static const int _pageSize = 20;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage(1);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPage(int page) async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await inspectionRequestsService.listInspectorAssignedPaged(
        page: page,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _jobs = result.requests;
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

  Future<void> _refresh() => _loadPage(1);

  void _goToPage(int p) {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
    _loadPage(p);
  }

  String _s(dynamic v) => (v ?? '').toString();

  String _idOf(Map<String, dynamic> r) {
    return _s(r['id']).isNotEmpty
        ? _s(r['id'])
        : _s(r['_id']).isNotEmpty
            ? _s(r['_id'])
            : _s(r['inspectionRequestId']);
  }

  String _formatAddress(dynamic addr) {
    if (addr == null) return '';
    if (addr is String) return addr;

    if (addr is Map) {
      final parts = <String>[
        _s(addr['address']),
        _s(addr['city']),
        _s(addr['state']),
        _s(addr['zipCode']),
      ].where((x) => x.trim().isNotEmpty).toList();

      return parts.join(', ');
    }

    return _s(addr);
  }

  String _formatWhen(Map<String, dynamic> r) {
    final raw = r['inspectionDate'] ?? r['scheduledAt'] ?? r['createdAt'];
    final s = _s(raw);
    if (s.isEmpty) return '';
    final dt = DateTime.tryParse(s);
    if (dt == null) return s;
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _titleOf(Map<String, dynamic> r) {
    final t = _s(r['title']);
    if (t.isNotEmpty) return t;
    final name = _s(r['name']);
    if (name.isNotEmpty) return name;
    final type = _s(r['inspectionType']);
    if (type.isNotEmpty) return type;
    return 'Car inspection';
  }

  String _statusOf(Map<String, dynamic> r) {
    final s = _s(r['status']).trim();
    return s.isEmpty ? '-' : s;
  }

  bool _isCompletedStatus(String status) {
    final s = status.toLowerCase().trim();
    return s == 'completed' || s.contains('completed');
  }

  Color _statusBg(String s) {
    final v = s.toLowerCase();
    if (v.contains('complete')) return Colors.green.withOpacity(0.15);
    if (v.contains('progress')) return Colors.orange.withOpacity(0.15);
    if (v.contains('pending')) return Colors.blue.withOpacity(0.12);
    return Colors.black.withOpacity(0.06);
  }

  Color _statusBorder(String s) {
    final v = s.toLowerCase();
    if (v.contains('complete')) return Colors.green.withOpacity(0.35);
    if (v.contains('progress')) return Colors.orange.withOpacity(0.35);
    if (v.contains('pending')) return Colors.blue.withOpacity(0.30);
    return Colors.black.withOpacity(0.14);
  }

  void _openRequest(Map<String, dynamic> r) {
    final id = _idOf(r);
    if (id.isEmpty) return;

    // open details page (NOT start)
    context.push('/dashboard/inspector/requests/$id');
  }

  Widget _buildJobCard(Map<String, dynamic> r, bool isMobile, bool isVeryNarrow) {
    final status = _statusOf(r);
    final isCompleted = _isCompletedStatus(status);
    final title = _titleOf(r);
    final addr = _formatAddress(r['address']);
    final when = _formatWhen(r);

    final statusChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _statusBg(status),
        border: Border.all(color: _statusBorder(status)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(status, style: const TextStyle(fontWeight: FontWeight.w800)),
    );

    final openBtn = FilledButton.tonal(
      onPressed: isCompleted ? null : () => _openRequest(r),
      child: const Text('Open'),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 20,
                    child: Icon(Icons.directions_car_filled_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        if (addr.trim().isNotEmpty)
                          Text(
                            addr,
                            style: const TextStyle(color: Colors.black54),
                            maxLines: isMobile ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (when.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            when,
                            style: const TextStyle(color: Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (!isMobile)
                    Row(
                      children: [
                        statusChip,
                        const SizedBox(width: 10),
                        SizedBox(height: 36, child: openBtn),
                      ],
                    ),
                ],
              ),
              if (isMobile) ...[
                const SizedBox(height: 12),
                if (isVeryNarrow)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      statusChip,
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity, height: 40, child: openBtn),
                    ],
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [statusChip, SizedBox(height: 36, child: openBtn)],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final isMobile = screenW < 700;
    final isVeryNarrow = screenW < 380;

    return AppShell(
      title: 'Inspector Dashboard',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Stack(
            children: [
              ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Assigned Jobs',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (_totalItems > 0)
                        Text('$_totalItems total', style: const TextStyle(color: Colors.black54)),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: _loading ? null : _refresh,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_error != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Text('Failed to load jobs: $_error', textAlign: TextAlign.center),
                            const SizedBox(height: 10),
                            FilledButton.tonal(onPressed: _refresh, child: const Text('Retry')),
                          ],
                        ),
                      ),
                    ),
                  ] else if (!_loading && _jobs.isEmpty) ...[
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Text('No assigned jobs found.'),
                      ),
                    ),
                  ] else ...[
                    ..._jobs.map((r) => _buildJobCard(r, isMobile, isVeryNarrow)),
                    if (_totalPages > 1) ...[
                      const SizedBox(height: 8),
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
              if (_loading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.04),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}