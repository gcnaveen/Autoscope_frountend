// // // import 'package:flutter/material.dart';
// // // import 'package:go_router/go_router.dart';
// // // import '../../shared/app_shell.dart';
// // // import '../../../services/service_locator.dart'; // assumes you have userRequestsService in locator

// // // class UserDashboardPage extends StatefulWidget {
// // //   const UserDashboardPage({super.key});

// // //   @override
// // //   State<UserDashboardPage> createState() => _UserDashboardPageState();
// // // }

// // // class _UserDashboardPageState extends State<UserDashboardPage> {
// // //   late Future<List<UserRequestRow>> _future;
// // //   final _searchCtrl = TextEditingController();

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _future = _load();
// // //   }

// // //   @override
// // //   void dispose() {
// // //     _searchCtrl.dispose();
// // //     super.dispose();
// // //   }

// // //   Future<List<UserRequestRow>> _load() async {
// // //     final list = await userRequestsService.listMyRequests();
// // //     // convert dynamic json -> UI rows
// // //     return list.map((j) => UserRequestRow.fromJson(j)).toList();
// // //   }

// // //   void _reload() {
// // //     setState(() => _future = _load());
// // //   }

// // //   String detailsRoute(String id) {
// // //     // ✅ CHANGE THIS if your route differs
// // //     // Example: '/dashboard/user/requests/:id'
// // //     return '/dashboard/user/requests/$id';
// // //   }

// // //   String reportRoute(String id) => '/dashboard/user/requests/$id/report';


// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final w = MediaQuery.sizeOf(context).width;
// // //     final isMobile = w < 900;

// // //     return AppShell(
// // //       title: 'User Dashboard',
// // //       child: Center(
// // //         child: ConstrainedBox(
// // //           constraints: const BoxConstraints(maxWidth: 1100),
// // //           child: FutureBuilder<List<UserRequestRow>>(
// // //             future: _future,
// // //             builder: (context, snap) {
// // //               if (snap.connectionState == ConnectionState.waiting) {
// // //                 return const Padding(
// // //                   padding: EdgeInsets.all(40),
// // //                   child: Center(child: CircularProgressIndicator()),
// // //                 );
// // //               }

// // //               if (snap.hasError) {
// // //                 return Padding(
// // //                   padding: const EdgeInsets.all(18),
// // //                   child: Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                     children: [
// // //                       Text(
// // //                         'Welcome',
// // //                         style: Theme.of(context)
// // //                             .textTheme
// // //                             .headlineSmall
// // //                             ?.copyWith(fontWeight: FontWeight.w900),
// // //                       ),
// // //                       const SizedBox(height: 10),
// // //                       Text('Failed to load your requests: ${snap.error}'),
// // //                       const SizedBox(height: 12),
// // //                       FilledButton.icon(
// // //                         onPressed: _reload,
// // //                         icon: const Icon(Icons.refresh),
// // //                         label: const Text('Retry'),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 );
// // //               }

// // //               final all = (snap.data ?? []);

// // //               // search filter
// // //               final q = _searchCtrl.text.trim().toLowerCase();
// // //               final filtered = q.isEmpty
// // //                   ? all
// // //                   : all.where((r) {
// // //                       final s = [
// // //                         r.requestId,
// // //                         r.id,
// // //                         r.requestType,
// // //                         r.status,
// // //                         r.city,
// // //                         r.make,
// // //                         r.model,
// // //                         r.licensePlate,
// // //                       ].join(' ').toLowerCase();
// // //                       return s.contains(q);
// // //                     }).toList();

// // //               final active = filtered.where((r) => r.isActive).toList();
// // //               final history = filtered.where((r) => !r.isActive).toList();

// // //               return ListView(
// // //                 padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
// // //                 children: [
// // //                   Row(
// // //                     children: [
// // //                       Expanded(
// // //                         child: Text(
// // //                           'Welcome',
// // //                           style: Theme.of(context)
// // //                               .textTheme
// // //                               .headlineSmall
// // //                               ?.copyWith(fontWeight: FontWeight.w900),
// // //                         ),
// // //                       ),
// // //                       IconButton(
// // //                         tooltip: 'Refresh',
// // //                         onPressed: _reload,
// // //                         icon: const Icon(Icons.refresh),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                   const SizedBox(height: 6),
// // //                   const Text(
// // //                     'Your inspection / valuation requests',
// // //                     style: TextStyle(color: Colors.black54),
// // //                   ),
// // //                   const SizedBox(height: 14),

// // //                   Card(
// // //                     child: Padding(
// // //                       padding: const EdgeInsets.all(14),
// // //                       child: Column(
// // //                         children: [
// // //                           TextField(
// // //                             controller: _searchCtrl,
// // //                             onChanged: (_) => setState(() {}),
// // //                             decoration: InputDecoration(
// // //                               prefixIcon: const Icon(Icons.search),
// // //                               hintText: 'Search by id / car / city / status...',
// // //                               border: OutlineInputBorder(
// // //                                 borderRadius: BorderRadius.circular(12),
// // //                               ),
// // //                             ),
// // //                           ),
// // //                           const SizedBox(height: 12),

// // //                           if (filtered.isEmpty)
// // //                             const Padding(
// // //                               padding: EdgeInsets.all(30),
// // //                               child: Text('No requests found.'),
// // //                             )
// // //                           else ...[
// // //                             _SectionHeader(
// // //                               title: 'Active Requests',
// // //                               count: active.length,
// // //                             ),
// // //                             const SizedBox(height: 8),
// // //                             if (active.isEmpty)
// // //                               const _EmptyHint('No active requests.')
// // //                             else
// // //                               ...active.map((r) => _UserRequestCard(
// // //                                     r: r,
// // //                                     compact: isMobile,
// // //                                     onView: () => context.go(r.isCompleted ? reportRoute(r.id) : detailsRoute(r.id)),
// // //                                     buttonText: r.isCompleted ? 'View Report' : 'View Details',
// // //                                   )),

// // //                             const SizedBox(height: 14),
// // //                             const Divider(height: 18),

