import 'dart:async';
import 'package:flutter/material.dart';

OverlayEntry? _topSnackEntry;
Timer? _topSnackTimer;

/// Floating TOP snack (toast-style).
/// variant: 'success' | 'error' | 'warning'
void showTopSnack(
  BuildContext context,
  String message, {
  String variant = 'success',
  Duration duration = const Duration(seconds: 3),
}) {
  // Remove existing snack if present
  _topSnackTimer?.cancel();
  _topSnackTimer = null;
  _topSnackEntry?.remove();
  _topSnackEntry = null;

  final v = variant.toLowerCase().trim();

  late Color bg;
  late IconData icon;

  switch (v) {
    case 'success':
      bg = Colors.green.shade700;
      icon = Icons.check_circle_outline;
      break;
    case 'error':
      bg = Colors.red.shade700;
      icon = Icons.error_outline;
      break;
    case 'warning':
    default:
      bg = Colors.orange.shade800;
      icon = Icons.warning_amber_outlined;
      break;
  }

  final overlay = Overlay.of(context, rootOverlay: true);
  if (overlay == null) return;

  _topSnackEntry = OverlayEntry(
    builder: (ctx) {
      final topInset = MediaQuery.of(ctx).padding.top;
      final width = MediaQuery.of(ctx).size.width;
      final isMobile = width < 600;

      return Positioned(
        top: topInset + 14,
        left: isMobile ? 12 : 24,
        right: isMobile ? 12 : 24,
        child: _TopSnackView(
          message: message,
          backgroundColor: bg,
          icon: icon,
          onClose: _hideTopSnack,
        ),
      );
    },
  );

  overlay.insert(_topSnackEntry!);

  _topSnackTimer = Timer(duration, _hideTopSnack);
}

void _hideTopSnack() {
  _topSnackTimer?.cancel();
  _topSnackTimer = null;

  _topSnackEntry?.remove();
  _topSnackEntry = null;
}

class _TopSnackView extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onClose;

  const _TopSnackView({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.onClose,
  });

  @override
  State<_TopSnackView> createState() => _TopSnackViewState();
}

class _TopSnackViewState extends State<_TopSnackView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  Future<void> _close() async {
    await _controller.reverse();
    widget.onClose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Dismissible(
          key: const ValueKey('top_snack'),
          direction: DismissDirection.up,
          onDismissed: (_) => _close(),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _close,
                    borderRadius: BorderRadius.circular(999),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
