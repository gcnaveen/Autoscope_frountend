// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// import '../../../shared/app_shell.dart';
// import '../../../../services/service_locator.dart';
// import 'widgets/inspection_request_manage_dialog.dart';

// class InspectionRequestsPage extends StatefulWidget {
//   const InspectionRequestsPage({super.key});

//   @override
//   State<InspectionRequestsPage> createState() => _InspectionRequestsPageState();
// }

// class _InspectionRequestsPageState extends State<InspectionRequestsPage> {
//   late Future<List<_RequestRow>> _future;
//   final _searchCtrl = TextEditingController();
//   int _tick = 0;

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

//   Future<List<_RequestRow>> _load() async {
//     final raw = await inspectionRequestsService.listAdminRequests();
//     return raw
//         .whereType<Map>()
//         .map((x) => _RequestRow.fromJson(Map<String, dynamic>.from(x)))
//         .toList();
//   }

//   void _reload() {
//     setState(() {
//       _tick++;
//       _future = _load();
//     });
//   }

//   Future<void> _openManage(_RequestRow r) async {
//     final ok = await showDialog<bool>(
//       context: context,
//       barrierDismissible: true,
//       builder: (_) => InspectionRequestManageDialog(
//         requestMongoId: r.mongoId,
//         requestDisplayId: r.requestId,
//         status: r.status,
//         assignedInspectorId: r.assignedInspectorId,
//         assignedInspectorObj: r.assignedInspectorObj,
//       ),
//     );

//     if (ok == true) _reload();
//   }

//   /// ✅ Completed -> open report by inspectionId
//   void _openReport(_RequestRow r) {
//     final id = (r.inspectionId ?? '').trim();
//     if (id.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Inspection report not available yet.')),
//       );
//       return;
//     }
//     context.go('/dashboard/admin/inspections/$id/report');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AppShell(
//       title: 'Inspection Requests',
//       child: Center(
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 1200),
//           child: FutureBuilder<List<_RequestRow>>(
//             key: ValueKey(_tick),
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
//                   child: Text('Failed to load requests: ${snap.error}'),
//                 );
//               }

//               final all = snap.data ?? [];
//               final q = _searchCtrl.text.trim().toLowerCase();

//               final filtered = q.isEmpty
//                   ? all
//                   : all.where((r) {
//                       final hay = <String>[
//                         r.requestId,
//                         r.city,
//                         r.type,
//                         r.status,
//                         r.customerName ?? '',
//                         r.customerEmail ?? '',
//                         r.customerPhone ?? '',
//                         r.vehicleMake ?? '',
//                         r.vehicleModel ?? '',
//                         r.licensePlate ?? '',
//                         r.inspectorName ?? '',
//                       ].join(' ').toLowerCase();

//                       return hay.contains(q);
//                     }).toList();

//               return ListView(
//                 padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           'Inspection Requests',
//                           style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                                 fontWeight: FontWeight.w900,
//                               ),
//                         ),
//                       ),
//                       IconButton(
//                         tooltip: 'Refresh',
//                         onPressed: _reload,
//                         icon: const Icon(Icons.refresh),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
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
//                               hintText: 'Search by requestId / city / type / customer / vehicle / inspector...',
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           if (filtered.isEmpty)
//                             const Padding(
//                               padding: EdgeInsets.all(30),
//                               child: Text('No inspection requests found.'),
//                             )
//                           else
//                             ...filtered.map((r) => _RequestCard(
//                                   key: PageStorageKey('req-${r.mongoId}'),
//                                   r: r,
//                                   onManage: () => _openManage(r),
//                                   onViewReport: () => _openReport(r),
//                                 )),
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
//    List Model (UI only)
// ========================= */

// class _RequestRow {
//   final String mongoId; // request _id
//   final String requestId; // Req-001
//   final String type; // requestType
//   final String city;
//   final String status;

//   final DateTime createdAt;
//   final DateTime? updatedAt;

//   // preferred slot
//   final DateTime? preferredDate;
//   final String preferredTime;

//   // user/customer
//   final String? customerName;
//   final String? customerEmail;
//   final String? customerPhone;

//   // vehicle
//   final String? vehicleMake;
//   final String? vehicleModel;
//   final int? vehicleYear;
//   final String? licensePlate;
//   final int? mileage;
//   final String? color;

//   // notes
//   final String? notes;

//   // ✅ inspection id (for report)
//   final String? inspectionId;

//   // ✅ assigned inspector
//   final String? assignedInspectorId;
//   final Map<String, dynamic>? assignedInspectorObj;
//   final DateTime? assignedAt;

//   // inspection summary (optional)
//   final String? inspectionSummaryStatus;
//   final double? overallRating;

//     // ✅ inspection timings
//   final DateTime? inspectionStartTime;
//   final DateTime? inspectionEndTime;
//   final int? timeTaken; // minutes (or whatever backend sends)


