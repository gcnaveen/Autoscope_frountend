// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import '../../shared/app_shell.dart';
// import '../../../models/admin_dashboard_data.dart';
// import '../../../services/service_locator.dart'; // to access apiClient or adminDashboardService
// import '../../../services/admin_dashboard_service.dart';

// class AdminDashboardPage extends StatefulWidget {
//   const AdminDashboardPage({super.key});

//   @override
//   State<AdminDashboardPage> createState() => _AdminDashboardPageState();
// }

// class _AdminDashboardPageState extends State<AdminDashboardPage> {
//   late final AdminDashboardService _svc;
//   late Future<AdminDashboardData> _future;

//   @override
//   void initState() {
//     super.initState();
//     // If you already registered AdminDashboardService in locator, use that.
//     // Otherwise create it here using apiClient from locator.
//     _svc = AdminDashboardService(apiClient: apiClient);
//     _future = _svc.getDashboard();
//   }

//   void _reload() {
//     setState(() => _future = _svc.getDashboard());
//   }

//   @override
//   Widget build(BuildContext context) {
//     final w = MediaQuery.sizeOf(context).width;
//     final isMobile = w < 900;

//     return AppShell(
//       title: 'Admin Dashboard',
//       child: FutureBuilder<AdminDashboardData>(
//         future: _future,
//         builder: (context, snap) {
//           if (snap.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snap.hasError) {
//             return Center(
//               child: ConstrainedBox(
//                 constraints: const BoxConstraints(maxWidth: 520),
//                 child: Card(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(Icons.error_outline, size: 34),
//                         const SizedBox(height: 10),
//                         const Text(
//                           'Failed to load dashboard',
//                           style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
//                         ),
//                         const SizedBox(height: 6),
//                         Text(
//                           '${snap.error}',
//                           textAlign: TextAlign.center,
//                           style: const TextStyle(color: Colors.black54),
//                         ),
//                         const SizedBox(height: 12),
//                         FilledButton.icon(
//                           onPressed: _reload,
//                           icon: const Icon(Icons.refresh),
//                           label: const Text('Retry'),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           }

//           final d = snap.data!;

//           return Center(
//             child: ConstrainedBox(
//               constraints: const BoxConstraints(maxWidth: 1200),
//               child: ListView(
//                 padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
//                 children: [
//                   _HeaderCard(
//                     onUsers: () => context.go('/dashboard/admin/users'),
//                     onInspectors: () => context.go('/dashboard/admin/inspectors'),
//                     onRequests: () => context.go('/dashboard/admin/inspections'),
//                     onTemplates: () => context.go('/dashboard/admin/checklists'),
//                   ),
//                   const SizedBox(height: 18),

//                   GridView.count(
//                     crossAxisCount: isMobile ? 1 : 2,
//                     mainAxisSpacing: 12,
//                     crossAxisSpacing: 12,
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     childAspectRatio: isMobile ? 2.6 : 2.3,
//                     children: [
//                       _KpiActionCard(
//                         kpiTitle: 'Users',
//                         kpiValue: '${d.totalUsers}',
//                         kpiSubtitle: 'Registered Customers',
//                         icon: Icons.people_alt_outlined,
//                         onTap: () => context.go('/dashboard/admin/users'),
//                       ),
//                       _KpiActionCard(
//                         kpiTitle: 'Inspectors',
//                         kpiValue: '${d.totalInspectors}',
//                         kpiSubtitle: 'Total Inspectors',
//                         icon: Icons.badge_outlined,
//                         onTap: () => context.go('/dashboard/admin/inspectors'),
//                       ),
//                       _KpiActionCard(
//                         kpiTitle: 'Inspection Requests',
//                         kpiValue: '${d.openRequests}',
//                         kpiSubtitle: 'Total Inspection Requests',
//                         icon: Icons.assignment_outlined,
//                         onTap: () => context.go('/dashboard/admin/inspections'),
//                       ),
//                       _KpiActionCard(
//                         kpiTitle: 'Checklist Templates',
//                         kpiValue: '${d.totalChecklistTemplates}',
//                         kpiSubtitle: 'Total Checklist Templates',
//                         icon: Icons.playlist_add_check_outlined,
//                         onTap: () => context.go('/dashboard/admin/checklists'),
//                       ),  
//                     ],
//                   ),

