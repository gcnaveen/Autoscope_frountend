// import 'package:go_router/go_router.dart';
// import '../features/dashboards/admin/checklists/checklist_editor_page.dart';
// import '../services/service_locator.dart';
// import '../models/role.dart';

// import '../features/public/landing/landing_page.dart';
// import '../features/public/products/products_page.dart';
// import '../features/public/request/request_page.dart';

// import '../features/report/pages/inspection_report_page.dart';

// // TODO: rename your current AuthPage to UserOtpAuthPage (recommended)
// import '../features/auth/auth_page.dart';
// import '../features/auth/staff_login_page.dart';


// // TODO: create StaffLoginPage
// // import '../features/auth/staff_login_page.dart';


// import '../features/dashboards/user/user_dashboard_page.dart';
// import '../features/dashboards/user/user_request_details_page.dart';

// import '../features/dashboards/inspector/inspector_dashboard_page.dart';
// import '../features/dashboards/inspector/inspector_request_details_page.dart';
// import '../features/dashboards/inspector/start_inspection_page.dart';
// import '../features/dashboards/inspector/inspector_request_details_page.dart';
// import '../features/dashboards/inspector/start_inspection_page.dart';

// import '../features/dashboards/admin/admin_dashboard_page.dart';
// import '../features/dashboards/admin/users/users_page.dart';
// import '../features/dashboards/admin/inspectors/inspectors_page.dart';
// import '../features/dashboards/admin/inspections/inspection_requests_page.dart';
// import '../features/dashboards/admin/checklists/checklist_templates_page.dart';

// import '../features/dashboards/admin/vehicle_catalog_page.dart';

// import '../features/profile/profile_page.dart';

// GoRouter buildRouter() {
//   return GoRouter(
//     initialLocation: '/',
//     refreshListenable: authService.session,
//     redirect: (context, state) {
//       final s = authService.session.value;
//       final loc = state.matchedLocation;

//       // Auth routes
//       final isUserAuth = loc == '/auth/user';
//       final isStaffAuth = loc == '/auth/staff';
//       final isAnyAuth = isUserAuth || isStaffAuth;

//       // Public
//       final isPublic = loc == '/' || loc == '/products' || loc == '/request';

//       // Protected
//       final isProfile = loc == '/profile';
//       final isDashboard = loc.startsWith('/dashboard');

//       // --- Not logged in ---
//       if (s == null) {
//         if (isPublic || isAnyAuth) return null;
//         return '/auth/user'; // default login entry for public users
//       }

//       // --- Logged in ---
//       // If logged in, do not allow auth pages
//       if (isAnyAuth) return _roleHome(s.role);

//       // Allow public + profile + dashboards
//       if (isPublic || isProfile) return null;

//       // Role-based dashboard protection
//       if (loc.startsWith('/dashboard/admin') && s.role != Role.admin) {
//         return _roleHome(s.role);
//       }
//       if (loc.startsWith('/dashboard/user') && s.role != Role.user) {
//         return _roleHome(s.role);
//       }
//       if (loc.startsWith('/dashboard/inspector') && s.role != Role.inspector) {
//         return _roleHome(s.role);
//       }

//       return null;
//     },
//     routes: [
//       GoRoute(path: '/', builder: (c, s) => const LandingPage()),
//       GoRoute(path: '/products', builder: (c, s) => const ProductsPage()),
//       GoRoute(path: '/request', builder: (c, s) => const RequestPage()),

//       // ✅ Split auth routes
//       GoRoute(path: '/auth/user', builder: (c, s) => const AuthPage()),
//       GoRoute(path: '/auth/staff', builder: (c, s) => const StaffLoginPage()),
//       // GoRoute(path: '/auth/staff', builder: (c, s) => const StaffLoginPage()),

//       GoRoute(path: '/dashboard/admin', builder: (c, s) => const AdminDashboardPage()),
//       GoRoute(path: '/dashboard/user', builder: (c, s) => const UserDashboardPage()),
//       GoRoute(path: '/dashboard/inspector', builder: (c, s) => const InspectorDashboardPage()),

//       GoRoute(path: '/dashboard/admin/users', builder: (c, s) => const UsersPage()),
//       GoRoute(path: '/dashboard/admin/inspectors', builder: (c, s) => const InspectorsPage()),
//       GoRoute(path: '/dashboard/admin/inspections', builder: (c, s) => const InspectionRequestsPage()),
//       GoRoute(path: '/dashboard/admin/checklists', builder: (c, s) => const ChecklistTemplatesPage()),

//       GoRoute(
//         path: '/dashboard/admin/vehicle-catalog',
//         builder: (context, state) => const VehicleCatalogPage(),
//       ),