//   _RequestRow({
//     required this.mongoId,
//     required this.requestId,
//     required this.type,
//     required this.city,
//     required this.status,
//     required this.createdAt,
//     this.updatedAt,
//     this.preferredDate,
//     this.preferredTime = '',
//     this.customerName,
//     this.customerEmail,
//     this.customerPhone,
//     this.vehicleMake,
//     this.vehicleModel,
//     this.vehicleYear,
//     this.licensePlate,
//     this.mileage,
//     this.color,
//     this.notes,
//     this.inspectionId,
//     this.assignedInspectorId,
//     this.assignedInspectorObj,
//     this.assignedAt,
//     this.inspectionSummaryStatus,
//     this.overallRating,
//     this.inspectionStartTime,
//     this.inspectionEndTime,
//     this.timeTaken,
//   });

//   bool get isAssigned => assignedInspectorId != null;

//   String? get inspectorName {
//     final m = assignedInspectorObj;
//     if (m == null) return null;
//     final fn = (m['firstName'] ?? '').toString().trim();
//     final ln = (m['lastName'] ?? '').toString().trim();
//     final full = [fn, ln].where((x) => x.isNotEmpty).join(' ');
//     return full.isEmpty ? null : full;
//   }

//   String? get inspectorEmail {
//     final m = assignedInspectorObj;
//     if (m == null) return null;
//     final e = (m['email'] ?? '').toString().trim();
//     return e.isEmpty ? null : e;
//   }

//   factory _RequestRow.fromJson(Map<String, dynamic> j) {
//     // type
//     final type = (j['requestType'] ?? j['inspectionType'] ?? j['type'] ?? 'Inspection').toString();

//     // city
//     String city = '-';
//     final loc = j['location'];
//     if (loc is Map && loc['city'] != null) {
//       city = loc['city'].toString();
//     } else if (j['city'] != null) {
//       city = j['city'].toString();
//     }

//     // created/updated
//     final createdAt = DateTime.tryParse((j['createdAt'] ?? '').toString()) ?? DateTime.now();
//     final updatedAt = DateTime.tryParse((j['updatedAt'] ?? '').toString());

//     // preferred
//     final preferredDate = DateTime.tryParse((j['preferredDate'] ?? '').toString());
//     final preferredTime = (j['preferredTime'] ?? '').toString();

//     // user/customer
//     String? customerName;
//     String? customerEmail;
//     String? customerPhone;
//     final user = j['userId'];
//     if (user is Map) {
//       final u = Map<String, dynamic>.from(user);
//       final fn = (u['firstName'] ?? '').toString().trim();
//       final ln = (u['lastName'] ?? '').toString().trim();
//       final full = [fn, ln].where((x) => x.isNotEmpty).join(' ');
//       customerName = full.isEmpty ? null : full;
//       customerEmail = (u['email'] ?? '').toString().trim();
//       if (customerEmail != null && customerEmail!.isEmpty) customerEmail = null;
//       customerPhone = (u['phone'] ?? '').toString().trim();
//       if (customerPhone != null && customerPhone!.isEmpty) customerPhone = null;
//     }

//     // vehicle
//     String? vMake, vModel, plate, vColor;
//     int? vYear, vMileage;
//     final vi = j['vehicleInfo'];
//     if (vi is Map) {
//       final v = Map<String, dynamic>.from(vi);
//       vMake = (v['make'] ?? '').toString().trim();
//       if (vMake.isEmpty) vMake = null;

//       vModel = (v['model'] ?? '').toString().trim();
//       if (vModel.isEmpty) vModel = null;

//       final yr = v['year'];
//       if (yr is int) vYear = yr;
//       if (yr is String) vYear = int.tryParse(yr);

//       plate = (v['licensePlate'] ?? '').toString().trim();
//       if (plate.isEmpty) plate = null;

//       final mil = v['mileage'];
//       if (mil is int) vMileage = mil;
//       if (mil is String) vMileage = int.tryParse(mil);

//       vColor = (v['color'] ?? '').toString().trim();
//       if (vColor.isEmpty) vColor = null;
//     }

//     // notes
//     final notes = (j['notes'] ?? '').toString().trim();
//     final notesOrNull = notes.isEmpty ? null : notes;

//     // assigned inspector: null / string / object
//     String? assignedId;
//     Map<String, dynamic>? assignedObj;

//     final rawAssigned = j['assignedInspectorId'];
//     if (rawAssigned is String && rawAssigned.trim().isNotEmpty) {
//       assignedId = rawAssigned.trim();
//     } else if (rawAssigned is Map) {
//       assignedObj = Map<String, dynamic>.from(rawAssigned);
//       final id = (assignedObj['_id'] ?? assignedObj['id'] ?? '').toString();
//       if (id.trim().isNotEmpty) assignedId = id.trim();
//     }

//     final assignedAt = DateTime.tryParse((j['assignedAt'] ?? '').toString());

//     // inspectionId: null / string / object
//     String? inspectionId;
//     final rawInspection = j['inspectionId'];
//     if (rawInspection is String && rawInspection.trim().isNotEmpty) {
//       inspectionId = rawInspection.trim();
//     } else if (rawInspection is Map) {
//       final m = Map<String, dynamic>.from(rawInspection);
//       final id = (m['_id'] ?? m['id'] ?? '').toString().trim();
//       if (id.isNotEmpty) inspectionId = id;
//     } else {
//       final s = (rawInspection ?? '').toString().trim();
//       if (s.isNotEmpty && s != 'null') inspectionId = s;
//     }

