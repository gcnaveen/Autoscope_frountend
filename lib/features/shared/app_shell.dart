import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../public/widgets/public_navbar.dart';
import '../../services/service_locator.dart';
import '../../models/role.dart';

class AppShell extends StatelessWidget {
  final String title;
  final Widget child;

  const AppShell({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final loc = state.matchedLocation; // e.g. /dashboard/admin/users

    return Scaffold(
      appBar: const PublicNavBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BreadcrumbBar(
            location: loc,
            title: title,
          ),
          // ✅ IMPORTANT: ListView/GridView pages must have bounded height
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BreadcrumbBar extends StatelessWidget {
  final String location;
  final String title;

  const _BreadcrumbBar({
    required this.location,
    required this.title,
  });

  String _roleHome(Role role) {
    switch (role) {
      case Role.admin:
        return '/dashboard/admin';
      case Role.user:
        return '/dashboard/user';
      case Role.inspector:
        return '/dashboard/inspector';
    }
  }

  List<_Crumb> _buildCrumbs(BuildContext context) {
    final s = authService.session.value;

    // If not logged in, don't show breadcrumbs (shouldn't happen for AppShell pages)
    if (s == null) return [];

    final roleHome = _roleHome(s.role);

    // Dashboard area
    if (location.startsWith('/dashboard')) {
      // common base crumb
      final crumbs = <_Crumb>[
        _Crumb('Dashboard', roleHome, clickable: true),
      ];

      // admin subpages
      if (location == '/dashboard/admin') {
        crumbs.add(_Crumb('Admin Dashboard', null, clickable: false));
        return crumbs;
      }
      if (location == '/dashboard/admin/users') {
        crumbs.add(_Crumb('Admin', '/dashboard/admin', clickable: true));
        crumbs.add(_Crumb('Users', null, clickable: false));
        return crumbs;
      }
      if (location == '/dashboard/admin/inspectors') {
        crumbs.add(_Crumb('Admin', '/dashboard/admin', clickable: true));
        crumbs.add(_Crumb('Inspectors', null, clickable: false));
        return crumbs;
      }
      if (location == '/dashboard/admin/inspections') {
        crumbs.add(_Crumb('Admin', '/dashboard/admin', clickable: true));
        crumbs.add(_Crumb('Inspection Requests', null, clickable: false));
        return crumbs;
      }
      if (location == '/dashboard/admin/checklists') {
        crumbs.add(_Crumb('Admin', '/dashboard/admin', clickable: true));
        crumbs.add(_Crumb('Checklist Templates', null, clickable: false));
        return crumbs;
      }

      // user dashboard
      if (location == '/dashboard/user') {
        crumbs.add(_Crumb('User Dashboard', null, clickable: false));
        return crumbs;
      }

      // inspector dashboard
      if (location == '/dashboard/inspector') {
        crumbs.add(_Crumb('Inspector Dashboard', null, clickable: false));
        return crumbs;
      }

      // fallback
      crumbs.add(_Crumb(title, null, clickable: false));
      return crumbs;
    }

    // Profile page (logged-in)
    if (location == '/profile') {
      return [
        _Crumb('Dashboard', _roleHome(s.role), clickable: true),
        _Crumb('My Profile', null, clickable: false),
      ];
    }

    // fallback for any other protected page
    return [
      _Crumb('Dashboard', _roleHome(s.role), clickable: true),
      _Crumb(title, null, clickable: false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final crumbs = _buildCrumbs(context);
    if (crumbs.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < crumbs.length; i++) ...[
            _CrumbWidget(crumb: crumbs[i]),
            if (i != crumbs.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.chevron_right, size: 18, color: Colors.black38),
              ),
          ],
        ],
      ),
    );
  }
}

class _Crumb {
  final String label;
  final String? path;
  final bool clickable;

  _Crumb(this.label, this.path, {required this.clickable});
}

class _CrumbWidget extends StatelessWidget {
  final _Crumb crumb;

  const _CrumbWidget({required this.crumb});

  @override
  Widget build(BuildContext context) {
    if (!crumb.clickable || crumb.path == null) {
      return Text(
        crumb.label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.go(crumb.path!),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Text(
          crumb.label,
          style: const TextStyle(
            color: Color(0xFF1E5EFF),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
