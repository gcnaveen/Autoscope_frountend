// lib/features/dashboards/user/inspection_report_page.dart
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../shared/app_shell.dart';
import '../../../services/service_locator.dart';

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
                    inspection.isEmpty ? 'No inspection data found. $message' : 'Failed to load report. $message',
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
   Report UI
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
  // Anchor placed as the first child of the ListView (a RenderObjectWidget),
  // used as the Y=0 reference for section scroll calculations.
  final _scrollAnchorKey = GlobalKey();

  // #22/25 – one GlobalKey per checklist section, keyed by typeName
  final Map<String, GlobalKey> _sectionKeys = {};

  bool _showScrollToTop = false;


  bool _viewerOpen = false;
  int _viewerIndex = 0;

  int _heroIndex = 0;

  late final List<_PhotoRef> _photos;
  late final Map<String, List<int>> _sectionToPhotoIdx;

  // ✅ Videos
  late final List<_VideoRef> _videos;
  late final Map<String, List<int>> _sectionToVideoIdx;

  // ✅ Reviews
  late final String _inspectionRequestId;
  bool _canReview = false;
  bool _reviewSubmitted = false;
  bool _reviewPopupDismissed = false;

  @override
  void initState() {
    super.initState();

    // Pre-populate section keys for #22/25 hyperlink-scroll
    final rawTypes = (widget.inspection['types'] as List?) ?? const [];
    for (final t in rawTypes) {
      final name = _cleanStr(_asMap(t)['typeName']);
      if (name.isNotEmpty) _sectionKeys[name] = GlobalKey();
    }

    final built = _buildAllPhotos(widget.inspection);
    _photos = built.$1;
    _sectionToPhotoIdx = built.$2;

    final builtV = _buildAllVideos(widget.inspection);
    _videos = builtV.$1;
    _sectionToVideoIdx = builtV.$2;

    _scrollCtrl.addListener(() {
      final show = _scrollCtrl.offset > 520;
      if (show != _showScrollToTop) {
        setState(() => _showScrollToTop = show);
      }
    });

    if (_photos.isNotEmpty) _heroIndex = 0;

    // ✅ Review eligibility: only when completed + has inspectionRequestId
    final status = _cleanStr(widget.inspection['status']).toLowerCase();
    final completedAt = _cleanStr(widget.inspection['completedAt']);
    final isCompleted = status == 'completed' || completedAt.isNotEmpty;

    _inspectionRequestId = _extractId(widget.inspection['inspectionRequestId']);
    _canReview = isCompleted && _inspectionRequestId.isNotEmpty;

    if (_canReview) {
      _reviewSubmitted = _lsBool('review_submitted_$_inspectionRequestId');
      _reviewPopupDismissed = _lsBool('review_popup_dismissed_$_inspectionRequestId');

      // auto popup only if not submitted and not dismissed before
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_reviewSubmitted && !_reviewPopupDismissed) {
          _openReviewDialog(auto: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToSection(String typeName) {
    final key = _sectionKeys[typeName];
    if (!_scrollCtrl.hasClients) return;
    final ctx = key?.currentContext;
    if (ctx == null) return;

    final sectionBox = ctx.findRenderObject() as RenderBox?;
    if (sectionBox == null || !sectionBox.attached) return;

    final anchorBox = _scrollAnchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (anchorBox == null) return;

    final target = (sectionBox.localToGlobal(Offset.zero).dy - anchorBox.localToGlobal(Offset.zero).dy)
        .clamp(_scrollCtrl.position.minScrollExtent, _scrollCtrl.position.maxScrollExtent);

    _scrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
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

  void _nextHero() {
    if (_photos.isEmpty) return;
    setState(() => _heroIndex = (_heroIndex + 1) % _photos.length);
  }

  void _prevHero() {
    if (_photos.isEmpty) return;
    setState(() => _heroIndex = (_heroIndex - 1 + _photos.length) % _photos.length);
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

  void _openVideoDialog(String url) {
    final u = url.trim();
    if (u.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Video'),
        content: SizedBox(
          width: 900,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _HtmlVideoPlayer(url: u),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  // ✅ Review dialog
  void _openReviewDialog({required bool auto}) {
    if (!_canReview) return;
    if (_reviewSubmitted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ReviewDialog(
        inspectionRequestId: _inspectionRequestId,
        onSubmitted: () {
          if (!mounted) return;
          setState(() => _reviewSubmitted = true);
          _setLsBool('review_submitted_$_inspectionRequestId', true);
        },
        onDismissed: () {
          _setLsBool('review_popup_dismissed_$_inspectionRequestId', true);
          _reviewPopupDismissed = true;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inspection = widget.inspection;

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
    final virId = id.isEmpty ? '-' : _formatVirId(id, inspection['inspectionDate']);
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
          // Force all children to be built eagerly so GlobalKeys are attached
          // even before the user scrolls down to the checklist section.
          cacheExtent: 9999999,
          children: [
            SizedBox(key: _scrollAnchorKey, height: 0),
            _HeaderRow(
              title: 'Inspection Report',
              onDownload: _downloadReport,
              showReview: _canReview,
              reviewSubmitted: _reviewSubmitted,
              onReview: (_canReview && !_reviewSubmitted) ? () => _openReviewDialog(auto: false) : null,
            ),
            const SizedBox(height: 12),

            // top info cards
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 900;
                final gap = 12.0;

                final left = _Card(
                  title: 'Report Information',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kv('Inspection ID', virId),
                      _kv('Overall Rating', overallRating == null ? '-' : overallRating.toStringAsFixed(2)),
                      _kv('Inspection Date', inspectionDate.isEmpty ? '-' : inspectionDate),
                      if (completedAt.isNotEmpty) _kv('Completed At', completedAt),
                      _kv('Created At', createdAt.isEmpty ? '-' : createdAt),
                      _kv('Updated At', updatedAt.isEmpty ? '-' : updatedAt),
                    ],
                  ),
                );

                final right = _Card(
                  title: 'Inspector',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kv(
                        'Inspector',
                        '${_cleanStr(inspector['firstName'])} ${_cleanStr(inspector['lastName'])}'.trim().isEmpty
                            ? '-'
                            : '${_cleanStr(inspector['firstName'])} ${_cleanStr(inspector['lastName'])}'.trim(),
                      ),
                      _kv('Email', _cleanStr(inspector['email']).isEmpty ? '-' : _cleanStr(inspector['email'])),
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

            // Vehicle Information (sub-sections)
            _Card(
              title: 'Vehicle Information',
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, c) {
                      final wide = c.maxWidth >= 900;

                      // ✅ Vehicle details card that shows Chassis as IMAGE instead of URL text
                      final vehicleDetailsCard = _VehicleDetailsCard(
                        title: 'Vehicle Details',
                        data: vehicleDetails,
                        onOpenImage: _openUrlInViewer,
                      );

                      final exteriorCard = _SubSectionMapCard(title: 'Exterior Details', data: exteriorDetails);
                      final interiorCard = _SubSectionMapCard(title: 'Interior Details', data: interiorDetails);
                      final serviceCard =
                          _SubSectionMapCard(title: 'Service / Warranty Overview', data: serviceWarrantyOverview);

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

            const SizedBox(height: 12),

            // Overall Rating + Section Overview
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
                  child: _SectionOverviewGrid(
                    types: types,
                    onTapSection: _scrollToSection,
                  ),
                );

                final summaryCard = _QuickSummaryCard(
                  types: types,
                  photosCount: _photos.length,
                  damagesCount: damages.length,
                );

                if (!wide) {
                  return Column(
                    children: [
                      sectionOverviewCard,
                      const SizedBox(height: 12),
                      overallCard,
                      const SizedBox(height: 12),
                      summaryCard,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: sectionOverviewCard),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          overallCard,
                          const SizedBox(height: 12),
                          summaryCard,
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            // Damage Overview — below Service Overview and Overall Rating
            const SizedBox(height: 12),
            _DamagesBlock(
              damages: damages,
              carTopAssetPath: kCarTopDamageAsset,
              onOpenImage: (url) => _openUrlInViewer(url),
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
              onThumbClick: (index) => _setHero(index, openViewer: false),
              onOpenViewer: () => _openViewer(_heroIndex),
              onPrevHero: _prevHero,
              onNextHero: _nextHero,
            ),

            // ✅ Videos
            if (_videos.isNotEmpty) ...[
              const SizedBox(height: 12),
              _VideosBlock(
                videos: _videos,
                sectionToVideoIdx: _sectionToVideoIdx,
                onOpen: (url) => _openVideoDialog(url),
              ),
            ] else ...[
              const SizedBox(height: 12),
              const _Card(
                title: 'Videos',
                child: Text('No videos uploaded.'),
              ),
            ],

            const SizedBox(height: 18),

            // Checklist
            _Card(
              title: 'Checklist',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final t in types) ...[
                    const SizedBox(height: 6),
                    (() {
                      final tm = _asMap(t);
                      final typeName = _cleanStr(tm['typeName']);
                      final gk = _sectionKeys[typeName];
                      // SizedBox (a RenderObjectWidget) is required — KeyedSubtree has no
                      // RenderObject so Scrollable.ensureVisible can't find its position.
                      return SizedBox(
                        key: gk,
                        width: double.infinity,
                        child: _ChecklistSection(type: tm),
                      );
                    })(),
                    const SizedBox(height: 12),
                  ]
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Disclaimer
            _Card(
              title: 'Disclaimer',
              child: const Text(
                'Auto Scope inspects vehicles to the best of its ability based on visible and accessible '
                'components at the time of inspection. This report does not constitute a guarantee or '
                'warranty of the vehicle\'s condition. Auto Scope shall not be liable for any latent '
                'defects or issues that were not visible or accessible during inspection. The findings '
                'in this report are valid at the time of inspection only and may change over time. '
                'This report is prepared solely for the use of the commissioning party and must not '
                'be relied upon by any third party without written consent from Auto Scope.',
                style: TextStyle(color: Colors.black87, height: 1.6),
              ),
            ),

            const SizedBox(height: 12),

            // Company signature & stamp
            _Card(
              title: 'Authorized By',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Auto Scope Vehicle Inspection Services',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, c) {
                      final wide = c.maxWidth >= 500;
                      final stampBox = _SignatureBox(label: 'Company Stamp');
                      final sigBox = _SignatureBox(label: 'Authorized Signature');
                      if (!wide) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [stampBox, const SizedBox(height: 16), sigBox],
                        );
                      }
                      return Row(
                        children: [
                          stampBox,
                          const SizedBox(width: 40),
                          sigBox,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
          ],
        ),

        if (_showScrollToTop)
          Positioned(
            right: 18,
            bottom: 18,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                onTap: () => _scrollCtrl.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                ),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Back to Top',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
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

    // Add chassis photo into Photos viewer under "Vehicle Details"
    final vehicleDetails = _asMap(inspection['vehicleDetails']);
    final chassisPhoto = _cleanStr(vehicleDetails['chassisPhotoUrl']);
    final chassisNo = _cleanStr(vehicleDetails['chassisNo']);
    if (_isHttpUrl(chassisPhoto)) {
      add(chassisPhoto, 'Vehicle Details');
    } else if (_isHttpUrl(chassisNo)) {
      // backward compat: old records stored URL in chassisNo
      add(chassisNo, 'Vehicle Details');
    }

    for (final t in types) {
      final tm = _asMap(t);
      final section = _cleanStr(tm['typeName']).isEmpty ? 'Section' : _cleanStr(tm['typeName']);

      final overallPhotos = (tm['overallPhotos'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
      for (final u in overallPhotos) add(u, section);

      final items = (tm['checklistItems'] as List?) ?? const [];
      for (final it in items) {
        final im = _asMap(it);
        final photos = (im['photos'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
        for (final u in photos) add(u, section);
      }
    }

    // Add damage images into Photos viewer under section: "Damages"
    final damages = _parseDamages(inspection);
    for (final d in damages) {
      for (final u in d.images) {
        add(u, 'Damages');
      }
    }

    return (refs, sectionMap);
  }

  // returns (videosList, section->indexes)
  (List<_VideoRef>, Map<String, List<int>>) _buildAllVideos(Map<String, dynamic> inspection) {
    final types = (inspection['types'] as List?) ?? const [];
    final refs = <_VideoRef>[];
    final seen = <String>{};
    final sectionMap = <String, List<int>>{};

    void add(String url, String section) {
      final u = url.trim();
      if (u.isEmpty) return;
      if (seen.contains(u)) return;
      seen.add(u);
      final idx = refs.length;
      refs.add(_VideoRef(url: u, section: section));
      sectionMap.putIfAbsent(section, () => []).add(idx);
    }

    for (final t in types) {
      final tm = _asMap(t);
      final section = _cleanStr(tm['typeName']).isEmpty ? 'Section' : _cleanStr(tm['typeName']);

      // Support both keys (depends on backend response)
      final vids = (tm['videos'] as List?) ?? (tm['overallVideos'] as List?) ?? const [];

      for (final v in vids) {
        final u = _cleanStr(v);
        if (u.isEmpty) continue;
        add(u, section);
      }
    }

    return (refs, sectionMap);
  }

  // PDF download
  void _downloadReport() async {
    if (_viewerOpen) _closeViewer();

    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF download is available on Web.')),
      );
      return;
    }

    try {
      final inspectionId = (widget.inspection['_id'] ?? widget.inspection['id'] ?? '').toString().trim();
      if (inspectionId.isEmpty) throw Exception('Missing inspectionId');

      final pdf = await inspectionRequestsService.getInspectionReportPdf(inspectionId);

      final blob = html.Blob([pdf.bytes], pdf.contentType);
      final url = html.Url.createObjectUrlFromBlob(blob);

      final a = html.AnchorElement(href: url)
        ..style.display = 'none'
        ..download = pdf.fileName;

      html.document.body?.children.add(a);
      a.click();
      a.remove();

      html.Url.revokeObjectUrl(url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF download failed: $e')),
      );
    }
  }
}

/* =========================
   Review Dialog
========================= */

class _ReviewDialog extends StatefulWidget {
  final String inspectionRequestId;
  final VoidCallback onSubmitted;
  final VoidCallback onDismissed;

  const _ReviewDialog({
    required this.inspectionRequestId,
    required this.onSubmitted,
    required this.onDismissed,
  });

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 0;
  final _ctrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _ctrl.text.trim();
    if (_rating <= 0) return;
    if (comment.isEmpty) return;

    setState(() => _busy = true);
    try {
      final res = await reviewsService.submitReview(
        inspectionRequestId: widget.inspectionRequestId,
        rating: _rating,
        comment: comment,
      );

      final ok = res['success'] == true;
      if (!mounted) return;

      if (ok) {
        widget.onSubmitted();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks! Your review is submitted for approval.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submit failed: ${res['message'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _star(int i) {
    final filled = i <= _rating;
    return IconButton(
      onPressed: _busy ? null : () => setState(() => _rating = i),
      icon: Icon(filled ? Icons.star : Icons.star_border, color: Colors.amber.shade700),
      tooltip: '$i',
    );
  }

  void _dismiss() {
    widget.onDismissed();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_busy && _rating > 0 && _ctrl.text.trim().isNotEmpty;

    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Rate your inspection')),
          IconButton(
            tooltip: 'Close',
            onPressed: _busy ? null : _dismiss,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your review will appear on the website after admin approval.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Row(children: [_star(1), _star(2), _star(3), _star(4), _star(5)]),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              enabled: !_busy,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Comment',
                hintText: 'Write your experience…',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : _dismiss,
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: canSubmit ? _submit : null,
          child: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Submit'),
        ),
      ],
    );
  }
}

/* =========================
   Section Overview
========================= */

class _SectionOverviewGrid extends StatelessWidget {
  final List<dynamic> types;
  final void Function(String typeName)? onTapSection;
  const _SectionOverviewGrid({required this.types, this.onTapSection});

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) {
      return const Text('No sections found.', style: TextStyle(color: Colors.black54));
    }

    final list = types.map((e) => _asMap(e)).toList();

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 520 ? 2 : 1;
        const gap = 12.0;

        final tileW = (c.maxWidth - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in list)
              SizedBox(
                width: tileW,
                child: _SectionOverviewTile(
                  type: t,
                  onTap: onTapSection == null
                      ? null
                      : () => onTapSection!(_cleanStr(t['typeName'])),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SectionOverviewTile extends StatelessWidget {
  final Map<String, dynamic> type;
  final VoidCallback? onTap;
  const _SectionOverviewTile({required this.type, this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = _cleanStr(type['typeName']).isEmpty ? 'Section' : _cleanStr(type['typeName']);
    final avg = _toDouble(type['averageRating']) ?? 0.0;
    final items = (type['checklistItems'] as List?) ?? const [];
    final itemCount = items.length;

    final v = (avg / 5.0).clamp(0.0, 1.0);

    Color toneFg() {
      if (avg >= 4.5) return Colors.green.shade800;
      if (avg >= 3.5) return Colors.blue.shade800;
      if (avg >= 2.0) return Colors.orange.shade900;
      return Colors.red.shade800;
    }

    Color toneBg() {
      final fg = toneFg();
      return fg.withValues(alpha: 0.10);
    }

    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.view_list_outlined, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: toneBg(),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: toneFg().withValues(alpha: 0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14, color: toneFg()),
                    const SizedBox(width: 6),
                    Text(
                      avg.toStringAsFixed(2),
                      style: TextStyle(fontWeight: FontWeight.w900, color: toneFg()),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$itemCount items',
            style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 6,
              backgroundColor: Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(toneFg().withValues(alpha: 0.85)),
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

/* =========================
   Right-side Summary
========================= */

class _QuickSummaryCard extends StatelessWidget {
  final List<dynamic> types;
  final int photosCount;
  final int damagesCount;

  const _QuickSummaryCard({
    required this.types,
    required this.photosCount,
    required this.damagesCount,
  });

  int _totalItems() {
    int count = 0;
    for (final t in types) {
      final m = _asMap(t);
      final items = (m['checklistItems'] as List?) ?? const [];
      count += items.length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final sections = types.length;
    final items = _totalItems();

    return _Card(
      title: 'Summary',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _MiniStat(icon: Icons.view_list_outlined, label: 'Sections', value: '$sections'),
          _MiniStat(icon: Icons.checklist_outlined, label: 'Items', value: '$items'),
          _MiniStat(icon: Icons.photo_library_outlined, label: 'Photos', value: '$photosCount'),
          _MiniStat(icon: Icons.place_outlined, label: 'Damages', value: '$damagesCount'),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w800)),
          const SizedBox(width: 10),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

/* =========================
   Damages (Map + List)
========================= */

class _DamagesBlock extends StatefulWidget {
  final List<_DamagePoint> damages;
  final String carTopAssetPath;
  final void Function(String url) onOpenImage;

  const _DamagesBlock({
    required this.damages,
    required this.carTopAssetPath,
    required this.onOpenImage,
  });

  @override
  State<_DamagesBlock> createState() => _DamagesBlockState();
}

class _DamagesBlockState extends State<_DamagesBlock> {
  int? _selectedIdx;

  @override
  Widget build(BuildContext context) {
    if (widget.damages.isEmpty) {
      return const _Card(title: 'Damages', child: Text('No damages marked.'));
    }

    final selected = _selectedIdx != null ? widget.damages[_selectedIdx!] : null;

    return Card(
      elevation: 0,
      color: Colors.black.withValues(alpha: 0.02),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Damages (${widget.damages.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            // Full-width landscape damage map
            _CarDamageMap(
              assetPath: widget.carTopAssetPath,
              damages: widget.damages,
              onTapMarker: (d, idx) {
                setState(() {
                  _selectedIdx = (_selectedIdx == idx - 1) ? null : idx - 1;
                });
              },
            ),
            // Inline preview shown when a marker is tapped
            if (selected != null) ...[
              const SizedBox(height: 12),
              _DamagePreview(
                damage: selected,
                index: _selectedIdx! + 1,
                onOpenImage: widget.onOpenImage,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CarDamageMap extends StatefulWidget {
  final String assetPath;
  final List<_DamagePoint> damages;
  final void Function(_DamagePoint d, int index) onTapMarker;

  const _CarDamageMap({
    required this.assetPath,
    required this.damages,
    required this.onTapMarker,
  });

  @override
  State<_CarDamageMap> createState() => _CarDamageMapState();
}

class _CarDamageMapState extends State<_CarDamageMap> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        color: Colors.white.withValues(alpha: 0.6),
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            // Car image is portrait (≈0.764:1); rotating 90° CW → landscape ratio ≈ 1.308:1
            const imgW = 574.0;
            const imgH = 751.0;
            final h = w * imgW / imgH; // landscape height after 90° rotation

            return SizedBox(
              width: w,
              height: h,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RotatedBox(
                      quarterTurns: 1, // 90° CW → portrait car becomes landscape
                      child: Image.asset(
                        widget.assetPath,
                        fit: BoxFit.fill,
                        errorBuilder: (_, e, st) => Container(
                          color: Colors.black.withValues(alpha: 0.06),
                          child: const Center(child: Text('Car image not found')),
                        ),
                      ),
                    ),
                  ),
                  // After 90° CW rotation: new_x = old_y, new_y = 1 - old_x
                  for (int i = 0; i < widget.damages.length; i++)
                    _DamageMarker(
                      index: i + 1,
                      left: (widget.damages[i].y * w).clamp(0, w),
                      top: ((1 - widget.damages[i].x) * h).clamp(0, h),
                      onTap: () => widget.onTapMarker(widget.damages[i], i + 1),
                    ),
                ],
              ),
            );
          },
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
                  color: Colors.black.withValues(alpha: 0.20),
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

class _DamagePreview extends StatelessWidget {
  final _DamagePoint damage;
  final int index;
  final void Function(String url) onOpenImage;

  const _DamagePreview({
    required this.damage,
    required this.index,
    required this.onOpenImage,
  });

  @override
  Widget build(BuildContext context) {
    final desc = damage.description.trim().isEmpty ? '-' : damage.description.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Damage #$index',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: Colors.black87)),
        ],
      ),
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
  final VoidCallback onPrevHero;
  final VoidCallback onNextHero;

  const _PhotosBlock({
    required this.photos,
    required this.sectionToPhotoIdx,
    required this.heroIndex,
    required this.onHeroOpen,
    required this.onThumbClick,
    required this.onOpenViewer,
    required this.onPrevHero,
    required this.onNextHero,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const _Card(
        title: 'Photos',
        child: Text('No photos uploaded.'),
      );
    }

    final clampedIdx = heroIndex.clamp(0, photos.length - 1);
    final heroRef = photos[clampedIdx];

    return Card(
      elevation: 0,
      color: Colors.black.withValues(alpha: 0.02),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Photos  (${photos.length}) • click thumbnail to preview',
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

                final hero = _HeroTile(
                  url: heroRef.url,
                  caption: '${heroRef.section}  •  ${clampedIdx + 1} / ${photos.length}',
                  onOpen: onHeroOpen,
                  onPrev: onPrevHero,
                  onNext: onNextHero,
                );

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
  final String caption;
  final VoidCallback onOpen;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _HeroTile({
    required this.url,
    required this.caption,
    required this.onOpen,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          // Main image (tap to open full viewer)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              onTap: onOpen,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _NetImageBox(
                  url: url,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          ),
          // Left nav button
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(child: _NavBtn(icon: Icons.chevron_left, onTap: onPrev)),
          ),
          // Right nav button
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(child: _NavBtn(icon: Icons.chevron_right, onTap: onNext)),
          ),
          // Caption + open button at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onOpen,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_full, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Open', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
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
   Videos
========================= */

class _VideosBlock extends StatelessWidget {
  final List<_VideoRef> videos;
  final Map<String, List<int>> sectionToVideoIdx;
  final void Function(String url) onOpen;

  const _VideosBlock({
    required this.videos,
    required this.sectionToVideoIdx,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final sections = sectionToVideoIdx.keys.toList();

    return Card(
      elevation: 0,
      color: Colors.black.withValues(alpha: 0.02),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Videos  (${videos.length}) • click to play',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            for (final s in sections) ...[
              Text(s, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final idx in sectionToVideoIdx[s] ?? const [])
                    _VideoTile(
                      url: videos[idx].url,
                      onTap: () => onOpen(videos[idx].url),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final String url;
  final VoidCallback onTap;

  const _VideoTile({required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 110,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.black.withValues(alpha: 0.08),
              child: const Center(
                child: Icon(Icons.play_circle_fill, size: 44),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final Set<String> _registeredVideoViews = <String>{};

class _HtmlVideoPlayer extends StatefulWidget {
  final String url;
  const _HtmlVideoPlayer({required this.url});

  @override
  State<_HtmlVideoPlayer> createState() => _HtmlVideoPlayerState();
}

class _HtmlVideoPlayerState extends State<_HtmlVideoPlayer> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'report-video-${widget.url.hashCode}';

    if (!_registeredVideoViews.contains(_viewType)) {
      _registeredVideoViews.add(_viewType);

      ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        final v = html.VideoElement()
          ..src = widget.url
          ..controls = true
          ..preload = 'metadata'
          ..style.width = '100%'
          ..style.height = '100%';

        // iOS Safari inline playback
        v.setAttribute('playsinline', 'true');
        v.setAttribute('webkit-playsinline', 'true');

        return v;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}

/* =========================
   Viewer Overlay
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
      color: Colors.black.withValues(alpha: 0.75),
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
                      color: Colors.black.withValues(alpha: 0.55),
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
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

/* =========================
   Checklist
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
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Column 1: position + label
              Expanded(
                flex: 5,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pos ?? ''}.',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black54),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Column 2: status chip
              SizedBox(
                width: 100,
                child: _StatusChip(status: status),
              ),
              const SizedBox(width: 8),
              // Column 3: rating chip
              SizedBox(
                width: 52,
                child: _RatingChip(rating: rating),
              ),
              const SizedBox(width: 8),
              // Column 4: remarks
              Expanded(
                flex: 4,
                child: Text(
                  remarks.trim().isEmpty ? '-' : remarks,
                  style: const TextStyle(color: Colors.black87, height: 1.25),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
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
      ..color = Colors.black.withValues(alpha: 0.08);

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
      ..color = Colors.black.withValues(alpha: 0.55)
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
      ..color = Colors.black.withValues(alpha: 0.75)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, needlePaint);

    canvas.drawCircle(center, 5.5, Paint()..color = Colors.white);
    canvas.drawCircle(center, 4.8, Paint()..color = Colors.black.withValues(alpha: 0.7));
  }

  @override
  bool shouldRepaint(covariant _OdometerPainter oldDelegate) => oldDelegate.v != v;
}

/* =========================
   Small pieces
========================= */

class _HeaderRow extends StatelessWidget {
  final String title;
  final VoidCallback onDownload;

  final bool showReview;
  final bool reviewSubmitted;
  final VoidCallback? onReview;

  const _HeaderRow({
    required this.title,
    required this.onDownload,
    this.showReview = false,
    this.reviewSubmitted = false,
    this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Centered title
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),

        // Logo left, buttons right — floats above title without affecting its centering
        Row(
          children: [
            Image.asset(
              'assets/logo/autoscope_logo_old.png',
              height: 52,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            const Spacer(),
            if (showReview)
              Tooltip(
                message: reviewSubmitted ? 'Review submitted' : 'Give review',
                child: InkWell(
                  onTap: onReview,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
                    ),
                    child: Icon(
                      reviewSubmitted ? Icons.star : Icons.star_border,
                      size: 20,
                    ),
                  ),
                ),
              ),
            Tooltip(
              message: 'Download (Save as PDF)',
              child: InkWell(
                onTap: onDownload,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
                  ),
                  child: const Icon(Icons.download_outlined, size: 20),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


/* =========================
   Vehicle Details Card (Chassis as Image)
========================= */

class _VehicleDetailsCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;
  final void Function(String url) onOpenImage;

  const _VehicleDetailsCard({
    required this.title,
    required this.data,
    required this.onOpenImage,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
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

    const order = [
      'make',
      'model',
      'gradeVariant',
      'engineCapacity',
      'modelYear',
      'cylinderSize',
      'transmission',
      'fuelType',
      'driveTrain',
      'specs',
      'odometerReading',
      'registrationNo',
      'emiratesRegAt',
      'chassisNo',
      'ownershipType',
    ];

    final keys = <String>[
      ...order.where((k) => data.containsKey(k)),
      ...data.keys.where((k) => !order.contains(k) && k != 'chassisPhotoUrl'),
    ];

    final chassisValue = _cleanStr(data['chassisNo']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          for (final k in keys)
            if (k == 'chassisNo')
              _kv(_prettyKey(k), chassisValue.isEmpty ? '-' : chassisValue)
            else
              _kv(
                _prettyKey(k),
                _cleanStr(data[k]).isEmpty ? '-' : _cleanStr(data[k]),
              ),
        ],
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
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
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
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          for (final k in keys) _kv(_prettyKey(k), _cleanStr(data[k]).isEmpty ? '-' : _cleanStr(data[k])),
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
      color: Colors.black.withValues(alpha: 0.02),
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

class _SignatureBox extends StatelessWidget {
  final String label;
  const _SignatureBox({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          width: 160,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
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
        border: Border.all(color: fg.withValues(alpha: 0.20)),
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
      bg = Colors.green.withValues(alpha: 0.12);
      fg = Colors.green.shade800;
    } else if (s == 'good') {
      bg = Colors.blue.withValues(alpha: 0.12);
      fg = Colors.blue.shade800;
    } else if (s == 'average') {
      bg = Colors.orange.withValues(alpha: 0.12);
      fg = Colors.orange.shade800;
    } else if (s == 'poor') {
      bg = Colors.red.withValues(alpha: 0.12);
      fg = Colors.red.shade800;
    } else {
      bg = Colors.grey.withValues(alpha: 0.12);
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
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('★ $text', style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

/* =========================
   Clean Network Image
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
        errorBuilder: (_, _, _) => Container(
          width: width == double.infinity ? null : width,
          height: height == double.infinity ? null : height,
          color: Colors.black.withValues(alpha: 0.06),
          child: const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.black45),
          ),
        ),
        loadingBuilder: (context, w, progress) {
          if (progress == null) return w;
          return Container(
            width: width == double.infinity ? null : width,
            height: height == double.infinity ? null : height,
            color: Colors.black.withValues(alpha: 0.06),
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

class _VideoRef {
  final String url;
  final String section;
  const _VideoRef({required this.url, required this.section});
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

String _formatVirId(String rawId, dynamic isoDate) {
  final dt = DateTime.tryParse(_cleanStr(isoDate))?.toLocal();
  final yyyy = dt?.year.toString() ?? 'XXXX';
  final mm = dt?.month.toString().padLeft(2, '0') ?? 'XX';
  final suffix = rawId.length >= 5
      ? rawId.substring(rawId.length - 5).toUpperCase()
      : rawId.toUpperCase().padLeft(5, '0');
  return 'VIR-$yyyy-$mm-$suffix';
}

String _fmtIso(dynamic iso) {
  final s = _cleanStr(iso);
  if (s.isEmpty) return '';
  final dt = DateTime.tryParse(s);
  if (dt == null) return s;
  final local = dt.toLocal();
  String two(int x) => x.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}

bool _isHttpUrl(String s) {
  final u = Uri.tryParse(s.trim());
  return u != null && (u.scheme == 'http' || u.scheme == 'https');
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
  const overrides = <String, String>{
    'chassisNo': 'Chassis Number',
    'registrationNo': 'Registration Number',
    'emiratesRegAt': 'Emirates Registered At',
    'odometerReading': 'Odometer Reading',
    'gradeVariant': 'Grade / Variant',
    'engineCapacity': 'Engine Capacity',
    'modelYear': 'Model Year',
    'cylinderSize': 'Cylinder Size',
    'fuelType': 'Fuel Type',
    'driveTrain': 'Drive Train',
    'ownershipType': 'Ownership Type',
    'serviceHistory': 'Service History',
    'servicedWith': 'Serviced With',
    'lastServiceDate': 'Last Service Date',
    'warrantyAvailable': 'Warranty Available',
    'warrantyEndsIn': 'Warranty Ends In',
    'hadAccidents': 'Had Accidents',
    'interiorColor': 'Interior Color',
    'numberOfKeys': 'Number of Keys',
    'modificationDone': 'Modification Done',
    'exteriorColor': 'Exterior Color',
    'wheelSize': 'Wheel Size',
    'wheelType': 'Wheel Type',
  };
  if (overrides.containsKey(k)) return overrides[k]!;
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
  if (s.contains('excellent')) return _Tone(Colors.green.withValues(alpha: 0.12), Colors.green.shade800);
  if (s.contains('good')) return _Tone(Colors.blue.withValues(alpha: 0.12), Colors.blue.shade800);
  if (s.contains('average')) return _Tone(Colors.orange.withValues(alpha: 0.12), Colors.orange.shade800);
  if (s.contains('poor')) return _Tone(Colors.red.withValues(alpha: 0.12), Colors.red.shade800);
  if (s.contains('draft')) return _Tone(Colors.black.withValues(alpha: 0.06), Colors.black87);
  return _Tone(Colors.grey.withValues(alpha: 0.12), Colors.grey.shade800);
}

/* =========================
   Reviews helpers (localStorage + id parsing)
========================= */

String _extractId(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  if (v is Map) {
    final m = _asMap(v);
    final id = (m['_id'] ?? m['id'] ?? '').toString();
    return id;
  }
  return '';
}

bool _lsBool(String key) => html.window.localStorage[key] == '1';
void _setLsBool(String key, bool value) => html.window.localStorage[key] = value ? '1' : '0';