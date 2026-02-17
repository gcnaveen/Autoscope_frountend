// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// import '../../../services/service_locator.dart';
// import '../../../models/role.dart';

// class PublicNavBar extends StatelessWidget implements PreferredSizeWidget {
//   const PublicNavBar({super.key});

//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);

//   String _roleHome(Role role) {
//     switch (role) {
//       case Role.admin:
//         return '/dashboard/admin';
//       case Role.user:
//         return '/dashboard/user';
//       case Role.inspector:
//         return '/dashboard/inspector';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final w = MediaQuery.sizeOf(context).width;
//     final isMobile = w < 900;

//     final session = authService.session.value;
//     final isLoggedIn = session != null;

//     Widget homeBtn() => TextButton(
//           onPressed: () => context.go('/'),
//           child: const Text('Home', style: TextStyle(color: Colors.white70)),
//         );

//     Widget productsMenu() {
//       return PopupMenuButton<String>(
//         tooltip: 'Services',
//         offset: const Offset(0, 42),
//         onSelected: (v) => context.go(v),
//         itemBuilder: (_) => const [
//           PopupMenuItem(value: '/products?focus=inspection', child: Text('Car Inspection')),
//           PopupMenuItem(value: '/products?focus=valuation', child: Text('Car Valuation')),
//         ],
//         child: Row(
//           children: const [
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//               child: Text('Services', style: TextStyle(color: Colors.white70)),
//             ),
//             Icon(Icons.arrow_drop_down, color: Colors.white70),
//             SizedBox(width: 6),
//           ],
//         ),
//       );
//     }

//     Widget dashboardBtn() {
//       final path = _roleHome(session!.role);
//       return TextButton(
//         onPressed: () => context.go(path),
//         child: const Text('Dashboard', style: TextStyle(color: Colors.white70)),
//       );
//     }

//     return AppBar(
//       title: Row(
//         children: [
//           Image.asset(
//             'assets/logo/autoscope_logo.png',
//             height: 42, // adjust to fit AppBar height
//             fit: BoxFit.contain,
//           ),
//           // const SizedBox(width: 10),
//           // const Text(
//           //   'Auto Scope', // optional (remove if you want only logo)
//           //   style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF) ),
//           // ),
//         ],
//       ),

//       actions: [
//         if (!isMobile) ...[
//           homeBtn(),
//           productsMenu(),
//           if (isLoggedIn) dashboardBtn(),
//           const SizedBox(width: 8),
//         ] else
//           PopupMenuButton<String>(
//             icon: const Icon(Icons.menu, color: Colors.white),
//             onSelected: (v) => context.go(v),
//             itemBuilder: (_) => [
//               const PopupMenuItem(value: '/', child: Text('Home')),
//               const PopupMenuItem(value: '/products?focus=inspection', child: Text('Car Inspection')),
//               const PopupMenuItem(value: '/products?focus=valuation', child: Text('Car Valuation')),
//               if (isLoggedIn) PopupMenuItem(value: _roleHome(session!.role), child: const Text('Dashboard')),
//               if (isLoggedIn) const PopupMenuItem(value: '/profile', child: Text('My Profile')),
//             ],
//           ),

//         const SizedBox(width: 6),

//         // ✅ Profile icon always available when logged in
//         if (isLoggedIn)
//           IconButton(
//             tooltip: 'My Profile',
//             onPressed: () => context.go('/profile'),
//             icon: const Icon(Icons.account_circle, color: Colors.white),
//           ),

//         // ✅ Logout icon
//         if (isLoggedIn)
//           IconButton(
//             tooltip: 'Logout',
//             onPressed: () {
//               authService.logout();
//               context.go('/');
//             },
//             icon: const Icon(Icons.logout, color: Colors.white),
//           ),

//         if (!isLoggedIn) ...[
//           FilledButton(
//             onPressed: () => context.go('/auth'),
//             child: const Text('Login'),
//           ),
//         ],

//         const SizedBox(width: 12),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../services/service_locator.dart';
import '../../../models/role.dart';

class PublicNavBar extends StatelessWidget implements PreferredSizeWidget {
  const PublicNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 900;

    final session = authService.session.value;
    final isLoggedIn = session != null;

    Widget homeBtn() => TextButton(
          onPressed: () => context.go('/'),
          child: const Text('Home', style: TextStyle(color: Colors.white70)),
        );

    Widget productsMenu() {
      return PopupMenuButton<String>(
        tooltip: 'Services',
        offset: const Offset(0, 42),
        onSelected: (v) => context.go(v),
        itemBuilder: (_) => const [
          PopupMenuItem(value: '/products?focus=inspection', child: Text('Car Inspection')),
          PopupMenuItem(value: '/products?focus=valuation', child: Text('Car Valuation')),
        ],
        child: Row(
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text('Services', style: TextStyle(color: Colors.white70)),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.white70),
            SizedBox(width: 6),
          ],
        ),
      );
    }

    Widget dashboardBtn() {
      final path = _roleHome(session!.role);
      return TextButton(
        onPressed: () => context.go(path),
        child: const Text('Dashboard', style: TextStyle(color: Colors.white70)),
      );
    }

    return AppBar(
      title: InkWell(
        onTap: () => context.go('/'), // ✅ click logo -> home
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Image.asset(
              'assets/logo/autoscope_logo.png',
              height: 42, // adjust to fit AppBar height
              fit: BoxFit.contain,
            ),
            // const SizedBox(width: 10),
            // const Text(
            //   'Auto Scope', // optional (remove if you want only logo)
            //   style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFFFFFF) ),
            // ),
          ],
        ),
      ),
      actions: [
        if (!isMobile) ...[
          homeBtn(),
          productsMenu(),
          if (isLoggedIn) dashboardBtn(),
          const SizedBox(width: 8),
        ] else
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: (v) => context.go(v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: '/', child: Text('Home')),
              const PopupMenuItem(value: '/products?focus=inspection', child: Text('Car Inspection')),
              const PopupMenuItem(value: '/products?focus=valuation', child: Text('Car Valuation')),
              if (isLoggedIn) PopupMenuItem(value: _roleHome(session!.role), child: const Text('Dashboard')),
              if (isLoggedIn) const PopupMenuItem(value: '/profile', child: Text('My Profile')),
            ],
          ),

        const SizedBox(width: 6),

        // ✅ Profile icon always available when logged in
        if (isLoggedIn)
          IconButton(
            tooltip: 'My Profile',
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.account_circle, color: Colors.white),
          ),

        // ✅ Logout icon
        if (isLoggedIn)
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              authService.logout();
              context.go('/');
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),

        if (!isLoggedIn) ...[
          FilledButton(
            onPressed: () => context.go('/auth'),
            child: const Text('Login'),
          ),
        ],

        const SizedBox(width: 12),
      ],
    );
  }
}