//                   const SizedBox(height: 18),

//                   Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
//                   const SizedBox(height: 10),
//                   _RecentActivityCard(items: d.recentActivities),

//                   const SizedBox(height: 18),

//                   Text('Latest Requests', style: Theme.of(context).textTheme.titleLarge),
//                   const SizedBox(height: 10),
//                   _LatestRequestsCard(
//                     rows: d.latestRequests,
//                     onViewAll: () => context.go('/dashboard/admin/inspections'),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// // ----------------------- Widgets (same as yours, but 2 updated) -----------------------

// class _HeaderCard extends StatelessWidget {
//   final VoidCallback onUsers;
//   final VoidCallback onInspectors;
//   final VoidCallback onRequests;
//   final VoidCallback onTemplates;

//   const _HeaderCard({
//     required this.onUsers,
//     required this.onInspectors,
//     required this.onRequests,
//     required this.onTemplates,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: Container(
//         padding: const EdgeInsets.all(18),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           gradient: LinearGradient(
//             colors: [
//               const Color(0xFF0B1220),
//               const Color(0xFF0B1220).withOpacity(0.88),
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Welcome, Admin',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 22,
//                 fontWeight: FontWeight.w900,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // class _QuickAction extends StatelessWidget {
// //   final String label;
// //   final IconData icon;
// //   final VoidCallback onTap;

// //   const _QuickAction({required this.label, required this.icon, required this.onTap});

// //   @override
// //   Widget build(BuildContext context) {
// //     return FilledButton.tonalIcon(
// //       onPressed: onTap,
// //       icon: Icon(icon, size: 18),
// //       label: Text(label),
// //     );
// //   }
// // }

// class _KpiCard extends StatelessWidget {
//   final String title;
//   final String value;
//   final String subtitle;
//   final IconData icon;

//   const _KpiCard({
//     required this.title,
//     required this.value,
//     required this.subtitle,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 280,
//       child: Card(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Container(
//                 height: 44,
//                 width: 44,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF1E5EFF).withOpacity(0.10),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(icon, color: const Color(0xFF1E5EFF)),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
//                     const SizedBox(height: 4),
//                     Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
//                     const SizedBox(height: 2),
//                     Text(subtitle, style: const TextStyle(color: Colors.black54)),
//                   ],
//                 ),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ActionTile extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final IconData icon;
//   final String cta;
//   final VoidCallback onTap;

