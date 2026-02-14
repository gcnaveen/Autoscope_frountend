// import 'dart:math' as math;
// import 'package:flutter/material.dart';

// import '../../shared/app_shell.dart';
// import '../../../services/service_locator.dart';

// class InspectionReportPage extends StatefulWidget {
//   final String inspectionId;
//   const InspectionReportPage({super.key, required this.inspectionId});

//   @override
//   State<InspectionReportPage> createState() => _InspectionReportPageState();
// }

// class _InspectionReportPageState extends State<InspectionReportPage> {
//   late Future<Map<String, dynamic>> _future;

//   @override
//   void initState() {
//     super.initState();
//     _future = inspectionRequestsService.getInspectionById(widget.inspectionId);
//   }

//   void _retry() {
//     setState(() {
//       _future = inspectionRequestsService.getInspectionById(widget.inspectionId);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AppShell(
//       title: 'Inspection Report',
//       child: Center(
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 1150),
//           child: FutureBuilder<Map<String, dynamic>>(
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
//                       Text('Failed to load report: ${snap.error}'),
//                       const SizedBox(height: 12),
//                       FilledButton.icon(
//                         onPressed: _retry,
//                         icon: const Icon(Icons.refresh),
//                         label: const Text('Retry'),
//                       )
//                     ],
//                   ),
//                 );
//               }

//               final root = snap.data ?? const <String, dynamic>{};
//               final success = root['success'] == true;
//               final message = (root['message'] ?? '').toString();

//               final data = (root['data'] is Map)
//                   ? Map<String, dynamic>.from(root['data'] as Map)
//                   : const <String, dynamic>{};

//               final inspection = (data['inspection'] is Map)
//                   ? Map<String, dynamic>.from(data['inspection'] as Map)
//                   : const <String, dynamic>{};

//               if (!success || inspection.isEmpty) {
//                 return Padding(
//                   padding: const EdgeInsets.all(18),
//                   child: Text(
//                     inspection.isEmpty
//                         ? 'No inspection data found. $message'
//                         : 'Failed to load report. $message',
//                   ),
//                 );
//               }

//               return _ReportView(inspection: inspection, onRetry: _retry);
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }

// /* =========================
//    Report UI (PDF-like)
// ========================= */

// class _ReportView extends StatefulWidget {
//   final Map<String, dynamic> inspection;
//   final VoidCallback onRetry;
//   const _ReportView({required this.inspection, required this.onRetry});

//   @override
//   State<_ReportView> createState() => _ReportViewState();
// }

// class _ReportViewState extends State<_ReportView> {
//   final _scrollCtrl = ScrollController();

//   bool _showFloatingPhotos = false;

//   bool _viewerOpen = false;
//   int _viewerIndex = 0;

//   int _heroIndex = 0;

//   late final List<_PhotoRef> _photos;
//   late final Map<String, List<int>> _sectionToPhotoIdx;

//   @override
//   void initState() {
//     super.initState();

//     final built = _buildAllPhotos(widget.inspection);
//     _photos = built.$1;
//     _sectionToPhotoIdx = built.$2;

//     _scrollCtrl.addListener(() {
//       final show = _scrollCtrl.offset > 520 && _photos.isNotEmpty;
//       if (show != _showFloatingPhotos) {
//         setState(() => _showFloatingPhotos = show);
//       }
//     });

//     if (_photos.isNotEmpty) _heroIndex = 0;
//   }

//   @override
//   void dispose() {
//     _scrollCtrl.dispose();
//     super.dispose();
//   }

//   void _openViewer(int index) {
//     if (_photos.isEmpty) return;
//     setState(() {
//       _viewerIndex = index.clamp(0, _photos.length - 1);
//       _viewerOpen = true;
//     });
//   }

//   void _closeViewer() {
//     setState(() => _viewerOpen = false);
//   }

//   void _next() {
//     if (_photos.isEmpty) return;
//     setState(() => _viewerIndex = (_viewerIndex + 1) % _photos.length);
//   }

//   void _prev() {
//     if (_photos.isEmpty) return;
//     setState(() => _viewerIndex = (_viewerIndex - 1 + _photos.length) % _photos.length);
//   }

//   void _setHero(int index, {bool openViewer = false}) {
//     if (_photos.isEmpty) return;
//     setState(() => _heroIndex = index.clamp(0, _photos.length - 1));
//     if (openViewer) _openViewer(_heroIndex);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final inspection = widget.inspection;

//     final template = _asMap(inspection['checklistTemplateId']);
//     final inspector = _asMap(inspection['inspectorId']);

//     // vehicle sections from your API response
//     final vehicleDetails = _asMap(inspection['vehicleDetails']);
//     final serviceWarrantyOverview = _asMap(inspection['serviceWarrantyOverview']);
//     final interiorDetails = _asMap(inspection['interiorDetails']);
//     final exteriorDetails = _asMap(inspection['exteriorDetails']);

//     final types = (inspection['types'] as List?) ?? const [];

//     final id = (inspection['_id'] ?? inspection['id'] ?? '').toString();
//     final status = (inspection['status'] ?? '').toString();
//     final overallRating = _toDouble(inspection['overallRating']);

//     final inspectionDate = _fmtIso(inspection['inspectionDate']);
//     final completedAt = _fmtIso(inspection['completedAt']);
//     final createdAt = _fmtIso(inspection['createdAt']);
//     final updatedAt = _fmtIso(inspection['updatedAt']);

//     final notes = _cleanStr(inspection['notes']);

//     return Stack(
//       children: [
//         ListView(
//           controller: _scrollCtrl,
//           padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
//           children: [
//             _HeaderRow(
//               title: 'Inspection Report',
//               status: status,
//             ),
//             const SizedBox(height: 12),

//             // top info cards
//             LayoutBuilder(
//               builder: (context, c) {
//                 final wide = c.maxWidth >= 900;
//                 final gap = 12.0;

//                 final left = _Card(
//                   title: 'Report Info',
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _kv('Inspection ID', id),
//                       _kv('Overall Rating',
//                           overallRating == null ? '-' : overallRating.toStringAsFixed(2)),
//                       _kv('Inspection Date', inspectionDate.isEmpty ? '-' : inspectionDate),
//                       if (completedAt.isNotEmpty) _kv('Completed At', completedAt),
//                       _kv('Created At', createdAt.isEmpty ? '-' : createdAt),
//                       _kv('Updated At', updatedAt.isEmpty ? '-' : updatedAt),
//                     ],
//                   ),
//                 );