// // //                             _SectionHeader(
// // //                               title: 'History',
// // //                               count: history.length,
// // //                             ),
// // //                             const SizedBox(height: 8),
// // //                             if (history.isEmpty)
// // //                               const _EmptyHint('No completed/cancelled requests.')
// // //                             else
// // //                               ...history.map((r) => _UserRequestCard(
// // //                                     r: r,
// // //                                     compact: isMobile,
// // //                                     onView: () => context.go(r.isCompleted ? reportRoute(r.id) : detailsRoute(r.id)),
// // //                                     buttonText: r.isCompleted ? 'View Report' : 'View Details',
// // //                                   )),
// // //                           ],
// // //                         ],
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ],
// // //               );
// // //             },
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // /* =========================
// // //    UI Model
// // // ========================= */

// // // class UserRequestRow {
// // //   final String id; // backend "id" or "_id"
// // //   final String requestId; // "Req-001" (optional)
// // //   final String requestType; // car inspection / valuation
// // //   final String status; // pending/assigned/completed/cancelled...
// // //   final DateTime createdAt;

// // //   final String make;
// // //   final String model;
// // //   final int? year;
// // //   final String licensePlate;
// // //   final String city;

// // //   UserRequestRow({
// // //     required this.id,
// // //     required this.requestId,
// // //     required this.requestType,
// // //     required this.status,
// // //     required this.createdAt,
// // //     required this.make,
// // //     required this.model,
// // //     required this.year,
// // //     required this.licensePlate,
// // //     required this.city,
// // //   });

// // //   bool get isActive {
// // //     final s = status.toLowerCase();
// // //     // treat these as "active"
// // //     if (s.contains('pending')) return true;
// // //     if (s.contains('assigned')) return true;
// // //     if (s.contains('in_progress')) return true;
// // //     if (s.contains('in progress')) return true;
// // //     // treat others as history
// // //     return false;
// // //   }
// // //   bool get isCompleted => status.toLowerCase().trim() == 'completed';

// // //   factory UserRequestRow.fromJson(Map<String, dynamic> j) {
// // //     // API sometimes: data.request (single), data.requests (list), etc.
// // //     final vehicle = (j['vehicleInfo'] is Map<String, dynamic>) ? (j['vehicleInfo'] as Map<String, dynamic>) : const <String, dynamic>{};
// // //     final loc = (j['location'] is Map<String, dynamic>) ? (j['location'] as Map<String, dynamic>) : const <String, dynamic>{};

// // //     return UserRequestRow(
// // //       id: (j['id'] ?? j['_id'] ?? '').toString(),
// // //       requestId: (j['requestId'] ?? '').toString(),
// // //       requestType: (j['requestType'] ?? j['inspectionType'] ?? 'inspection').toString(),
// // //       status: (j['status'] ?? 'pending').toString(),
// // //       createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ?? DateTime.now(),
// // //       make: (vehicle['make'] ?? '-').toString(),
// // //       model: (vehicle['model'] ?? '-').toString(),
// // //       year: (vehicle['year'] is num) ? (vehicle['year'] as num).toInt() : int.tryParse('${vehicle['year']}'),
// // //       licensePlate: (vehicle['licensePlate'] ?? '-').toString(),
// // //       city: (loc['city'] ?? '-').toString(),
// // //     );
// // //   }
// // // }

// // // /* =========================
// // //    Widgets
// // // ========================= */

// // // class _SectionHeader extends StatelessWidget {
// // //   final String title;
// // //   final int count;

// // //   const _SectionHeader({required this.title, required this.count});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Row(
// // //       children: [
// // //         Expanded(
// // //           child: Text(
// // //             title,
// // //             style: const TextStyle(fontWeight: FontWeight.w900),
// // //           ),
// // //         ),
// // //         Container(
// // //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
// // //           decoration: BoxDecoration(
// // //             color: Colors.black.withOpacity(0.06),
// // //             borderRadius: BorderRadius.circular(999),
// // //           ),
// // //           child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w800)),
// // //         )
// // //       ],
// // //     );
// // //   }
// // // }