//   const _ActionTile({
//     required this.title,
//     required this.subtitle,
//     required this.icon,
//     required this.cta,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: InkWell(
//         borderRadius: BorderRadius.circular(16),
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Container(
//                 height: 52,
//                 width: 52,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF1E5EFF).withOpacity(0.10),
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 child: Icon(icon, color: const Color(0xFF1E5EFF), size: 26),
//               ),
//               const SizedBox(width: 14),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
//                     const SizedBox(height: 6),
//                     Text(subtitle, style: const TextStyle(color: Colors.black54, height: 1.3)),
//                     const SizedBox(height: 12),
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: FilledButton.tonal(
//                         onPressed: onTap,
//                         child: Text(cta),
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 10),
//               const Icon(Icons.chevron_right, color: Colors.black38),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _KpiActionCard extends StatelessWidget {
//   final String kpiTitle;
//   final String kpiValue;
//   final String kpiSubtitle;
//   final IconData icon;
//   final VoidCallback onTap;

//   const _KpiActionCard({
//     required this.kpiTitle,
//     required this.kpiValue,
//     required this.kpiSubtitle,
//     required this.icon,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 280,
//       child: Card(
//         child: InkWell(
//           borderRadius: BorderRadius.circular(16),
//           onTap: onTap,
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Container(
//                   height: 44,
//                   width: 44,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF1E5EFF).withOpacity(0.10),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(icon, color: const Color(0xFF1E5EFF)),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(kpiTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
//                       const SizedBox(height: 4),
//                       Text(kpiValue, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
//                       const SizedBox(height: 2),
//                       Text(kpiSubtitle, style: const TextStyle(color: Colors.black54)),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 const Icon(Icons.chevron_right, color: Colors.black38),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // UPDATED: now accepts API list
// class _RecentActivityCard extends StatelessWidget {
//   final List<DashboardActivity> items;
//   const _RecentActivityCard({required this.items});

//   @override
//   Widget build(BuildContext context) {
//     if (items.isEmpty) {
//       return const Card(
//         child: Padding(
//           padding: EdgeInsets.all(14),
//           child: Text('No recent activity yet.', style: TextStyle(color: Colors.black54)),
//         ),
//       );
//     }

//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           children: items
//               .map((x) => ListTile(
//                     leading: const Icon(Icons.bolt),
//                     title: Text(
//                       x.action.replaceAll('_', ' '),
//                       style: const TextStyle(fontWeight: FontWeight.w800),
//                     ),
//                     subtitle: Text(x.description),
//                   ))
//               .toList(),
//         ),
//       ),
//     );
//   }
// }

// // UPDATED: now accepts API list
// class _LatestRequestsCard extends StatelessWidget {
//   final List<DashboardLatestRequest> rows;
//   final VoidCallback onViewAll;

//   const _LatestRequestsCard({required this.rows, required this.onViewAll});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           children: [
//             if (rows.isEmpty)
//               const Padding(
//                 padding: EdgeInsets.symmetric(vertical: 10),
//                 child: Text('No recent requests yet.', style: TextStyle(color: Colors.black54)),
//               )
//             else
//               ...rows.map(
//                 (r) => ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor: const Color(0xFF1E5EFF).withOpacity(0.10),
//                     foregroundColor: const Color(0xFF1E5EFF),
//                     child: const Icon(Icons.directions_car),
//                   ),
//                   title: Text('${r.id} • ${r.type}', style: const TextStyle(fontWeight: FontWeight.w800)),
//                   subtitle: Text(r.location),
//                   trailing: Chip(
//                     label: Text(r.status),
//                     backgroundColor: (r.status.toLowerCase().contains('pending'))
//                         ? Colors.orange.withOpacity(0.12)
//                         : Colors.green.withOpacity(0.12),
//                     side: BorderSide(
//                       color: (r.status.toLowerCase().contains('pending'))
//                           ? Colors.orange.withOpacity(0.20)
//                           : Colors.green.withOpacity(0.20),
//                     ),
//                   ),
//                 ),
//               ),
//             const Divider(height: 18),
//             Align(
//               alignment: Alignment.centerRight,
//               child: TextButton(
//                 onPressed: onViewAll,
//                 child: const Text('View all requests →'),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/app_shell.dart';
import '../../../models/admin_dashboard_data.dart';
import '../../../services/service_locator.dart';
import '../../../services/admin_dashboard_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late final AdminDashboardService _svc;
  late Future<AdminDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _svc = AdminDashboardService(apiClient: apiClient);
    _future = _svc.getDashboard();
  }

  void _reload() {
    setState(() => _future = _svc.getDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 900;

    return AppShell(
      title: 'Admin Dashboard',
      child: FutureBuilder<AdminDashboardData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 34),
                        const SizedBox(height: 10),
                        const Text(
                          'Failed to load dashboard',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${snap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          final d = snap.data!;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  _HeaderCard(
                    onUsers: () => context.go('/dashboard/admin/users'),
                    onInspectors: () => context.go('/dashboard/admin/inspectors'),
                    onRequests: () => context.go('/dashboard/admin/inspections'),
                    onTemplates: () => context.go('/dashboard/admin/checklists'),
                  ),
                  const SizedBox(height: 18),

                  GridView.count(
                    crossAxisCount: isMobile ? 1 : 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isMobile ? 2.6 : 2.3,
                    children: [
                      _KpiActionCard(
                        kpiTitle: 'Users',
                        kpiValue: '${d.totalUsers}',
                        kpiSubtitle: 'Active: ${d.usersByStatus.active} • Inactive: ${d.usersByStatus.inactive}',
                        icon: Icons.people_alt_outlined,
                        onTap: () => context.go('/dashboard/admin/users'),
                      ),
                      _KpiActionCard(
                        kpiTitle: 'Inspectors',
                        kpiValue: '${d.totalInspectors}',
                        kpiSubtitle: 'Active: ${d.inspectorsByStatus.active} • Busy: ${d.inspectorsByStatus.busy}',
                        icon: Icons.badge_outlined,
                        onTap: () => context.go('/dashboard/admin/inspectors'),
                      ),

                      // ✅ FIX: show total_requests (not open_requests) if subtitle says Total
                      _KpiActionCard(
                        kpiTitle: 'Inspection Requests',
                        kpiValue: '${d.inspectionRequests.totalRequests}',
                        kpiSubtitle: 'Open: ${d.inspectionRequests.openRequests} • Completed: ${d.inspectionRequests.byStatus.completed}',
                        icon: Icons.assignment_outlined,
                        onTap: () => context.go('/dashboard/admin/inspections'),
                      ),

                      _KpiActionCard(
                        kpiTitle: 'Checklist Templates',
                        kpiValue: '${d.totalChecklistTemplates}',
                        kpiSubtitle: 'Active Templates',
                        icon: Icons.playlist_add_check_outlined,
                        onTap: () => context.go('/dashboard/admin/checklists'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  _RecentActivityCard(items: d.recentActivities),

                  const SizedBox(height: 18),

                  Text('Latest Requests', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  _LatestRequestsCard(
                    rows: d.latestRequests,
                    onViewAll: () => context.go('/dashboard/admin/inspections'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ----------------------- Widgets (unchanged from yours) -----------------------

class _HeaderCard extends StatelessWidget {
  final VoidCallback onUsers;
  final VoidCallback onInspectors;
  final VoidCallback onRequests;
  final VoidCallback onTemplates;

  const _HeaderCard({
    required this.onUsers,
    required this.onInspectors,
    required this.onRequests,
    required this.onTemplates,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0B1220),
              const Color(0xFF0B1220).withOpacity(0.88),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Admin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiActionCard extends StatelessWidget {
  final String kpiTitle;
  final String kpiValue;
  final String kpiSubtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _KpiActionCard({
    required this.kpiTitle,
    required this.kpiValue,
    required this.kpiSubtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E5EFF).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF1E5EFF)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(kpiTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(kpiValue, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(kpiSubtitle, style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.black38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final List<DashboardActivity> items;
  const _RecentActivityCard({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Text('No recent activity yet.', style: TextStyle(color: Colors.black54)),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: items
              .map((x) => ListTile(
                    leading: const Icon(Icons.bolt),
                    title: Text(
                      x.action.replaceAll('_', ' '),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(x.description),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _LatestRequestsCard extends StatelessWidget {
  final List<DashboardLatestRequest> rows;
  final VoidCallback onViewAll;

  const _LatestRequestsCard({required this.rows, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('No recent requests yet.', style: TextStyle(color: Colors.black54)),
              )
            else
              ...rows.map(
                (r) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1E5EFF).withOpacity(0.10),
                    foregroundColor: const Color(0xFF1E5EFF),
                    child: const Icon(Icons.directions_car),
                  ),
                  title: Text('${r.id} • ${r.type}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(r.location),
                  trailing: Chip(
                    label: Text(r.status),
                    backgroundColor: (r.status.toLowerCase().contains('pending'))
                        ? Colors.orange.withOpacity(0.12)
                        : Colors.green.withOpacity(0.12),
                    side: BorderSide(
                      color: (r.status.toLowerCase().contains('pending'))
                          ? Colors.orange.withOpacity(0.20)
                          : Colors.green.withOpacity(0.20),
                    ),
                  ),
                ),
              ),
            const Divider(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onViewAll,
                child: const Text('View all requests →'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