//     // inspection summary
//     String? summaryStatus;
//     double? overallRating;
//     final sum = j['inspectionSummary'];
//     if (sum is Map) {
//       final sm = Map<String, dynamic>.from(sum);
//       final st = (sm['status'] ?? '').toString().trim();
//       summaryStatus = st.isEmpty ? null : st;

//       final r = sm['overallRating'];
//       if (r is num) overallRating = r.toDouble();
//       if (r is String) overallRating = double.tryParse(r);
//     }

//     final inspectionStartTime = DateTime.tryParse((j['inspectionStartTime'] ?? '').toString());
//     final inspectionEndTime = DateTime.tryParse((j['inspectionEndTime'] ?? '').toString());

//     int? timeTaken;
//     final tt = j['timeTaken'];
//     if (tt is int) timeTaken = tt;
//     if (tt is num) timeTaken = tt.toInt();
//     if (tt is String) timeTaken = int.tryParse(tt.trim());

//     return _RequestRow(
//       mongoId: (j['_id'] ?? j['id'] ?? '-').toString(),
//       requestId: (j['requestId'] ?? '-').toString(),
//       type: type,
//       city: city,
//       status: (j['status'] ?? 'pending').toString(),
//       createdAt: createdAt,
//       updatedAt: updatedAt,
//       preferredDate: preferredDate,
//       preferredTime: preferredTime,
//       customerName: customerName,
//       customerEmail: customerEmail,
//       customerPhone: customerPhone,
//       vehicleMake: vMake,
//       vehicleModel: vModel,
//       vehicleYear: vYear,
//       licensePlate: plate,
//       mileage: vMileage,
//       color: vColor,
//       notes: notesOrNull,
//       inspectionId: inspectionId,
//       assignedInspectorId: assignedId,
//       assignedInspectorObj: assignedObj,
//       assignedAt: assignedAt,
//       inspectionSummaryStatus: summaryStatus,
//       overallRating: overallRating,
//       inspectionStartTime: inspectionStartTime,
//       inspectionEndTime: inspectionEndTime,
//       timeTaken: timeTaken,
//     );
//   }
// }

// /* =========================
//    List Card
// ========================= */

// class _RequestCard extends StatefulWidget {
//   final _RequestRow r;
//   final VoidCallback onManage;
//   final VoidCallback onViewReport;

//   const _RequestCard({
//     super.key,
//     required this.r,
//     required this.onManage,
//     required this.onViewReport,
//   });

//   @override
//   State<_RequestCard> createState() => _RequestCardState();
// }

// class _RequestCardState extends State<_RequestCard> with TickerProviderStateMixin {
//   bool _expanded = false;

//   @override
//   void initState() {
//     super.initState();
//     // Optional: auto-expand non-pending cards
//     final status = widget.r.status.toLowerCase().trim();
//     _expanded = status == 'pending';
//   }

//   void _toggle() => setState(() => _expanded = !_expanded);

//   @override
//   Widget build(BuildContext context) {
//     final r = widget.r;

//     final status = r.status.toLowerCase().trim();
//     final isPending = status == 'pending';
//     final isAssigned = status == 'assigned';
//     final isCompleted = status == 'completed';
//     final isInProgress = status == 'inprogress' || status == 'in_progress';
//     final isCancelled = status == 'cancelled' || status == 'canceled';

//     final hasReport = _s(r.inspectionId).isNotEmpty;
//     final buttonText = isCompleted ? 'View Report' : 'Manage';

//     final VoidCallback? buttonAction =
//         isInProgress ? null : (isCompleted ? (hasReport ? widget.onViewReport : null) : widget.onManage);

//     final inspectorName = _s(r.inspectorName);
//     final inspectorEmail = _s(r.inspectorEmail);
//     final inspectorLabel = inspectorName.isNotEmpty
//         ? inspectorName
//         : (inspectorEmail.isNotEmpty ? inspectorEmail : 'Unassigned');

//     final carLine = [
//       _s(r.vehicleMake),
//       _s(r.vehicleModel),
//       r.vehicleYear?.toString() ?? '',
//     ].where((x) => x.trim().isNotEmpty).join(' ');

//     final customerLine = [
//       _s(r.customerName),
//       _s(r.customerPhone),
//       _s(r.customerEmail),
//     ].where((x) => x.trim().isNotEmpty).join(' • ');

//     final preferredLine = () {
//       final d = r.preferredDate;
//       final t = _s(r.preferredTime);
//       if (d == null && t.isEmpty) return '';
//       final datePart = d == null ? '' : _fmtDate(d);
//       if (datePart.isNotEmpty && t.isNotEmpty) return '$datePart • $t';
//       return datePart.isNotEmpty ? datePart : t;
//     }();

//     Color chipBg() {
//       if (isCancelled) return Colors.red.withOpacity(0.12);
//       if (isPending) return Colors.orange.withOpacity(0.12);
//       if (isAssigned) return Colors.green.withOpacity(0.12);
//       if (isCompleted) return Colors.blue.withOpacity(0.12);
//       if (isInProgress) return Colors.purple.withOpacity(0.12);
//       return Colors.grey.withOpacity(0.12);
//     }