//                 final right = _Card(
//                   title: 'Template & Inspector',
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _kv('Template',
//                           _cleanStr(template['name']).isEmpty ? '-' : _cleanStr(template['name'])),
//                       _kv('Version',
//                           _cleanStr(template['version']).isEmpty ? '-' : _cleanStr(template['version'])),
//                       _kv(
//                         'Inspector',
//                         '${_cleanStr(inspector['firstName'])} ${_cleanStr(inspector['lastName'])}'
//                                 .trim()
//                                 .isEmpty
//                             ? '-'
//                             : '${_cleanStr(inspector['firstName'])} ${_cleanStr(inspector['lastName'])}'
//                                 .trim(),
//                       ),
//                       _kv('Email',
//                           _cleanStr(inspector['email']).isEmpty ? '-' : _cleanStr(inspector['email'])),
//                     ],
//                   ),
//                 );

//                 if (!wide) {
//                   return Column(
//                     children: [
//                       left,
//                       const SizedBox(height: 12),
//                       right,
//                     ],
//                   );
//                 }

//                 return Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(child: left),
//                     SizedBox(width: gap),
//                     Expanded(child: right),
//                   ],
//                 );
//               },
//             ),

//             const SizedBox(height: 12),

//             // Vehicle Info (sub-sections)
//             // ✅ rearranged per your sketch:
//             // 1) Exterior + Interior side-by-side
//             // 2) Service/Warranty full width below
//             _Card(
//               title: 'Vehicle Info',
//               child: Column(
//                 children: [
//                   LayoutBuilder(
//                     builder: (context, c) {
//                       final wide = c.maxWidth >= 900;
//                       final vehicleDetailsCard = 
//                           _SubSectionMapCard(title: 'Vehicle Details', data: vehicleDetails);
//                       final exteriorCard =
//                           _SubSectionMapCard(title: 'Exterior Details', data: exteriorDetails);
//                       final interiorCard =
//                           _SubSectionMapCard(title: 'Interior Details', data: interiorDetails);
//                       final serviceCard = 
//                           _SubSectionMapCard(title: 'Service / Warranty Overview', data: serviceWarrantyOverview);
//                       if (!wide) {
//                         return Column(
//                           children: [
//                             vehicleDetailsCard,
//                             const SizedBox(height: 10),
//                             exteriorCard,
//                             const SizedBox(height: 10),
//                             interiorCard,
//                             const SizedBox(height: 10),
//                             serviceCard,
//                           ],
//                         );
//                       }

//                       // return Row(
//                       //   crossAxisAlignment: CrossAxisAlignment.start,
//                       //   children: [
//                       //     Expanded(child: vehicleDetailsCard),
//                       //     const SizedBox(width: 12),
//                       //     Expanded(child: exteriorCard),
//                       //     const SizedBox(width: 12),
//                       //     Expanded(child: interiorCard),
//                       //     const SizedBox(width: 12),
//                       //     Expanded(child: serviceCard),
//                       //   ],
//                       // );

//                       return Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // 1st column (left)
//                           Expanded(flex: 6, child: vehicleDetailsCard),

//                           const SizedBox(width: 12),

//                           // 2nd column (right) -> 2 rows
//                           Expanded(
//                             flex: 6,
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 // Row 1 -> 2 columns (Exterior + Interior)
//                                 Row(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Expanded(child: exteriorCard),
//                                     const SizedBox(width: 12),
//                                     Expanded(child: interiorCard),
//                                   ],
//                                 ),

//                                 const SizedBox(height: 12),

//                                 // Row 2 -> 1 column (Service)
//                                 serviceCard,
//                               ],
//                             ),
//                           ),
//                         ],
//                       );
//                     },
//                   ),

//                   // const SizedBox(height: 10),
//                   // _SubSectionMapCard(
//                   //   title: 'Service / Warranty Overview',
//                   //   data: serviceWarrantyOverview,
//                   // ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 12),

//             // ✅ Overall Rating + Section Overview side-by-side (like your last screenshot)
//             LayoutBuilder(
//               builder: (context, c) {
//                 final wide = c.maxWidth >= 950;

//                 final overallCard = _Card(
//                   title: 'Overall Rating',
//                   child: LayoutBuilder(
//                     builder: (context, c2) {
//                       final label = _ratingLabel(overallRating ?? 0);

//                       // smaller gauge (compact)
//                       final gauge = SizedBox(
//                         width: 300,
//                         height: 150,
//                         child: _OdometerGauge(value: overallRating ?? 0),
//                       );

//                       final details = Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             overallRating == null ? '-' : overallRating.toStringAsFixed(2),
//                             style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
//                           ),
//                           const SizedBox(height: 6),
//                           _Badge(text: label, tone: _badgeTone(label)),
//                           const SizedBox(height: 8),
//                           const Text('Scale: 0 to 5', style: TextStyle(color: Colors.black54)),
//                         ],
//                       );

//                       return Row(
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           gauge,
//                           const SizedBox(width: 16),
//                           Expanded(child: details),
//                         ],
//                       );
//                     },
//                   ),
//                 );

//                 final sectionOverviewCard = _Card(
//                   title: 'Section Overview',
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       for (final t in types) _SectionOverviewLine(type: _asMap(t)),
//                     ],
//                   ),
//                 );

//                 if (!wide) {
//                   return Column(
//                     children: [
//                       sectionOverviewCard,
//                       const SizedBox(height: 12),
//                       overallCard,
//                     ],
//                   );
//                 }

//                 return Row(
//                   // crossAxisAlignment: CrossAxisAlignment.start,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Expanded(flex: 6, child: sectionOverviewCard),
//                     const SizedBox(width: 12),
//                     Expanded(flex: 6, child: overallCard),
//                   ],
//                 );
//               },
//             ),

//             // optional overall notes only if present
//             if (notes.isNotEmpty) ...[
//               const SizedBox(height: 12),
//               _Card(
//                 title: 'Overall Description',
//                 child: Text(notes),
//               ),
//             ],

//             const SizedBox(height: 12),

//             // Photos: hero + section thumbs (bigger / full width)
//             _PhotosBlock(
//               photos: _photos,
//               sectionToPhotoIdx: _sectionToPhotoIdx,
//               heroIndex: _heroIndex,
//               onHeroOpen: () => _openViewer(_heroIndex),
//               onThumbClick: (index) => _setHero(index, openViewer: true),
//               onOpenViewer: () => _openViewer(_heroIndex),
//             ),

//             const SizedBox(height: 18),

//             // Checklist (names + status + rating only)
//             _Card(
//               title: 'Checklist',
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   for (final t in types) ...[
//                     const SizedBox(height: 6),
//                     _ChecklistSection(type: _asMap(t)),
//                     const SizedBox(height: 12),
//                   ]
//                 ],
//               ),
//             ),
//           ],
//         ),

//         // Floating Photos button while scrolling
//         if (_showFloatingPhotos)
//           Positioned(
//             right: 18,
//             bottom: 18,
//             child: _FloatingPhotosButton(
//               count: _photos.length,
//               onPressed: () => _openViewer(_heroIndex),
//             ),
//           ),

//         // Popover viewer overlay
//         if (_viewerOpen && _photos.isNotEmpty)
//           Positioned.fill(
//             child: _ImageViewerOverlay(
//               photos: _photos,
//               index: _viewerIndex,
//               onClose: _closeViewer,
//               onNext: _next,
//               onPrev: _prev,
//             ),
//           ),
//       ],
//     );
//   }

//   // returns (photosList, section->indexes)
//   (List<_PhotoRef>, Map<String, List<int>>) _buildAllPhotos(Map<String, dynamic> inspection) {
//     final types = (inspection['types'] as List?) ?? const [];
//     final refs = <_PhotoRef>[];
//     final seen = <String>{};
//     final sectionMap = <String, List<int>>{};

//     void add(String url, String section) {
//       final u = url.trim();
//       if (u.isEmpty) return;
//       if (seen.contains(u)) return;
//       seen.add(u);
//       final idx = refs.length;
//       refs.add(_PhotoRef(url: u, section: section));
//       sectionMap.putIfAbsent(section, () => []).add(idx);
//     }

//     for (final t in types) {
//       final tm = _asMap(t);
//       final section = _cleanStr(tm['typeName']).isEmpty ? 'Section' : _cleanStr(tm['typeName']);

//       final overallPhotos =
//           (tm['overallPhotos'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
//       for (final u in overallPhotos) add(u, section);

//       final items = (tm['checklistItems'] as List?) ?? const [];
//       for (final it in items) {
//         final im = _asMap(it);
//         final photos =
//             (im['photos'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
//         for (final u in photos) add(u, section);
//       }
//     }

//     return (refs, sectionMap);
//   }
// }

// /* =========================
//    Photos
// ========================= */

// class _PhotosBlock extends StatelessWidget {
//   final List<_PhotoRef> photos;
//   final Map<String, List<int>> sectionToPhotoIdx;

//   final int heroIndex;
//   final VoidCallback onHeroOpen;
//   final void Function(int index) onThumbClick;
//   final VoidCallback onOpenViewer;

//   const _PhotosBlock({
//     required this.photos,
//     required this.sectionToPhotoIdx,
//     required this.heroIndex,
//     required this.onHeroOpen,
//     required this.onThumbClick,
//     required this.onOpenViewer,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (photos.isEmpty) {
//       return const _Card(
//         title: 'Photos',
//         child: Text('No photos uploaded.'),
//       );
//     }

//     final heroUrl = photos[heroIndex.clamp(0, photos.length - 1)].url;

//     return Card(
//       elevation: 0,
//       color: Colors.black.withOpacity(0.02),
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     'Photos  (${photos.length}) • click any image to view',
//                     style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
//                   ),
//                 ),
//                 FilledButton.tonalIcon(
//                   onPressed: onOpenViewer,
//                   icon: const Icon(Icons.open_in_full),
//                   label: const Text('View'),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             LayoutBuilder(
//               builder: (context, c) {
//                 final wide = c.maxWidth >= 950;

//                 final hero = _HeroTile(url: heroUrl, onOpen: onHeroOpen);

//                 final thumbs = _SectionThumbs(
//                   photos: photos,
//                   sectionToPhotoIdx: sectionToPhotoIdx,
//                   onTapIndex: onThumbClick,
//                 );

//                 if (!wide) {
//                   return Column(
//                     children: [
//                       hero,
//                       const SizedBox(height: 12),
//                       thumbs,
//                     ],
//                   );
//                 }

//                 // ✅ hero height based on its width (16:9)
//                 const gap = 14.0;
//                 final heroWidth = (c.maxWidth - gap) * (7 / 12); // because flex 7 vs 5
//                 final heroHeight = heroWidth * 9 / 16;

//                 return Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(flex: 7, child: hero),
//                     const SizedBox(width: gap),
//                     // Expanded(flex: 5, child: thumbs),
//                     Expanded(
//                       flex: 5,
//                       child: SizedBox(
//                         height: heroHeight,
//                         child: _SectionThumbs(
//                           photos: photos,
//                           sectionToPhotoIdx: sectionToPhotoIdx,
//                           onTapIndex: onThumbClick,
//                         ),
//                       ),
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _HeroTile extends StatelessWidget {
//   final String url;
//   final VoidCallback onOpen;
//   const _HeroTile({required this.url, required this.onOpen});

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(14),
//       child: MouseRegion(
//         cursor: SystemMouseCursors.click,
//         child: InkWell(
//           onTap: onOpen,
//           child: Stack(
//             children: [
//               AspectRatio(
//                 aspectRatio: 16 / 9,
//                 child: Image.network(
//                   url,
//                   fit: BoxFit.cover,
//                   errorBuilder: (_, __, ___) => const ColoredBox(
//                     color: Colors.black12,
//                     child: Center(child: Text('Failed to load image')),
//                   ),
//                 ),
//               ),
//               Positioned(
//                 right: 12,
//                 bottom: 12,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.55),
//                     borderRadius: BorderRadius.circular(999),
//                   ),
//                   child: const Row(
//                     children: [
//                       Icon(Icons.open_in_full, size: 16, color: Colors.white),
//                       SizedBox(width: 8),
//                       Text('Open', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
//                     ],
//                   ),
//                 ),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _SectionThumbs extends StatelessWidget {
//   final List<_PhotoRef> photos;
//   final Map<String, List<int>> sectionToPhotoIdx;
//   final void Function(int index) onTapIndex;

//   const _SectionThumbs({
//     required this.photos,
//     required this.sectionToPhotoIdx,
//     required this.onTapIndex,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final sections = sectionToPhotoIdx.keys.toList();

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.6),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.black.withOpacity(0.06)),
//       ),
//       padding: const EdgeInsets.all(12),
//       child: SizedBox(
//         height: 220, // compact but scrollable
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               for (final s in sections) ...[
//                 Text(s, style: const TextStyle(fontWeight: FontWeight.w900)),
//                 const SizedBox(height: 8),
//                 Wrap(
//                   spacing: 10,
//                   runSpacing: 10,
//                   children: [
//                     for (final idx in sectionToPhotoIdx[s] ?? const [])
//                       _ThumbTile(
//                         url: photos[idx].url,
//                         onTap: () => onTapIndex(idx),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//               ]
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ThumbTile extends StatelessWidget {
//   final String url;
//   final VoidCallback onTap;

//   const _ThumbTile({
//     required this.url,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 110,
//       height: 70,
//       child: MouseRegion(
//         cursor: SystemMouseCursors.click,
//         child: InkWell(
//           onTap: onTap,
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(12),
//             child: Image.network(
//               url,
//               fit: BoxFit.cover,
//               errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// /* =========================
//    Viewer Overlay (popover)
// ========================= */

// class _ImageViewerOverlay extends StatelessWidget {
//   final List<_PhotoRef> photos;
//   final int index;
//   final VoidCallback onClose;
//   final VoidCallback onNext;
//   final VoidCallback onPrev;

//   const _ImageViewerOverlay({
//     required this.photos,
//     required this.index,
//     required this.onClose,
//     required this.onNext,
//     required this.onPrev,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final i = index.clamp(0, photos.length - 1);
//     final item = photos[i];

//     return Material(
//       color: Colors.black.withOpacity(0.75),
//       child: SafeArea(
//         child: Stack(
//           children: [
//             // close on background tap
//             Positioned.fill(
//               child: InkWell(onTap: onClose, child: const SizedBox()),
//             ),
//             Center(
//               child: ConstrainedBox(
//                 constraints: const BoxConstraints(maxWidth: 1100),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(16),
//                     child: Container(
//                       color: Colors.black.withOpacity(0.55),
//                       child: Stack(
//                         children: [
//                           Positioned.fill(
//                             child: InteractiveViewer(
//                               child: Image.network(
//                                 item.url,
//                                 fit: BoxFit.contain,
//                                 errorBuilder: (_, __, ___) => const Center(
//                                   child: Text('Failed to load image',
//                                       style: TextStyle(color: Colors.white)),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           Positioned(
//                             top: 10,
//                             right: 10,
//                             child: IconButton(
//                               tooltip: 'Close',
//                               onPressed: onClose,
//                               icon: const Icon(Icons.close, color: Colors.white),
//                             ),
//                           ),
//                           Positioned(
//                             left: 8,
//                             top: 0,
//                             bottom: 0,
//                             child: Center(
//                               child: _NavBtn(icon: Icons.chevron_left, onTap: onPrev),
//                             ),
//                           ),
//                           Positioned(
//                             right: 8,
//                             top: 0,
//                             bottom: 0,
//                             child: Center(
//                               child: _NavBtn(icon: Icons.chevron_right, onTap: onNext),
//                             ),
//                           ),
//                           Positioned(
//                             left: 12,
//                             right: 12,
//                             bottom: 12,
//                             child: Row(
//                               children: [
//                                 Expanded(
//                                   child: Text(
//                                     '${item.section}  •  ${i + 1} / ${photos.length}',
//                                     style: const TextStyle(
//                                         color: Colors.white, fontWeight: FontWeight.w800),
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _NavBtn extends StatelessWidget {
//   final IconData icon;
//   final VoidCallback onTap;
//   const _NavBtn({required this.icon, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return MouseRegion(
//       cursor: SystemMouseCursors.click,
//       child: InkWell(
//         onTap: onTap,
//         child: Container(
//           width: 46,
//           height: 46,
//           decoration: BoxDecoration(
//             color: Colors.black.withOpacity(0.35),
//             borderRadius: BorderRadius.circular(999),
//             border: Border.all(color: Colors.white.withOpacity(0.15)),
//           ),
//           child: Icon(icon, color: Colors.white),
//         ),
//       ),
//     );
//   }
// }

// /* =========================
//    Checklist (names + status + rating)
// ========================= */

// class _ChecklistSection extends StatelessWidget {
//   final Map<String, dynamic> type;
//   const _ChecklistSection({required this.type});

//   @override
//   Widget build(BuildContext context) {
//     final name = _cleanStr(type['typeName']).isEmpty ? 'Section' : _cleanStr(type['typeName']);
//     final avg = type['averageRating'];

//     final items = (type['checklistItems'] as List?) ?? const [];
//     if (items.isEmpty) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900))),
//               _SmallMuted('Avg: ${_cleanStr(avg).isEmpty ? '-' : _cleanStr(avg)}'),
//             ],
//           ),
//           const SizedBox(height: 10),
//           const Text('No checklist items.', style: TextStyle(color: Colors.black54)),
//         ],
//       );
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900))),
//             _SmallMuted('Avg: ${_cleanStr(avg).isEmpty ? '-' : _cleanStr(avg)}'),
//           ],
//         ),
//         const SizedBox(height: 10),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.6),
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: Colors.black.withOpacity(0.06)),
//           ),
//           child: Column(
//             children: [
//               for (final it in items) _ChecklistRow(item: _asMap(it)),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _ChecklistRow extends StatelessWidget {
//   final Map<String, dynamic> item;
//   const _ChecklistRow({required this.item});

