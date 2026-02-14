import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  String _titleFor(String seg) {
    switch (seg) {
      case 'dashboard':
        return 'Dashboard';
      case 'admin':
        return 'Admin';
      case 'user':
        return 'User';
      case 'inspector':
        return 'Inspector';
      case 'users':
        return 'Users';
      case 'inspectors':
        return 'Inspectors';
      case 'inspections':
        return 'Inspection Requests';
      case 'checklists':
        return 'Checklist Templates';
      case 'profile':
        return 'My Profile';
      case 'Request Details':
        return 'Request Details';
      default:
        // fallback (capitalize)
        if (seg.isEmpty) return '';
        return seg[0].toUpperCase() + seg.substring(1);
    }
  }

  List<_Crumb> _crumbsFromLocation(String location) {
    final uri = Uri.parse(location);
    final segs = uri.pathSegments.where((e) => e.isNotEmpty).toList();

    // We only show breadcrumbs for logged-in section
    // e.g. /dashboard/admin/users OR /profile
    final crumbs = <_Crumb>[];
    var path = '';

    for (final s in segs) {
      path += '/$s';
      crumbs.add(_Crumb(label: _titleFor(s), path: path));
    }
    return crumbs;
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    final location = router.routeInformationProvider.value.location;

    final crumbs = _crumbsFromLocation(location);

    // Back button support (works for browser + in-app)
    final canPop = router.canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 14,
        title: Row(
          children: const [
            Icon(Icons.directions_car_filled, size: 20),
            SizedBox(width: 10),
            Text('Auto Scope', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Home'),
          ),
          TextButton(
            onPressed: () => context.go('/products'),
            child: const Text('Services'),
          ),
          const SizedBox(width: 8),

          // Profile button (can be PopupMenu later)
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.account_circle),
          ),

          // Logout
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              // call your authService.logout() here if you have access
              // ex: authService.logout();
              context.go('/'); // or /auth
            },
            icon: const Icon(Icons.logout),
          ),

          const SizedBox(width: 10),
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Breadcrumb bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.06))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                if (canPop)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    tooltip: 'Back',
                  ),

                if (!canPop) const SizedBox(width: 8),

                // Breadcrumbs
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (int i = 0; i < crumbs.length; i++) ...[
                        _CrumbLink(
                          label: crumbs[i].label,
                          onTap: () => context.go(crumbs[i].path),
                          isLast: i == crumbs.length - 1,
                        ),
                        if (i != crumbs.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('›', style: TextStyle(color: Colors.black45)),
                          ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Page content
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Crumb {
  final String label;
  final String path;
  _Crumb({required this.label, required this.path});
}

class _CrumbLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  const _CrumbLink({
    required this.label,
    required this.onTap,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLast ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isLast ? FontWeight.w800 : FontWeight.w600,
            color: isLast ? Colors.black87 : const Color(0xFF1E5EFF),
          ),
        ),
      ),
    );
  }
}