//     // ✅ Boxes (your existing layout)
//     final leftBox = _InfoBox(
//       title: 'Car & Customer',
//       icon: Icons.directions_car_outlined,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _kv(Icons.directions_car_outlined, 'Car', carLine.isEmpty ? '-' : carLine),
//           const SizedBox(height: 10),
//           _kv(Icons.person_outline, 'Customer', customerLine.isEmpty ? '-' : customerLine),
//           const SizedBox(height: 10),
//           _kv(Icons.location_on_outlined, 'City', _sOrDash(r.city)),
//         ],
//       ),
//     );

//     final midBox = _InfoBox(
//       title: 'Inspector Details',
//       icon: Icons.badge_outlined,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _kv(Icons.badge_outlined, 'Inspector', inspectorLabel),
//           const SizedBox(height: 10),
//           _kv(Icons.email_outlined, 'Email', inspectorEmail.isEmpty ? '-' : inspectorEmail),
//           const SizedBox(height: 10),
//           _kv(Icons.schedule_outlined, 'Assigned At',
//               r.assignedAt == null ? '-' : _fmtDateTimeShort(r.assignedAt!)),
//         ],
//       ),
//     );

//     final rightBox = _InfoBox(
//       title: 'Timings',
//       icon: Icons.schedule_outlined,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _kv(Icons.update_outlined, 'Updated', r.updatedAt == null ? '-' : _fmtDateTimeShort(r.updatedAt!)),
//           const SizedBox(height: 10),

//           // ✅ you can later switch preferred vs inspection start/end here
//           _kv(Icons.event_available_outlined, 'Preferred', preferredLine.isEmpty ? '-' : preferredLine),

//           const SizedBox(height: 10),
//           if (_s(r.inspectionSummaryStatus).isNotEmpty || r.overallRating != null)
//             _kv(
//               Icons.assessment_outlined,
//               'Summary',
//               [
//                 if (r.overallRating != null) '★ ${r.overallRating!.toStringAsFixed(2)}',
//               ].join(' • '),
//             ),
//         ],
//       ),
//     );

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 14),
//       child: Card(
//         elevation: 0,
//         color: Colors.black.withOpacity(0.02),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//         child: Padding(
//           padding: const EdgeInsets.all(14),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ===== Header =====
//               Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       r.requestId,
//                       style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
//                     ),
//                   ),
//                   Chip(label: Text(r.status), backgroundColor: chipBg()),
//                   const SizedBox(width: 10),
//                   SizedBox(
//                     height: 36,
//                     child: FilledButton.tonal(
//                       onPressed: buttonAction,
//                       child: Text(buttonText),
//                     ),
//                   ),
//                   const SizedBox(width: 6),
//                   IconButton(
//                     tooltip: _expanded ? 'Collapse' : 'Expand',
//                     onPressed: _toggle,
//                     icon: AnimatedRotation(
//                       turns: _expanded ? 0.5 : 0.0,
//                       duration: const Duration(milliseconds: 180),
//                       child: const Icon(Icons.expand_more),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 10),

//               // ===== Collapsed summary (always visible) =====
//               Wrap(
//                 spacing: 14,
//                 runSpacing: 8,
//                 children: [
//                   _MiniInfo(icon: Icons.directions_car_outlined, text: carLine.isEmpty ? '-' : carLine),
//                   _MiniInfo(icon: Icons.person_outline, text: _s(r.customerName).isEmpty ? '-' : _s(r.customerName)),
//                   _MiniInfo(icon: Icons.badge_outlined, text: inspectorLabel),
//                   _MiniInfo(icon: Icons.location_on_outlined, text: _sOrDash(r.city)),
//                 ],
//               ),

//               // ===== Expandable body =====
//               ClipRect(
//                 child: AnimatedSize(
//                   duration: const Duration(milliseconds: 220),
//                   curve: Curves.easeOutCubic,
//                   child: _expanded
//                       ? Padding(
//                           padding: const EdgeInsets.only(top: 14),
//                           child: LayoutBuilder(
//                             builder: (context, c) {
//                               final isMobile = c.maxWidth < 900;

//                               if (isMobile) {
//                                 return Column(
//                                   children: [
//                                     leftBox,
//                                     const SizedBox(height: 12),
//                                     midBox,
//                                     const SizedBox(height: 12),
//                                     rightBox,
//                                   ],
//                                 );
//                               }

//                               // ✅ desktop: same height premium
//                               return IntrinsicHeight(
//                                 child: Row(
//                                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                                   children: [
//                                     Expanded(flex: 6, child: leftBox),
//                                     const SizedBox(width: 12),
//                                     Expanded(flex: 5, child: midBox),
//                                     const SizedBox(width: 12),
//                                     Expanded(flex: 5, child: rightBox),
//                                   ],
//                                 ),
//                               );
//                             },
//                           ),
//                         )
//                       : const SizedBox.shrink(),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   static String _s(String? v) => (v ?? '').trim();
//   static String _sOrDash(String? v) => _s(v).isEmpty ? '-' : _s(v);

