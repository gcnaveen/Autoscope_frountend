// lib/features/dashboards/user/inspection_report_page.dart
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'dart:typed_data';

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../shared/app_shell.dart';
import '../../../services/service_locator.dart';
import '../../shared/top_snackbar.dart';
import '../../shared/widgets/web_camera_capture_web.dart';

const String kCarTopDamageAsset = 'assets/images/car_views/top.jpg';

class InspectionReportPage extends StatefulWidget {
  final String inspectionId;
  final bool isAdminContext;
  final bool printMode;
  final bool isForApproval;
  const InspectionReportPage({
    super.key,
    required this.inspectionId,
    this.isAdminContext = false,
    this.printMode = false,
    this.isForApproval = false,
  });

  @override
  State<InspectionReportPage> createState() => _InspectionReportPageState();
}

class _InspectionReportPageState extends State<InspectionReportPage> {
  late Future<Map<String, dynamic>> _future;
  List<String>? _disclaimerPoints;
  bool _autoPrintScheduled = false;

  @override
  void initState() {
    super.initState();
    _future = inspectionRequestsService.getInspectionById(widget.inspectionId);
    _loadDisclaimer();
  }

  Future<void> _loadDisclaimer() async {
    try {
      final points = await reportSettingsService.loadDisclaimer();
      if (mounted && points.isNotEmpty) {
        setState(() => _disclaimerPoints = points);
      }
    } catch (_) {
      // silently fall back to the hardcoded list in _DisclaimerContent
    }
  }

  void _retry() {
    setState(() {
      _autoPrintScheduled = false;
      _future = inspectionRequestsService.getInspectionById(widget.inspectionId);
    });
  }

  void _scheduleAutoPrint() {
    if (_autoPrintScheduled || !widget.printMode || !kIsWeb) return;
    _autoPrintScheduled = true;
    // 2-second delay so network images have time to load before printing
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) html.window.print();
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = Center(
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

            // Schedule auto-print once data is ready (print mode only)
            if (widget.printMode) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleAutoPrint());
            }

            return _ReportView(
              inspection: inspection,
              onRetry: _retry,
              disclaimerPoints: _disclaimerPoints,
              isAdminContext: widget.isAdminContext,
              printMode: widget.printMode,
              isForApproval: widget.isForApproval,
            );
          },
        ),
      ),
    );

    // Print mode: no AppShell, plain white Scaffold so only the report prints
    if (widget.printMode) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: body,
      );
    }

    return AppShell(
      title: 'Inspection Report',
      child: body,
    );
  }
}

/* =========================
   Report UI
========================= */

class _ReportView extends StatefulWidget {
  final Map<String, dynamic> inspection;
  final VoidCallback onRetry;
  final List<String>? disclaimerPoints;
  final bool isAdminContext;
  final bool printMode;
  final bool isForApproval;
  const _ReportView({
    required this.inspection,
    required this.onRetry,
    this.disclaimerPoints,
    this.isAdminContext = false,
    this.printMode = false,
    this.isForApproval = false,
  });

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
  final _photosKey = GlobalKey();

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

  void _scrollToPhotos() {
    final ctx = _photosKey.currentContext;
    if (ctx == null || !_scrollCtrl.hasClients) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final anchorBox = _scrollAnchorKey.currentContext
        ?.findRenderObject() as RenderBox?;
    if (anchorBox == null) return;
    final target = (box.localToGlobal(Offset.zero).dy -
            anchorBox.localToGlobal(Offset.zero).dy)
        .clamp(_scrollCtrl.position.minScrollExtent,
            _scrollCtrl.position.maxScrollExtent);
    _scrollCtrl.animateTo(target,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut);
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
              onNavigateToPhoto: (url) {
                final idx = _photos.indexWhere((p) => p.url == url);
                if (idx >= 0) {
                  _setHero(idx);
                  WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _scrollToPhotos());
                }
              },
              scrollCtrl: _scrollCtrl,
              scrollAnchorKey: _scrollAnchorKey,
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
            SizedBox(
              key: _photosKey,
              width: double.infinity,
              child: _PhotosBlock(
                photos: _photos,
                sectionToPhotoIdx: _sectionToPhotoIdx,
                heroIndex: _heroIndex,
                onHeroOpen: () => _openViewer(_heroIndex),
                onThumbClick: (index) => _setHero(index, openViewer: false),
                onOpenViewer: () => _openViewer(_heroIndex),
                onPrevHero: _prevHero,
                onNextHero: _nextHero,
              ),
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
              child: _DisclaimerContent(points: widget.disclaimerPoints),
            ),

            const SizedBox(height: 12),

            // Company signature & stamp
            _Card(
              title: 'Authorized By',
              child: _AuthorizedBySection(
                adminSignatureUrl: _cleanStr(inspection['adminSignature']),
                approvedByName: _cleanStr(inspection['approvedByName'] ?? inspection['adminName'] ?? ''),
              ),
            ),

            // Admin approval action bar
            if (widget.isAdminContext && widget.isForApproval) ...[
              const SizedBox(height: 16),
              _AdminApprovalBar(
                inspection: inspection,
                onDone: widget.onRetry,
              ),
            ],