// // // class _EmptyHint extends StatelessWidget {
// // //   final String text;
// // //   const _EmptyHint(this.text);

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Padding(
// // //       padding: const EdgeInsets.symmetric(vertical: 12),
// // //       child: Align(
// // //         alignment: Alignment.centerLeft,
// // //         child: Text(text, style: const TextStyle(color: Colors.black54)),
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _UserRequestCard extends StatelessWidget {
// // //   final UserRequestRow r;
// // //   final bool compact;
// // //   final VoidCallback onView;
// // //   final String buttonText;

// // //   const _UserRequestCard({
// // //     required this.r,
// // //     required this.compact,
// // //     required this.onView,
// // //     required this.buttonText,
// // //   });

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final pending = r.status.toLowerCase().contains('pending');
// // //     final assigned = r.status.toLowerCase().contains('assigned');
// // //     final active = r.isActive;

// // //     final chipBg = pending
// // //         ? Colors.orange.withOpacity(0.12)
// // //         : assigned
// // //             ? Colors.blue.withOpacity(0.12)
// // //             : active
// // //                 ? Colors.blue.withOpacity(0.12)
// // //                 : Colors.green.withOpacity(0.12);

// // //     final chipBorder = pending
// // //         ? Colors.orange.withOpacity(0.20)
// // //         : assigned
// // //             ? Colors.blue.withOpacity(0.20)
// // //             : active
// // //                 ? Colors.blue.withOpacity(0.20)
// // //                 : Colors.green.withOpacity(0.20);

// // //     final chipText = r.status;

// // //     final title = [
// // //       if (r.requestId.isNotEmpty) r.requestId,
// // //       r.requestType,
// // //     ].join(' • ');

// // //     final carLine = '${r.make} ${r.model}${r.year == null ? '' : ' (${r.year})'}';
// // //     final sub = '${r.city} • ${r.licensePlate} • ${_fmtDate(r.createdAt)}';

    
// // //     return Padding(
// // //       padding: const EdgeInsets.only(bottom: 10),
// // //       child: Card(
// // //         elevation: 0,
// // //         color: Colors.black.withOpacity(0.02),
// // //         child: Padding(
// // //           padding: const EdgeInsets.all(12),
// // //           child: Column(
// // //             children: [
// // //               ListTile(
// // //                 contentPadding: EdgeInsets.zero,
// // //                 leading: CircleAvatar(
// // //                   backgroundColor: const Color(0xFF1E5EFF).withOpacity(0.10),
// // //                   foregroundColor: const Color(0xFF1E5EFF),
// // //                   child: Icon(active ? Icons.assignment_outlined : Icons.check_circle_outline),
// // //                 ),
// // //                 title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
// // //                 subtitle: Text('$carLine\n$sub'),
// // //                 isThreeLine: true,
// // //                 trailing: Chip(
// // //                   label: Text(chipText),
// // //                   backgroundColor: chipBg,
// // //                   side: BorderSide(color: chipBorder),
// // //                 ),
// // //               ),
// // //               const SizedBox(height: 8),
// // //               Align(
// // //                 alignment: Alignment.centerLeft,
// // //                 child: FilledButton.tonal(
// // //                   onPressed: onView,
// // //                   child: const Text('View Details'),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   static String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
// // // }

// // // lib/features/dashboards/user/user_dashboard_page.dart
// // //
// // // IMPORTANT (router):
// // // This file navigates completed requests to:
// // //   /dashboard/user/inspections/:inspectionId/report
// // // So make sure you have a GoRoute for that path in your go_router config,
// // // and render the SAME report page widget you use for admin.

// // import 'package:flutter/material.dart';
// // import 'package:go_router/go_router.dart';

// // import '../../shared/app_shell.dart';
// // import '../../../services/service_locator.dart';

// // class UserDashboardPage extends StatefulWidget {
// //   const UserDashboardPage({super.key});

// //   @override
// //   State<UserDashboardPage> createState() => _UserDashboardPageState();
// // }

// // class _UserDashboardPageState extends State<UserDashboardPage> {
// //   late Future<List<UserRequestRow>> _future;
// //   final _searchCtrl = TextEditingController();

// //   @override
// //   void initState() {
// //     super.initState();
// //     _future = _load();
// //   }

// //   @override
// //   void dispose() {
// //     _searchCtrl.dispose();
// //     super.dispose();
// //   }

// //   Future<List<UserRequestRow>> _load() async {
// //     final list = await userRequestsService.listMyRequests();

// //     if (list is! List) return <UserRequestRow>[];

// //     return list
// //         .whereType<Map>()
// //         .map((x) => UserRequestRow.fromJson(Map<String, dynamic>.from(x)))
// //         .toList();
// //   }

// //   void _reload() => setState(() => _future = _load());

// //   String detailsRoute(String requestMongoId) => '/dashboard/user/requests/$requestMongoId';

// //   // ✅ Completed report must use INSPECTION ID (same as admin)
// //   String reportRoute(String inspectionId) => '/dashboard/user/inspections/$inspectionId/report';

// //   void _openRequest(UserRequestRow r) {
// //     if (r.isCompleted) {
// //       final inspId = (r.inspectionId ?? '').trim();
// //       if (inspId.isEmpty) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text('Inspection report not available yet.')),
// //         );
// //         return;
// //       }
// //       context.go(reportRoute(inspId));
// //       return;
// //     }

// //     context.go(detailsRoute(r.id));
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final w = MediaQuery.sizeOf(context).width;
// //     final isMobile = w < 900;

// //     return AppShell(
// //       title: 'User Dashboard',
// //       child: Center(
// //         child: ConstrainedBox(
// //           constraints: const BoxConstraints(maxWidth: 1100),
// //           child: FutureBuilder<List<UserRequestRow>>(
// //             future: _future,
// //             builder: (context, snap) {
// //               if (snap.connectionState == ConnectionState.waiting) {
// //                 return const Padding(
// //                   padding: EdgeInsets.all(40),
// //                   child: Center(child: CircularProgressIndicator()),
// //                 );
// //               }

// //               if (snap.hasError) {
// //                 return Padding(
// //                   padding: const EdgeInsets.all(18),
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         'Welcome',
// //                         style: Theme.of(context).textTheme.headlineSmall?.copyWith(
// //                               fontWeight: FontWeight.w900,
// //                             ),
// //                       ),
// //                       const SizedBox(height: 10),
// //                       Text('Failed to load your requests: ${snap.error}'),
// //                       const SizedBox(height: 12),
// //                       FilledButton.icon(
// //                         onPressed: _reload,
// //                         icon: const Icon(Icons.refresh),
// //                         label: const Text('Retry'),
// //                       ),
// //                     ],
// //                   ),
// //                 );
// //               }

// //               final all = (snap.data ?? []);

// //               final q = _searchCtrl.text.trim().toLowerCase();
// //               final filtered = q.isEmpty
// //                   ? all
// //                   : all.where((r) {
// //                       final s = [
// //                         r.requestId,
// //                         r.id,
// //                         r.requestType,
// //                         r.status,
// //                         r.city,
// //                         r.make,
// //                         r.model,
// //                         r.licensePlate,
// //                       ].join(' ').toLowerCase();
// //                       return s.contains(q);
// //                     }).toList();

// //               final active = filtered.where((r) => r.isActive).toList();
// //               final history = filtered.where((r) => !r.isActive).toList();

// //               return ListView(
// //                 padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
// //                 children: [
// //                   Row(
// //                     children: [
// //                       Expanded(
// //                         child: Text(
// //                           'Welcome',
// //                           style: Theme.of(context).textTheme.headlineSmall?.copyWith(
// //                                 fontWeight: FontWeight.w900,
// //                               ),
// //                         ),
// //                       ),
// //                       IconButton(
// //                         tooltip: 'Refresh',
// //                         onPressed: _reload,
// //                         icon: const Icon(Icons.refresh),
// //                       ),
// //                     ],
// //                   ),
// //                   const SizedBox(height: 6),
// //                   const Text(
// //                     'Your inspection / valuation requests',
// //                     style: TextStyle(color: Colors.black54),
// //                   ),
// //                   const SizedBox(height: 14),

// //                   Card(
// //                     child: Padding(
// //                       padding: const EdgeInsets.all(14),
// //                       child: Column(
// //                         children: [
// //                           TextField(
// //                             controller: _searchCtrl,
// //                             onChanged: (_) => setState(() {}),
// //                             decoration: InputDecoration(
// //                               prefixIcon: const Icon(Icons.search),
// //                               hintText: 'Search by id / car / city / status...',
// //                               border: OutlineInputBorder(
// //                                 borderRadius: BorderRadius.circular(12),
// //                               ),
// //                             ),
// //                           ),
// //                           const SizedBox(height: 12),

// //                           if (filtered.isEmpty)
// //                             const Padding(
// //                               padding: EdgeInsets.all(30),
// //                               child: Text('No requests found.'),
// //                             )
// //                           else ...[
// //                             _SectionHeader(title: 'Active Requests', count: active.length),
// //                             const SizedBox(height: 8),
// //                             if (active.isEmpty)
// //                               const _EmptyHint('No active requests.')
// //                             else
// //                               ...active.map(
// //                                 (r) => _UserRequestCard(
// //                                   r: r,
// //                                   compact: isMobile,
// //                                   onView: () => _openRequest(r),
// //                                   buttonText: r.isCompleted ? 'View Report' : 'View Details',
// //                                 ),
// //                               ),

// //                             const SizedBox(height: 14),
// //                             const Divider(height: 18),

// //                             _SectionHeader(title: 'History', count: history.length),
// //                             const SizedBox(height: 8),
// //                             if (history.isEmpty)
// //                               const _EmptyHint('No completed/cancelled requests.')
// //                             else
// //                               ...history.map(
// //                                 (r) => _UserRequestCard(
// //                                   r: r,
// //                                   compact: isMobile,
// //                                   onView: () => _openRequest(r),
// //                                   buttonText: r.isCompleted ? 'View Report' : 'View Details',
// //                                 ),
// //                               ),
// //                           ],
// //                         ],
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               );
// //             },
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // /* =========================
// //    UI Model
// // ========================= */

// // class UserRequestRow {
// //   final String id; // request _id
// //   final String requestId; // Req-001 (optional)
// //   final String requestType;
// //   final String status;
// //   final DateTime createdAt;

// //   final String make;
// //   final String model;
// //   final int? year;
// //   final String licensePlate;
// //   final String city;

// //   // ✅ IMPORTANT: report opens by INSPECTION ID, not request id
// //   final String? inspectionId;

// //   UserRequestRow({
// //     required this.id,
// //     required this.requestId,
// //     required this.requestType,
// //     required this.status,
// //     required this.createdAt,
// //     required this.make,
// //     required this.model,
// //     required this.year,
// //     required this.licensePlate,
// //     required this.city,
// //     this.inspectionId,
// //   });

// //   bool get isActive {
// //     final s = status.toLowerCase();
// //     if (s.contains('pending')) return true;
// //     if (s.contains('assigned')) return true;
// //     if (s.contains('in_progress') || s.contains('in progress') || s.contains('inprogress')) return true;
// //     return false;
// //   }

// //   bool get isCompleted => status.toLowerCase().trim() == 'completed';

// //   factory UserRequestRow.fromJson(Map<String, dynamic> j) {
// //     final vehicle = (j['vehicleInfo'] is Map) ? Map<String, dynamic>.from(j['vehicleInfo']) : const <String, dynamic>{};
// //     final loc = (j['location'] is Map) ? Map<String, dynamic>.from(j['location']) : const <String, dynamic>{};

// //     // ✅ Parse inspectionId safely: null / string / object
// //     String? inspectionId;
// //     final rawInspection = j['inspectionId'];
// //     if (rawInspection is String && rawInspection.trim().isNotEmpty && rawInspection != 'null') {
// //       inspectionId = rawInspection.trim();
// //     } else if (rawInspection is Map) {
// //       final m = Map<String, dynamic>.from(rawInspection);
// //       final id = (m['_id'] ?? m['id'] ?? '').toString().trim();
// //       if (id.isNotEmpty) inspectionId = id;
// //     } else {
// //       final s = (rawInspection ?? '').toString().trim();
// //       if (s.isNotEmpty && s != 'null') inspectionId = s;
// //     }

// //     return UserRequestRow(
// //       id: (j['id'] ?? j['_id'] ?? '').toString(),
// //       requestId: (j['requestId'] ?? '').toString(),
// //       requestType: (j['requestType'] ?? j['inspectionType'] ?? 'inspection').toString(),
// //       status: (j['status'] ?? 'pending').toString(),
// //       createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ?? DateTime.now(),
// //       make: (vehicle['make'] ?? '-').toString(),
// //       model: (vehicle['model'] ?? '-').toString(),
// //       year: (vehicle['year'] is num) ? (vehicle['year'] as num).toInt() : int.tryParse('${vehicle['year']}'),
// //       licensePlate: (vehicle['licensePlate'] ?? '-').toString(),
// //       city: (loc['city'] ?? '-').toString(),
// //       inspectionId: inspectionId,
// //     );
// //   }
// // }

// // /* =========================
// //    Widgets
// // ========================= */

// // class _SectionHeader extends StatelessWidget {
// //   final String title;
// //   final int count;

// //   const _SectionHeader({required this.title, required this.count});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Row(
// //       children: [
// //         Expanded(
// //           child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
// //         ),
// //         Container(
// //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
// //           decoration: BoxDecoration(
// //             color: Colors.black.withOpacity(0.06),
// //             borderRadius: BorderRadius.circular(999),
// //           ),
// //           child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w800)),
// //         )
// //       ],
// //     );
// //   }
// // }

// // class _EmptyHint extends StatelessWidget {
// //   final String text;
// //   const _EmptyHint(this.text);

// //   @override
// //   Widget build(BuildContext context) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 12),
// //       child: Align(
// //         alignment: Alignment.centerLeft,
// //         child: Text(text, style: const TextStyle(color: Colors.black54)),
// //       ),
// //     );
// //   }
// // }

// // class _UserRequestCard extends StatelessWidget {
// //   final UserRequestRow r;
// //   final bool compact;
// //   final VoidCallback onView;
// //   final String buttonText;

// //   const _UserRequestCard({
// //     required this.r,
// //     required this.compact,
// //     required this.onView,
// //     required this.buttonText,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     final s = r.status.toLowerCase();
// //     final pending = s.contains('pending');
// //     final assigned = s.contains('assigned');
// //     final completed = r.isCompleted;

// //     final chipBg = completed
// //         ? Colors.green.withOpacity(0.12)
// //         : pending
// //             ? Colors.orange.withOpacity(0.12)
// //             : assigned
// //                 ? Colors.blue.withOpacity(0.12)
// //                 : Colors.blue.withOpacity(0.12);

// //     final chipBorder = completed
// //         ? Colors.green.withOpacity(0.20)
// //         : pending
// //             ? Colors.orange.withOpacity(0.20)
// //             : assigned
// //                 ? Colors.blue.withOpacity(0.20)
// //                 : Colors.blue.withOpacity(0.20);

// //     final title = [
// //       if (r.requestId.isNotEmpty) r.requestId,
// //       r.requestType,
// //     ].join(' • ');

// //     final carLine = '${r.make} ${r.model}${r.year == null ? '' : ' (${r.year})'}';
// //     final sub = '${r.city} • ${r.licensePlate} • ${_fmtDate(r.createdAt)}';

// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 10),
// //       child: Card(
// //         elevation: 0,
// //         color: Colors.black.withOpacity(0.02),
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// //         child: Padding(
// //           padding: const EdgeInsets.all(12),
// //           child: Column(
// //             children: [
// //               ListTile(
// //                 contentPadding: EdgeInsets.zero,
// //                 leading: CircleAvatar(
// //                   backgroundColor: const Color(0xFF1E5EFF).withOpacity(0.10),
// //                   foregroundColor: const Color(0xFF1E5EFF),
// //                   child: Icon(r.isActive ? Icons.assignment_outlined : Icons.check_circle_outline),
// //                 ),
// //                 title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
// //                 subtitle: Text('$carLine\n$sub'),
// //                 isThreeLine: true,
// //                 trailing: Chip(
// //                   label: Text(r.status),
// //                   backgroundColor: chipBg,
// //                   side: BorderSide(color: chipBorder),
// //                 ),
// //               ),
// //               const SizedBox(height: 8),
// //               Align(
// //                 alignment: Alignment.centerLeft,
// //                 child: FilledButton.tonal(
// //                   onPressed: onView,
// //                   child: Text(buttonText), // ✅ use passed text
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   static String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
// // }

// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// import '../../shared/app_shell.dart';
// import '../../../services/service_locator.dart';

// class UserDashboardPage extends StatefulWidget {
//   const UserDashboardPage({super.key});

//   @override
//   State<UserDashboardPage> createState() => _UserDashboardPageState();
// }

// class _UserDashboardPageState extends State<UserDashboardPage> {
//   late Future<List<UserRequestRow>> _future;
//   final _searchCtrl = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _future = _load();
//   }

//   @override
//   void dispose() {
//     _searchCtrl.dispose();
//     super.dispose();
//   }

//   Future<List<UserRequestRow>> _load() async {
//     final raw = await userRequestsService.listMyRequests();

//     // Safer mapping (handles dynamic payloads)
//     return raw
//         .whereType<Map>()
//         .map((m) => UserRequestRow.fromJson(Map<String, dynamic>.from(m)))
//         .toList();
//   }

//   void _reload() {
//     setState(() => _future = _load());
//   }

//   // Your existing details route (request id)
//   String detailsRoute(String requestId) => '/dashboard/user/requests/$requestId';

//   // ✅ MUST match your GoRoute:
//   // GoRoute(path: '/dashboard/user/inspections/:inspectionId/report', ...)
//   String reportRoute(String inspectionId) =>
//       '/dashboard/user/inspections/$inspectionId/report';

//   /// ✅ Single place to open either Details or Report
//   /// - If not completed -> open request details
//   /// - If completed -> open report by inspectionId (fetch it if list response didn't include it)
//   Future<void> _openRequest(UserRequestRow r) async {
//     if (!r.isCompleted) {
//       context.go(detailsRoute(r.id));
//       return;
//     }

//     String inspId = (r.inspectionId ?? '').trim();

//     // If inspectionId is missing in list response, fetch request once to get it
//     bool dialogOpen = false;
//     if (inspId.isEmpty) {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => const Center(child: CircularProgressIndicator()),
//       );
//       dialogOpen = true;

//       try {
//         final full = await userRequestsService.getRequestById(r.id);

//         // inspectionId may be string or object depending on backend
//         final raw = full['inspectionId'];
//         if (raw is String) {
//           inspId = raw.trim();
//         } else if (raw is Map) {
//           final mm = Map<String, dynamic>.from(raw);
//           inspId = (mm['_id'] ?? mm['id'] ?? '').toString().trim();
//         } else {
//           inspId = (raw ?? '').toString().trim();
//         }
//       } catch (_) {
//         // handled below
//       } finally {
//         if (mounted && dialogOpen) {
//           final nav = Navigator.of(context, rootNavigator: true);
//           if (nav.canPop()) nav.pop();
//         }
//       }
//     }

//     if (inspId.isEmpty) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Inspection report not available yet.')),
//       );
//       return;
//     }

//     context.go(reportRoute(inspId));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final w = MediaQuery.sizeOf(context).width;
//     final isMobile = w < 900;

//     return AppShell(
//       title: 'User Dashboard',
//       child: Center(
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 1100),
//           child: FutureBuilder<List<UserRequestRow>>(
//             future: _future,
//             builder: (context, snap) {
//               if (snap.connectionState == ConnectionState.waiting) {
//                 return const Padding(
//                   padding: EdgeInsets.all(40),
//                   child: Center(child: CircularProgressIndicator()),
//                 );
//               }