//   static String _fmtDate(DateTime dt) {
//     final d = dt.toLocal();
//     const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
//     return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
//   }

//   static String _fmtDateTimeShort(DateTime dt) {
//     final d = dt.toLocal();
//     const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
//     final hh = d.hour;
//     final mm = d.minute.toString().padLeft(2, '0');
//     final ap = hh >= 12 ? 'PM' : 'AM';
//     final h12 = (hh % 12 == 0) ? 12 : (hh % 12);
//     return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year} • $h12:$mm $ap';
//   }
// }

// class _KeyValueRow extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;

//   const _KeyValueRow({
//     required this.icon,
//     required this.label,
//     required this.value,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(icon, size: 18, color: Colors.black54),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: theme.textTheme.bodySmall?.copyWith(
//                   color: Colors.black54,
//                   fontWeight: FontWeight.w700,
//                   height: 1.1,
//                 ),
//               ),
//               const SizedBox(height: 3),
//               Text(
//                 value,
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                   fontWeight: FontWeight.w700,
//                   height: 1.25,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _StatusPill extends StatelessWidget {
//   final String text;
//   final Color bg;
//   final Color fg;

//   const _StatusPill({required this.text, required this.bg, required this.fg});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: fg.withOpacity(0.18)),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(fontWeight: FontWeight.w900, color: fg),
//       ),
//     );
//   }
// }

// class _StatusUI {
//   final Color bg;
//   final Color fg;
//   const _StatusUI(this.bg, this.fg);

//   factory _StatusUI.from(String status) {
//     final s = status.toLowerCase().trim();
//     if (s == 'pending') return _StatusUI(const Color(0xFFFFF4E5), const Color(0xFFB45309));
//     if (s == 'assigned') return _StatusUI(const Color(0xFFE9F7EF), const Color(0xFF1F7A3E));
//     if (s == 'completed') return _StatusUI(const Color(0xFFEAF2FF), const Color(0xFF1D4ED8));
//     if (s == 'in_progress' || s == 'inprogress') return _StatusUI(const Color(0xFFF3E8FF), const Color(0xFF6D28D9));
//     if (s == 'cancelled' || s == 'canceled') return _StatusUI(const Color(0xFFFFE8E8), const Color(0xFFB91C1C));
//     return _StatusUI(Colors.black.withOpacity(0.06), Colors.black87);
//   }
// }

// class _InfoBox extends StatelessWidget {
//   final String title;
//   final IconData icon;
//   final Widget child;

//   const _InfoBox({
//     required this.title,
//     required this.icon,
//     required this.child,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF7F8FC),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: const Color(0xFFE4E8F2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 34,
//                 height: 34,
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.04),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(icon, size: 18, color: Colors.black87),
//               ),
//               const SizedBox(width: 10),
//               Text(
//                 title,
//                 style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           child,
//         ],
//       ),
//     );
//   }
// }



// Widget _kv(IconData icon, String label, String value) {
//   return Row(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Icon(icon, size: 16, color: Colors.black54),
//       const SizedBox(width: 8),
//       Expanded(
//         child: RichText(
//           text: TextSpan(
//             style: const TextStyle(color: Colors.black87, height: 1.35),
//             children: [
//               TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w800)),
//               TextSpan(text: value),
//             ],
//           ),
//         ),
//       ),
//     ],
//   );
// }



// class _MiniInfo extends StatelessWidget {
//   final IconData icon;
//   final String text;

//   const _MiniInfo({required this.icon, required this.text});

//   @override
//   Widget build(BuildContext context) {
//     final style = Theme.of(context).textTheme.bodySmall?.copyWith(
//           color: Colors.black.withOpacity(0.70),
//           height: 1.2,
//         );

//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: 16, color: Colors.black.withOpacity(0.55)),
//         const SizedBox(width: 6),
//         Flexible(
//           child: Text(
//             text,
//             style: style,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/app_shell.dart';
import '../../../../services/service_locator.dart';
import 'widgets/inspection_request_manage_dialog.dart';

class InspectionRequestsPage extends StatefulWidget {
  const InspectionRequestsPage({super.key});

  @override
  State<InspectionRequestsPage> createState() => _InspectionRequestsPageState();
}

class _InspectionRequestsPageState extends State<InspectionRequestsPage> {
  late Future<List<_RequestRow>> _future;
  final _searchCtrl = TextEditingController();
  int _tick = 0;

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

  Future<List<_RequestRow>> _load() async {
    final raw = await inspectionRequestsService.listAdminRequests();
    return raw
        .whereType<Map>()
        .map((x) => _RequestRow.fromJson(Map<String, dynamic>.from(x)))
        .toList();
  }

  void _reload() {
    setState(() {
      _tick++;
      _future = _load();
    });
  }