            const SizedBox(height: 18),
          ],
        ),

        if (_showScrollToTop && !widget.printMode)
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

  // Generate a standalone HTML report in a new window and auto-print it.
  // Uses a Blob URL so the full multi-page report is captured correctly
  // (bypasses Flutter's CanvasKit canvas viewport limitation).
  void _downloadReport() {
    if (_viewerOpen) _closeViewer();

    if (!kIsWeb) {
      showTopSnack(context, 'PDF download is available on Web.', variant: 'warning');
      return;
    }

    final origin = html.window.location.origin;
    final content = _buildPrintHtml(widget.inspection, widget.disclaimerPoints, origin: origin);
    // Blob URLs allow inline scripts, unlike data: URIs — so window.print() fires.
    final blob = html.Blob([content], 'text/html');
    final url  = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    // Revoke after the new tab has had time to load
    Future.delayed(const Duration(seconds: 15), () => html.Url.revokeObjectUrl(url));
  }

  static String _buildPrintHtml(
    Map<String, dynamic> inspection,
    List<String>? disclaimerPoints, {
    String origin = '',
  }) {
    // ── helpers ──────────────────────────────────────────────────────────────
    String s(dynamic v) => _cleanStr(v);
    String d(dynamic v) => s(v).isEmpty ? '-' : s(v);

    // Mirrors the app's _kv widget: bold label (fixed width) + regular value
    String kv(String label, dynamic val) {
      final v = d(val);
      return '<div class="kv"><span class="kv-k">$label:</span><span class="kv-v">$v</span></div>';
    }

    // Uses same _prettyKey overrides as the app
    String kvMap(Map<String, dynamic> data, List<String> order) {
      final keys = <String>[
        ...order.where((k) => data.containsKey(k)),
        ...data.keys.where((k) => !order.contains(k) && k != 'chassisPhotoUrl'),
      ];
      if (keys.isEmpty) return '<span class="muted">—</span>';
      return keys.map((k) => kv(_prettyKey(k), data[k])).join('');
    }

    // Mirrors _StatusChip: bg = color.withOpacity(0.12), no border
    String statusChip(String st) {
      final sl = st.trim().toLowerCase();
      String bg, fg;
      if (sl == 'excellent')   { bg = 'rgba(76,175,80,0.12)';  fg = '#2e7d32'; }
      else if (sl == 'good')   { bg = 'rgba(21,101,192,0.12)'; fg = '#1565c0'; }
      else if (sl == 'average'){ bg = 'rgba(230,81,0,0.12)';   fg = '#e65100'; }
      else if (sl == 'poor')   { bg = 'rgba(198,40,40,0.12)';  fg = '#c62828'; }
      else { bg = 'rgba(0,0,0,0.06)'; fg = '#555'; }
      return '<span class="chip" style="background:$bg;color:$fg">${st.isEmpty ? "-" : st}</span>';
    }

    // Mirrors _RatingChip: grey bg, ★ prefix
    String ratingChip(dynamic r) {
      final v = _toDouble(r);
      if (v == null) return '<span class="rchip">-</span>';
      return '<span class="rchip">★ ${v.toStringAsFixed(1)}</span>';
    }

    // Mirrors _Badge tones used for overall rating label
    String ratingBadge(String label) {
      final ll = label.toLowerCase();
      String bg, fg, bd;
      if (ll == 'excellent')  { bg='rgba(76,175,80,0.12)';  fg='#2e7d32'; bd='rgba(76,175,80,0.2)'; }
      else if (ll == 'good')  { bg='rgba(21,101,192,0.12)'; fg='#1565c0'; bd='rgba(21,101,192,0.2)'; }
      else if (ll == 'average'){ bg='rgba(230,81,0,0.12)';  fg='#e65100'; bd='rgba(230,81,0,0.2)'; }
      else                    { bg='rgba(198,40,40,0.12)';  fg='#c62828'; bd='rgba(198,40,40,0.2)'; }
      return '<span class="badge" style="background:$bg;color:$fg;border:1px solid $bd">$label</span>';
    }

    String ratingLabel(double? r) {
      if (r == null) return 'N/A';
      if (r >= 4.5) return 'Excellent';
      if (r >= 3.5) return 'Good';
      if (r >= 2.0) return 'Average';
      return 'Poor';
    }

    // ── data ─────────────────────────────────────────────────────────────────
    final rawId = (inspection['_id'] ?? inspection['id'] ?? '').toString();
    final virId = rawId.isEmpty ? '-' : _formatVirId(rawId, inspection['inspectionDate']);
    final overallRating = _toDouble(inspection['overallRating']);
    final overallRatingStr = overallRating?.toStringAsFixed(2) ?? '-';
    final rlabel = ratingLabel(overallRating);
    final inspDate  = _fmtIso(inspection['inspectionDate']);
    final compDate  = _fmtIso(inspection['completedAt']);
    final createDate = _fmtIso(inspection['createdAt']);
    final updateDate = _fmtIso(inspection['updatedAt']);
    final notes = s(inspection['notes']);

    final inspector = _asMap(inspection['inspectorId']);
    final inspName  = [s(inspector['firstName']), s(inspector['lastName'])].where((x) => x.isNotEmpty).join(' ');
    final inspEmail = s(inspector['email']);

    final vd   = _asMap(inspection['vehicleDetails']);
    final ext  = _asMap(inspection['exteriorDetails']);
    final int_ = _asMap(inspection['interiorDetails']);
    final sw   = _asMap(inspection['serviceWarrantyOverview']);

    final types   = (inspection['types'] as List?) ?? const [];
    final damages = _parseDamages(inspection);

    // Chassis photo
    final chassisPhotoUrl = s(vd['chassisPhotoUrl']);
    final chassisNoRaw    = s(vd['chassisNo']);
    final chassisPhoto = chassisPhotoUrl.startsWith('http') ? chassisPhotoUrl
        : chassisNoRaw.startsWith('http') ? chassisNoRaw : '';

    const vdOrder = ['make','model','gradeVariant','engineCapacity','modelYear','cylinderSize',
      'transmission','fuelType','driveTrain','specs','odometerReading','registrationNo',
      'emiratesRegAt','chassisNo','ownershipType'];

    // ── photos ────────────────────────────────────────────────────────────────
    final allPhotos = <String>[];
    // Chassis photo first
    if (chassisPhoto.isNotEmpty) allPhotos.add(chassisPhoto);
    for (final t in types) {
      final tm = _asMap(t);
      for (final u in (tm['overallPhotos'] as List?) ?? const []) {
        final us = u.toString().trim(); if (us.isNotEmpty && !allPhotos.contains(us)) allPhotos.add(us);
      }
      for (final it in (tm['checklistItems'] as List?) ?? const []) {
        for (final u in (_asMap(it)['photos'] as List?) ?? const []) {
          final us = u.toString().trim(); if (us.isNotEmpty && !allPhotos.contains(us)) allPhotos.add(us);
        }
      }
    }
    for (final dmg in damages) {
      for (final u in dmg.images) { if (u.isNotEmpty && !allPhotos.contains(u)) allPhotos.add(u); }
    }

    // ── HTML sections ─────────────────────────────────────────────────────────

    // Header — matches _HeaderRow: logo left, "Inspection Report" center, ID right
    final headerHtml = '''
<div class="hdr">
  <img src="$origin/assets/logo/autoscope_logo_old.png" height="52" alt="" onerror="this.style.display='none'">
  <div class="hdr-title">Inspection Report</div>
  <div class="hdr-id">$virId</div>
</div>''';

    // Report Information + Inspector — matches the two _Card widgets side by side
    final infoHtml = '''
<div class="row-2" style="margin-bottom:12px">
  <div class="card">
    <div class="card-title">Report Information</div>
    ${kv('Inspection ID', virId)}
    ${kv('Overall Rating', overallRatingStr)}
    ${kv('Inspection Date', inspDate.isEmpty ? '-' : inspDate)}
    ${compDate.isNotEmpty ? kv('Completed At', compDate) : ''}
    ${kv('Created At', createDate.isEmpty ? '-' : createDate)}
    ${kv('Updated At', updateDate.isEmpty ? '-' : updateDate)}
  </div>
  <div class="card">
    <div class="card-title">Inspector</div>
    ${kv('Inspector', inspName.isEmpty ? '-' : inspName)}
    ${kv('Email', inspEmail.isEmpty ? '-' : inspEmail)}
  </div>
</div>''';

    // Overall Rating + Section Overview — matches the row in the app
    final sectionTiles = types.map((t) {
      final tm   = _asMap(t);
      final name = s(tm['typeName']).isEmpty ? 'Section' : s(tm['typeName']);
      final avg  = _toDouble(tm['averageRating']);
      final avgStr = avg?.toStringAsFixed(2) ?? '-';
      return '<div class="sec-tile"><div class="sec-tile-name">$name</div><div class="sec-tile-avg">★ $avgStr</div></div>';
    }).join('');

    final overallHtml = '''
<div class="row-2" style="margin-bottom:12px">
  <div class="card">
    <div class="card-title">Section Overview</div>
    <div class="sec-grid">$sectionTiles</div>
  </div>
  <div class="card">
    <div class="card-title">Overall Rating</div>
    <div style="font-size:22px;font-weight:900;margin-bottom:6px">$overallRatingStr</div>
    ${ratingBadge(rlabel)}
    <div style="margin-top:8px;color:rgba(0,0,0,0.54);font-size:13px">Scale: 0 to 5</div>
  </div>
</div>''';

    // Vehicle Information — matches the _Card wrapping sub-section boxes
    final chassisPhotoBlock = chassisPhoto.isNotEmpty ? '''
<div style="margin-top:10px">
  <div style="font-weight:700;font-size:11px;color:rgba(0,0,0,0.54);text-transform:uppercase;letter-spacing:0.4px;margin-bottom:5px">Chassis Photo</div>
  <img src="$chassisPhoto" style="max-height:160px;max-width:100%;border-radius:8px;border:1px solid rgba(0,0,0,0.06);display:block" alt="" onerror="this.style.display='none'">
</div>''' : '';

    final vehicleHtml = '''
<div class="card" style="margin-bottom:12px">
  <div class="card-title">Vehicle Information</div>
  <div class="row-2">
    <div class="box">
      <div class="box-title">Vehicle Details</div>
      ${kvMap(vd, vdOrder)}
      $chassisPhotoBlock
    </div>
    <div>
      <div class="box" style="margin-bottom:10px">
        <div class="box-title">Exterior Details</div>
        ${kvMap(ext, const [])}
      </div>
      <div class="box" style="margin-bottom:10px">
        <div class="box-title">Interior Details</div>
        ${kvMap(int_, const [])}
      </div>
      <div class="box">
        <div class="box-title">Service / Warranty Overview</div>
        ${kvMap(sw, const [])}
      </div>
    </div>
  </div>
</div>''';

    // Damages — matches _DamagesBlock with canvas map + _DamagePreview list
    final damageJson = '[${damages.map((dp) => '{"x":${dp.x},"y":${dp.y}}').join(',')}]';

    final dmgMapHtml = (origin.isEmpty || damages.isEmpty) ? '' : '''
<div id="car-map-wrapper" style="margin-bottom:12px">
  <div class="box" style="padding:12px">
    <div style="position:relative;display:inline-block;width:100%">
      <canvas id="car-canvas" style="width:100%;display:block;border-radius:8px"></canvas>
      <div id="car-markers" style="position:absolute;top:0;left:0;width:100%;height:100%;pointer-events:none"></div>
    </div>
  </div>
</div>''';

    final dmgItems = damages.isEmpty
        ? '<span class="muted">No damages marked.</span>'
        : damages.asMap().entries.map((e) {
            final i  = e.key;
            final dp = e.value;
            final imgs = dp.images.isEmpty ? ''
                : '<div class="photo-grid" style="margin-top:8px">${dp.images.map((u) => '<img class="photo-thumb" src="$u" alt="">').join('')}</div>';
            return '''<div class="dmg-row">
  <div class="dmg-dot">${i + 1}</div>
  <div style="flex:1">
    <div style="font-weight:800;font-size:14px">${d(dp.description)}</div>
    $imgs
  </div>
</div>''';
          }).join('');

    final damagesHtml = '''
<div class="card" style="margin-bottom:12px">
  <div class="card-title">Damages (${damages.length})</div>
  $dmgMapHtml
  $dmgItems
</div>''';

    // Photos — matches _PhotosBlock overview
    final photosHtml = allPhotos.isEmpty ? '' : '''
<div class="card" style="margin-bottom:12px">
  <div class="card-title">Photos</div>
  <div class="photo-grid">${allPhotos.map((u) => '<img class="photo-thumb" src="$u" alt="">').join('')}</div>
</div>''';

    // Checklist — matches _ChecklistSection + _ChecklistRow (4 equal columns)
    final clSections = types.map((t) {
      final tm    = _asMap(t);
      final name  = s(tm['typeName']).isEmpty ? 'Section' : s(tm['typeName']);
      final avg   = s(tm['averageRating']);
      final items = (tm['checklistItems'] as List?) ?? const [];

      final rows = items.map((it) {
        final im     = _asMap(it);
        final pos    = s(im['position']);
        final label  = s(im['label']).isEmpty ? '-' : s(im['label']);
        final status = s(im['status']).isEmpty ? '-' : s(im['status']);
        final remark = s(im['remarks']).isEmpty ? '-' : s(im['remarks']);
        return '''<div class="cl-row">
  <div><span class="cl-pos">${pos.isNotEmpty ? "$pos." : ""}</span> <span class="cl-label">$label</span></div>
  <div>${statusChip(status)}</div>
  <div>${ratingChip(im['rating'])}</div>
  <div class="cl-remarks">$remark</div>
</div>''';
      }).join('');

      return '''<div class="cl-section">
  <div class="cl-hdr">
    <span class="cl-name">$name</span>
    <span class="cl-avg">Avg: ${avg.isEmpty ? '-' : avg}</span>
  </div>
  <div class="box" style="border-radius:0 0 14px 14px;padding:0">
    $rows
  </div>
</div>''';
    }).join('');

    final checklistHtml = '''
<div class="card" style="margin-bottom:12px">
  <div class="card-title">Checklist</div>
  $clSections
</div>''';

    // Notes (only if present)
    final notesHtml = notes.isEmpty ? '' : '''
<div class="card" style="margin-bottom:12px">
  <div class="card-title">Overall Description</div>
  <p style="color:rgba(0,0,0,0.87);font-size:13px;line-height:1.55">$notes</p>
</div>''';

    // Disclaimer — matches _DisclaimerContent (numbered list)
    final discPoints = (disclaimerPoints != null && disclaimerPoints.isNotEmpty)
        ? disclaimerPoints
        : const [
            'This report reflects the visible condition of the vehicle only at the time and date of inspection.',
            'The inspection is provided solely as an aid for evaluating the vehicle\'s general condition and does not constitute a warranty, guarantee, or recommendation to buy or sell the vehicle.',
            'The inspection conducted by Auto Scope is limited strictly to the items listed in this report and is visual, non-invasive, and non-mechanical in nature.',
            'No dismantling, disassembly, or internal examination of components has been carried out.',
            'Certain hidden, internal, or intermittent defects may not be detectable at the time of inspection despite standard inspection procedures being followed.',
            'Auto Scope shall not be liable for repair costs, damages, losses, undiscovered defects, or differences between this report and future third-party assessments.',
            'This report is issued strictly for informational purposes and should not be considered a warranty or guarantee of the vehicle\'s condition.',
          ];
    final discItems = discPoints.asMap().entries.map((e) => '''<div class="disc-item">
  <span class="disc-num">${e.key + 1}</span>
  <span class="disc-text">${e.value}</span>
</div>''').join('');

    final disclaimerHtml = '''
<div class="card" style="margin-bottom:12px">
  <div class="card-title">Disclaimer</div>
  $discItems
</div>''';

    // Authorized By — matches _AuthorizedBySection
    final sigUrl     = s(inspection['adminSignature']);
    final approvedBy = s(inspection['approvedByName'] ?? inspection['adminName'] ?? '');
    final sigBlock = sigUrl.isNotEmpty
        ? '<img src="$sigUrl" style="height:80px;max-width:220px;border-radius:6px;margin-top:8px;display:block" alt="Signature">'
        : '<div style="width:200px;height:72px;border:1px solid rgba(0,0,0,0.12);border-radius:6px;margin-top:8px"></div>';

    final authorizedHtml = '''
<div class="card" style="margin-bottom:12px">
  <div class="card-title">Authorized By</div>
  <div class="auth-company">AUTO SCOPE INSPECTION AND PRICING SERVICES - L.L.C - S.P.C</div>
  <div class="auth-sub">Abu Dhabi, U.A.E</div>
  <div style="display:flex;gap:48px;margin-top:20px;flex-wrap:wrap;align-items:flex-start">
    <div>
      <div class="auth-lbl">Company Stamp</div>
      <img src="$origin/assets/images/company_stamp.png" width="140" height="140" style="object-fit:contain;display:block;margin-top:6px" alt="" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
      <div style="display:none;width:120px;height:120px;border:1.5px solid rgba(0,0,0,0.12);border-radius:50%;align-items:center;justify-content:center;color:rgba(0,0,0,0.3);font-weight:700;margin-top:6px">STAMP</div>
    </div>
    <div>
      <div class="auth-lbl">Authorized Signature</div>
      $sigBlock
      ${approvedBy.isNotEmpty ? '<div style="margin-top:6px;font-weight:700">$approvedBy</div>' : ''}
    </div>
  </div>
</div>''';

    // ── assemble ──────────────────────────────────────────────────────────────
    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Inspection Report – $virId</title>
  <style>
    @page { size: A4 portrait; margin: 10mm 12mm }
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0 }

    /* Matches Flutter's default body font and print-mode white background */
    body { font-family: Arial, Helvetica, sans-serif; font-size: 14px; color: #1a1a1a; background: #fff; padding: 0 }

    /* _HeaderRow */
    .hdr { display: flex; align-items: center; margin-bottom: 18px }
    .hdr-title { flex: 1; text-align: center; font-size: 24px; font-weight: 900 }
    .hdr-id { min-width: 80px; text-align: right; font-size: 11px; color: #aaa }

    /* _Card  (elevation:0, color: Colors.black.withValues(alpha:0.02)) */
    .card { background: rgba(0,0,0,0.02); border-radius: 12px; padding: 14px; margin-bottom: 0 }
    .card-title { font-size: 16px; font-weight: 900; margin-bottom: 10px }

    /* Sub-section boxes (_VehicleDetailsCard, _SubSectionMapCard — white bg, rgba(0,0,0,0.06) border, 14px radius) */
    .box { background: white; border-radius: 14px; border: 1px solid rgba(0,0,0,0.06); padding: 12px }
    .box-title { font-weight: 900; font-size: 14px; margin-bottom: 10px }

    /* _kv widget: bold label fixed 140px, regular value */
    .kv { display: flex; margin-bottom: 6px; line-height: 1.4; font-size: 14px }
    .kv-k { width: 140px; flex-shrink: 0; font-weight: 900; padding-right: 8px }
    .kv-v { flex: 1 }

    /* Layout */
    .row-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 12px }

    /* _StatusChip: bg = color.withOpacity(0.12), no border */
    .chip { display: inline-block; padding: 4px 10px; border-radius: 999px; font-weight: 900; font-size: 13px }

    /* _RatingChip: grey bg, ★ prefix */
    .rchip { display: inline-block; padding: 4px 10px; border-radius: 999px; background: rgba(0,0,0,0.06); font-weight: 900; font-size: 13px; color: #1a1a1a }

    /* _Badge */
    .badge { display: inline-block; padding: 5px 10px; border-radius: 999px; font-weight: 900; font-size: 13px }

    /* Section overview tiles (simplified _SectionOverviewTile) */
    .sec-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px }
    .sec-tile { background: rgba(255,255,255,0.65); border-radius: 14px; border: 1px solid rgba(0,0,0,0.06); padding: 10px 12px; display: flex; justify-content: space-between; align-items: center }
    .sec-tile-name { font-weight: 900; font-size: 13px }
    .sec-tile-avg { font-weight: 900; font-size: 13px; color: #1565c0; background: rgba(21,101,192,0.12); padding: 3px 10px; border-radius: 999px }

    /* Checklist (_ChecklistSection / _ChecklistRow) */
    .cl-section { margin-bottom: 12px; break-inside: avoid }
    .cl-hdr { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px }
    .cl-name { font-weight: 900; font-size: 14px }
    .cl-avg { font-size: 12px; color: rgba(0,0,0,0.54) }
    /* 4 equal columns matching _ChecklistRow expanded layout */
    .cl-row { display: grid; grid-template-columns: 1fr 1fr 1fr 1fr; gap: 12px; padding: 10px 12px; border-top: 1px solid rgba(0,0,0,0.06); align-items: start; font-size: 13px }
    .cl-pos { font-weight: 900; color: rgba(0,0,0,0.54) }
    .cl-label { font-weight: 800 }
    .cl-remarks { color: rgba(0,0,0,0.87); line-height: 1.25 }

    /* _DamageMarker */
    .dmg-dot { display: inline-flex; min-width: 26px; width: 26px; height: 26px; background: #ff5252; border-radius: 50%; color: white; font-weight: 900; align-items: center; justify-content: center; font-size: 12px; border: 2px solid white; box-shadow: 0 3px 8px rgba(0,0,0,0.2); flex-shrink: 0 }
    /* _DamagePreview style */
    .dmg-row { display: flex; gap: 12px; align-items: flex-start; padding: 8px 0; border-top: 1px solid rgba(0,0,0,0.06); break-inside: avoid }
    .dmg-row:first-of-type { border-top: none }

    /* Photos grid */
    .photo-grid { display: grid; grid-template-columns: repeat(5, 1fr); gap: 8px }
    .photo-thumb { width: 100%; aspect-ratio: 4/3; object-fit: cover; border-radius: 8px; display: block }

    /* _DisclaimerContent (numbered) */
    .disc-item { display: flex; gap: 12px; margin-bottom: 10px }
    .disc-num { font-weight: 700; color: rgba(0,0,0,0.54); font-size: 13px; flex-shrink: 0; width: 24px }
    .disc-text { color: rgba(0,0,0,0.87); font-size: 13px; line-height: 1.55 }

    /* _AuthorizedBySection */
    .auth-company { font-weight: 900; font-size: 14px }
    .auth-sub { color: rgba(0,0,0,0.54); font-size: 13px; margin-top: 2px }
    .auth-lbl { font-weight: 700; font-size: 11px; color: rgba(0,0,0,0.54); text-transform: uppercase; letter-spacing: 0.4px; margin-bottom: 6px }

    .muted { color: rgba(0,0,0,0.54) }

    @media print {
      body { padding: 0 }
      .card { break-inside: avoid }
      .cl-section { break-inside: avoid }
      .dmg-row { break-inside: avoid }
    }
  </style>
</head>
<body>

  $headerHtml

  $infoHtml

  $vehicleHtml

  $overallHtml

  $damagesHtml

  $photosHtml

  $checklistHtml

  $notesHtml

  $disclaimerHtml

  $authorizedHtml

  <script>
    window.addEventListener('load', function(){
      var damages = $damageJson;
      var canvas  = document.getElementById('car-canvas');
      var markers = document.getElementById('car-markers');
      function doPrint(){ window.print(); }
      if(canvas && damages.length){
        var img = new Image();
        img.onload = function(){
          var W=img.naturalWidth, H=img.naturalHeight;
          canvas.width=H; canvas.height=W;
          var ctx=canvas.getContext('2d');
          ctx.translate(H/2,W/2); ctx.rotate(-Math.PI/2);
          ctx.drawImage(img,-W/2,-H/2);
          damages.forEach(function(d,i){
            var m=document.createElement('div');
            m.style.cssText='position:absolute;transform:translate(-50%,-50%);width:26px;height:26px;border-radius:50%;background:#ff5252;color:#fff;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:900;border:2px solid #fff;box-shadow:0 3px 8px rgba(0,0,0,.2)';
            m.style.left=(d.y*100)+'%'; m.style.top=(d.x*100)+'%';
            m.textContent=i+1;
            markers.appendChild(m);
          });
          setTimeout(doPrint,500);
        };
        img.onerror=function(){
          var w=document.getElementById('car-map-wrapper');
          if(w) w.style.display='none';
          setTimeout(doPrint,500);
        };
        img.src='$origin/assets/images/car_views/top.jpg';
      } else {
        setTimeout(doPrint,2000);
      }
    });
  </script>
</body>
</html>''';
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
        showTopSnack(context, 'Thanks! Your review is submitted for approval.', variant: 'success');
      } else {
        showTopSnack(context, 'Submit failed: ${res['message'] ?? 'Unknown error'}', variant: 'error');
      }
    } catch (e) {
      if (!mounted) return;
      showTopSnack(context, 'Submit failed: $e', variant: 'error');
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
  final void Function(String url)? onNavigateToPhoto;
  final ScrollController? scrollCtrl;
  final GlobalKey? scrollAnchorKey;

  const _DamagesBlock({
    required this.damages,
    required this.carTopAssetPath,
    required this.onOpenImage,
    this.onNavigateToPhoto,
    this.scrollCtrl,
    this.scrollAnchorKey,
  });

  @override
  State<_DamagesBlock> createState() => _DamagesBlockState();
}

class _DamagesBlockState extends State<_DamagesBlock> {
  int? _selectedIdx;
  final _previewKey = GlobalKey();

  void _scrollToPreview() {
    final ctrl = widget.scrollCtrl;
    final anchorKey = widget.scrollAnchorKey;
    if (ctrl == null || !ctrl.hasClients || anchorKey == null) return;
    final previewCtx = _previewKey.currentContext;
    if (previewCtx == null) return;
    final previewBox = previewCtx.findRenderObject() as RenderBox?;
    if (previewBox == null || !previewBox.attached) return;
    final anchorBox = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (anchorBox == null) return;
    final target = (previewBox.localToGlobal(Offset.zero).dy - anchorBox.localToGlobal(Offset.zero).dy)
        .clamp(ctrl.position.minScrollExtent, ctrl.position.maxScrollExtent);
    ctrl.animateTo(target, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

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
                final newIdx = idx - 1;
                final toggling = _selectedIdx == newIdx;
                setState(() {
                  _selectedIdx = toggling ? null : newIdx;
                });
                if (!toggling) {
                  if (d.images.isNotEmpty && widget.onNavigateToPhoto != null) {
                    widget.onNavigateToPhoto!(d.images.first);
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToPreview());
                  }
                }
              },
            ),
            // Inline preview shown when a marker is tapped
            if (selected != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                key: _previewKey,
                width: double.infinity,
                child: _DamagePreview(
                  damage: selected,
                  index: _selectedIdx! + 1,
                ),
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
            // Portrait image (574×751) rotated 90° CCW → landscape display
            const imgW = 574.0;
            const imgH = 751.0;
            final h = w * imgW / imgH; // landscape height after 90° CCW rotation

            return SizedBox(
              width: w,
              height: h,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RotatedBox(
                      quarterTurns: 3, // 90° CCW — landscape, front/rear correctly oriented
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
                  // After 90° CCW rotation: new_x = old_y, new_y = old_x
                  for (int i = 0; i < widget.damages.length; i++)
                    _DamageMarker(
                      index: i + 1,
                      left: (widget.damages[i].y * w).clamp(0, w),
                      top: (widget.damages[i].x * h).clamp(0, h),
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

  const _DamagePreview({required this.damage, required this.index});

  @override
  Widget build(BuildContext context) {
    final desc = damage.description.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26, height: 26,
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
                    fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Damage #$index',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(desc,
                      style: const TextStyle(
                          color: Colors.black87, fontSize: 13)),
                ],
                if (damage.images.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${damage.images.length} photo${damage.images.length > 1 ? 's' : ''} — see Photos section below',
                    style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
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
              // Column 1: position + label (25%)
              Expanded(
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
              const SizedBox(width: 12),
              // Column 2: status chip (25%)
              Expanded(
                child: _StatusChip(status: status),
              ),
              const SizedBox(width: 12),
              // Column 3: rating chip (25%)
              Expanded(
                child: _RatingChip(rating: rating),
              ),
              const SizedBox(width: 12),
              // Column 4: remarks (25%)
              Expanded(
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

// ─── Disclaimer ───────────────────────────────────────────────────────────────

class _DisclaimerContent extends StatelessWidget {
  final List<String>? points;
  const _DisclaimerContent({this.points});

  static const _fallback = [
    'This report reflects the visible condition of the vehicle only at the time and date of inspection.',
    'The inspection is provided solely as an aid for evaluating the vehicle\'s general condition and does not constitute a warranty, guarantee, or recommendation to buy or sell the vehicle.',
    'The inspection conducted by Auto Scope is limited strictly to the items listed in this report and is visual, non-invasive, and non-mechanical in nature.',
    'No dismantling, disassembly, or internal examination of components has been carried out.',
    'The inspection does not include verification of service history, accident history, ownership records, recalls, mileage accuracy, or seller-provided specifications/features.',
    'Certain hidden, internal, or intermittent defects may not be detectable at the time of inspection despite standard inspection procedures being followed.',
    'Mechanical, electrical, and electronic components may fail at any time after inspection, and Auto Scope accepts no responsibility for issues arising thereafter.',
    'Auto Scope shall not be liable for repair costs, damages, losses, undiscovered defects, or differences between this report and future third-party assessments.',
    'This report is prepared exclusively for the client who ordered the inspection. Any third-party reliance on this report shall be entirely at their own risk.',
    'This report is issued strictly for informational purposes and should not be considered a warranty or guarantee of the vehicle\'s condition.',
  ];

  @override
  Widget build(BuildContext context) {
    final items = (points != null && points!.isNotEmpty) ? points! : _fallback;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  items[i],
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Authorized By ────────────────────────────────────────────────────────────

class _AuthorizedBySection extends StatelessWidget {
  final String adminSignatureUrl;
  final String approvedByName;

  const _AuthorizedBySection({
    this.adminSignatureUrl = '',
    this.approvedByName = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AUTO SCOPE INSPECTION AND PRICING SERVICES - L.L.C - S.P.C',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        const SizedBox(height: 2),
        const Text(
          'Abu Dhabi, U.A.E',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 500;
            final stamp = _StampBox();
            final sig = _SigBox(
              signatureUrl: adminSignatureUrl,
              approvedByName: approvedByName,
            );
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [stamp, const SizedBox(height: 24), sig],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [stamp, const SizedBox(width: 48), sig],
            );
          },
        ),
      ],
    );
  }
}

class _StampBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Company Stamp',
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 140,
          height: 140,
          child: Image.asset(
            'assets/images/company_stamp.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26, width: 1.5),
              ),
              child: const Center(
                child: Text(
                  'STAMP',
                  style: TextStyle(color: Colors.black26, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SigBox extends StatelessWidget {
  final String signatureUrl;
  final String approvedByName;

  const _SigBox({this.signatureUrl = '', this.approvedByName = ''});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Authorized Signature',
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Container(
          width: 200,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: signatureUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: _NetImageBox(
                    url: signatureUrl,
                    width: 200,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                )
              : null,
        ),
        if (approvedByName.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            approvedByName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

// ─── Admin Approval Bar ───────────────────────────────────────────────────────

class _AdminApprovalBar extends StatelessWidget {
  final Map<String, dynamic> inspection;
  final VoidCallback onDone;

  const _AdminApprovalBar({required this.inspection, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final id = (inspection['_id'] ?? inspection['id'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.pending_actions_outlined, color: Colors.amber),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'This inspection is awaiting your approval.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => _showReject(context, id),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => _showApprove(context, id),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showApprove(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => _ApproveDialog(inspectionId: id, onApproved: onDone),
    );
  }

  void _showReject(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => _RejectDialog(inspectionId: id, onRejected: onDone),
    );
  }
}

// ─── Approve Dialog ───────────────────────────────────────────────────────────

class _ApproveDialog extends StatefulWidget {
  final String inspectionId;
  final VoidCallback onApproved;

  const _ApproveDialog({required this.inspectionId, required this.onApproved});

  @override
  State<_ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends State<_ApproveDialog> {
  Uint8List? _sigBytes;
  String _sigFileName = 'signature.png';
  String _sigContentType = 'image/png';
  bool _busy = false;

  void _showSourcePicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Capture Photo'),
              onTap: () { Navigator.pop(ctx); _captureSignature(); },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Upload from Files'),
              onTap: () { Navigator.pop(ctx); _uploadSignature(); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _captureSignature() async {
    if (!mounted) return;
    final cap = await capturePhotoBytesViaPopup(context);
    if (cap == null || !mounted) return;
    setState(() {
      _sigBytes = cap.bytes;
      _sigFileName = cap.fileName;
      _sigContentType = cap.contentType;
    });
  }

  Future<void> _uploadSignature() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;
    final file = input.files?.first;
    if (file == null) return;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;
    setState(() {
      _sigBytes = Uint8List.fromList(reader.result as List<int>);
      _sigFileName = file.name;
      _sigContentType = file.type.isNotEmpty ? file.type : 'image/png';
    });
  }

  Future<void> _submit() async {
    if (_sigBytes == null) return;
    setState(() => _busy = true);
    try {
      final sigUrl = await inspectionRequestsService.uploadSignatureImage(
        bytes: _sigBytes!,
        fileName: _sigFileName,
        contentType: _sigContentType,
      );
      await inspectionRequestsService.approveInspection(
        inspectionId: widget.inspectionId,
        signatureUrl: sigUrl,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onApproved();
      showTopSnack(context, 'Inspection approved successfully.', variant: 'success');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showTopSnack(context, 'Failed to approve: $e', variant: 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Approve Inspection'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AUTHORIZED SIGNATURE',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black54,
                fontSize: 11,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showSourcePicker,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withValues(alpha: 0.02),
                ),
                child: _sigBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.memory(_sigBytes!, fit: BoxFit.contain),
                      )
                    : const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: Colors.black38),
                            SizedBox(height: 4),
                            Text(
                              'Tap to capture or upload signature',
                              style: TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (_busy || _sigBytes == null) ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: Colors.green),
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Approve'),
        ),
      ],
    );
  }
}

// ─── Reject Dialog ────────────────────────────────────────────────────────────

class _RejectDialog extends StatefulWidget {
  final String inspectionId;
  final VoidCallback onRejected;

  const _RejectDialog({required this.inspectionId, required this.onRejected});

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reasonCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) return;
    setState(() => _busy = true);
    try {
      await inspectionRequestsService.rejectInspection(
        inspectionId: widget.inspectionId,
        rejectionReason: reason,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onRejected();
      showTopSnack(context, 'Inspection rejected — returned to inspector.', variant: 'success');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showTopSnack(context, 'Failed to reject: $e', variant: 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Inspection'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The inspection will be returned to in-progress status.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonCtrl,
              onChanged: (_) => setState(() {}),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for Rejection',
                hintText: 'e.g. Missing damage photos on rear bumper section.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (_busy || _reasonCtrl.text.trim().isEmpty) ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Reject'),
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