//               if (snap.hasError) {
//                 return Padding(
//                   padding: const EdgeInsets.all(18),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Welcome',
//                         style: Theme.of(context)
//                             .textTheme
//                             .headlineSmall
//                             ?.copyWith(fontWeight: FontWeight.w900),
//                       ),
//                       const SizedBox(height: 10),
//                       Text('Failed to load your requests: ${snap.error}'),
//                       const SizedBox(height: 12),
//                       FilledButton.icon(
//                         onPressed: _reload,
//                         icon: const Icon(Icons.refresh),
//                         label: const Text('Retry'),
//                       ),
//                     ],
//                   ),
//                 );
//               }

//               final all = (snap.data ?? []);

//               // search filter
//               final q = _searchCtrl.text.trim().toLowerCase();
//               final filtered = q.isEmpty
//                   ? all
//                   : all.where((r) {
//                       final s = [
//                         r.requestId,
//                         r.id,
//                         r.requestType,
//                         r.status,
//                         r.city,
//                         r.make,
//                         r.model,
//                         r.licensePlate,
//                       ].join(' ').toLowerCase();
//                       return s.contains(q);
//                     }).toList();

//               final active = filtered.where((r) => r.isActive).toList();
//               final history = filtered.where((r) => !r.isActive).toList();

//               return ListView(
//                 padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           'Welcome',
//                           style: Theme.of(context)
//                               .textTheme
//                               .headlineSmall
//                               ?.copyWith(fontWeight: FontWeight.w900),
//                         ),
//                       ),
//                       IconButton(
//                         tooltip: 'Refresh',
//                         onPressed: _reload,
//                         icon: const Icon(Icons.refresh),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 6),
//                   const Text(
//                     'Your inspection / valuation requests',
//                     style: TextStyle(color: Colors.black54),
//                   ),
//                   const SizedBox(height: 14),