  Future<void> _openManage(_RequestRow r) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => InspectionRequestManageDialog(
        requestMongoId: r.mongoId,
        requestDisplayId: r.requestId,
        status: r.status,
        assignedInspectorId: r.assignedInspectorId,
        assignedInspectorObj: r.assignedInspectorObj,
      ),
    );

    if (ok == true) _reload();
  }

  /// Completed -> open report by inspectionId
  void _openReport(_RequestRow r) {
    final id = (r.inspectionId ?? '').trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inspection report not available yet.')),
      );
      return;
    }
    context.go('/dashboard/admin/inspections/$id/report');
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Inspection Requests',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: FutureBuilder<List<_RequestRow>>(
            key: ValueKey(_tick),
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
                  child: Text('Failed to load requests: ${snap.error}'),
                );
              }

              final all = snap.data ?? [];
              final q = _searchCtrl.text.trim().toLowerCase();

              final filtered = q.isEmpty
                  ? all
                  : all.where((r) {
                      final hay = <String>[
                        r.requestId,
                        r.city,
                        r.type,
                        r.status,
                        r.customerName ?? '',
                        r.customerEmail ?? '',
                        r.customerPhone ?? '',
                        r.vehicleMake ?? '',
                        r.vehicleModel ?? '',
                        r.licensePlate ?? '',
                        r.inspectorName ?? '',
                      ].join(' ').toLowerCase();

                      return hay.contains(q);
                    }).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Inspection Requests',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                              hintText: 'Search by requestId / city / type / customer / vehicle / inspector...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (filtered.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(30),
                              child: Text('No inspection requests found.'),
                            )
                          else
                            ...filtered.map((r) => _RequestCard(
                                  key: ValueKey('req-${r.mongoId}'),
                                  r: r,
                                  onManage: () => _openManage(r),
                                  onViewReport: () => _openReport(r),
                                )),
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
   List Model (UI only)
========================= */

class _RequestRow {
  final String mongoId;
  final String requestId;
  final String type;
  final String city;
  final String status;

  final DateTime createdAt;
  final DateTime? updatedAt;

  final DateTime? preferredDate;
  final String preferredTime;

  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;

  final String? vehicleMake;
  final String? vehicleModel;
  final int? vehicleYear;
  final String? licensePlate;
  final int? mileage;
  final String? color;

  final String? notes;

  final String? inspectionId;

  final String? assignedInspectorId;
  final Map<String, dynamic>? assignedInspectorObj;
  final DateTime? assignedAt;

  final String? inspectionSummaryStatus;
  final double? overallRating;

  final DateTime? inspectionStartTime;
  final DateTime? inspectionEndTime;
  final int? timeTaken;

  _RequestRow({
    required this.mongoId,
    required this.requestId,
    required this.type,
    required this.city,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.preferredDate,
    this.preferredTime = '',
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleYear,
    this.licensePlate,
    this.mileage,
    this.color,
    this.notes,
    this.inspectionId,
    this.assignedInspectorId,
    this.assignedInspectorObj,
    this.assignedAt,
    this.inspectionSummaryStatus,
    this.overallRating,
    this.inspectionStartTime,
    this.inspectionEndTime,
    this.timeTaken,
  });

  String? get inspectorName {
    final m = assignedInspectorObj;
    if (m == null) return null;
    final fn = (m['firstName'] ?? '').toString().trim();
    final ln = (m['lastName'] ?? '').toString().trim();
    final full = [fn, ln].where((x) => x.isNotEmpty).join(' ');
    return full.isEmpty ? null : full;
  }

  String? get inspectorEmail {
    final m = assignedInspectorObj;
    if (m == null) return null;
    final e = (m['email'] ?? '').toString().trim();
    return e.isEmpty ? null : e;
  }