//   @override
//   Widget build(BuildContext context) {
//     final pos = item['position'];
//     final label = _cleanStr(item['label']).isEmpty ? '-' : _cleanStr(item['label']);
//     final status = _cleanStr(item['status']).isEmpty ? '-' : _cleanStr(item['status']);
//     final rating = item['rating'];
//     final remarks = _cleanStr(item['remarks']); // ✅ description/remarks

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//       child: Column(
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               // LEFT SIDE: pos + label + chips (no big gap)
//               Expanded(
//                 flex: 7,
//                 child: Wrap(
//                   crossAxisAlignment: WrapCrossAlignment.center,
//                   spacing: 10,
//                   runSpacing: 8,
//                   children: [
//                     Text(
//                       '${pos ?? ''}.',
//                       style: const TextStyle(fontWeight: FontWeight.w900),
//                     ),
//                     Text(
//                       label,
//                       style: const TextStyle(fontWeight: FontWeight.w800),
//                     ),
//                     _StatusChip(status: status),
//                     _RatingChip(rating: rating),
//                   ],
//                 ),
//               ),

//               const SizedBox(width: 12),

//               // RIGHT SIDE: remarks
//               Expanded(
//                 flex: 5,
//                 child: Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     remarks.trim().isEmpty ? '-' : remarks,
//                     style: const TextStyle(color: Colors.black87, height: 1.25),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           const Divider(height: 18),
//         ],
//       ),
//     );
//   }
// }