//                   Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(14),
//                       child: Column(
//                         children: [
//                           TextField(
//                             controller: _searchCtrl,
//                             onChanged: (_) => setState(() {}),
//                             decoration: InputDecoration(
//                               prefixIcon: const Icon(Icons.search),
//                               hintText: 'Search by id / car / city / status...',
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 12),

//                           if (filtered.isEmpty)
//                             const Padding(
//                               padding: EdgeInsets.all(30),
//                               child: Text('No requests found.'),
//                             )
//                           else ...[
//                             _SectionHeader(
//                               title: 'Active Requests',
//                               count: active.length,
//                             ),
//                             const SizedBox(height: 8),
//                             if (active.isEmpty)
//                               const _EmptyHint('No active requests.')
//                             else
//                               ...active.map(
//                                 (r) => _UserRequestCard(
//                                   r: r,
//                                   compact: isMobile,
//                                   onView: () => _openRequest(r),
//                                   buttonText:
//                                       r.isCompleted ? 'View Report' : 'View Details',
//                                 ),
//                               ),

//                             const SizedBox(height: 14),
//                             const Divider(height: 18),

//                             _SectionHeader(
//                               title: 'History',
//                               count: history.length,
//                             ),
//                             const SizedBox(height: 8),
//                             if (history.isEmpty)
//                               const _EmptyHint(
//                                   'No completed/cancelled requests.')
//                             else
//                               ...history.map(
//                                 (r) => _UserRequestCard(
//                                   r: r,
//                                   compact: isMobile,
//                                   onView: () => _openRequest(r),
//                                   buttonText:
//                                       r.isCompleted ? 'View Report' : 'View Details',
//                                 ),
//                               ),
//                           ],
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }

// /* =========================
//    UI Model
// ========================= */

// class UserRequestRow {
//   final String id; // backend "id" or "_id"
//   final String requestId; // "Req-001"
//   final String requestType; // car inspection / valuation
//   final String status; // pending/assigned/completed/cancelled...
//   final DateTime createdAt;

//   // ✅ IMPORTANT for report navigation
//   final String? inspectionId; // might be null in list API

//   final String make;
//   final String model;
//   final int? year;
//   final String licensePlate;
//   final String city;

//   UserRequestRow({
//     required this.id,
//     required this.requestId,
//     required this.requestType,
//     required this.status,
//     required this.createdAt,
//     required this.make,
//     required this.model,
//     required this.year,
//     required this.licensePlate,
//     required this.city,
//     this.inspectionId,
//   });

//   bool get isActive {
//     final s = status.toLowerCase();
//     if (s.contains('pending')) return true;
//     if (s.contains('assigned')) return true;
//     if (s.contains('in_progress')) return true;
//     if (s.contains('in progress')) return true;
//     return false;
//   }

//   bool get isCompleted => status.toLowerCase().trim() == 'completed';

//   factory UserRequestRow.fromJson(Map<String, dynamic> j) {
//     final vehicle = (j['vehicleInfo'] is Map)
//         ? Map<String, dynamic>.from(j['vehicleInfo'] as Map)
//         : const <String, dynamic>{};
//     final loc = (j['location'] is Map)
//         ? Map<String, dynamic>.from(j['location'] as Map)
//         : const <String, dynamic>{};

//     // inspectionId can be null/string/object depending on backend
//     String? inspectionId;
//     final inspRaw = j['inspectionId'];
//     if (inspRaw is String) {
//       inspectionId = inspRaw.trim();
//     } else if (inspRaw is Map) {
//       final m = Map<String, dynamic>.from(inspRaw);
//       inspectionId = (m['_id'] ?? m['id'] ?? '').toString().trim();
//     } else if (inspRaw != null) {
//       inspectionId = inspRaw.toString().trim();
//     }
//     if (inspectionId != null && inspectionId!.isEmpty) inspectionId = null;