//       GoRoute(path: '/dashboard/user/requests/:id', builder: (c, s) { 
//           final id = s.pathParameters['id'] ?? '';
//           return UserRequestDetailsPage(requestId: id);
//         },
//       ),

//       GoRoute(
//         path: '/dashboard/user/inspections/:inspectionId/report',
//         builder: (context, state) {
//           final inspectionId = state.pathParameters['inspectionId']!;
//           // ✅ Reuse the SAME report page/widget you use for admin:
//           return InspectionReportPage(inspectionId: inspectionId); 
//         },
//       ),

//       GoRoute(
//         path: '/dashboard/inspector/requests/:id',
//         builder: (c, s) {
//           final id = s.pathParameters['id'] ?? '';
//           return InspectorRequestDetailsPage(requestId: id);
//         },
//       ),
//       GoRoute(
//         path: '/dashboard/inspector/requests/:id/start',
//         builder: (c, s) {
//           final id = s.pathParameters['id'] ?? '';
//           return StartInspectionPage(requestId: id);
//         },
//       ),
//       GoRoute(
//         path: '/dashboard/inspector/requests/:id',
//         builder: (c, s) {
//           final id = s.pathParameters['id'] ?? '';
//           return InspectorRequestDetailsPage(requestId: id);
//         },
//       ),
//       GoRoute(
//         path: '/dashboard/inspector/requests/:id/start',
//         builder: (c, s) {
//           final id = s.pathParameters['id'] ?? '';
//           return StartInspectionPage(requestId: id);
//         },
//       ),
//       GoRoute(
//         path: '/dashboard/admin/checklists/new',
//         builder: (context, state) => const ChecklistEditorPage.create(),
//       ),
//       GoRoute(
//         path: '/dashboard/admin/checklists/:id/edit',
//         builder: (context, state) {
//           final id = state.pathParameters['id']!;
//           return ChecklistEditorPage.edit(templateId: id);
//         },
//       ),
//       GoRoute(path: '/profile', builder: (c, s) => const ProfilePage()),

//       GoRoute(
//         path: '/dashboard/admin/inspections/:inspectionId/report',
//         builder: (context, state) {
//           final id = state.pathParameters['inspectionId']!;
//           return InspectionReportPage(inspectionId: id);
//         },
//       ),

//       GoRoute(
//         path: '/dashboard/user/inspections/:inspectionId/report',
//         builder: (context, state) {
//           final id = state.pathParameters['inspectionId']!;
//           return InspectionReportPage(inspectionId: id);
//         },
//       ),
//     ],
//   );
// }

// String _roleHome(Role role) {
//   switch (role) {
//     case Role.admin:
//       return '/dashboard/admin';
//     case Role.user:
//       return '/dashboard/user';
//     case Role.inspector:
//       return '/dashboard/inspector';
//   }
// }

import 'package:flutter/foundation.dart' show Listenable;
import 'package:go_router/go_router.dart';

import '../features/dashboards/admin/checklists/checklist_editor_page.dart';
import '../services/service_locator.dart';
import '../models/role.dart';

import '../features/public/landing/landing_page.dart';
import '../features/public/products/products_page.dart';
import '../features/public/request/request_page.dart';

import '../features/report/pages/inspection_report_page.dart';

import '../features/auth/auth_page.dart';
import '../features/auth/staff_login_page.dart';

import '../features/dashboards/user/user_dashboard_page.dart';
import '../features/dashboards/user/user_request_details_page.dart';

import '../features/dashboards/inspector/inspector_dashboard_page.dart';
import '../features/dashboards/inspector/inspector_request_details_page.dart';
import '../features/dashboards/inspector/start_inspection_page.dart';
import '../features/dashboards/inspector/inspector_request_details_page.dart';
import '../features/dashboards/inspector/start_inspection_page.dart';

import '../features/dashboards/admin/admin_dashboard_page.dart';
import '../features/dashboards/admin/users/users_page.dart';
import '../features/dashboards/admin/inspectors/inspectors_page.dart';
import '../features/dashboards/admin/inspections/inspection_requests_page.dart';
import '../features/dashboards/admin/checklists/checklist_templates_page.dart';

import '../features/dashboards/admin/vehicle_catalog_page.dart';