// /* =========================
//    Section Overview
// ========================= */

// class _SectionOverviewLine extends StatelessWidget {
//   final Map<String, dynamic> type;
//   const _SectionOverviewLine({required this.type});

//   @override
//   Widget build(BuildContext context) {
//     final name = _cleanStr(type['typeName']).isEmpty ? 'Section' : _cleanStr(type['typeName']);
//     final avg = type['averageRating'];

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('•  ', style: TextStyle(fontWeight: FontWeight.w900)),
//           Expanded(
//             child: Text(
//               '$name  •  Avg: ${_cleanStr(avg).isEmpty ? '-' : _cleanStr(avg)}',
//               style: const TextStyle(height: 1.25),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /* =========================
//    Odometer Gauge (0..5)
// ========================= */

// class _OdometerGauge extends StatelessWidget {
//   final double value;
//   const _OdometerGauge({required this.value});

//   @override
//   Widget build(BuildContext context) {
//     final double v = value.clamp(0.0, 5.0).toDouble();
//     return CustomPaint(
//       painter: _OdometerPainter(v),
//       child: const SizedBox.expand(),
//     );
//   }
// }

// class _OdometerPainter extends CustomPainter {
//   final double v;
//   _OdometerPainter(this.v);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height * 0.92);
//     final radius = math.min(size.width, size.height) * 0.78;

//     final bgPaint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 16
//       ..strokeCap = StrokeCap.round
//       ..color = Colors.black.withOpacity(0.08);

//     final rect = Rect.fromCircle(center: center, radius: radius);

//     const start = math.pi; // left
//     const sweep = math.pi; // to right

//     canvas.drawArc(rect, start, sweep, false, bgPaint);

//     void seg(double from, double to, Color color) {
//       final p = Paint()
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 16
//         ..strokeCap = StrokeCap.butt
//         ..color = color;

//       final a1 = start + (from / 5) * sweep;
//       final sw = ((to - from) / 5) * sweep;
//       canvas.drawArc(rect, a1, sw, false, p);
//     }

//     seg(0, 2, const Color(0xFFE53935)); // red
//     seg(2, 3.5, const Color(0xFFFB8C00)); // orange
//     seg(3.5, 4.5, const Color(0xFF1E88E5)); // blue
//     seg(4.5, 5, const Color(0xFF43A047)); // green

//     final tickPaint = Paint()
//       ..color = Colors.black.withOpacity(0.55)
//       ..strokeWidth = 2;

//     for (int i = 0; i <= 5; i++) {
//       final t = i / 5;
//       final ang = start + t * sweep;
//       final p1 =
//           Offset(center.dx + math.cos(ang) * (radius - 6), center.dy + math.sin(ang) * (radius - 6));
//       final p2 = Offset(
//           center.dx + math.cos(ang) * (radius - 18), center.dy + math.sin(ang) * (radius - 18));
//       canvas.drawLine(p1, p2, tickPaint);

//       final tp = TextPainter(
//         text: TextSpan(
//           text: '$i',
//           style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black54),
//         ),
//         textDirection: TextDirection.ltr,
//       )..layout();

//       final lp = Offset(
//         center.dx + math.cos(ang) * (radius - 36) - tp.width / 2,
//         center.dy + math.sin(ang) * (radius - 36) - tp.height / 2,
//       );
//       tp.paint(canvas, lp);
//     }

//     final needleAng = start + (v / 5) * sweep;
//     final needleEnd = Offset(
//       center.dx + math.cos(needleAng) * (radius - 28),
//       center.dy + math.sin(needleAng) * (radius - 28),
//     );

//     final needlePaint = Paint()
//       ..color = Colors.black.withOpacity(0.75)
//       ..strokeWidth = 4
//       ..strokeCap = StrokeCap.round;

//     canvas.drawLine(center, needleEnd, needlePaint);

//     canvas.drawCircle(center, 5.5, Paint()..color = Colors.white);
//     canvas.drawCircle(center, 4.8, Paint()..color = Colors.black.withOpacity(0.7));
//   }

//   @override
//   bool shouldRepaint(covariant _OdometerPainter oldDelegate) => oldDelegate.v != v;
// }

// /* =========================
//    Small pieces
// ========================= */

// class _HeaderRow extends StatelessWidget {
//   final String title;
//   final String status;
//   const _HeaderRow({required this.title, required this.status});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: Text(
//             title,
//             style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
//           ),
//         ),
//         _Badge(
//           text: status.isEmpty ? '-' : status,
//           tone: _badgeTone(status),
//         ),
//       ],
//     );
//   }
// }

// class _FloatingPhotosButton extends StatelessWidget {
//   final int count;
//   final VoidCallback onPressed;
//   const _FloatingPhotosButton({required this.count, required this.onPressed});

//   @override
//   Widget build(BuildContext context) {
//     return MouseRegion(
//       cursor: SystemMouseCursors.click,
//       child: InkWell(
//         onTap: onPressed,
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//           decoration: BoxDecoration(
//             color: Colors.black.withOpacity(0.75),
//             borderRadius: BorderRadius.circular(999),
//           ),
//           child: Row(
//             children: [
//               const Icon(Icons.photo_library_outlined, color: Colors.white, size: 18),
//               const SizedBox(width: 8),
//               Text('View Photos ($count)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _SubSectionMapCard extends StatelessWidget {
//   final String title;
//   final Map<String, dynamic> data;
//   const _SubSectionMapCard({required this.title, required this.data});

//   @override
//   Widget build(BuildContext context) {
//     if (data.isEmpty) {
//       return Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.6),
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: Colors.black.withOpacity(0.06)),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
//             const SizedBox(height: 8),
//             const Text('-', style: TextStyle(color: Colors.black54)),
//           ],
//         ),
//       );
//     }

//     final keys = data.keys.toList();

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.6),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.black.withOpacity(0.06)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
//           const SizedBox(height: 10),
//           for (final k in keys) _kv(_prettyKey(k), _cleanStr(data[k]).isEmpty ? '-' : _cleanStr(data[k])),
//         ],
//       ),
//     );
//   }
// }

// class _Card extends StatelessWidget {
//   final String title;
//   final Widget child;
//   const _Card({required this.title, required this.child});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 0,
//       color: Colors.black.withOpacity(0.02),
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
//             const SizedBox(height: 10),
//             child,
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _SmallMuted extends StatelessWidget {
//   final String text;
//   const _SmallMuted(this.text);

//   @override
//   Widget build(BuildContext context) {
//     return Text(text, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700));
//   }
// }

// class _Badge extends StatelessWidget {
//   final String text;
//   final _Tone tone;
//   const _Badge({required this.text, required this.tone});

//   @override
//   Widget build(BuildContext context) {
//     final bg = tone.bg;
//     final fg = tone.fg;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: fg.withOpacity(0.20)),
//       ),
//       child: Text(text, style: TextStyle(fontWeight: FontWeight.w900, color: fg)),
//     );
//   }
// }

// class _StatusChip extends StatelessWidget {
//   final String status;
//   const _StatusChip({required this.status});

//   @override
//   Widget build(BuildContext context) {
//     final s = status.trim().toLowerCase();
//     Color bg;
//     Color fg;

//     if (s == 'excellent') {
//       bg = Colors.green.withOpacity(0.12);
//       fg = Colors.green.shade800;
//     } else if (s == 'good') {
//       bg = Colors.blue.withOpacity(0.12);
//       fg = Colors.blue.shade800;
//     } else if (s == 'average') {
//       bg = Colors.orange.withOpacity(0.12);
//       fg = Colors.orange.shade800;
//     } else if (s == 'poor') {
//       bg = Colors.red.withOpacity(0.12);
//       fg = Colors.red.shade800;
//     } else {
//       bg = Colors.grey.withOpacity(0.12);
//       fg = Colors.grey.shade800;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
//       child: Text(status, style: TextStyle(fontWeight: FontWeight.w900, color: fg)),
//     );
//   }
// }

// class _RatingChip extends StatelessWidget {
//   final dynamic rating;
//   const _RatingChip({required this.rating});

//   @override
//   Widget build(BuildContext context) {
//     final text = (rating == null) ? '-' : rating.toString();
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.06),
//         borderRadius: BorderRadius.circular(999),
//       ),
//       child: Text('★ $text', style: const TextStyle(fontWeight: FontWeight.w900)),
//     );
//   }
// }

// /* =========================
//    Data helpers
// ========================= */

// class _PhotoRef {
//   final String url;
//   final String section;
//   const _PhotoRef({required this.url, required this.section});
// }

// Map<String, dynamic> _asMap(dynamic v) {
//   if (v is Map<String, dynamic>) return v;
//   if (v is Map) return Map<String, dynamic>.from(v);
//   return const <String, dynamic>{};
// }