//     return UserRequestRow(
//       id: (j['id'] ?? j['_id'] ?? '').toString(),
//       requestId: (j['requestId'] ?? '').toString(),
//       requestType:
//           (j['requestType'] ?? j['inspectionType'] ?? 'inspection').toString(),
//       status: (j['status'] ?? 'pending').toString(),
//       createdAt:
//           DateTime.tryParse((j['createdAt'] ?? '').toString()) ?? DateTime.now(),
//       inspectionId: inspectionId,
//       make: (vehicle['make'] ?? '-').toString(),
//       model: (vehicle['model'] ?? '-').toString(),
//       year: (vehicle['year'] is num)
//           ? (vehicle['year'] as num).toInt()
//           : int.tryParse('${vehicle['year']}'),
//       licensePlate: (vehicle['licensePlate'] ?? '-').toString(),
//       city: (loc['city'] ?? '-').toString(),
//     );
//   }
// }

// /* =========================
//    Widgets
// ========================= */

// class _SectionHeader extends StatelessWidget {
//   final String title;
//   final int count;

//   const _SectionHeader({required this.title, required this.count});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: Text(
//             title,
//             style: const TextStyle(fontWeight: FontWeight.w900),
//           ),
//         ),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//           decoration: BoxDecoration(
//             color: Colors.black.withOpacity(0.06),
//             borderRadius: BorderRadius.circular(999),
//           ),
//           child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w800)),
//         )
//       ],
//     );
//   }
// }

// class _EmptyHint extends StatelessWidget {
//   final String text;
//   const _EmptyHint(this.text);

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Align(
//         alignment: Alignment.centerLeft,
//         child: Text(text, style: const TextStyle(color: Colors.black54)),
//       ),
//     );
//   }
// }

// class _UserRequestCard extends StatelessWidget {
//   final UserRequestRow r;
//   final bool compact;
//   final VoidCallback onView;
//   final String buttonText;

//   const _UserRequestCard({
//     required this.r,
//     required this.compact,
//     required this.onView,
//     required this.buttonText,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final s = r.status.toLowerCase();
//     final pending = s.contains('pending');
//     final assigned = s.contains('assigned');
//     final active = r.isActive;

//     final chipBg = pending
//         ? Colors.orange.withOpacity(0.12)
//         : assigned
//             ? Colors.blue.withOpacity(0.12)
//             : active
//                 ? Colors.blue.withOpacity(0.12)
//                 : Colors.green.withOpacity(0.12);

//     final chipBorder = pending
//         ? Colors.orange.withOpacity(0.20)
//         : assigned
//             ? Colors.blue.withOpacity(0.20)
//             : active
//                 ? Colors.blue.withOpacity(0.20)
//                 : Colors.green.withOpacity(0.20);

//     final title = [
//       if (r.requestId.isNotEmpty) r.requestId,
//       r.requestType,
//     ].join(' • ');

//     final carLine =
//         '${r.make} ${r.model}${r.year == null ? '' : ' (${r.year})'}';
//     final sub = '${r.city} • ${r.licensePlate} • ${_fmtDate(r.createdAt)}';

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Card(
//         elevation: 0,
//         color: Colors.black.withOpacity(0.02),
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             children: [
//               ListTile(
//                 contentPadding: EdgeInsets.zero,
//                 leading: CircleAvatar(
//                   backgroundColor: const Color(0xFF1E5EFF).withOpacity(0.10),
//                   foregroundColor: const Color(0xFF1E5EFF),
//                   child: Icon(active
//                       ? Icons.assignment_outlined
//                       : Icons.check_circle_outline),
//                 ),
//                 title: Text(title,
//                     style: const TextStyle(fontWeight: FontWeight.w900)),
//                 subtitle: Text('$carLine\n$sub'),
//                 isThreeLine: true,
//                 trailing: Chip(
//                   label: Text(r.status),
//                   backgroundColor: chipBg,
//                   side: BorderSide(color: chipBorder),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Align(
//                 alignment: Alignment.centerLeft,
//                 child: FilledButton.tonal(
//                   onPressed: onView,
//                   child: Text(buttonText), // ✅ fixed
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   static String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
// }


// lib/features/dashboards/user/user_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/app_shell.dart';
import '../../../services/service_locator.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  late Future<List<UserRequestRow>> _future;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<UserRequestRow>> _load() async {
    final raw = await userRequestsService.listMyRequests();

    if (raw is! List) return <UserRequestRow>[];

    return raw
        .whereType<Map>()
        .map((m) => UserRequestRow.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  void _reload() => setState(() => _future = _load());

  // request details (requestId)
  String detailsRoute(String requestId) => '/dashboard/user/requests/$requestId';

  // ✅ MUST match your GoRoute:
  // GoRoute(path: '/dashboard/user/inspections/:inspectionId/report', ...)
  String reportRoute(String inspectionId) =>
      '/dashboard/user/inspections/$inspectionId/report';

  Future<void> _open(UserRequestRow r) async {
    if (!r.isCompleted) {
      context.go(detailsRoute(r.id));
      return;
    }

    // Completed -> open report by inspectionId
    String inspId = (r.inspectionId ?? '').trim();

    // If list API didn't return inspectionId, fetch the request once
    if (inspId.isEmpty) {
      // quick loader
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      try {
        final full = await userRequestsService.getRequestById(r.id);

        final raw = full['inspectionId'] ?? full['inspection'] ?? full['inspectionSummary']?['inspectionId'];

        if (raw is String) {
          inspId = raw.trim();
        } else if (raw is Map) {
          final mm = Map<String, dynamic>.from(raw);
          inspId = (mm['_id'] ?? mm['id'] ?? '').toString().trim();
        } else {
          inspId = (raw ?? '').toString().trim();
        }
      } catch (e) {
        // ignore; handled below
      } finally {
        if (mounted) {
          final nav = Navigator.of(context, rootNavigator: true);
          if (nav.canPop()) nav.pop();
        }
      }
    }

    if (inspId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inspection report not available yet.')),
      );
      return;
    }

    context.go(reportRoute(inspId));
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 900;

    return AppShell(
      title: 'User Dashboard',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: FutureBuilder<List<UserRequestRow>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Text('Failed to load your requests: ${snap.error}'),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final all = (snap.data ?? []);

              final q = _searchCtrl.text.trim().toLowerCase();
              final filtered = q.isEmpty
                  ? all
                  : all.where((r) {
                      final s = [
                        r.requestId,
                        r.id,
                        r.requestType,
                        r.status,
                        r.city,
                        r.make,
                        r.model,
                        r.licensePlate,
                        r.inspectionId ?? '',
                      ].join(' ').toLowerCase();
                      return s.contains(q);
                    }).toList();

              final active = filtered.where((r) => r.isActive).toList();
              final history = filtered.where((r) => !r.isActive).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Welcome',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your inspection / valuation requests',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 14),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: 'Search by id / car / city / status...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (filtered.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(30),
                              child: Text('No requests found.'),
                            )
                          else ...[
                            _SectionHeader(title: 'Active Requests', count: active.length),
                            const SizedBox(height: 8),
                            if (active.isEmpty)
                              const _EmptyHint('No active requests.')
                            else
                              ...active.map((r) => _UserRequestCard(
                                    r: r,
                                    compact: isMobile,
                                    onView: () => _open(r),
                                    buttonText: r.isCompleted ? 'View Report' : 'View Details',
                                  )),

                            const SizedBox(height: 14),
                            const Divider(height: 18),

                            _SectionHeader(title: 'History', count: history.length),
                            const SizedBox(height: 8),
                            if (history.isEmpty)
                              const _EmptyHint('No completed/cancelled requests.')
                            else
                              ...history.map((r) => _UserRequestCard(
                                    r: r,
                                    compact: isMobile,
                                    onView: () => _open(r),
                                    buttonText: r.isCompleted ? 'View Report' : 'View Details',
                                  )),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/* =========================
   UI Model
========================= */

class UserRequestRow {
  final String id; // request _id
  final String requestId; // Req-001 (optional)
  final String requestType;
  final String status;
  final DateTime createdAt;

  final String make;
  final String model;
  final int? year;
  final String licensePlate;
  final String city;

  // ✅ report is by inspectionId
  final String? inspectionId;

  UserRequestRow({
    required this.id,
    required this.requestId,
    required this.requestType,
    required this.status,
    required this.createdAt,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.city,
    this.inspectionId,
  });

  bool get isCompleted => status.toLowerCase().trim() == 'completed';

  bool get isActive {
    final s = status.toLowerCase().trim();
    if (s == 'pending') return true;
    if (s == 'assigned') return true;
    if (s == 'in_progress' || s == 'inprogress' || s == 'in progress') return true;
    return false;
  }

  factory UserRequestRow.fromJson(Map<String, dynamic> j) {
    final vehicle =
        (j['vehicleInfo'] is Map) ? Map<String, dynamic>.from(j['vehicleInfo']) : const <String, dynamic>{};
    final loc =
        (j['location'] is Map) ? Map<String, dynamic>.from(j['location']) : const <String, dynamic>{};

    // inspectionId can be null/string/object depending on backend
    String? inspectionId;
    final raw = j['inspectionId'] ?? j['inspection']?['_id'] ?? j['inspection']?['id'];
    if (raw is String) {
      inspectionId = raw.trim();
    } else if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      inspectionId = (m['_id'] ?? m['id'] ?? '').toString().trim();
    } else if (raw != null) {
      inspectionId = raw.toString().trim();
    }
    if (inspectionId != null && inspectionId!.isEmpty) inspectionId = null;

    return UserRequestRow(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      requestId: (j['requestId'] ?? '').toString(),
      requestType: (j['requestType'] ?? j['inspectionType'] ?? 'inspection').toString(),
      status: (j['status'] ?? 'pending').toString(),
      createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ?? DateTime.now(),
      make: (vehicle['make'] ?? '-').toString(),
      model: (vehicle['model'] ?? '-').toString(),
      year: (vehicle['year'] is num) ? (vehicle['year'] as num).toInt() : int.tryParse('${vehicle['year']}'),
      licensePlate: (vehicle['licensePlate'] ?? '-').toString(),
      city: (loc['city'] ?? '-').toString(),
      inspectionId: inspectionId,
    );
  }
}

/* =========================
   Widgets
========================= */

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w800)),
        )
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: const TextStyle(color: Colors.black54)),
      ),
    );
  }
}