  factory _RequestRow.fromJson(Map<String, dynamic> j) {
    final type = (j['requestType'] ?? j['inspectionType'] ?? j['type'] ?? 'Inspection').toString();

    String city = '-';
    final loc = j['location'];
    if (loc is Map && loc['city'] != null) {
      city = loc['city'].toString();
    } else if (j['city'] != null) {
      city = j['city'].toString();
    }

    final createdAt = DateTime.tryParse((j['createdAt'] ?? '').toString()) ?? DateTime.now();
    final updatedAt = DateTime.tryParse((j['updatedAt'] ?? '').toString());

    final preferredDate = DateTime.tryParse((j['preferredDate'] ?? '').toString());
    final preferredTime = (j['preferredTime'] ?? '').toString();

    String? customerName;
    String? customerEmail;
    String? customerPhone;
    final user = j['userId'];
    if (user is Map) {
      final u = Map<String, dynamic>.from(user);
      final fn = (u['firstName'] ?? '').toString().trim();
      final ln = (u['lastName'] ?? '').toString().trim();
      final full = [fn, ln].where((x) => x.isNotEmpty).join(' ');
      customerName = full.isEmpty ? null : full;

      customerEmail = (u['email'] ?? '').toString().trim();
      if (customerEmail.isEmpty) customerEmail = null;

      customerPhone = (u['phone'] ?? '').toString().trim();
      if (customerPhone.isEmpty) customerPhone = null;
    }

    String? vMake, vModel, plate, vColor;
    int? vYear, vMileage;
    final vi = j['vehicleInfo'];
    if (vi is Map) {
      final v = Map<String, dynamic>.from(vi);

      vMake = (v['make'] ?? '').toString().trim();
      if (vMake.isEmpty) vMake = null;

      vModel = (v['model'] ?? '').toString().trim();
      if (vModel.isEmpty) vModel = null;

      final yr = v['year'];
      if (yr is int) vYear = yr;
      if (yr is String) vYear = int.tryParse(yr);

      plate = (v['licensePlate'] ?? '').toString().trim();
      if (plate.isEmpty) plate = null;

      final mil = v['mileage'];
      if (mil is int) vMileage = mil;
      if (mil is String) vMileage = int.tryParse(mil);

      vColor = (v['color'] ?? '').toString().trim();
      if (vColor.isEmpty) vColor = null;
    }

    final notes = (j['notes'] ?? '').toString().trim();
    final notesOrNull = notes.isEmpty ? null : notes;

    String? assignedId;
    Map<String, dynamic>? assignedObj;

    final rawAssigned = j['assignedInspectorId'];
    if (rawAssigned is String && rawAssigned.trim().isNotEmpty) {
      assignedId = rawAssigned.trim();
    } else if (rawAssigned is Map) {
      assignedObj = Map<String, dynamic>.from(rawAssigned);
      final id = (assignedObj['_id'] ?? assignedObj['id'] ?? '').toString();
      if (id.trim().isNotEmpty) assignedId = id.trim();
    }

    final assignedAt = DateTime.tryParse((j['assignedAt'] ?? '').toString());

    String? inspectionId;
    final rawInspection = j['inspectionId'];
    if (rawInspection is String && rawInspection.trim().isNotEmpty) {
      inspectionId = rawInspection.trim();
    } else if (rawInspection is Map) {
      final m = Map<String, dynamic>.from(rawInspection);
      final id = (m['_id'] ?? m['id'] ?? '').toString().trim();
      if (id.isNotEmpty) inspectionId = id;
    } else {
      final s = (rawInspection ?? '').toString().trim();
      if (s.isNotEmpty && s != 'null') inspectionId = s;
    }

    String? summaryStatus;
    double? overallRating;
    final sum = j['inspectionSummary'];
    if (sum is Map) {
      final sm = Map<String, dynamic>.from(sum);
      final st = (sm['status'] ?? '').toString().trim();
      summaryStatus = st.isEmpty ? null : st;

      final r = sm['overallRating'];
      if (r is num) overallRating = r.toDouble();
      if (r is String) overallRating = double.tryParse(r);
    }

    final inspectionStartTime = DateTime.tryParse((j['inspectionStartTime'] ?? '').toString());
    final inspectionEndTime = DateTime.tryParse((j['inspectionEndTime'] ?? '').toString());

    int? timeTaken;
    final tt = j['timeTaken'];
    if (tt is int) timeTaken = tt;
    if (tt is num) timeTaken = tt.toInt();
    if (tt is String) timeTaken = int.tryParse(tt.trim());

    return _RequestRow(
      mongoId: (j['_id'] ?? j['id'] ?? '-').toString(),
      requestId: (j['requestId'] ?? '-').toString(),
      type: type,
      city: city,
      status: (j['status'] ?? 'pending').toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      preferredDate: preferredDate,
      preferredTime: preferredTime,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      vehicleMake: vMake,
      vehicleModel: vModel,
      vehicleYear: vYear,
      licensePlate: plate,
      mileage: vMileage,
      color: vColor,
      notes: notesOrNull,
      inspectionId: inspectionId,
      assignedInspectorId: assignedId,
      assignedInspectorObj: assignedObj,
      assignedAt: assignedAt,
      inspectionSummaryStatus: summaryStatus,
      overallRating: overallRating,
      inspectionStartTime: inspectionStartTime,
      inspectionEndTime: inspectionEndTime,
      timeTaken: timeTaken,
    );
  }
}

/* =========================
   List Card (UI)
========================= */

class _RequestCard extends StatefulWidget {
  final _RequestRow r;
  final VoidCallback onManage;
  final VoidCallback onViewReport;