// String _cleanStr(dynamic v) {
//   final s = (v ?? '').toString().trim();
//   if (s.isEmpty || s == 'null') return '';
//   return s;
// }

// double? _toDouble(dynamic v) {
//   if (v == null) return null;
//   if (v is num) return v.toDouble();
//   return double.tryParse(v.toString());
// }

// String _fmtIso(dynamic iso) {
//   final s = _cleanStr(iso);
//   if (s.isEmpty) return '';
//   final dt = DateTime.tryParse(s);
//   if (dt == null) return s;
//   String two(int x) => x.toString().padLeft(2, '0');
//   return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
// }

// Widget _kv(String k, String v) {
//   return Padding(
//     padding: const EdgeInsets.only(bottom: 6),
//     child: Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         SizedBox(width: 140, child: Text('$k:', style: const TextStyle(fontWeight: FontWeight.w900))),
//         Expanded(child: Text(v)),
//       ],
//     ),
//   );
// }

// String _prettyKey(String k) {
//   if (k.isEmpty) return k;
//   final out = k.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
//   return out[0].toUpperCase() + out.substring(1);
// }

// String _ratingLabel(double v) {
//   if (v >= 4.5) return 'Excellent';
//   if (v >= 3.5) return 'Good';
//   if (v >= 2.0) return 'Average';
//   return 'Poor';
// }

// class _Tone {
//   final Color bg;
//   final Color fg;
//   const _Tone(this.bg, this.fg);
// }

// _Tone _badgeTone(String label) {
//   final s = label.toLowerCase();
//   if (s.contains('excellent')) return _Tone(Colors.green.withOpacity(0.12), Colors.green.shade800);
//   if (s.contains('good')) return _Tone(Colors.blue.withOpacity(0.12), Colors.blue.shade800);
//   if (s.contains('average')) return _Tone(Colors.orange.withOpacity(0.12), Colors.orange.shade800);
//   if (s.contains('poor')) return _Tone(Colors.red.withOpacity(0.12), Colors.red.shade800);
//   if (s.contains('draft')) return _Tone(Colors.black.withOpacity(0.06), Colors.black87);
//   return _Tone(Colors.grey.withOpacity(0.12), Colors.grey.shade800);
// }



// lib/features/dashboards/user/inspection_report_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../shared/app_shell.dart';
import '../../../services/service_locator.dart';

/// ✅ IMPORTANT:
/// Set this to the SAME asset you used in StartInspectionPage for the top car image.
/// Example:
///   assets/images/top.jpg
///   assets/images/car_top_outline.png
const String kCarTopDamageAsset = 'assets/images/car_views/top.jpg';

class InspectionReportPage extends StatefulWidget {
  final String inspectionId;
  const InspectionReportPage({super.key, required this.inspectionId});

  @override
  State<InspectionReportPage> createState() => _InspectionReportPageState();
}

class _InspectionReportPageState extends State<InspectionReportPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = inspectionRequestsService.getInspectionById(widget.inspectionId);
  }

  void _retry() {
    setState(() {
      _future = inspectionRequestsService.getInspectionById(widget.inspectionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Inspection Report',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1150),
          child: FutureBuilder<Map<String, dynamic>>(
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
                      Text('Failed to load report: ${snap.error}'),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      )
                    ],
                  ),
                );
              }

              final root = snap.data ?? const <String, dynamic>{};
              final success = root['success'] == true;
              final message = (root['message'] ?? '').toString();

              final data = (root['data'] is Map)
                  ? Map<String, dynamic>.from(root['data'] as Map)
                  : const <String, dynamic>{};

              final inspection = (data['inspection'] is Map)
                  ? Map<String, dynamic>.from(data['inspection'] as Map)
                  : const <String, dynamic>{};

              if (!success || inspection.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    inspection.isEmpty
                        ? 'No inspection data found. $message'
                        : 'Failed to load report. $message',
                  ),
                );
              }

              return _ReportView(inspection: inspection, onRetry: _retry);
            },
          ),
        ),
      ),
    );
  }
}

/* =========================
   Report UI (PDF-like)
========================= */

class _ReportView extends StatefulWidget {
  final Map<String, dynamic> inspection;
  final VoidCallback onRetry;
  const _ReportView({required this.inspection, required this.onRetry});

  @override
  State<_ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<_ReportView> {
  final _scrollCtrl = ScrollController();

  bool _showFloatingPhotos = false;

  bool _viewerOpen = false;
  int _viewerIndex = 0;

  int _heroIndex = 0;

  late final List<_PhotoRef> _photos;
  late final Map<String, List<int>> _sectionToPhotoIdx;

  @override
  void initState() {
    super.initState();

    final built = _buildAllPhotos(widget.inspection);
    _photos = built.$1;
    _sectionToPhotoIdx = built.$2;

    _scrollCtrl.addListener(() {
      final show = _scrollCtrl.offset > 520 && _photos.isNotEmpty;
      if (show != _showFloatingPhotos) {
        setState(() => _showFloatingPhotos = show);
      }
    });

    if (_photos.isNotEmpty) _heroIndex = 0;
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _openViewer(int index) {
    if (_photos.isEmpty) return;
    setState(() {
      _viewerIndex = index.clamp(0, _photos.length - 1);
      _viewerOpen = true;
    });
  }

  void _closeViewer() {
    setState(() => _viewerOpen = false);
  }

  void _next() {
    if (_photos.isEmpty) return;
    setState(() => _viewerIndex = (_viewerIndex + 1) % _photos.length);
  }

  void _prev() {
    if (_photos.isEmpty) return;
    setState(() => _viewerIndex = (_viewerIndex - 1 + _photos.length) % _photos.length);
  }

  void _setHero(int index, {bool openViewer = false}) {
    if (_photos.isEmpty) return;
    setState(() => _heroIndex = index.clamp(0, _photos.length - 1));
    if (openViewer) _openViewer(_heroIndex);
  }

  void _openUrlInViewer(String url) {
    final u = url.trim();
    if (u.isEmpty) return;

    final idx = _photos.indexWhere((p) => p.url == u);
    if (idx >= 0) {
      _openViewer(idx);
      return;
    }

    // fallback: show a clean dialog even if it's not in the photo list
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Image'),
        content: _NetImageBox(
          url: u,
          width: 700,
          height: 420,
          borderRadius: BorderRadius.circular(14),
          fit: BoxFit.contain,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _openDamageDialog(_DamagePoint d, int idx) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Damage #$idx'),
        content: SizedBox(
          width: 720,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Damage ID: ${d.id}'),
              const SizedBox(height: 8),
              Text('Description: ${d.description.trim().isEmpty ? '-' : d.description.trim()}'),
              const SizedBox(height: 12),
              if (d.images.isEmpty)
                const Text('No photos uploaded.')
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final url in d.images)
                      _NetImageBox(
                        url: url,
                        width: 170,
                        height: 110,
                        onTap: () => _openUrlInViewer(url),
                      ),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inspection = widget.inspection;

    final template = _asMap(inspection['checklistTemplateId']);
    final inspector = _asMap(inspection['inspectorId']);

    // vehicle sections from your API response
    final vehicleDetails = _asMap(inspection['vehicleDetails']);
    final serviceWarrantyOverview = _asMap(inspection['serviceWarrantyOverview']);
    final interiorDetails = _asMap(inspection['interiorDetails']);
    final exteriorDetails = _asMap(inspection['exteriorDetails']);

    final types = (inspection['types'] as List?) ?? const [];

    // ✅ damages from report response
    final damages = _parseDamages(inspection);

    final id = (inspection['_id'] ?? inspection['id'] ?? '').toString();
    final status = (inspection['status'] ?? '').toString();
    final overallRating = _toDouble(inspection['overallRating']);

    final inspectionDate = _fmtIso(inspection['inspectionDate']);
    final completedAt = _fmtIso(inspection['completedAt']);
    final createdAt = _fmtIso(inspection['createdAt']);
    final updatedAt = _fmtIso(inspection['updatedAt']);

    final notes = _cleanStr(inspection['notes']);

    return Stack(
      children: [
        ListView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            _HeaderRow(
              title: 'Inspection Report',
              status: status,
            ),
            const SizedBox(height: 12),

            // top info cards
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 900;
                final gap = 12.0;

                final left = _Card(
                  title: 'Report Info',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kv('Inspection ID', id),
                      _kv('Overall Rating',
                          overallRating == null ? '-' : overallRating.toStringAsFixed(2)),
                      _kv('Inspection Date', inspectionDate.isEmpty ? '-' : inspectionDate),
                      if (completedAt.isNotEmpty) _kv('Completed At', completedAt),
                      _kv('Created At', createdAt.isEmpty ? '-' : createdAt),
                      _kv('Updated At', updatedAt.isEmpty ? '-' : updatedAt),
                    ],
                  ),
                );

                final right = _Card(
                  title: 'Template & Inspector',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kv('Template',
                          _cleanStr(template['name']).isEmpty ? '-' : _cleanStr(template['name'])),
                      _kv('Version',
                          _cleanStr(template['version']).isEmpty ? '-' : _cleanStr(template['version'])),
                      _kv(
                        'Inspector',
                        '${_cleanStr(inspector['firstName'])} ${_cleanStr(inspector['lastName'])}'
                                .trim()
                                .isEmpty
                            ? '-'
                            : '${_cleanStr(inspector['firstName'])} ${_cleanStr(inspector['lastName'])}'
                                .trim(),
                      ),
                      _kv('Email',
                          _cleanStr(inspector['email']).isEmpty ? '-' : _cleanStr(inspector['email'])),
                    ],
                  ),
                );

                if (!wide) {
                  return Column(
                    children: [
                      left,
                      const SizedBox(height: 12),
                      right,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: left),
                    SizedBox(width: gap),
                    Expanded(child: right),
                  ],
                );
              },
            ),