class _UserRequestCard extends StatelessWidget {
  final UserRequestRow r;
  final bool compact;
  final VoidCallback onView;
  final String buttonText;

  const _UserRequestCard({
    required this.r,
    required this.compact,
    required this.onView,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    final s = r.status.toLowerCase().trim();
    final pending = s.contains('pending');
    final assigned = s.contains('assigned');
    final active = r.isActive;
    final completed = r.isCompleted;

    final chipBg = completed
        ? Colors.green.withOpacity(0.12)
        : pending
            ? Colors.orange.withOpacity(0.12)
            : assigned
                ? Colors.blue.withOpacity(0.12)
                : active
                    ? Colors.blue.withOpacity(0.12)
                    : Colors.grey.withOpacity(0.12);

    final chipBorder = completed
        ? Colors.green.withOpacity(0.20)
        : pending
            ? Colors.orange.withOpacity(0.20)
            : assigned
                ? Colors.blue.withOpacity(0.20)
                : active
                    ? Colors.blue.withOpacity(0.20)
                    : Colors.grey.withOpacity(0.20);

    final title = [
      if (r.requestId.isNotEmpty) r.requestId,
      r.requestType,
    ].join(' • ');

    final carLine = '${r.make} ${r.model}${r.year == null ? '' : ' (${r.year})'}';
    final sub = '${r.city} • ${r.licensePlate} • ${_fmtDate(r.createdAt)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        color: Colors.black.withOpacity(0.02),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1E5EFF).withOpacity(0.10),
                  foregroundColor: const Color(0xFF1E5EFF),
                  child: Icon(active ? Icons.assignment_outlined : Icons.check_circle_outline),
                ),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('$carLine\n$sub'),
                isThreeLine: true,
                trailing: Chip(
                  label: Text(r.status),
                  backgroundColor: chipBg,
                  side: BorderSide(color: chipBorder),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonal(
                  onPressed: onView,
                  child: Text(buttonText), // ✅ NOT const
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
