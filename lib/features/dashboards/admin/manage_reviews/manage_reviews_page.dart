// lib/features/dashboards/admin/manage_reviews/manage_reviews_page.dart
import 'package:flutter/material.dart';

import '../../../shared/app_shell.dart';
import '../../../shared/widgets/pagination_bar.dart';
import '../../../../services/service_locator.dart';

class ManageReviewsPage extends StatefulWidget {
  const ManageReviewsPage({super.key});

  @override
  State<ManageReviewsPage> createState() => _ManageReviewsPageState();
}

class _ManageReviewsPageState extends State<ManageReviewsPage> {
  bool _loading = false;
  String? _error;

  String _status = 'all';
  List<Map<String, dynamic>> _reviews = [];
  int _page = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  static const int _pageSize = 20;

  final _scrollCtrl = ScrollController();

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
      final result = await reviewsService.getAdminReviewsPaged(
        page: page,
        limit: _pageSize,
        status: _status == 'all' ? null : _status,
      );

      if (!mounted) return;
      setState(() {
        _reviews = result.reviews;
        _page = page;
        _totalPages = result.totalPages;
        _totalItems = result.total;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load reviews: $e';
        _loading = false;
      });
    }
  }

  Future<void> _load() => _loadPage(1);

  void _goToPage(int p) {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
    _loadPage(p);
  }

  Future<void> _setStatus(String v) async {
    if (_status == v) return;
    setState(() { _status = v; _page = 1; });
    await _loadPage(1);
  }

  Future<void> _approve(String id) async {
    final ok = await _confirm('Approve this review?');
    if (ok != true) return;

    try {
      setState(() => _loading = true);
      await reviewsService.approveReview(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Approve failed: $e';
      });
    }
  }

  Future<void> _reject(String id) async {
    final ok = await _confirm('Reject this review?');
    if (ok != true) return;

    try {
      setState(() => _loading = true);
      await reviewsService.rejectReview(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Reject failed: $e';
      });
    }
  }

  Future<bool?> _confirm(String msg) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
  }

  String _s(dynamic v, {String fallback = '-'}) {
    if (v == null) return fallback;
    final t = v.toString().trim();
    return t.isEmpty ? fallback : t;
  }

  int _rating(dynamic v) {
    if (v is int) return v.clamp(0, 5);
    if (v is num) return v.toInt().clamp(0, 5);
    return (int.tryParse(v?.toString() ?? '') ?? 0).clamp(0, 5);
  }

  Color _chipColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _stars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          size: 16,
          color: filled ? Colors.amber : Colors.grey.shade400,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Manage Reviews',
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    _StatusButton(label: 'All', selected: _status == 'all', onTap: () => _setStatus('all')),
                    const SizedBox(width: 8),
                    _StatusButton(label: 'Pending', selected: _status == 'pending', onTap: () => _setStatus('pending')),
                    const SizedBox(width: 8),
                    _StatusButton(label: 'Approved', selected: _status == 'approved', onTap: () => _setStatus('approved')),
                    const SizedBox(width: 8),
                    _StatusButton(label: 'Rejected', selected: _status == 'rejected', onTap: () => _setStatus('rejected')),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _loading ? null : _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_error != null) ...[
                  Center(
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_reviews.isEmpty && !_loading && _error == null) ...[
                  const SizedBox(height: 48),
                  const Center(child: Text('No reviews found.')),
                ],

                if (_totalPages > 1 && !_loading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PaginationBar(
                      currentPage: _page,
                      totalPages: _totalPages,
                      totalItems: _totalItems,
                      pageSize: _pageSize,
                      onPrev: _page > 1 ? () => _goToPage(_page - 1) : null,
                      onNext: _page < _totalPages ? () => _goToPage(_page + 1) : null,
                    ),
                  ),

                ..._reviews.map<Widget>((r) {
                  final id = _s(r['_id'] ?? r['id'] ?? r['reviewId'], fallback: '');
                  final status = _s(r['status'], fallback: 'pending').toLowerCase();
                  final rating = _rating(r['rating']);
                  final comment = _s(r['comment'] ?? r['message'] ?? r['text']);
                  final requestId = _s(r['inspectionRequestId'] ?? r['requestId']);
                  final createdAt = _s(r['createdAt'] ?? r['created_at']);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _stars(rating),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _chipColor(status).withOpacity(0.12),
                                  border: Border.all(color: _chipColor(status).withOpacity(0.35)),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: _chipColor(status),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (id.isNotEmpty)
                                Text(id, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Text(comment, style: const TextStyle(fontSize: 14, height: 1.35)),
                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _kv('Request', requestId),
                              _kv('Created', createdAt),
                            ],
                          ),

                          const SizedBox(height: 12),
                          if (status == 'pending')
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: id.isEmpty || _loading ? null : () => _reject(id),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Reject'),
                                ),
                                const SizedBox(width: 10),
                                FilledButton.icon(
                                  onPressed: id.isEmpty || _loading ? null : () => _approve(id),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Approve'),
                                ),
                              ],
                            )
                          else
                            Text('No actions', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.04),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$k: $v', style: const TextStyle(fontSize: 12)),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? Colors.blue.withOpacity(0.08) : null,
        side: BorderSide(color: selected ? Colors.blue : Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label),
    );
  }
}