import '../features/profile/profile_page.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: Listenable.merge([authService.session, authService.ready]),
    redirect: (context, state) {
      // ✅ wait for init() restore (prevents logout on refresh)
      if (authService.ready.value == false) return null;

      final s = authService.session.value;
      final loc = state.matchedLocation;

      // Auth routes
      final isUserAuth = loc == '/auth/user';
      final isStaffAuth = loc == '/auth/staff';
      final isAnyAuth = isUserAuth || isStaffAuth;

      // Public
      final isPublic = loc == '/' || loc == '/products' || loc == '/request';

      // Protected
      final isProfile = loc == '/profile';
      final isDashboard = loc.startsWith('/dashboard');

      // --- Not logged in ---
      if (s == null) {
        if (isPublic || isAnyAuth) return null;
        return '/auth/user'; // default login entry for public users
      }

      // --- Logged in ---
      // If logged in, do not allow auth pages
      if (isAnyAuth) return _roleHome(s.role);

      // Allow public + profile + dashboards
      if (isPublic || isProfile) return null;

      // Role-based dashboard protection
      if (loc.startsWith('/dashboard/admin') && s.role != Role.admin) {
        return _roleHome(s.role);
      }
      if (loc.startsWith('/dashboard/user') && s.role != Role.user) {
        return _roleHome(s.role);
      }
      if (loc.startsWith('/dashboard/inspector') && s.role != Role.inspector) {
        return _roleHome(s.role);
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (c, s) => const LandingPage()),
      GoRoute(path: '/products', builder: (c, s) => const ProductsPage()),
      GoRoute(path: '/request', builder: (c, s) => const RequestPage()),

      // ✅ Split auth routes
      GoRoute(path: '/auth/user', builder: (c, s) => const AuthPage()),
      GoRoute(path: '/auth/staff', builder: (c, s) => const StaffLoginPage()),

      GoRoute(path: '/dashboard/admin', builder: (c, s) => const AdminDashboardPage()),
      GoRoute(path: '/dashboard/user', builder: (c, s) => const UserDashboardPage()),
      GoRoute(path: '/dashboard/inspector', builder: (c, s) => const InspectorDashboardPage()),

      GoRoute(path: '/dashboard/admin/users', builder: (c, s) => const UsersPage()),
      GoRoute(path: '/dashboard/admin/inspectors', builder: (c, s) => const InspectorsPage()),
      GoRoute(path: '/dashboard/admin/inspections', builder: (c, s) => const InspectionRequestsPage()),
      GoRoute(path: '/dashboard/admin/checklists', builder: (c, s) => const ChecklistTemplatesPage()),

      GoRoute(
        path: '/dashboard/admin/vehicle-catalog',
        builder: (context, state) => const VehicleCatalogPage(),
      ),

      GoRoute(
        path: '/dashboard/user/requests/:id',
        builder: (c, s) {
          final id = s.pathParameters['id'] ?? '';
          return UserRequestDetailsPage(requestId: id);
        },
      ),

      GoRoute(
        path: '/dashboard/user/inspections/:inspectionId/report',
        builder: (context, state) {
          final inspectionId = state.pathParameters['inspectionId']!;
          return InspectionReportPage(inspectionId: inspectionId);
        },
      ),

      GoRoute(
        path: '/dashboard/inspector/requests/:id',
        builder: (c, s) {
          final id = s.pathParameters['id'] ?? '';
          return InspectorRequestDetailsPage(requestId: id);
        },
      ),
      GoRoute(
        path: '/dashboard/inspector/requests/:id/start',
        builder: (c, s) {
          final id = s.pathParameters['id'] ?? '';
          return StartInspectionPage(requestId: id);
        },
      ),
      GoRoute(
        path: '/dashboard/inspector/requests/:id',
        builder: (c, s) {
          final id = s.pathParameters['id'] ?? '';
          return InspectorRequestDetailsPage(requestId: id);
        },
      ),
      GoRoute(
        path: '/dashboard/inspector/requests/:id/start',
        builder: (c, s) {
          final id = s.pathParameters['id'] ?? '';
          return StartInspectionPage(requestId: id);
        },
      ),

      GoRoute(
        path: '/dashboard/admin/checklists/new',
        builder: (context, state) => const ChecklistEditorPage.create(),
      ),
      GoRoute(
        path: '/dashboard/admin/checklists/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChecklistEditorPage.edit(templateId: id);
        },
      ),

      GoRoute(path: '/profile', builder: (c, s) => const ProfilePage()),

      GoRoute(
        path: '/dashboard/admin/inspections/:inspectionId/report',
        builder: (context, state) {
          final id = state.pathParameters['inspectionId']!;
          return InspectionReportPage(inspectionId: id);
        },
      ),

      GoRoute(
        path: '/dashboard/user/inspections/:inspectionId/report',
        builder: (context, state) {
          final id = state.pathParameters['inspectionId']!;
          return InspectionReportPage(inspectionId: id);
        },
      ),
    ],
  );
}

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