  const _RequestCard({
    super.key,
    required this.r,
    required this.onManage,
    required this.onViewReport,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> with TickerProviderStateMixin {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    final status = widget.r.status.toLowerCase().trim();
    _expanded = status == 'pending';
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final r = widget.r;

    final status = r.status.toLowerCase().trim();
    final isPending = status == 'pending';
    final isAssigned = status == 'assigned';
    final isCompleted = status == 'completed';
    final isInProgress = status == 'inprogress' || status == 'in_progress';
    final isCancelled = status == 'cancelled' || status == 'canceled';

    final hasReport = _s(r.inspectionId).isNotEmpty;
    final buttonText = isCompleted ? 'View Report' : 'Manage';

    final VoidCallback? buttonAction =
        isInProgress ? null : (isCompleted ? (hasReport ? widget.onViewReport : null) : widget.onManage);

    final inspectorName = _s(r.inspectorName);
    final inspectorEmail = _s(r.inspectorEmail);
    final inspectorLabel =
        inspectorName.isNotEmpty ? inspectorName : (inspectorEmail.isNotEmpty ? inspectorEmail : 'Unassigned');

    final carLine = [
      _s(r.vehicleMake),
      _s(r.vehicleModel),
      r.vehicleYear?.toString() ?? '',
    ].where((x) => x.trim().isNotEmpty).join(' ');

    final customerLine = [
      _s(r.customerName),
      _s(r.customerPhone),
      _s(r.customerEmail),
    ].where((x) => x.trim().isNotEmpty).join(' • ');

    final preferredLine = () {
      final d = r.preferredDate;
      final t = _s(r.preferredTime);
      if (d == null && t.isEmpty) return '';
      final datePart = d == null ? '' : _fmtDate(d);
      if (datePart.isNotEmpty && t.isNotEmpty) return '$datePart • $t';
      return datePart.isNotEmpty ? datePart : t;
    }();

    Color chipBg() {
      if (isCancelled) return Colors.red.withOpacity(0.12);
      if (isPending) return Colors.orange.withOpacity(0.12);
      if (isAssigned) return Colors.green.withOpacity(0.12);
      if (isCompleted) return Colors.blue.withOpacity(0.12);
      if (isInProgress) return Colors.purple.withOpacity(0.12);
      return Colors.grey.withOpacity(0.12);
    }

    final leftBox = _InfoBox(
      title: 'Car & Customer',
      icon: Icons.directions_car_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv(Icons.directions_car_outlined, 'Car', carLine.isEmpty ? '-' : carLine),
          const SizedBox(height: 10),
          _kv(Icons.person_outline, 'Customer', customerLine.isEmpty ? '-' : customerLine),
          const SizedBox(height: 10),
          _kv(Icons.location_on_outlined, 'City', _sOrDash(r.city)),
        ],
      ),
    );

    final midBox = _InfoBox(
      title: 'Inspector Details',
      icon: Icons.badge_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv(Icons.badge_outlined, 'Inspector', inspectorLabel),
          const SizedBox(height: 10),
          _kv(Icons.email_outlined, 'Email', inspectorEmail.isEmpty ? '-' : inspectorEmail),
          const SizedBox(height: 10),
          _kv(Icons.schedule_outlined, 'Assigned At', r.assignedAt == null ? '-' : _fmtDateTimeShort(r.assignedAt!)),
        ],
      ),
    );

    final rightBox = _InfoBox(
      title: 'Timings',
      icon: Icons.schedule_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv(Icons.update_outlined, 'Updated', r.updatedAt == null ? '-' : _fmtDateTimeShort(r.updatedAt!)),
          const SizedBox(height: 10),
          _kv(Icons.event_available_outlined, 'Preferred', preferredLine.isEmpty ? '-' : preferredLine),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        elevation: 0,
        color: Colors.black.withOpacity(0.02),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.requestId,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ),
                  Chip(label: Text(r.status), backgroundColor: chipBg()),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 36,
                    child: FilledButton.tonal(
                      onPressed: buttonAction,
                      child: Text(buttonText),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: _expanded ? 'Collapse' : 'Expand',
                    onPressed: _toggle,
                    icon: AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(Icons.expand_more),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _MiniInfo(icon: Icons.directions_car_outlined, text: carLine.isEmpty ? '-' : carLine),
                  _MiniInfo(icon: Icons.person_outline, text: _s(r.customerName).isEmpty ? '-' : _s(r.customerName)),
                  _MiniInfo(icon: Icons.badge_outlined, text: inspectorLabel),
                  _MiniInfo(icon: Icons.location_on_outlined, text: _sOrDash(r.city)),
                ],
              ),
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: _expanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: LayoutBuilder(
                            builder: (context, c) {
                              final isMobile = c.maxWidth < 900;
                              if (isMobile) {
                                return Column(
                                  children: [
                                    leftBox,
                                    const SizedBox(height: 12),
                                    midBox,
                                    const SizedBox(height: 12),
                                    rightBox,
                                  ],
                                );
                              }
                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(flex: 6, child: leftBox),
                                    const SizedBox(width: 12),
                                    Expanded(flex: 5, child: midBox),
                                    const SizedBox(width: 12),
                                    Expanded(flex: 5, child: rightBox),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _s(String? v) => (v ?? '').trim();
  static String _sOrDash(String? v) => _s(v).isEmpty ? '-' : _s(v);

  static String _fmtDate(DateTime dt) {
    final d = dt.toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  static String _fmtDateTimeShort(DateTime dt) {
    final d = dt.toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hh = d.hour;
    final mm = d.minute.toString().padLeft(2, '0');
    final ap = hh >= 12 ? 'PM' : 'AM';
    final h12 = (hh % 12 == 0) ? 12 : (hh % 12);
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year} • $h12:$mm $ap';
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _InfoBox({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E8F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: Colors.black87),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

Widget _kv(IconData icon, String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: Colors.black54),
      const SizedBox(width: 8),
      Expanded(
        child: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, height: 1.35),
            children: [
              TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w800)),
              TextSpan(text: value),
            ],
          ),
        ),
      ),
    ],
  );
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.black.withOpacity(0.70),
          height: 1.2,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.black.withOpacity(0.55)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
