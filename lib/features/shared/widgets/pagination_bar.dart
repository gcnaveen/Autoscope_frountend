import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final from = totalItems == 0 ? 0 : ((currentPage - 1) * pageSize + 1).clamp(1, totalItems);
    final to   = totalItems == 0 ? 0 : (currentPage * pageSize).clamp(1, totalItems);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Previous page',
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        const SizedBox(width: 4),
        Text(
          'Page $currentPage of $totalPages  ($from–$to of $totalItems)',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Next page',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