            const SizedBox(height: 12),

            // Vehicle Info (sub-sections)
            _Card(
              title: 'Vehicle Info',
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, c) {
                      final wide = c.maxWidth >= 900;
                      final vehicleDetailsCard =
                          _SubSectionMapCard(title: 'Vehicle Details', data: vehicleDetails);
                      final exteriorCard =
                          _SubSectionMapCard(title: 'Exterior Details', data: exteriorDetails);
                      final interiorCard =
                          _SubSectionMapCard(title: 'Interior Details', data: interiorDetails);
                      final serviceCard = _SubSectionMapCard(
                        title: 'Service / Warranty Overview',
                        data: serviceWarrantyOverview,
                      );

                      if (!wide) {
                        return Column(
                          children: [
                            vehicleDetailsCard,
                            const SizedBox(height: 10),
                            exteriorCard,
                            const SizedBox(height: 10),
                            interiorCard,
                            const SizedBox(height: 10),
                            serviceCard,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: vehicleDetailsCard),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: exteriorCard),
                                    const SizedBox(width: 12),
                                    Expanded(child: interiorCard),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                serviceCard,
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // ✅ Damages block (map + list)
            const SizedBox(height: 12),
            _DamagesBlock(
              damages: damages,
              carTopAssetPath: kCarTopDamageAsset,
              onTapDamage: (d, idx) => _openDamageDialog(d, idx),
              onOpenImage: (url) => _openUrlInViewer(url),
            ),

            const SizedBox(height: 12),

            // ✅ Overall Rating + Section Overview side-by-side
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 950;

                final overallCard = _Card(
                  title: 'Overall Rating',
                  child: LayoutBuilder(
                    builder: (context, c2) {
                      final label = _ratingLabel(overallRating ?? 0);

                      final gauge = SizedBox(
                        width: 300,
                        height: 150,
                        child: _OdometerGauge(value: overallRating ?? 0),
                      );

                      final details = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            overallRating == null ? '-' : overallRating.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          _Badge(text: label, tone: _badgeTone(label)),
                          const SizedBox(height: 8),
                          const Text('Scale: 0 to 5', style: TextStyle(color: Colors.black54)),
                        ],
                      );

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          gauge,
                          const SizedBox(width: 16),
                          Expanded(child: details),
                        ],
                      );
                    },
                  ),
                );

                final sectionOverviewCard = _Card(
                  title: 'Section Overview',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final t in types) _SectionOverviewLine(type: _asMap(t)),
                    ],
                  ),
                );

                if (!wide) {
                  return Column(
                    children: [
                      sectionOverviewCard,
                      const SizedBox(height: 12),
                      overallCard,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 6, child: sectionOverviewCard),
                    const SizedBox(width: 12),
                    Expanded(flex: 6, child: overallCard),
                  ],
                );
              },
            ),

            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Card(
                title: 'Overall Description',
                child: Text(notes),
              ),
            ],

            const SizedBox(height: 12),

            // Photos
            _PhotosBlock(
              photos: _photos,
              sectionToPhotoIdx: _sectionToPhotoIdx,
              heroIndex: _heroIndex,
              onHeroOpen: () => _openViewer(_heroIndex),
              onThumbClick: (index) => _setHero(index, openViewer: true),
              onOpenViewer: () => _openViewer(_heroIndex),
            ),

            const SizedBox(height: 18),

            // Checklist
            _Card(
              title: 'Checklist',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final t in types) ...[
                    const SizedBox(height: 6),
                    _ChecklistSection(type: _asMap(t)),
                    const SizedBox(height: 12),
                  ]
                ],
              ),
            ),
          ],
        ),

        if (_showFloatingPhotos)
          Positioned(
            right: 18,
            bottom: 18,
            child: _FloatingPhotosButton(
              count: _photos.length,
              onPressed: () => _openViewer(_heroIndex),
            ),
          ),

        if (_viewerOpen && _photos.isNotEmpty)
          Positioned.fill(
            child: _ImageViewerOverlay(
              photos: _photos,
              index: _viewerIndex,
              onClose: _closeViewer,
              onNext: _next,
              onPrev: _prev,
            ),
          ),
      ],
    );
  }

  // returns (photosList, section->indexes)
  (List<_PhotoRef>, Map<String, List<int>>) _buildAllPhotos(Map<String, dynamic> inspection) {
    final types = (inspection['types'] as List?) ?? const [];
    final refs = <_PhotoRef>[];
    final seen = <String>{};
    final sectionMap = <String, List<int>>{};

    void add(String url, String section) {
      final u = url.trim();
      if (u.isEmpty) return;
      if (seen.contains(u)) return;
      seen.add(u);
      final idx = refs.length;
      refs.add(_PhotoRef(url: u, section: section));
      sectionMap.putIfAbsent(section, () => []).add(idx);
    }

    for (final t in types) {
      final tm = _asMap(t);
      final section = _cleanStr(tm['typeName']).isEmpty ? 'Section' : _cleanStr(tm['typeName']);

      final overallPhotos =
          (tm['overallPhotos'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
      for (final u in overallPhotos) add(u, section);

      final items = (tm['checklistItems'] as List?) ?? const [];
      for (final it in items) {
        final im = _asMap(it);
        final photos =
            (im['photos'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
        for (final u in photos) add(u, section);
      }
    }

    // ✅ Add damage images into Photos viewer under section: "Damages"
    final damages = _parseDamages(inspection);
    for (final d in damages) {
      for (final u in d.images) {
        add(u, 'Damages');
      }
    }

    return (refs, sectionMap);
  }
}

/* =========================
   Damages (Map + List)
========================= */

class _DamagesBlock extends StatelessWidget {
  final List<_DamagePoint> damages;
  final String carTopAssetPath;
  final void Function(_DamagePoint d, int index) onTapDamage;
  final void Function(String url) onOpenImage;

  const _DamagesBlock({
    required this.damages,
    required this.carTopAssetPath,
    required this.onTapDamage,
    required this.onOpenImage,
  });

  @override
  Widget build(BuildContext context) {
    if (damages.isEmpty) {
      return const _Card(title: 'Damages', child: Text('No damages marked.'));
    }

    return Card(
      elevation: 0,
      color: Colors.black.withOpacity(0.02),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Damages (${damages.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 950;

                final map = _CarDamageMap(
                  assetPath: carTopAssetPath,
                  damages: damages,
                  onTapMarker: onTapDamage,
                );

                final list = _DamageList(
                  damages: damages,
                  onTapDamage: onTapDamage,
                  onOpenImage: onOpenImage,
                );

                if (!wide) {
                  return Column(
                    children: [
                      map,
                      const SizedBox(height: 12),
                      list,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: map),
                    const SizedBox(width: 12),
                    Expanded(flex: 5, child: list),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CarDamageMap extends StatelessWidget {
  final String assetPath;
  final List<_DamagePoint> damages;
  final void Function(_DamagePoint d, int index) onTapMarker;

  const _CarDamageMap({
    required this.assetPath,
    required this.damages,
    required this.onTapMarker,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ No InteractiveViewer here -> prevents scroll-wheel zooming
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        color: Colors.white.withOpacity(0.6),
        padding: const EdgeInsets.all(12),
        child: AspectRatio(
          // IMPORTANT: keep SAME ratio as StartInspectionPage for exact marker alignment
          aspectRatio: 16 / 9,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final h = c.maxHeight;

              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black.withOpacity(0.06),
                        child: const Center(child: Text('Car image not found (asset path)')),
                      ),
                    ),
                  ),
                  for (int i = 0; i < damages.length; i++)
                    _DamageMarker(
                      index: i + 1,
                      left: (damages[i].x * w).clamp(0, w),
                      top: (damages[i].y * h).clamp(0, h),
                      onTap: () => onTapMarker(damages[i], i + 1),
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

class _DamageMarker extends StatelessWidget {
  final int index;
  final double left;
  final double top;
  final VoidCallback onTap;

  const _DamageMarker({
    required this.index,
    required this.left,
    required this.top,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const size = 26.0;
    return Positioned(
      left: left - size / 2,
      top: top - size / 2,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DamageList extends StatelessWidget {
  final List<_DamagePoint> damages;
  final void Function(_DamagePoint d, int index) onTapDamage;
  final void Function(String url) onOpenImage;

  const _DamageList({
    required this.damages,
    required this.onTapDamage,
    required this.onOpenImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (int i = 0; i < damages.length; i++) ...[
            _DamageTile(
              index: i + 1,
              d: damages[i],
              onTap: () => onTapDamage(damages[i], i + 1),
              onOpenImage: onOpenImage,
            ),
            if (i != damages.length - 1) const Divider(height: 18),
          ],
        ],
      ),
    );
  }
}

class _DamageTile extends StatelessWidget {
  final int index;
  final _DamagePoint d;
  final VoidCallback onTap;
  final void Function(String url) onOpenImage;

  const _DamageTile({
    required this.index,
    required this.d,
    required this.onTap,
    required this.onOpenImage,
  });

  @override
  Widget build(BuildContext context) {
    final desc = d.description.trim().isEmpty ? '-' : d.description.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // left marker
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
          ),
          child: Center(
            child: Text(
              '$index',
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  onTap: onTap,
                  child: Text(
                    'Damage #$index',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text('Description: $desc', style: const TextStyle(color: Colors.black87)),
              const SizedBox(height: 6),
              Text('Damage ID: ${d.id}', style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 10),

              if (d.images.isEmpty)
                const Text('No damage photos uploaded.', style: TextStyle(color: Colors.black54))
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final url in d.images)
                      _NetImageBox(
                        url: url,
                        width: 120,
                        height: 78,
                        onTap: () => onOpenImage(url),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/* =========================
   Photos
========================= */

class _PhotosBlock extends StatelessWidget {
  final List<_PhotoRef> photos;
  final Map<String, List<int>> sectionToPhotoIdx;

  final int heroIndex;
  final VoidCallback onHeroOpen;
  final void Function(int index) onThumbClick;
  final VoidCallback onOpenViewer;

  const _PhotosBlock({
    required this.photos,
    required this.sectionToPhotoIdx,
    required this.heroIndex,
    required this.onHeroOpen,
    required this.onThumbClick,
    required this.onOpenViewer,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const _Card(
        title: 'Photos',
        child: Text('No photos uploaded.'),
      );
    }

    final heroUrl = photos[heroIndex.clamp(0, photos.length - 1)].url;

    return Card(
      elevation: 0,
      color: Colors.black.withOpacity(0.02),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Photos  (${photos.length}) • click any image to view',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onOpenViewer,
                  icon: const Icon(Icons.open_in_full),
                  label: const Text('View'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 950;

                final hero = _HeroTile(url: heroUrl, onOpen: onHeroOpen);

                final thumbs = _SectionThumbs(
                  photos: photos,
                  sectionToPhotoIdx: sectionToPhotoIdx,
                  onTapIndex: onThumbClick,
                );

                if (!wide) {
                  return Column(
                    children: [
                      hero,
                      const SizedBox(height: 12),
                      thumbs,
                    ],
                  );
                }

                const gap = 14.0;
                final heroWidth = (c.maxWidth - gap) * (7 / 12);
                final heroHeight = heroWidth * 9 / 16;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: hero),
                    const SizedBox(width: gap),
                    Expanded(
                      flex: 5,
                      child: SizedBox(
                        height: heroHeight,
                        child: thumbs,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroTile extends StatelessWidget {
  final String url;
  final VoidCallback onOpen;
  const _HeroTile({required this.url, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onOpen,
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _NetImageBox(
                  url: url,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.zero,
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.open_in_full, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Open', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionThumbs extends StatelessWidget {
  final List<_PhotoRef> photos;
  final Map<String, List<int>> sectionToPhotoIdx;
  final void Function(int index) onTapIndex;

  const _SectionThumbs({
    required this.photos,
    required this.sectionToPhotoIdx,
    required this.onTapIndex,
  });

  @override
  Widget build(BuildContext context) {
    final sections = sectionToPhotoIdx.keys.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final s in sections) ...[
              Text(s, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final idx in sectionToPhotoIdx[s] ?? const [])
                    _ThumbTile(
                      url: photos[idx].url,
                      onTap: () => onTapIndex(idx),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ]
          ],
        ),
      ),
    );
  }
}

class _ThumbTile extends StatelessWidget {
  final String url;
  final VoidCallback onTap;

  const _ThumbTile({
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 70,
      child: _NetImageBox(
        url: url,
        width: 110,
        height: 70,
        onTap: onTap,
      ),
    );
  }
}

/* =========================
   Viewer Overlay (popover)
========================= */

class _ImageViewerOverlay extends StatelessWidget {
  final List<_PhotoRef> photos;
  final int index;
  final VoidCallback onClose;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const _ImageViewerOverlay({
    required this.photos,
    required this.index,
    required this.onClose,
    required this.onNext,
    required this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    final i = index.clamp(0, photos.length - 1);
    final item = photos[i];

    return Material(
      color: Colors.black.withOpacity(0.75),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InkWell(onTap: onClose, child: const SizedBox()),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: Colors.black.withOpacity(0.55),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: InteractiveViewer(
                              child: _NetImageBox(
                                url: item.url,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton(
                              tooltip: 'Close',
                              onPressed: onClose,
                              icon: const Icon(Icons.close, color: Colors.white),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: _NavBtn(icon: Icons.chevron_left, onTap: onPrev),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: _NavBtn(icon: Icons.chevron_right, onTap: onNext),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.section}  •  ${i + 1} / ${photos.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

/* =========================
   Checklist (names + status + rating)
========================= */

class _ChecklistSection extends StatelessWidget {
  final Map<String, dynamic> type;
  const _ChecklistSection({required this.type});

  @override
  Widget build(BuildContext context) {
    final name = _cleanStr(type['typeName']).isEmpty ? 'Section' : _cleanStr(type['typeName']);
    final avg = type['averageRating'];

    final items = (type['checklistItems'] as List?) ?? const [];
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900))),
              _SmallMuted('Avg: ${_cleanStr(avg).isEmpty ? '-' : _cleanStr(avg)}'),
            ],
          ),
          const SizedBox(height: 10),
          const Text('No checklist items.', style: TextStyle(color: Colors.black54)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900))),
            _SmallMuted('Avg: ${_cleanStr(avg).isEmpty ? '-' : _cleanStr(avg)}'),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              for (final it in items) _ChecklistRow(item: _asMap(it)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ChecklistRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final pos = item['position'];
    final label = _cleanStr(item['label']).isEmpty ? '-' : _cleanStr(item['label']);
    final status = _cleanStr(item['status']).isEmpty ? '-' : _cleanStr(item['status']);
    final rating = item['rating'];
    final remarks = _cleanStr(item['remarks']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 7,
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    Text('${pos ?? ''}.', style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                    _StatusChip(status: status),
                    _RatingChip(rating: rating),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    remarks.trim().isEmpty ? '-' : remarks,
                    style: const TextStyle(color: Colors.black87, height: 1.25),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 18),
        ],
      ),
    );
  }
}

/* =========================
   Section Overview
========================= */

class _SectionOverviewLine extends StatelessWidget {
  final Map<String, dynamic> type;
  const _SectionOverviewLine({required this.type});

  @override
  Widget build(BuildContext context) {
    final name = _cleanStr(type['typeName']).isEmpty ? 'Section' : _cleanStr(type['typeName']);
    final avg = type['averageRating'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontWeight: FontWeight.w900)),
          Expanded(
            child: Text(
              '$name  •  Avg: ${_cleanStr(avg).isEmpty ? '-' : _cleanStr(avg)}',
              style: const TextStyle(height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================
   Odometer Gauge (0..5)
========================= */

class _OdometerGauge extends StatelessWidget {
  final double value;
  const _OdometerGauge({required this.value});

  @override
  Widget build(BuildContext context) {
    final double v = value.clamp(0.0, 5.0).toDouble();
    return CustomPaint(
      painter: _OdometerPainter(v),
      child: const SizedBox.expand(),
    );
  }
}

class _OdometerPainter extends CustomPainter {
  final double v;
  _OdometerPainter(this.v);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.92);
    final radius = math.min(size.width, size.height) * 0.78;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withOpacity(0.08);

    final rect = Rect.fromCircle(center: center, radius: radius);

    const start = math.pi;
    const sweep = math.pi;

    canvas.drawArc(rect, start, sweep, false, bgPaint);

    void seg(double from, double to, Color color) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.butt
        ..color = color;

      final a1 = start + (from / 5) * sweep;
      final sw = ((to - from) / 5) * sweep;
      canvas.drawArc(rect, a1, sw, false, p);
    }

    seg(0, 2, const Color(0xFFE53935));
    seg(2, 3.5, const Color(0xFFFB8C00));
    seg(3.5, 4.5, const Color(0xFF1E88E5));
    seg(4.5, 5, const Color(0xFF43A047));

    final tickPaint = Paint()
      ..color = Colors.black.withOpacity(0.55)
      ..strokeWidth = 2;

    for (int i = 0; i <= 5; i++) {
      final t = i / 5;
      final ang = start + t * sweep;
      final p1 = Offset(
        center.dx + math.cos(ang) * (radius - 6),
        center.dy + math.sin(ang) * (radius - 6),
      );
      final p2 = Offset(
        center.dx + math.cos(ang) * (radius - 18),
        center.dy + math.sin(ang) * (radius - 18),
      );
      canvas.drawLine(p1, p2, tickPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '$i',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black54),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final lp = Offset(
        center.dx + math.cos(ang) * (radius - 36) - tp.width / 2,
        center.dy + math.sin(ang) * (radius - 36) - tp.height / 2,
      );
      tp.paint(canvas, lp);
    }

    final needleAng = start + (v / 5) * sweep;
    final needleEnd = Offset(
      center.dx + math.cos(needleAng) * (radius - 28),
      center.dy + math.sin(needleAng) * (radius - 28),
    );

    final needlePaint = Paint()
      ..color = Colors.black.withOpacity(0.75)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, needlePaint);

    canvas.drawCircle(center, 5.5, Paint()..color = Colors.white);
    canvas.drawCircle(center, 4.8, Paint()..color = Colors.black.withOpacity(0.7));
  }

  @override
  bool shouldRepaint(covariant _OdometerPainter oldDelegate) => oldDelegate.v != v;
}

/* =========================
   Small pieces
========================= */

class _HeaderRow extends StatelessWidget {
  final String title;
  final String status;
  const _HeaderRow({required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        _Badge(
          text: status.isEmpty ? '-' : status,
          tone: _badgeTone(status),
        ),
      ],
    );
  }
}

class _FloatingPhotosButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;
  const _FloatingPhotosButton({required this.count, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              const Icon(Icons.photo_library_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'View Photos ($count)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubSectionMapCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;
  const _SubSectionMapCard({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('-', style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }

    final keys = data.keys.toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          for (final k in keys)
            _kv(_prettyKey(k), _cleanStr(data[k]).isEmpty ? '-' : _cleanStr(data[k])),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.black.withOpacity(0.02),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _SmallMuted extends StatelessWidget {
  final String text;
  const _SmallMuted(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700));
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final _Tone tone;
  const _Badge({required this.text, required this.tone});

  @override
  Widget build(BuildContext context) {
    final bg = tone.bg;
    final fg = tone.fg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.20)),
      ),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w900, color: fg)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.trim().toLowerCase();
    Color bg;
    Color fg;

    if (s == 'excellent') {
      bg = Colors.green.withOpacity(0.12);
      fg = Colors.green.shade800;
    } else if (s == 'good') {
      bg = Colors.blue.withOpacity(0.12);
      fg = Colors.blue.shade800;
    } else if (s == 'average') {
      bg = Colors.orange.withOpacity(0.12);
      fg = Colors.orange.shade800;
    } else if (s == 'poor') {
      bg = Colors.red.withOpacity(0.12);
      fg = Colors.red.shade800;
    } else {
      bg = Colors.grey.withOpacity(0.12);
      fg = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status, style: TextStyle(fontWeight: FontWeight.w900, color: fg)),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final dynamic rating;
  const _RatingChip({required this.rating});

  @override
  Widget build(BuildContext context) {
    final text = (rating == null) ? '-' : rating.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('★ $text', style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

/* =========================
   Clean Network Image (no red 403 text in UI)
========================= */

class _NetImageBox extends StatelessWidget {
  final String url;

  final double width;
  final double height;

  final BoxFit fit;
  final BorderRadius borderRadius;

  final VoidCallback? onTap;

  const _NetImageBox({
    required this.url,
    this.width = 110,
    this.height = 70,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        url,
        fit: fit,
        width: width == double.infinity ? null : width,
        height: height == double.infinity ? null : height,
        // ✅ never show the error string in UI
        errorBuilder: (_, __, ___) => Container(
          width: width == double.infinity ? null : width,
          height: height == double.infinity ? null : height,
          color: Colors.black.withOpacity(0.06),
          child: const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.black45),
          ),
        ),
        loadingBuilder: (context, w, progress) {
          if (progress == null) return w;
          return Container(
            width: width == double.infinity ? null : width,
            height: height == double.infinity ? null : height,
            color: Colors.black.withOpacity(0.06),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
      ),
    );

    if (onTap == null) return child;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}

/* =========================
   Data helpers + Models
========================= */

class _PhotoRef {
  final String url;
  final String section;
  const _PhotoRef({required this.url, required this.section});
}

class _DamagePoint {
  final String id;
  final String description;
  final List<String> images;
  final double x; // 0..1
  final double y; // 0..1

  const _DamagePoint({
    required this.id,
    required this.description,
    required this.images,
    required this.x,
    required this.y,
  });
}

List<_DamagePoint> _parseDamages(Map<String, dynamic> inspection) {
  final dc = _asMap(inspection['damaged_coordinates']);
  final list = (dc['data'] as List?) ?? const [];

  final out = <_DamagePoint>[];

  for (final item in list) {
    final m = _asMap(item);
    final coords = _asMap(m['coordinates']);

    final x = (_toDouble(coords['x']) ?? 0.0).clamp(0.0, 1.0).toDouble();
    final y = (_toDouble(coords['y']) ?? 0.0).clamp(0.0, 1.0).toDouble();

    final images = ((m['damageImages'] as List?) ?? const [])
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty && s != 'null')
        .toList();

    final id = _cleanStr(m['damageid']).isNotEmpty
        ? _cleanStr(m['damageid'])
        : (_cleanStr(m['_id']).isNotEmpty ? _cleanStr(m['_id']) : _cleanStr(m['id']));

    out.add(
      _DamagePoint(
        id: id.isEmpty ? '-' : id,
        description: _cleanStr(m['damagedescription']),
        images: images,
        x: x,
        y: y,
      ),
    );
  }

  return out;
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return const <String, dynamic>{};
}

String _cleanStr(dynamic v) {
  final s = (v ?? '').toString().trim();
  if (s.isEmpty || s == 'null') return '';
  return s;
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

String _fmtIso(dynamic iso) {
  final s = _cleanStr(iso);
  if (s.isEmpty) return '';
  final dt = DateTime.tryParse(s);
  if (dt == null) return s;
  String two(int x) => x.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
}

Widget _kv(String k, String v) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 140, child: Text('$k:', style: const TextStyle(fontWeight: FontWeight.w900))),
        Expanded(child: Text(v)),
      ],
    ),
  );
}

String _prettyKey(String k) {
  if (k.isEmpty) return k;
  final out = k.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
  return out[0].toUpperCase() + out.substring(1);
}

String _ratingLabel(double v) {
  if (v >= 4.5) return 'Excellent';
  if (v >= 3.5) return 'Good';
  if (v >= 2.0) return 'Average';
  return 'Poor';
}

class _Tone {
  final Color bg;
  final Color fg;
  const _Tone(this.bg, this.fg);
}

_Tone _badgeTone(String label) {
  final s = label.toLowerCase();
  if (s.contains('excellent')) return _Tone(Colors.green.withOpacity(0.12), Colors.green.shade800);
  if (s.contains('good')) return _Tone(Colors.blue.withOpacity(0.12), Colors.blue.shade800);
  if (s.contains('average')) return _Tone(Colors.orange.withOpacity(0.12), Colors.orange.shade800);
  if (s.contains('poor')) return _Tone(Colors.red.withOpacity(0.12), Colors.red.shade800);
  if (s.contains('draft')) return _Tone(Colors.black.withOpacity(0.06), Colors.black87);
  return _Tone(Colors.grey.withOpacity(0.12), Colors.grey.shade800);
}

