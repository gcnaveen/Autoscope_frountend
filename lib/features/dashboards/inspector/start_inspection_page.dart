import 'dart:async';
import 'dart:typed_data';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../models/checklist_template.dart';
import '../../../services/service_locator.dart';
import '../../../services/dropdown_config_service.dart';
import '../../shared/app_shell.dart';
import '../../shared/top_snackbar.dart';
import '../../shared/widgets/image_uploader.dart';
import '../../shared/widgets/media_uploader.dart';
import '../../shared/widgets/web_camera_capture_web.dart';

// ✅ Damage marker editor + DamageCoordinate
import 'widgets/damage_marker_editor.dart';

/// ✅ Forces ALL user-typed text to UPPERCASE
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();

    final base = newValue.selection.baseOffset > upper.length
        ? upper.length
        : newValue.selection.baseOffset;
    final extent = newValue.selection.extentOffset > upper.length
        ? upper.length
        : newValue.selection.extentOffset;

    return newValue.copyWith(
      text: upper,
      selection: TextSelection(baseOffset: base, extentOffset: extent),
      composing: TextRange.empty,
    );
  }
}

class StartInspectionPage extends StatefulWidget {
  final String requestId; // inspection-request _id
  const StartInspectionPage({super.key, required this.requestId});

  @override
  State<StartInspectionPage> createState() => _StartInspectionPageState();
}

class _StartInspectionPageState extends State<StartInspectionPage> {
  late Future<List<ChecklistTemplate>> _future;
  ChecklistTemplate? _selectedTemplate;

  /// Wizard section index:
  /// 0 Vehicle Details
  /// 1 Service & Warranty
  /// 2 Interior Details
  /// 3 Exterior Details
  /// 4.. checklist types
  /// last = Damaged Coordinates
  int _section = 0;

  /// ✅ IMPORTANT: We will use inspectionRequestId as the "inspectionId" for section-progress APIs
  String get _progressId => widget.requestId;

  bool _startingInspection = false;
  bool _inspectionStarted = false;
  String? _startError;

  bool _submitting = false;
  bool _savingDraft = false;

  final _scrollCtrl = ScrollController();
  final _upper = UpperCaseTextFormatter();

  // progress restore
  bool _progressFetched = false;
  bool _progressApplied = false;
  Map<String, dynamic>? _progressSnapshot;

  // ============================
  // FORM KEYS
  // ============================
  final _vehicleFormKey = GlobalKey<FormState>();
  final _serviceFormKey = GlobalKey<FormState>();
  final _interiorFormKey = GlobalKey<FormState>();
  final _exteriorFormKey = GlobalKey<FormState>();

  // ============================
  // REPORT INPUT CONTROLLERS
  // ============================

  // Vehicle Details
  final makeCtrl = TextEditingController();
  final modelCtrl = TextEditingController();
  final gradeVariantCtrl = TextEditingController();
  final engineCapacityCtrl = TextEditingController();
  final modelYearCtrl = TextEditingController();
  final cylinderSizeCtrl = TextEditingController();
  final transmissionCtrl = TextEditingController();
  final fuelTypeCtrl = TextEditingController();
  final driveTrainCtrl = TextEditingController();
  final specsCtrl = TextEditingController();
  final odometerCtrl = TextEditingController();
  final registrationNoCtrl = TextEditingController();
  final emiratesRegAtCtrl = TextEditingController();
  final chassisNoCtrl = TextEditingController();
  String? _chassisNoPhotoUrl;
  bool _chassisUploading = false;

  final ownershipTypeCtrl = TextEditingController();

  // Service & Warranty Overview
  String? serviceHistory; // Available / Not Available
  final servicedWithCtrl = TextEditingController(); // Agency / Third party
  final lastServiceDateCtrl = TextEditingController(); // yyyy-mm-dd (picked)
  String? warrantyAvailable; // Yes/No
  final warrantyEndsInCtrl = TextEditingController(); // MMM-yy (picked)
  String? hadAccidents; // Yes/No

  // Interior Details
  final seatsCtrl = TextEditingController();
  final interiorColorCtrl = TextEditingController();
  final upholsteryCtrl = TextEditingController();
  final numberOfKeysCtrl = TextEditingController();
  String? interiorModificationDone; // Yes/No

  // Exterior Details
  final exteriorColorCtrl = TextEditingController();
  final doorsCtrl = TextEditingController();
  final wheelSizeCtrl = TextEditingController();
  String? _wheelType;
  final wheelTypeOtherCtrl = TextEditingController();
  bool _wheelSizeIsOther = false;
  final wheelSizeOtherCtrl = TextEditingController();
  bool _specsIsOther = false;
  final specsOtherCtrl = TextEditingController();
  String? exteriorModificationDone; // Yes/No

  // ============================
  // ✅ DAMAGED COORDINATES
  // ============================
  static const String _carTopImageAsset = 'assets/images/car_views/top.jpg';
  List<DamageCoordinate> _damagedCoordinates = [];

  Map<String, dynamic> _buildDamagedCoordinatesPayload() {
    return {
      'data': _damagedCoordinates.map((d) => d.toApiJson()).toList(),
    };
  }

  // ============================
  // ✅ Make/Model dropdowns (API + OTHER)
  // ============================
  bool loadingMakes = false;
  bool loadingModels = false;

  List<String> makes = [];
  List<String> models = [];

  String? selectedMake; // MAKE NAME (UPPERCASE)
  String? selectedMakeId; // MAKE ID
  String? selectedModel; // MODEL NAME (UPPERCASE)

  final Map<String, String> _makeIdByName = {};

  bool _makeIsOther = false;
  bool _modelIsOther = false;
  final otherMakeCtrl = TextEditingController();
  final otherModelCtrl = TextEditingController();

  // ============================
  // CHECKLIST STATE
  // ============================

  final Map<String, String?> _grade = {}; // selected option label
  final Map<String, TextEditingController> _remarks = {};
  final Map<String, List<String>> _itemPhotos = {};

  final Map<int, TextEditingController> _overallRemarks = {};
  final Map<int, List<String>> _overallPhotos = {};
  final Map<int, List<String>> _overallVideos = {};

  static const List<String> _gradeOptions = [
    'Excellent (5)',
    'Good (4)',
    'Average (3)',
    'Poor (1)',
    'Not Applicable',
  ];

  // Not configurable
  static const List<String> _ownershipTypeOptions = ['INDIVIDUAL', 'COMPANY'];

  // Configurable — loaded from DropdownConfigService; initialised to defaults
  List<String> _transmissionOptions    = DropdownConfigService.defaults['transmission']!;
  List<String> _fuelTypeOptions        = DropdownConfigService.defaults['fuelType']!;
  List<String> _gradeVariantOptions    = DropdownConfigService.defaults['gradeVariant']!;
  List<String> _cylinderSizeOptions    = DropdownConfigService.defaults['cylinderSize']!;
  List<String> _driveTrainOptions      = DropdownConfigService.defaults['driveTrain']!;
  List<String> _specsOptions           = DropdownConfigService.defaults['specs']!;       // no 'OTHER' — appended in UI
  List<String> _wheelSizeOptions       = DropdownConfigService.defaults['wheelSize']!;   // no 'Other' — appended in UI
  List<String> _wheelTypeOptions       = DropdownConfigService.defaults['wheelType']!;   // no 'Other' — appended in UI
  List<String> _servicedWithOptions    = DropdownConfigService.defaults['servicedWith']!;
  List<String> _seatsOptions           = DropdownConfigService.defaults['seats']!;
  List<String> _interiorColorOptions   = DropdownConfigService.defaults['interiorColor']!;
  List<String> _exteriorColorOptions   = DropdownConfigService.defaults['exteriorColor']!;
  List<String> _upholsteryOptions      = DropdownConfigService.defaults['upholstery']!;
  List<String> _numberOfKeysOptions    = DropdownConfigService.defaults['numberOfKeys']!;
  List<String> _doorsOptions           = DropdownConfigService.defaults['doors']!;

  // "Other" text controllers for every configurable dropdown
  final Map<String, TextEditingController> _otherCtrls = {};

  // Custom fields defined by admin
  List<CustomField> _customFields = [];
  final Map<String, String> _customFieldValues = {};           // keyed by field.id
  final Map<String, TextEditingController> _customTextCtrls = {}; // keyed by field.id (text) or field.id+'_other' (dropdown other)

  double? _gradeToRating(String? v) {
    if (v == null) return null;
    if (v.startsWith('Excellent')) return 5;
    if (v.startsWith('Good')) return 4;
    if (v.startsWith('Average')) return 3;
    if (v.startsWith('Poor')) return 1;
    return null;
  }

  String? _gradeToStatus(String? v) {
    if (v == null) return null;
    if (v == 'Not Applicable') return 'Not Applicable';
    return v.split(' ').first.trim();
  }

  bool _isHttpUrl(String s) {
    final u = Uri.tryParse(s.trim());
    return u != null && (u.scheme == 'http' || u.scheme == 'https');
  }

  @override
  void initState() {
    super.initState();
    _future = _loadTemplates();
    _loadMakes();
    _loadDropdownConfig();

    for (final key in const [
      'gradeVariant', 'cylinderSize', 'transmission', 'fuelType', 'driveTrain',
      'seats', 'interiorColor', 'exteriorColor', 'upholstery', 'numberOfKeys',
      'doors', 'servicedWith',
    ]) {
      _otherCtrls[key] = TextEditingController();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ On "Start Inspection" open, fetch draft first and fill all data
      _bootstrapStartInspection();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();

    for (final c in _remarks.values) {
      c.dispose();
    }
    for (final c in _overallRemarks.values) {
      c.dispose();
    }

    makeCtrl.dispose();
    modelCtrl.dispose();
    gradeVariantCtrl.dispose();
    engineCapacityCtrl.dispose();
    modelYearCtrl.dispose();
    cylinderSizeCtrl.dispose();
    transmissionCtrl.dispose();
    fuelTypeCtrl.dispose();
    driveTrainCtrl.dispose();
    specsCtrl.dispose();
    odometerCtrl.dispose();
    registrationNoCtrl.dispose();
    emiratesRegAtCtrl.dispose();
    chassisNoCtrl.dispose();
    ownershipTypeCtrl.dispose();

    servicedWithCtrl.dispose();
    lastServiceDateCtrl.dispose();
    warrantyEndsInCtrl.dispose();

    seatsCtrl.dispose();
    interiorColorCtrl.dispose();
    upholsteryCtrl.dispose();
    numberOfKeysCtrl.dispose();

    exteriorColorCtrl.dispose();
    doorsCtrl.dispose();
    wheelSizeCtrl.dispose();
    wheelSizeOtherCtrl.dispose();
    wheelTypeOtherCtrl.dispose();
    specsOtherCtrl.dispose();

    otherMakeCtrl.dispose();
    otherModelCtrl.dispose();

    for (final c in _otherCtrls.values) {
      c.dispose();
    }
    for (final c in _customTextCtrls.values) {
      c.dispose();
    }

    super.dispose();
  }

  void _snack(String msg, String variant) {
    showTopSnack(context, msg, variant: variant);
  }

  // ── Dropdown config ───────────────────────────────────────────────────────

  Future<void> _loadDropdownConfig() async {
    final results = await Future.wait([
      dropdownConfigService.load(),
      dropdownConfigService.loadCustomFields(),
    ]);
    if (!mounted) return;
    final cfg = results[0] as Map<String, List<String>>;
    final fields = results[1] as List<CustomField>;
    setState(() {
      _gradeVariantOptions    = cfg['gradeVariant']!;
      _cylinderSizeOptions    = cfg['cylinderSize']!;
      _transmissionOptions    = cfg['transmission']!;
      _fuelTypeOptions        = cfg['fuelType']!;
      _driveTrainOptions      = cfg['driveTrain']!;
      _specsOptions           = cfg['specs']!;
      _seatsOptions           = cfg['seats']!;
      _interiorColorOptions   = cfg['interiorColor']!;
      _exteriorColorOptions   = cfg['exteriorColor']!;
      _upholsteryOptions      = cfg['upholstery']!;
      _numberOfKeysOptions    = cfg['numberOfKeys']!;
      _doorsOptions           = cfg['doors']!;
      _wheelSizeOptions       = cfg['wheelSize']!;
      _wheelTypeOptions       = cfg['wheelType']!;
      _servicedWithOptions    = cfg['servicedWith']!;
      _customFields = fields;
      for (final f in fields) {
        if (f.type == 'text') {
          _customTextCtrls.putIfAbsent(f.id, () => TextEditingController());
        } else {
          _customFieldValues.putIfAbsent(f.id, () => '');
          _customTextCtrls.putIfAbsent('${f.id}_other', () => TextEditingController());
        }
      }
    });
  }

  /// Returns the true value for a controller: if the user picked 'Other' it
  /// returns the text from the matching `_otherCtrls` entry instead.
  String _resolveCtrl(TextEditingController ctrl, String key) {
    if (ctrl.text.trim() == 'Other') {
      return _otherCtrls[key]?.text.trim() ?? '';
    }
    return ctrl.text.trim();
  }

  /// A `_dropField` that automatically appends 'Other' and, when selected,
  /// reveals an inline text field backed by [otherCtrl].
  Widget _dropWithOther({
    required String label,
    required String? value,
    required List<String> options,
    required void Function(String?) onChanged,
    required TextEditingController otherCtrl,
    String? hint,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    final opts = options.contains('Other') ? options : [...options, 'Other'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _dropField(
          label: label,
          value: value,
          options: opts,
          onChanged: onChanged,
          hint: hint,
          icon: icon,
          validator: validator,
        ),
        if (value == 'Other') ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: otherCtrl,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _dec(
              label: 'Other $label',
              hint: 'Enter $label',
              icon: Icons.edit_outlined,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Please specify $label' : null,
          ),
        ],
      ],
    );
  }

  // ── Custom field helpers ──────────────────────────────────────────────────

  String _resolveCustomField(CustomField field) {
    if (field.type == 'text') return _customTextCtrls[field.id]?.text.trim() ?? '';
    final val = _customFieldValues[field.id] ?? '';
    if (val == 'Other') return _customTextCtrls['${field.id}_other']?.text.trim() ?? '';
    return val;
  }

  Widget _buildCustomFieldWidget(CustomField field) {
    if (field.type == 'text') {
      final ctrl = _customTextCtrls.putIfAbsent(field.id, () => TextEditingController());
      return TextFormField(
        controller: ctrl,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: _dec(label: field.label, hint: 'Enter ${field.label}', icon: Icons.edit_outlined),
        validator: field.required
            ? (v) => (v == null || v.trim().isEmpty) ? '${field.label} is required' : null
            : null,
      );
    }
    // dropdown type
    final opts = [...field.options, 'Other'];
    final rawVal = _customFieldValues[field.id] ?? '';
    final safeVal = opts.contains(rawVal) ? rawVal : null;
    final otherCtrl = _customTextCtrls.putIfAbsent('${field.id}_other', () => TextEditingController());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<String>(
          value: safeVal,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          items: opts.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
          onChanged: (v) => setState(() => _customFieldValues[field.id] = v ?? ''),
          decoration: _dec(label: field.label, hint: 'Select ${field.label}', icon: Icons.list_outlined),
          validator: field.required ? (v) => v == null ? '${field.label} is required' : null : null,
        ),
        if (safeVal == 'Other') ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: otherCtrl,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _dec(label: 'Other ${field.label}', hint: 'Enter ${field.label}', icon: Icons.edit_outlined),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please specify ${field.label}' : null,
          ),
        ],
      ],
    );
  }

  List<Widget> _customFieldsForSection(String section) {
    final widgets = <Widget>[];
    for (final f in _customFields.where((f) => f.section == section)) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(_buildCustomFieldWidget(f));
    }
    return widgets;
  }

  void _restoreCustomField(CustomField f, Map<String, dynamic> d) {
    final val = (d[f.payloadKey] ?? '').toString().trim();
    if (val.isEmpty) return;
    if (f.type == 'text') {
      _customTextCtrls[f.id]?.text = val;
    } else {
      if (f.options.contains(val)) {
        _customFieldValues[f.id] = val;
      } else {
        _customFieldValues[f.id] = 'Other';
        _customTextCtrls['${f.id}_other']?.text = val;
      }
    }
  }

  // ── Chassis photo helpers ─────────────────────────────────────────────────

  Future<void> _pickChassisPhoto() async {
    if (_chassisUploading) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Capture Photo'),
              onTap: () { Navigator.pop(ctx); _uploadChassisFromCamera(); },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Upload from Files'),
              onTap: () { Navigator.pop(ctx); _uploadChassisFromFiles(); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadChassisFromCamera() async {
    if (!mounted) return;
    setState(() => _chassisUploading = true);
    try {
      final cap = await capturePhotoBytesViaPopup(context);
      if (cap == null || !mounted) return;
      final url = await inspectionRequestsService.uploadInspectionMedia(
        inspectionRequestId: widget.requestId,
        typeName: 'vehicle_details',
        bytes: cap.bytes,
        fileName: cap.fileName,
        contentType: cap.contentType,
        mediaType: 'photos',
      );
      if (!mounted) return;
      setState(() => _chassisNoPhotoUrl = url);
    } catch (e) {
      if (mounted) _snack('Chassis photo upload failed: $e', 'error');
    } finally {
      if (mounted) setState(() => _chassisUploading = false);
    }
  }

  Future<void> _uploadChassisFromFiles() async {
    if (!mounted) return;
    final input = html.FileUploadInputElement()..accept = 'image/*';
    final completer = Completer<html.File?>();
    input.onChange.listen((_) =>
        completer.complete(input.files?.isNotEmpty == true ? input.files!.first : null));
    input.click();
    final file = await completer.future;
    if (file == null || !mounted) return;

    setState(() => _chassisUploading = true);
    try {
      final bytesCompleter = Completer<Uint8List>();
      final reader = html.FileReader();
      reader.onLoad.listen((_) {
        final r = reader.result;
        if (r is ByteBuffer) bytesCompleter.complete(Uint8List.view(r));
        else if (r is Uint8List) bytesCompleter.complete(r);
        else bytesCompleter.completeError(Exception('Unexpected result type'));
      });
      reader.onError.listen((_) =>
          bytesCompleter.completeError(reader.error ?? Exception('Read failed')));
      reader.readAsArrayBuffer(file);
      final bytes = await bytesCompleter.future;

      if (!mounted) return;
      final url = await inspectionRequestsService.uploadInspectionMedia(
        inspectionRequestId: widget.requestId,
        typeName: 'vehicle_details',
        bytes: bytes,
        fileName: file.name,
        contentType: normalizeContentType(file.type),
        mediaType: 'photos',
      );
      if (!mounted) return;
      setState(() => _chassisNoPhotoUrl = url);
    } catch (e) {
      if (mounted) _snack('Chassis photo upload failed: $e', 'error');
    } finally {
      if (mounted) setState(() => _chassisUploading = false);
    }
  }

  void _scrollToTop() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  // =========================================================
  // ✅ BOOTSTRAP: Fetch draft + apply + then startInspection
  // =========================================================
  Future<void> _bootstrapStartInspection() async {
    if (_startingInspection || _inspectionStarted) return;

    setState(() {
      _startingInspection = true;
      _startError = null;
    });

    try {
      // 1) GET existing progress using requestId
      await _fetchSectionProgress();
      _applyProgressIfReady(); // will apply only if template already loaded

      // 2) Call startInspection (keep it; backend might need it)
      await inspectionRequestsService.startInspection(widget.requestId);

      if (!mounted) return;
      setState(() => _inspectionStarted = true);

      // apply again (in case templates loaded after fetch)
      _applyProgressIfReady();
    } catch (e) {
      if (!mounted) return;
      setState(() => _startError = e.toString());
      // _snack('Failed to start inspection: $e', 'error');
    } finally {
      if (mounted) setState(() => _startingInspection = false);
    }
  }

  // ============================
  // DRAFT PROGRESS API (REQUEST-ID BASED)
  // ============================
  Future<void> _fetchSectionProgress() async {
    if (_progressFetched) return;
    _progressFetched = true;

    final id = _progressId.trim();
    if (id.isEmpty) return;

    try {
      final res = await inspectionRequestsService.getInspectionSectionProgress(id);

      // expected:
      // { data: { progress: { currentSectionIndex, sections:[...] } } }
      final data = (res['data'] is Map) ? res['data'] as Map : null;
      final progress = (data?['progress'] is Map) ? data!['progress'] as Map : null;

      if (progress != null) {
        _progressSnapshot = Map<String, dynamic>.from(progress);
      }
    } catch (e) {
      // If no draft exists backend might throw 404; keep non-blocking
      _snack('Draft not found / could not load: $e', 'warning');
    }
  }

  void _applyProgressIfReady() {
    if (_progressApplied) return;
    if (_selectedTemplate == null) return;
    if (_progressSnapshot == null) return;

    _progressApplied = true;

    final selected = _selectedTemplate!;
    final total = _totalSections(selected);
    final progress = _progressSnapshot!;

    final idxRaw = progress['currentSectionIndex'];
    final idx = int.tryParse(idxRaw?.toString() ?? '');
    if (idx != null) {
      _section = idx.clamp(0, total - 1);
    }

    final sections = progress['sections'];
    if (sections is List) {
      for (final s in sections) {
        if (s is! Map) continue;
        final sectionKey = (s['sectionKey'] ?? '').toString().trim();
        final sectionData = s['sectionData'];
        if (sectionKey.isEmpty) continue;
        _applySectionData(selected, sectionKey, sectionData);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncMakeModelUIFromControllers();
      if (mounted) setState(() {});
    });

    setState(() {});
  }

  // ============================
  // APPLY SECTION DATA (RESTORE)
  // ============================
  void _applySectionData(ChecklistTemplate selected, String sectionKey, dynamic sectionData) {
    // ✅ Restore damages
    if (sectionKey == 'damaged_coordinates') {
      List<dynamic>? list;

      if (sectionData is Map) {
        final m = Map<String, dynamic>.from(sectionData);
        final d = m['data'];
        if (d is List) list = d;
      } else if (sectionData is List) {
        list = sectionData;
      }

      if (list != null) {
        _damagedCoordinates = list
            .whereType<Map>()
            .map((x) => DamageCoordinate.fromJson(Map<String, dynamic>.from(x)))
            .toList();
      }
      return;
    }

    if (sectionData is! Map) return;
    final d = Map<String, dynamic>.from(sectionData);

    switch (sectionKey) {
      case 'vehicle_details':
        makeCtrl.text = (d['make'] ?? makeCtrl.text).toString().trim();
        modelCtrl.text = (d['model'] ?? modelCtrl.text).toString().trim();
        gradeVariantCtrl.text = (d['gradeVariant'] ?? gradeVariantCtrl.text).toString().trim();
        _otherCtrls['gradeVariant']?.text = (d['gradeVariantOther'] ?? '').toString().trim();
        engineCapacityCtrl.text = (d['engineCapacity'] ?? engineCapacityCtrl.text).toString().trim();
        modelYearCtrl.text = (d['modelYear'] ?? modelYearCtrl.text).toString().trim();
        cylinderSizeCtrl.text = (d['cylinderSize'] ?? cylinderSizeCtrl.text).toString().trim();
        _otherCtrls['cylinderSize']?.text = (d['cylinderSizeOther'] ?? '').toString().trim();
        transmissionCtrl.text = (d['transmission'] ?? transmissionCtrl.text).toString().trim();
        _otherCtrls['transmission']?.text = (d['transmissionOther'] ?? '').toString().trim();
        fuelTypeCtrl.text = (d['fuelType'] ?? fuelTypeCtrl.text).toString().trim();
        _otherCtrls['fuelType']?.text = (d['fuelTypeOther'] ?? '').toString().trim();
        driveTrainCtrl.text = (d['driveTrain'] ?? driveTrainCtrl.text).toString().trim();
        _otherCtrls['driveTrain']?.text = (d['driveTrainOther'] ?? '').toString().trim();
        specsCtrl.text = (d['specs'] ?? specsCtrl.text).toString().trim();
        // Migrate old 'US SPECS' to renamed 'AMERICAN'
        if (specsCtrl.text == 'US SPECS') specsCtrl.text = 'AMERICAN';
        specsOtherCtrl.text = (d['specsOther'] ?? specsOtherCtrl.text).toString().trim();
        _specsIsOther = specsCtrl.text == 'OTHER';
        odometerCtrl.text = (d['odometerReading'] ?? odometerCtrl.text).toString().trim();
        registrationNoCtrl.text = (d['registrationNo'] ?? registrationNoCtrl.text).toString().trim();
        emiratesRegAtCtrl.text = (d['emiratesRegAt'] ?? emiratesRegAtCtrl.text).toString().trim();

        final rawChassis = (d['chassisNo'] ?? '').toString().trim();
        final rawChassisPhoto = (d['chassisPhotoUrl'] ?? '').toString().trim();
        if (_isHttpUrl(rawChassisPhoto)) {
          // new format: chassisNo = text, chassisPhotoUrl = URL
          chassisNoCtrl.text = rawChassis;
          _chassisNoPhotoUrl = rawChassisPhoto;
        } else if (_isHttpUrl(rawChassis)) {
          // backward compat: old records stored URL directly in chassisNo
          chassisNoCtrl.text = '';
          _chassisNoPhotoUrl = rawChassis;
        } else {
          chassisNoCtrl.text = rawChassis;
          _chassisNoPhotoUrl = null;
        }

        ownershipTypeCtrl.text = (d['ownershipType'] ?? ownershipTypeCtrl.text).toString().trim();
        for (final f in _customFields.where((f) => f.section == 'vehicle_details')) {
          _restoreCustomField(f, d);
        }
        break;

      case 'service_warranty_overview':
        serviceHistory = (d['serviceHistory'] ?? serviceHistory)?.toString();
        servicedWithCtrl.text = (d['servicedWith'] ?? servicedWithCtrl.text).toString().trim();
        _otherCtrls['servicedWith']?.text = (d['servicedWithOther'] ?? '').toString().trim();
        lastServiceDateCtrl.text = (d['lastServiceDate'] ?? lastServiceDateCtrl.text).toString().trim();
        warrantyAvailable = (d['warrantyAvailable'] ?? warrantyAvailable)?.toString();
        warrantyEndsInCtrl.text = (d['warrantyEndsIn'] ?? warrantyEndsInCtrl.text).toString().trim();
        hadAccidents = (d['hadAccidents'] ?? hadAccidents)?.toString();
        for (final f in _customFields.where((f) => f.section == 'service_warranty')) {
          _restoreCustomField(f, d);
        }
        break;

      case 'interior_details':
        seatsCtrl.text = (d['seats'] ?? seatsCtrl.text).toString().trim();
        _otherCtrls['seats']?.text = (d['seatsOther'] ?? '').toString().trim();
        interiorColorCtrl.text = (d['interiorColor'] ?? interiorColorCtrl.text).toString().trim();
        _otherCtrls['interiorColor']?.text = (d['interiorColorOther'] ?? '').toString().trim();
        upholsteryCtrl.text = (d['upholstery'] ?? upholsteryCtrl.text).toString().trim();
        _otherCtrls['upholstery']?.text = (d['upholsteryOther'] ?? '').toString().trim();
        numberOfKeysCtrl.text = (d['numberOfKeys'] ?? numberOfKeysCtrl.text).toString().trim();
        _otherCtrls['numberOfKeys']?.text = (d['numberOfKeysOther'] ?? '').toString().trim();
        interiorModificationDone = (d['modificationDone'] ?? interiorModificationDone)?.toString();
        for (final f in _customFields.where((f) => f.section == 'interior_details')) {
          _restoreCustomField(f, d);
        }
        break;

      case 'exterior_details':
        exteriorColorCtrl.text = (d['exteriorColor'] ?? exteriorColorCtrl.text).toString().trim();
        _otherCtrls['exteriorColor']?.text = (d['exteriorColorOther'] ?? '').toString().trim();
        doorsCtrl.text = (d['doors'] ?? doorsCtrl.text).toString().trim();
        _otherCtrls['doors']?.text = (d['doorsOther'] ?? '').toString().trim();
        wheelSizeCtrl.text = (d['wheelSize'] ?? wheelSizeCtrl.text).toString().trim();
        // Migrate wheel size stored without inch symbol (backend may strip '"')
        if (wheelSizeCtrl.text.isNotEmpty && !wheelSizeCtrl.text.endsWith('"') && wheelSizeCtrl.text != 'Other') {
          final candidate = '${wheelSizeCtrl.text}"';
          if (_wheelSizeOptions.contains(candidate)) wheelSizeCtrl.text = candidate;
        }
        wheelSizeOtherCtrl.text = (d['wheelSizeOther'] ?? wheelSizeOtherCtrl.text).toString().trim();
        _wheelSizeIsOther = wheelSizeCtrl.text == 'Other';
        _wheelType = (d['wheelType'] ?? _wheelType)?.toString();
        wheelTypeOtherCtrl.text = (d['wheelTypeOther'] ?? wheelTypeOtherCtrl.text).toString().trim();
        exteriorModificationDone = (d['modificationDone'] ?? exteriorModificationDone)?.toString();
        for (final f in _customFields.where((f) => f.section == 'exterior_details')) {
          _restoreCustomField(f, d);
        }
        break;

      default:
        // checklist sections
        final ti = _findTypeIndexByKey(selected, sectionKey, d);
        if (ti == null) return;

        final gradeMap = d['grade'];
        if (gradeMap is Map) {
          for (final e in gradeMap.entries) {
            final ii = int.tryParse(e.key.toString());
            if (ii == null) continue;
            final k = '$ti:$ii';
            if (_grade.containsKey(k)) _grade[k] = e.value?.toString();
          }
        }

        final remMap = d['remarks'];
        if (remMap is Map) {
          for (final e in remMap.entries) {
            final ii = int.tryParse(e.key.toString());
            if (ii == null) continue;
            final k = '$ti:$ii';
            if (_remarks.containsKey(k)) _remarks[k]!.text = e.value?.toString() ?? '';
          }
        }

        final phMap = d['itemPhotos'];
        if (phMap is Map) {
          for (final e in phMap.entries) {
            final ii = int.tryParse(e.key.toString());
            if (ii == null) continue;
            final k = '$ti:$ii';
            if (_itemPhotos.containsKey(k) && e.value is List) {
              _itemPhotos[k] = (e.value as List).map((x) => x.toString()).toList();
            }
          }
        }

        final oRem = d['overallRemarks'];
        if (oRem != null && _overallRemarks.containsKey(ti)) {
          _overallRemarks[ti]!.text = oRem.toString();
        }

        final oPhotos = d['overallPhotos'];
        if (oPhotos is List) {
          _overallPhotos[ti] = oPhotos.map((x) => x.toString()).toList();
        }

        final oVideos = d['overallVideos'];
        if (oVideos is List) {
          _overallVideos[ti] = oVideos.map((x) => x.toString()).toList();
        }
        break;
    }
  }

  int? _findTypeIndexByKey(ChecklistTemplate selected, String sectionKey, Map<String, dynamic> sectionData) {
    final raw = sectionData['typeIndex'];
    final ti = int.tryParse(raw?.toString() ?? '');
    if (ti != null && ti >= 0 && ti < selected.types.length) return ti;

    for (var i = 0; i < selected.types.length; i++) {
      if (_normalizeKey(selected.types[i].typeName) == sectionKey) return i;
    }
    return null;
  }

  // ============================
  // TEMPLATES
  // ============================
  Future<List<ChecklistTemplate>> _loadTemplates() async {
    final raw = await checklistTemplatesService.listActiveTemplates();
    final templates = raw.map((x) => ChecklistTemplate.fromJson(x)).toList();

    if (templates.isNotEmpty) {
      _selectedTemplate = templates.first;
      _primeChecklistControllers();
    }

    // If draft already fetched, apply now
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyProgressIfReady();
    });

    return templates;
  }

  void _primeChecklistControllers() {
    final oldItemRemarkControllers = _remarks.values.toList();
    final oldOverallControllers = _overallRemarks.values.toList();

    _remarks.clear();
    _overallRemarks.clear();
    _grade.clear();
    _itemPhotos.clear();
    _overallPhotos.clear();
    _overallVideos.clear();

    final t = _selectedTemplate;
    if (t == null) return;

    for (var ti = 0; ti < t.types.length; ti++) {
      final type = t.types[ti];

      if (type.allowOverallRemarks) {
        _overallRemarks[ti] = TextEditingController();
      }

      _overallPhotos[ti] = [];
      _overallVideos[ti] = [];

      for (var ii = 0; ii < type.checklistItems.length; ii++) {
        final key = '$ti:$ii';
        _grade[key] = null;
        _remarks[key] = TextEditingController();
        _itemPhotos[key] = [];
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in oldItemRemarkControllers) {
        try {
          c.dispose();
        } catch (_) {}
      }
      for (final c in oldOverallControllers) {
        try {
          c.dispose();
        } catch (_) {}
      }
    });
  }

  // ============================
  // MAKE / MODEL API
  // ============================
  Future<void> _loadMakes() async {
    setState(() {
      loadingMakes = true;
      makes = [];
      models = [];
      selectedMake = null;
      selectedMakeId = null;
      selectedModel = null;
      _makeIdByName.clear();
      _makeIsOther = false;
      _modelIsOther = false;
      otherMakeCtrl.text = '';
      otherModelCtrl.text = '';
    });

    try {
      final detailed = await inspectionRequestsService.listVehicleMakesDetailed();

      for (final m in detailed) {
        final name = (m['name'] ?? '').toString().trim().toUpperCase();
        final id = (m['id'] ?? m['_id'] ?? '').toString().trim();
        if (name.isNotEmpty) _makeIdByName[name] = id;
      }

      final names = _makeIdByName.keys.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      if (!mounted) return;
      setState(() {
        makes = [...names, 'OTHER'];
        if (makes.isEmpty) makes = const ['OTHER'];
      });
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to load makes: $e', 'error');
      setState(() => makes = const ['OTHER']);
    } finally {
      if (mounted) setState(() => loadingMakes = false);
    }
  }

  Future<void> _loadModelsForMakeId(String makeId) async {
    setState(() {
      loadingModels = true;
      models = [];
      selectedModel = null;
      _modelIsOther = false;
      otherModelCtrl.text = '';
    });

    try {
      final list = await inspectionRequestsService.listVehicleModels(makeId);

      if (!mounted) return;
      final uniqueModels = list.map((e) => e.toString().trim().toUpperCase()).toSet().toList()
        ..sort((a, b) => a.compareTo(b));
      setState(() {
        models = [...uniqueModels, 'OTHER'];
        if (models.isEmpty) models = const ['OTHER'];
      });
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to load models: $e', 'error');
      setState(() {
        models = const ['OTHER'];
        selectedModel = 'OTHER';
        _modelIsOther = true;
      });
    } finally {
      if (mounted) setState(() => loadingModels = false);
    }
  }

  Future<void> _syncMakeModelUIFromControllers() async {
    final make = makeCtrl.text.trim().toUpperCase();
    final model = modelCtrl.text.trim().toUpperCase();
    if (make.isEmpty) return;

    if (makes.isEmpty && !loadingMakes) {
      await _loadMakes();
    }

    final mkId = _makeIdByName[make];

    if (mkId != null && mkId.trim().isNotEmpty) {
      selectedMake = make;
      selectedMakeId = mkId;
      _makeIsOther = false;
      otherMakeCtrl.text = '';

      await _loadModelsForMakeId(mkId);

      if (model.isNotEmpty && models.contains(model)) {
        selectedModel = model;
        _modelIsOther = false;
        otherModelCtrl.text = '';
      } else if (model.isNotEmpty) {
        selectedModel = 'OTHER';
        _modelIsOther = true;
        otherModelCtrl.text = model;
      }
    } else {
      selectedMake = 'OTHER';
      selectedMakeId = null;
      _makeIsOther = true;
      otherMakeCtrl.text = make;

      if (model.isNotEmpty) {
        selectedModel = 'OTHER';
        _modelIsOther = true;
        otherModelCtrl.text = model;
        models = const ['OTHER'];
      }
    }
  }

  bool _applyMakeModelToControllersNoNetwork() {
    String make = _makeIsOther ? otherMakeCtrl.text.trim().toUpperCase() : (selectedMake ?? '').trim().toUpperCase();
    String model = _modelIsOther ? otherModelCtrl.text.trim().toUpperCase() : (selectedModel ?? '').trim().toUpperCase();

    if (make.isEmpty) {
      _snack('Make is required', 'warning');
      return false;
    }
    if (model.isEmpty) {
      _snack('Model is required', 'warning');
      return false;
    }

    makeCtrl.text = make;
    modelCtrl.text = model;
    return true;
  }

  // ============================
  // WIZARD
  // ============================
  int _totalSections(ChecklistTemplate selected) => 5 + selected.types.length;

  String _sectionTitle(ChecklistTemplate selected, int index) {
    if (index == 0) return 'Vehicle Details';
    if (index == 1) return 'Service & Warranty Overview';
    if (index == 2) return 'Interior Details';
    if (index == 3) return 'Exterior Details';

    final damageIndex = 4 + selected.types.length;
    if (index == damageIndex) return 'Damaged Coordinates';

    final ti = index - 4;
    return selected.types[ti].typeName;
  }

  bool _isLastSection(ChecklistTemplate selected) => _section == _totalSections(selected) - 1;

  bool _validateCurrentSection(ChecklistTemplate selected) {
    if (_section == 0) return _vehicleFormKey.currentState?.validate() ?? false;
    if (_section == 1) return _serviceFormKey.currentState?.validate() ?? false;
    if (_section == 2) return _interiorFormKey.currentState?.validate() ?? false;
    if (_section == 3) return _exteriorFormKey.currentState?.validate() ?? false;

    final damageIndex = 4 + selected.types.length;
    if (_section == damageIndex) return true;

    final ti = _section - 4;
    return _validateChecklistTypeOnly(selected, ti);
  }

  bool _validateChecklistTypeOnly(ChecklistTemplate selected, int ti) {
    if (ti < 0 || ti >= selected.types.length) return true;
    final type = selected.types[ti];

    for (var ii = 0; ii < type.checklistItems.length; ii++) {
      final item = type.checklistItems[ii];
      if (!item.isRequired) continue;

      final key = '$ti:$ii';
      final g = _grade[key];
      if (g == null || g.trim().isEmpty) {
        _snack('Please select: ${type.typeName} → ${item.label}', 'warning');
        return false;
      }
    }
    return true;
  }

  Future<void> _next(ChecklistTemplate selected) async {
    final ok = _validateCurrentSection(selected);
    if (!ok) {
      _snack('Please fix the highlighted fields.', 'warning');
      _scrollToTop();
      return;
    }

    final saved = await _saveDraftOnNext(selected);
    if (!saved) return;

    final total = _totalSections(selected);
    if (_section < total - 1) {
      setState(() => _section++);
      _scrollToTop();
    }
  }

  void _back() {
    if (_section > 0) {
      setState(() => _section--);
      _scrollToTop();
    }
  }

  // ============================
  // SECTION KEYS + SECTION DATA (DRAFT)
  // ============================
  String _normalizeKey(String s) {
    final x = s.trim().toLowerCase();
    return x.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_');
  }

  String _sectionKeyForIndex(ChecklistTemplate selected, int index) {
    if (index == 0) return 'vehicle_details';
    if (index == 1) return 'service_warranty_overview';
    if (index == 2) return 'interior_details';
    if (index == 3) return 'exterior_details';

    final damageIndex = 4 + selected.types.length;
    if (index == damageIndex) return 'damaged_coordinates';

    final ti = index - 4;
    return _normalizeKey(selected.types[ti].typeName);
  }

  Map<String, dynamic> _buildSectionDataForIndex(ChecklistTemplate selected, int index) {
    if (index == 0) {
      _applyMakeModelToControllersNoNetwork();
      final data = <String, dynamic>{
        'make': makeCtrl.text.trim(),
        'model': modelCtrl.text.trim(),
        'gradeVariant': gradeVariantCtrl.text.trim(),
        'gradeVariantOther': _otherCtrls['gradeVariant']?.text.trim() ?? '',
        'engineCapacity': engineCapacityCtrl.text.trim(),
        'modelYear': modelYearCtrl.text.trim(),
        'cylinderSize': cylinderSizeCtrl.text.trim(),
        'cylinderSizeOther': _otherCtrls['cylinderSize']?.text.trim() ?? '',
        'transmission': transmissionCtrl.text.trim(),
        'transmissionOther': _otherCtrls['transmission']?.text.trim() ?? '',
        'fuelType': fuelTypeCtrl.text.trim(),
        'fuelTypeOther': _otherCtrls['fuelType']?.text.trim() ?? '',
        'driveTrain': driveTrainCtrl.text.trim(),
        'driveTrainOther': _otherCtrls['driveTrain']?.text.trim() ?? '',
        'specs': specsCtrl.text.trim(),
        'specsOther': _specsIsOther ? specsOtherCtrl.text.trim() : '',
        'odometerReading': odometerCtrl.text.trim(),
        'registrationNo': registrationNoCtrl.text.trim(),
        'emiratesRegAt': emiratesRegAtCtrl.text.trim(),
        'chassisNo': chassisNoCtrl.text.trim(),
        'chassisPhotoUrl': _chassisNoPhotoUrl ?? '',
        'ownershipType': ownershipTypeCtrl.text.trim(),
      };
      for (final f in _customFields.where((f) => f.section == 'vehicle_details')) {
        data[f.payloadKey] = _resolveCustomField(f);
      }
      return data;
    }

    if (index == 1) {
      final data = <String, dynamic>{
        'serviceHistory': serviceHistory,
        'servicedWith': servicedWithCtrl.text.trim(),
        'servicedWithOther': _otherCtrls['servicedWith']?.text.trim() ?? '',
        'lastServiceDate': lastServiceDateCtrl.text.trim(),
        'warrantyAvailable': warrantyAvailable,
        'warrantyEndsIn': warrantyEndsInCtrl.text.trim(),
        'hadAccidents': hadAccidents,
      };
      for (final f in _customFields.where((f) => f.section == 'service_warranty')) {
        data[f.payloadKey] = _resolveCustomField(f);
      }
      return data;
    }

    if (index == 2) {
      final data = <String, dynamic>{
        'seats': seatsCtrl.text.trim(),
        'seatsOther': _otherCtrls['seats']?.text.trim() ?? '',
        'interiorColor': interiorColorCtrl.text.trim(),
        'interiorColorOther': _otherCtrls['interiorColor']?.text.trim() ?? '',
        'upholstery': upholsteryCtrl.text.trim(),
        'upholsteryOther': _otherCtrls['upholstery']?.text.trim() ?? '',
        'numberOfKeys': numberOfKeysCtrl.text.trim(),
        'numberOfKeysOther': _otherCtrls['numberOfKeys']?.text.trim() ?? '',
        'modificationDone': interiorModificationDone,
      };
      for (final f in _customFields.where((f) => f.section == 'interior_details')) {
        data[f.payloadKey] = _resolveCustomField(f);
      }
      return data;
    }

    if (index == 3) {
      final data = <String, dynamic>{
        'exteriorColor': exteriorColorCtrl.text.trim(),
        'exteriorColorOther': _otherCtrls['exteriorColor']?.text.trim() ?? '',
        'doors': doorsCtrl.text.trim(),
        'doorsOther': _otherCtrls['doors']?.text.trim() ?? '',
        'wheelSize': wheelSizeCtrl.text.trim(),
        'wheelSizeOther': _wheelSizeIsOther ? wheelSizeOtherCtrl.text.trim() : '',
        'wheelType': _wheelType == 'Other' ? wheelTypeOtherCtrl.text.trim() : (_wheelType ?? ''),
        'modificationDone': exteriorModificationDone,
      };
      for (final f in _customFields.where((f) => f.section == 'exterior_details')) {
        data[f.payloadKey] = _resolveCustomField(f);
      }
      return data;
    }

    final damageIndex = 4 + selected.types.length;
    if (index == damageIndex) {
      return _buildDamagedCoordinatesPayload();
    }

    // checklist type section
    final ti = index - 4;
    final type = selected.types[ti];

    final gradeMap = <String, dynamic>{};
    final remarksMap = <String, dynamic>{};
    final itemPhotosMap = <String, dynamic>{};

    for (var ii = 0; ii < type.checklistItems.length; ii++) {
      final key = '$ti:$ii';
      gradeMap['$ii'] = _grade[key];
      remarksMap['$ii'] = _remarks[key]?.text ?? '';
      itemPhotosMap['$ii'] = _itemPhotos[key] ?? [];
    }

    return {
      'typeIndex': ti,
      'typeName': type.typeName,
      'overallRemarks': _overallRemarks[ti]?.text.trim() ?? '',
      'overallPhotos': _overallPhotos[ti] ?? [],
      'overallVideos': _overallVideos[ti] ?? [],
      'grade': gradeMap,
      'remarks': remarksMap,
      'itemPhotos': itemPhotosMap,
    };
  }

  Future<bool> _saveDraftOnNext(ChecklistTemplate selected) async {
    final id = _progressId.trim();
    if (id.isEmpty) {
      _snack('inspectionRequestId missing — draft cannot be saved', 'warning');
      return true;
    }

    if (_savingDraft) return false;

    setState(() => _savingDraft = true);

    try {
      _applyMakeModelToControllersNoNetwork();

      final total = _totalSections(selected);
      final currentIndex = _section;
      final nextIndex = (currentIndex + 1).clamp(0, total - 1);

      final sectionKey = _sectionKeyForIndex(selected, currentIndex);
      final nextKey = _sectionKeyForIndex(selected, nextIndex);

      final sectionData = _buildSectionDataForIndex(selected, currentIndex);

      final body = {
        // ✅ requestId used as inspectionId for draft APIs
        'inspectionId': id,
        'sectionKey': sectionKey,
        'sectionIndex': currentIndex,
        'currentSectionKey': nextKey,
        'currentSectionIndex': nextIndex,
        'sectionData': sectionData,
        'completed': true,
      };

      await inspectionRequestsService.updateInspectionSectionProgress(id, body);
      return true;
    } catch (e) {
      _snack('Failed to save draft: $e', 'error');
      return false;
    } finally {
      if (mounted) setState(() => _savingDraft = false);
    }
  }

  // ============================
  // VALIDATORS + FORMATTERS
  // ============================
  String? _req(String? v, {String msg = 'Required'}) {
    if (v == null) return msg;
    if (v.trim().isEmpty) return msg;
    return null;
  }

  String? _alphaNumValidator(String? v, {required String fieldName, int min = 2}) {
    final r = _req(v, msg: '$fieldName is required');
    if (r != null) return r;
    final s = v!.trim();
    if (s.length < min) return '$fieldName must be at least $min characters';
    if (!RegExp(r"^[A-Za-z0-9\s'./-]+$").hasMatch(s)) {
      return '$fieldName contains invalid characters';
    }
    return null;
  }

  String? _yearValidator(String? v) {
    final r = _req(v, msg: 'Model Year is required');
    if (r != null) return r;
    final year = int.tryParse(v!.trim());
    if (year == null) return 'Model Year must be a number';
    final now = DateTime.now().year;
    if (year < 1980 || year > now + 1) {
      return 'Enter a valid year (1980 - ${now + 1})';
    }
    return null;
  }

  String? _numberValidator(String? v, {required String fieldName, int max = 12}) {
    final r = _req(v, msg: '$fieldName is required');
    if (r != null) return r;
    final s = v!.trim();
    if (!RegExp(r'^\d+$').hasMatch(s)) return '$fieldName must be numeric';
    if (s.length > max) return '$fieldName is too long';
    return null;
  }

  List<TextInputFormatter> _digitsFormatters({int max = 12}) => [
        LengthLimitingTextInputFormatter(max),
        FilteringTextInputFormatter.digitsOnly,
      ];

  List<TextInputFormatter> _yearFormatters() => [
        LengthLimitingTextInputFormatter(4),
        FilteringTextInputFormatter.digitsOnly,
      ];

  // ============================
  // DATE PICKERS
  // ============================
  Future<void> _pickLastServiceDate() async {
    final now = DateTime.now();
    DateTime initial = now;
    final raw = lastServiceDateCtrl.text.trim();
    final parts = raw.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        initial = DateTime(y, m, d);
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990, 1, 1),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );

    if (picked == null) return;
    final s = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() => lastServiceDateCtrl.text = s);
  }

  Future<void> _pickWarrantyEndsMonthYear() async {
    final now = DateTime.now();
    DateTime initial = DateTime(now.year, now.month, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990, 1, 1),
      lastDate: DateTime(now.year + 10, 12, 31),
      helpText: 'Select warranty end month (pick any day)',
    );

    if (picked == null) return;

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final mmmyy = '${months[picked.month - 1]}-${(picked.year % 100).toString().padLeft(2, '0')}'.toUpperCase();
    setState(() => warrantyEndsInCtrl.text = mmmyy);
  }

  // ============================
  // UI HELPERS
  // ============================
  InputDecoration _dec({required String label, String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1E5EFF), width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 22,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1220),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _dropField({
    required String label,
    required String? value,
    required List<String> options,
    required void Function(String?) onChanged,
    String? hint,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    final safeValue = (value != null && options.contains(value)) ? value : null;
    return DropdownButtonFormField<String>(
      value: safeValue,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      items: options.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
      onChanged: onChanged,
      decoration: _dec(label: label, hint: hint, icon: icon),
      validator: validator,
    );
  }

  // ============================
  // SECTIONS UI
  // ============================
  Widget _vehicleDetailsSection() {
    return _sectionCard(
      title: 'Vehicle Details',
      icon: Icons.directions_car_outlined,
      child: Form(
        key: _vehicleFormKey,
        child: Column(
          children: [
            // MAKE
            DropdownButtonFormField<String>(
              value: (selectedMake != null && makes.contains(selectedMake)) ? selectedMake : null,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              items: makes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: loadingMakes
                  ? null
                  : (v) async {
                      if (v == null) return;

                      if (v == 'OTHER') {
                        setState(() {
                          selectedMake = 'OTHER';
                          selectedMakeId = null;
                          _makeIsOther = true;
                          otherMakeCtrl.text = '';
                          makeCtrl.text = '';
                          models = const ['OTHER'];
                          selectedModel = 'OTHER';
                          _modelIsOther = true;
                          otherModelCtrl.text = '';
                          modelCtrl.text = '';
                        });
                        return;
                      }

                      final mkName = v.trim().toUpperCase();
                      final mkId = _makeIdByName[mkName] ?? '';

                      setState(() {
                        selectedMake = mkName;
                        selectedMakeId = mkId;
                        _makeIsOther = false;
                        otherMakeCtrl.text = '';
                        makeCtrl.text = mkName;
                        selectedModel = null;
                        _modelIsOther = false;
                        otherModelCtrl.text = '';
                        modelCtrl.text = '';
                        models = [];
                      });

                      if (mkId.isNotEmpty) {
                        await _loadModelsForMakeId(mkId);
                      } else {
                        _snack('makeId missing for selected make', 'error');
                        setState(() {
                          models = const ['OTHER'];
                          selectedModel = 'OTHER';
                          _modelIsOther = true;
                        });
                      }
                    },
              decoration: _dec(
                label: 'Make',
                hint: loadingMakes ? 'Loading makes…' : 'Select make',
                icon: Icons.directions_car_outlined,
              ),
              validator: (v) => v == null ? 'Make is required' : null,
            ),

            if (_makeIsOther) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: otherMakeCtrl,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                inputFormatters: [LengthLimitingTextInputFormatter(40), _upper],
                decoration: _dec(label: 'Other Make', hint: 'Enter make', icon: Icons.edit_outlined),
                validator: (v) => _alphaNumValidator(v, fieldName: 'Other Make', min: 2),
              ),
            ],

            const SizedBox(height: 12),

            // MODEL
            DropdownButtonFormField<String>(
              value: (selectedModel != null && models.contains(selectedModel)) ? selectedModel : null,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              items: models.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (selectedMake == null || loadingModels)
                  ? null
                  : (v) {
                      if (v == null) return;

                      if (v == 'OTHER') {
                        setState(() {
                          selectedModel = 'OTHER';
                          _modelIsOther = true;
                          otherModelCtrl.text = '';
                          modelCtrl.text = '';
                        });
                        return;
                      }

                      setState(() {
                        selectedModel = v.toUpperCase();
                        _modelIsOther = false;
                        otherModelCtrl.text = '';
                        modelCtrl.text = v.toUpperCase();
                      });
                    },
              decoration: _dec(
                label: 'Model',
                hint: selectedMake == null ? 'Select make first' : (loadingModels ? 'Loading models…' : 'Select model'),
                icon: Icons.car_repair_outlined,
              ),
              validator: (v) => v == null ? 'Model is required' : null,
            ),

            if (_modelIsOther) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: otherModelCtrl,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                inputFormatters: [LengthLimitingTextInputFormatter(40), _upper],
                decoration: _dec(label: 'Other Model', hint: 'Enter model', icon: Icons.edit_outlined),
                validator: (v) => _alphaNumValidator(v, fieldName: 'Other Model', min: 2),
              ),
            ],

            const SizedBox(height: 12),

            _dropWithOther(
              label: 'Grade / Variant',
              value: gradeVariantCtrl.text.isEmpty ? null : gradeVariantCtrl.text,
              options: _gradeVariantOptions,
              icon: Icons.badge_outlined,
              hint: 'Select grade / variant',
              otherCtrl: _otherCtrls['gradeVariant']!,
              validator: (v) => v == null ? 'Grade / Variant is required' : null,
              onChanged: (v) => setState(() => gradeVariantCtrl.text = v ?? ''),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: engineCapacityCtrl,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              inputFormatters: [LengthLimitingTextInputFormatter(12), _upper],
              decoration: _dec(label: 'Engine Capacity', hint: 'e.g. 2.0L', icon: Icons.speed_outlined),
              validator: (v) => _alphaNumValidator(v, fieldName: 'Engine Capacity', min: 1),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: modelYearCtrl,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              keyboardType: TextInputType.number,
              inputFormatters: _yearFormatters(),
              decoration: _dec(label: 'Model Year', hint: '2020', icon: Icons.calendar_today_outlined),
              validator: _yearValidator,
            ),

            const SizedBox(height: 12),

            _dropWithOther(
              label: 'Cylinder Size',
              value: cylinderSizeCtrl.text.isEmpty ? null : cylinderSizeCtrl.text,
              options: _cylinderSizeOptions,
              icon: Icons.settings_outlined,
              hint: 'Select cylinder size',
              otherCtrl: _otherCtrls['cylinderSize']!,
              validator: (v) => v == null ? 'Cylinder Size is required' : null,
              onChanged: (v) => setState(() => cylinderSizeCtrl.text = v ?? ''),
            ),

            const SizedBox(height: 12),

            _dropWithOther(
              label: 'Transmission',
              value: transmissionCtrl.text.isEmpty ? null : transmissionCtrl.text,
              options: _transmissionOptions,
              icon: Icons.swap_horiz_outlined,
              hint: 'Select transmission',
              otherCtrl: _otherCtrls['transmission']!,
              validator: (v) => v == null ? 'Transmission is required' : null,
              onChanged: (v) => setState(() => transmissionCtrl.text = v ?? ''),
            ),

            const SizedBox(height: 12),

            _dropWithOther(
              label: 'Fuel Type',
              value: fuelTypeCtrl.text.isEmpty ? null : fuelTypeCtrl.text,
              options: _fuelTypeOptions,
              icon: Icons.local_gas_station_outlined,
              hint: 'Select fuel type',
              otherCtrl: _otherCtrls['fuelType']!,
              validator: (v) => v == null ? 'Fuel Type is required' : null,
              onChanged: (v) => setState(() => fuelTypeCtrl.text = v ?? ''),
            ),

            const SizedBox(height: 12),

            _dropWithOther(
              label: 'Drive Train',
              value: driveTrainCtrl.text.isEmpty ? null : driveTrainCtrl.text,
              options: _driveTrainOptions,
              icon: Icons.grid_on_outlined,
              hint: 'Select drive train',
              otherCtrl: _otherCtrls['driveTrain']!,
              validator: (v) => v == null ? 'Drive Train is required' : null,
              onChanged: (v) => setState(() => driveTrainCtrl.text = v ?? ''),
            ),

            const SizedBox(height: 12),

            _dropField(
              label: 'Specs',
              value: specsCtrl.text.isEmpty ? null : specsCtrl.text,
              options: [..._specsOptions, 'OTHER'],
              icon: Icons.public_outlined,
              hint: 'Select specs',
              validator: (v) => v == null ? 'Specs is required' : null,
              onChanged: (v) {
                setState(() {
                  specsCtrl.text = v ?? '';
                  _specsIsOther = v == 'OTHER';
                  if (!_specsIsOther) specsOtherCtrl.clear();
                });
              },
            ),

            if (_specsIsOther) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: specsOtherCtrl,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                inputFormatters: [LengthLimitingTextInputFormatter(40), _upper],
                decoration: _dec(label: 'Other Specs', hint: 'ENTER SPECS', icon: Icons.edit_outlined),
                validator: (v) {
                  if (!_specsIsOther) return null;
                  if (v == null || v.trim().isEmpty) return 'Other specs is required';
                  return null;
                },
              ),
            ],

            const SizedBox(height: 12),

            TextFormField(
              controller: odometerCtrl,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              keyboardType: TextInputType.number,
              inputFormatters: _digitsFormatters(max: 10),
              decoration: _dec(label: 'Odometer Reading', hint: 'e.g. 156468', icon: Icons.av_timer_outlined),
              validator: (v) => _numberValidator(v, fieldName: 'Odometer Reading', max: 10),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: registrationNoCtrl,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              inputFormatters: [LengthLimitingTextInputFormatter(20), _upper],
              decoration: _dec(label: 'Registration Number', hint: 'e.g. ABC123', icon: Icons.confirmation_number_outlined),
              validator: (v) => _alphaNumValidator(v, fieldName: 'Registration Number', min: 3),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: emiratesRegAtCtrl,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              inputFormatters: [LengthLimitingTextInputFormatter(20), _upper],
              decoration: _dec(label: 'Emirates Registered At', hint: 'e.g. DUBAI', icon: Icons.location_city_outlined),
              validator: (v) => _alphaNumValidator(v, fieldName: 'Emirates Registered At', min: 2),
            ),

            const SizedBox(height: 12),

            // Chassis Number + mandatory photo in the same row
            FormField<String>(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (_) => (_chassisNoPhotoUrl ?? '').trim().isEmpty
                  ? 'Chassis photo is required'
                  : null,
              builder: (photoState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: chassisNoCtrl,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            inputFormatters: [LengthLimitingTextInputFormatter(20), _upper],
                            decoration: _dec(
                              label: 'Chassis Number',
                              hint: 'e.g. JTMBA3FV800123456',
                              icon: Icons.numbers_outlined,
                            ),
                            validator: (v) => _alphaNumValidator(v, fieldName: 'Chassis Number', min: 5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _chassisUploading
                              ? const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : OutlinedButton.icon(
                                  onPressed: () async {
                                    await _pickChassisPhoto();
                                    photoState.didChange(_chassisNoPhotoUrl);
                                  },
                                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                                  label: const Text('Photo'),
                                ),
                        ),
                      ],
                    ),
                    if (_chassisNoPhotoUrl != null) ...[
                      const SizedBox(height: 10),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _chassisNoPhotoUrl!,
                              width: 96,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                          Positioned(
                            right: -8,
                            top: -8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _chassisNoPhotoUrl = null);
                                photoState.didChange(null);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black12),
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(Icons.close, size: 16, color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (photoState.hasError) ...[
                      const SizedBox(height: 6),
                      Text(
                        photoState.errorText ?? '',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 12),

            _dropField(
              label: 'Ownership Type',
              value: ownershipTypeCtrl.text.isEmpty ? null : ownershipTypeCtrl.text,
              options: _ownershipTypeOptions,
              icon: Icons.person_outline,
              hint: 'Select ownership type',
              validator: (v) => v == null ? 'Ownership Type is required' : null,
              onChanged: (v) => setState(() => ownershipTypeCtrl.text = v ?? ''),
            ),
            ..._customFieldsForSection('vehicle_details'),
          ],
        ),
      ),
    );
  }

  Widget _serviceWarrantySection() {
    return _sectionCard(
      title: 'Service & Warranty Overview',
      icon: Icons.assignment_outlined,
      child: Form(
        key: _serviceFormKey,
        child: Column(
          children: [
            _dropField(
              label: 'Service History',
              value: serviceHistory,
              options: const ['Available', 'Not Available'],
              icon: Icons.history_outlined,
              hint: 'Select',
              validator: (v) => v == null ? 'Service History is required' : null,
              onChanged: (v) => setState(() => serviceHistory = v),
            ),
            const SizedBox(height: 12),
            _dropWithOther(
              label: 'Serviced With',
              value: servicedWithCtrl.text.isEmpty ? null : servicedWithCtrl.text,
              options: _servicedWithOptions,
              icon: Icons.build_outlined,
              hint: 'Select',
              otherCtrl: _otherCtrls['servicedWith']!,
              validator: (v) => v == null ? 'Serviced With is required' : null,
              onChanged: (v) => setState(() => servicedWithCtrl.text = v ?? ''),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: lastServiceDateCtrl,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              readOnly: true,
              onTap: _pickLastServiceDate,
              decoration: _dec(label: 'Last Service Date', hint: 'Select date', icon: Icons.date_range_outlined),
              validator: (v) => _req(v, msg: 'Last Service Date is required'),
            ),
            const SizedBox(height: 12),
            _dropField(
              label: 'Warranty Available',
              value: warrantyAvailable,
              options: const ['Yes', 'No'],
              icon: Icons.verified_outlined,
              hint: 'Select',
              validator: (v) => v == null ? 'Warranty Available is required' : null,
              onChanged: (v) => setState(() => warrantyAvailable = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: warrantyEndsInCtrl,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              readOnly: true,
              onTap: _pickWarrantyEndsMonthYear,
              decoration: _dec(label: 'Warranty Ends In (Month/Year)', hint: 'Select month', icon: Icons.event_outlined),
              validator: (v) => _req(v, msg: 'Warranty Ends In is required'),
            ),
            const SizedBox(height: 12),
            _dropField(
              label: 'Had Accidents',
              value: hadAccidents,
              options: const ['Yes', 'No'],
              icon: Icons.report_problem_outlined,
              hint: 'Select',
              validator: (v) => v == null ? 'Had Accidents is required' : null,
              onChanged: (v) => setState(() => hadAccidents = v),
            ),
            ..._customFieldsForSection('service_warranty'),
          ],
        ),
      ),
    );
  }

  Widget _interiorSection() {
    return _sectionCard(
      title: 'Interior Details',
      icon: Icons.chair_outlined,
      child: Form(
        key: _interiorFormKey,
        child: Column(
          children: [
            _dropWithOther(
              label: 'Seats',
              value: seatsCtrl.text.isEmpty ? null : seatsCtrl.text,
              options: _seatsOptions,
              icon: Icons.event_seat_outlined,
              hint: 'Select seats',
              otherCtrl: _otherCtrls['seats']!,
              validator: (v) => v == null ? 'Seats is required' : null,
              onChanged: (v) => setState(() => seatsCtrl.text = v ?? ''),
            ),
            const SizedBox(height: 12),
            _dropWithOther(
              label: 'Interior Color',
              value: interiorColorCtrl.text.isEmpty ? null : interiorColorCtrl.text,
              options: _interiorColorOptions,
              icon: Icons.palette_outlined,
              hint: 'Select color',
              otherCtrl: _otherCtrls['interiorColor']!,
              validator: (v) => v == null ? 'Interior Color is required' : null,
              onChanged: (v) => setState(() => interiorColorCtrl.text = v ?? ''),
            ),
            const SizedBox(height: 12),
            _dropWithOther(
              label: 'Upholstery',
              value: upholsteryCtrl.text.isEmpty ? null : upholsteryCtrl.text,
              options: _upholsteryOptions,
              icon: Icons.texture_outlined,
              hint: 'Select upholstery',
              otherCtrl: _otherCtrls['upholstery']!,
              validator: (v) => v == null ? 'Upholstery is required' : null,
              onChanged: (v) => setState(() => upholsteryCtrl.text = v ?? ''),
            ),
            const SizedBox(height: 12),
            _dropWithOther(
              label: 'Number of Keys',
              value: numberOfKeysCtrl.text.isEmpty ? null : numberOfKeysCtrl.text,
              options: _numberOfKeysOptions,
              icon: Icons.key_outlined,
              hint: 'Select keys count',
              otherCtrl: _otherCtrls['numberOfKeys']!,
              validator: (v) => v == null ? 'Number of Keys is required' : null,
              onChanged: (v) => setState(() => numberOfKeysCtrl.text = v ?? ''),
            ),
            const SizedBox(height: 12),
            _dropField(
              label: 'Modification Done',
              value: interiorModificationDone,
              options: const ['Yes', 'No'],
              icon: Icons.construction_outlined,
              hint: 'Select',
              validator: (v) => v == null ? 'Modification Done is required' : null,
              onChanged: (v) => setState(() => interiorModificationDone = v),
            ),
            ..._customFieldsForSection('interior_details'),
          ],
        ),
      ),
    );
  }

  Widget _exteriorSection() {
    return _sectionCard(
      title: 'Exterior Details',
      icon: Icons.directions_car_filled_outlined,
      child: Form(
        key: _exteriorFormKey,
        child: Column(
          children: [
            _dropWithOther(
              label: 'Exterior Color',
              value: exteriorColorCtrl.text.isEmpty ? null : exteriorColorCtrl.text,
              options: _exteriorColorOptions,
              icon: Icons.palette_outlined,
              hint: 'Select color',
              otherCtrl: _otherCtrls['exteriorColor']!,
              validator: (v) => v == null ? 'Exterior Color is required' : null,
              onChanged: (v) => setState(() => exteriorColorCtrl.text = v ?? ''),
            ),
            const SizedBox(height: 12),
            _dropWithOther(
              label: 'Doors',
              value: doorsCtrl.text.isEmpty ? null : doorsCtrl.text,
              options: _doorsOptions,
              icon: Icons.door_front_door_outlined,
              hint: 'Select doors',
              otherCtrl: _otherCtrls['doors']!,
              validator: (v) => v == null ? 'Doors is required' : null,
              onChanged: (v) => setState(() => doorsCtrl.text = v ?? ''),
            ),
            const SizedBox(height: 12),
            _dropField(
              label: 'Wheel Size',
              value: wheelSizeCtrl.text.isEmpty ? null : wheelSizeCtrl.text,
              options: [..._wheelSizeOptions, 'Other'],
              icon: Icons.circle_outlined,
              hint: 'Select wheel size',
              validator: (v) => v == null ? 'Wheel Size is required' : null,
              onChanged: (v) {
                setState(() {
                  wheelSizeCtrl.text = v ?? '';
                  _wheelSizeIsOther = v == 'Other';
                  if (!_wheelSizeIsOther) wheelSizeOtherCtrl.clear();
                });
              },
            ),
            if (_wheelSizeIsOther) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: wheelSizeOtherCtrl,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                inputFormatters: [LengthLimitingTextInputFormatter(20)],
                decoration: _dec(label: 'Wheel Size (specify)', hint: 'e.g. 24"', icon: Icons.edit_outlined),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please specify wheel size' : null,
              ),
            ],
            const SizedBox(height: 12),
            _dropField(
              label: 'Wheel Type',
              value: _wheelType,
              options: [..._wheelTypeOptions, 'Other'],
              icon: Icons.tire_repair_outlined,
              hint: 'Select wheel type',
              validator: (v) => v == null ? 'Wheel Type is required' : null,
              onChanged: (v) => setState(() => _wheelType = v),
            ),
            if (_wheelType == 'Other') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: wheelTypeOtherCtrl,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                inputFormatters: [LengthLimitingTextInputFormatter(40)],
                decoration: _dec(label: 'Wheel Type (specify)', hint: 'Enter wheel type', icon: Icons.edit_outlined),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please specify wheel type' : null,
              ),
            ],
            const SizedBox(height: 12),
            _dropField(
              label: 'Modification Done',
              value: exteriorModificationDone,
              options: const ['Yes', 'No'],
              icon: Icons.construction_outlined,
              hint: 'Select',
              validator: (v) => v == null ? 'Modification Done is required' : null,
              onChanged: (v) => setState(() => exteriorModificationDone = v),
            ),
            ..._customFieldsForSection('exterior_details'),
          ],
        ),
      ),
    );
  }

  Widget _damagedCoordinatesSection() {
    return _sectionCard(
      title: 'Damaged Coordinates',
      icon: Icons.place_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tap on the car to add a damage point. A popup will open to add description and photos.',
            style: TextStyle(
              color: Colors.black.withOpacity(0.55),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          DamageMarkerEditor(
            imageAsset: _carTopImageAsset,
            inspectionRequestId: widget.requestId,
            markers: _damagedCoordinates,
            onChanged: (next) => setState(() => _damagedCoordinates = next),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _damagedCoordinates.isEmpty ? null : () => setState(() => _damagedCoordinates = []),
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checklistTypeSection(ChecklistTemplate selected, int ti) {
    final type = selected.types[ti];

    return _sectionCard(
      title: type.typeName,
      icon: Icons.fact_check_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (type.allowOverallRemarks)
            TextField(
              controller: _overallRemarks[ti],
              maxLines: 2,
              inputFormatters: [LengthLimitingTextInputFormatter(200), _upper],
              decoration: _dec(label: 'Overall Remarks', hint: 'Write overall remarks', icon: Icons.notes_outlined),
            ),

          if (type.allowOverallPhotos) ...[
            const SizedBox(height: 12),
            MediaUploader(
              title: 'Overall Media',
              initialPhotos: _overallPhotos[ti] ?? const [],
              initialVideos: _overallVideos[ti] ?? const [],
              onPhotosChanged: (v) => setState(() => _overallPhotos[ti] = v),
              onVideosChanged: (v) => setState(() => _overallVideos[ti] = v),
              uploadPhoto: ({
                required Uint8List bytes,
                required String contentType,
                required String fileName,
              }) {
                return inspectionRequestsService.uploadInspectionMedia(
                  inspectionRequestId: widget.requestId,
                  typeName: type.typeName,
                  bytes: bytes,
                  fileName: fileName,
                  contentType: contentType,
                  mediaType: 'photos',
                );
              },
              uploadVideo: ({
                required Uint8List bytes,
                required String contentType,
                required String fileName,
              }) {
                return inspectionRequestsService.uploadInspectionMedia(
                  inspectionRequestId: widget.requestId,
                  typeName: type.typeName,
                  bytes: bytes,
                  fileName: fileName,
                  contentType: contentType,
                  mediaType: 'videos',
                );
              },
            ),
          ],

          const SizedBox(height: 16),

          ...List.generate(type.checklistItems.length, (ii) {
            final item = type.checklistItems[ii];
            final key = '$ti:$ii';
            final required = item.isRequired;
            final urls = _itemPhotos[key] ?? const <String>[];

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black.withOpacity(0.07)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.position}. ${item.label}${required ? ' *' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      if ((item.description ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(item.description!, style: const TextStyle(color: Colors.black54)),
                      ],
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: (_grade[key] != null && _gradeOptions.contains(_grade[key])) ? _grade[key] : null,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        items: _gradeOptions.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                        onChanged: (v) => setState(() => _grade[key] = v),
                        decoration: _dec(
                          label: required ? 'Condition *' : 'Condition',
                          hint: 'Select condition',
                          icon: Icons.grade_outlined,
                        ),
                      ),

                      const SizedBox(height: 12),
                      ImageUploader(
                        typeName: type.typeName,
                        inspectionRequestId: widget.requestId,
                        title: 'Photos',
                        initialImages: urls,
                        onChanged: (v) => setState(() => _itemPhotos[key] = v),
                        enabled: true,
                        mediaType: 'photos',
                      ),

                      const SizedBox(height: 12),
                      TextField(
                        controller: _remarks[key],
                        maxLines: 2,
                        inputFormatters: [LengthLimitingTextInputFormatter(200), _upper],
                        decoration: _dec(label: 'Remarks', hint: 'Write remarks', icon: Icons.comment_outlined),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCurrentSection(ChecklistTemplate selected) {
    if (_section == 0) return _vehicleDetailsSection();
    if (_section == 1) return _serviceWarrantySection();
    if (_section == 2) return _interiorSection();
    if (_section == 3) return _exteriorSection();

    final damageIndex = 4 + selected.types.length;
    if (_section == damageIndex) return _damagedCoordinatesSection();

    final ti = _section - 4;
    return _checklistTypeSection(selected, ti);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Start Inspection',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: FutureBuilder<List<ChecklistTemplate>>(
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
                  child: Text('Failed to load template: ${snap.error}'),
                );
              }

              final templates = snap.data ?? [];
              if (templates.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('No active checklist templates found.'),
                );
              }

              final selected = _selectedTemplate ?? templates.first;
              final total = _totalSections(selected);

              if (_section >= total) _section = total - 1;

              final title = _sectionTitle(selected, _section);
              final progress = total == 0 ? 0.0 : (_section + 1) / total;

              return ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Start Inspection',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (_startingInspection)
                        const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (_startError != null)
                        TextButton.icon(
                          onPressed: _bootstrapStartInspection,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (templates.length > 1)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Text('Checklist Template:', style: TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<ChecklistTemplate>(
                                  value: selected,
                                  isExpanded: true,
                                  items: templates.map((t) => DropdownMenuItem(value: t, child: Text(t.name ?? t.id))).toList(),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() {
                                      _selectedTemplate = v;
                                      _primeChecklistControllers();
                                      _section = 0;
                                      _progressApplied = false; // allow apply if draft exists
                                    });
                                    _applyProgressIfReady();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
                              Text(
                                'Section ${_section + 1} / $total',
                                style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(value: progress),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  _buildCurrentSection(selected),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _section == 0 ? null : _back,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isLastSection(selected)
                            ? FilledButton.icon(
                                onPressed: (_submitting || _savingDraft) ? null : _submit,
                                icon: _submitting
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.check),
                                label: Text(_submitting ? 'Submitting...' : 'Submit'),
                              )
                            : FilledButton.icon(
                                onPressed: (_savingDraft || _startingInspection) ? null : () => _next(selected),
                                icon: _savingDraft
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.arrow_forward),
                                label: Text(_savingDraft ? 'Saving...' : 'Next'),
                              ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================
  // SUBMIT (same as before)
  // ============================
  bool _validateChecklistAll() {
    final t = _selectedTemplate;
    if (t == null) {
      _snack('No active checklist template found', 'error');
      return false;
    }

    for (var ti = 0; ti < t.types.length; ti++) {
      final type = t.types[ti];
      for (var ii = 0; ii < type.checklistItems.length; ii++) {
        final item = type.checklistItems[ii];
        if (!item.isRequired) continue;

        final key = '$ti:$ii';
        final g = _grade[key];
        if (g == null || g.trim().isEmpty) {
          _snack('Please select: ${type.typeName} → ${item.label}', 'warning');
          return false;
        }
      }
    }
    return true;
  }

  Map<String, dynamic> _buildReportPayload() {
    final vehicleDetails = <String, dynamic>{
      'make': makeCtrl.text.trim(),
      'model': modelCtrl.text.trim(),
      'gradeVariant': _resolveCtrl(gradeVariantCtrl, 'gradeVariant'),
      'engineCapacity': engineCapacityCtrl.text.trim(),
      'modelYear': modelYearCtrl.text.trim(),
      'cylinderSize': _resolveCtrl(cylinderSizeCtrl, 'cylinderSize'),
      'transmission': _resolveCtrl(transmissionCtrl, 'transmission'),
      'fuelType': _resolveCtrl(fuelTypeCtrl, 'fuelType'),
      'driveTrain': _resolveCtrl(driveTrainCtrl, 'driveTrain'),
      'specs': _specsIsOther ? specsOtherCtrl.text.trim() : specsCtrl.text.trim(),
      'odometerReading': odometerCtrl.text.trim(),
      'registrationNo': registrationNoCtrl.text.trim(),
      'emiratesRegAt': emiratesRegAtCtrl.text.trim(),
      'chassisNo': chassisNoCtrl.text.trim(),
      'chassisPhotoUrl': _chassisNoPhotoUrl ?? '',
      'ownershipType': ownershipTypeCtrl.text.trim(),
    };
    for (final f in _customFields.where((f) => f.section == 'vehicle_details')) {
      vehicleDetails[f.payloadKey] = _resolveCustomField(f);
    }

    final serviceWarranty = <String, dynamic>{
      'serviceHistory': serviceHistory,
      'servicedWith': _resolveCtrl(servicedWithCtrl, 'servicedWith'),
      'lastServiceDate': lastServiceDateCtrl.text.trim(),
      'warrantyAvailable': warrantyAvailable,
      'warrantyEndsIn': warrantyEndsInCtrl.text.trim(),
      'hadAccidents': hadAccidents,
    };
    for (final f in _customFields.where((f) => f.section == 'service_warranty')) {
      serviceWarranty[f.payloadKey] = _resolveCustomField(f);
    }

    final interiorDetails = <String, dynamic>{
      'seats': _resolveCtrl(seatsCtrl, 'seats'),
      'interiorColor': _resolveCtrl(interiorColorCtrl, 'interiorColor'),
      'upholstery': _resolveCtrl(upholsteryCtrl, 'upholstery'),
      'numberOfKeys': _resolveCtrl(numberOfKeysCtrl, 'numberOfKeys'),
      'modificationDone': interiorModificationDone,
    };
    for (final f in _customFields.where((f) => f.section == 'interior_details')) {
      interiorDetails[f.payloadKey] = _resolveCustomField(f);
    }

    final exteriorDetails = <String, dynamic>{
      'exteriorColor': _resolveCtrl(exteriorColorCtrl, 'exteriorColor'),
      'doors': _resolveCtrl(doorsCtrl, 'doors'),
      'wheelSize': _wheelSizeIsOther ? wheelSizeOtherCtrl.text.trim() : wheelSizeCtrl.text.trim(),
      'wheelType': _wheelType == 'Other' ? wheelTypeOtherCtrl.text.trim() : (_wheelType ?? ''),
      'modificationDone': exteriorModificationDone,
    };
    for (final f in _customFields.where((f) => f.section == 'exterior_details')) {
      exteriorDetails[f.payloadKey] = _resolveCustomField(f);
    }

    return {
      'vehicleDetails': vehicleDetails,
      'serviceWarrantyOverview': serviceWarranty,
      'interiorDetails': interiorDetails,
      'exteriorDetails': exteriorDetails,
    };
  }

  List<Map<String, dynamic>> _buildTypesPayload() {
    final t = _selectedTemplate!;
    final out = <Map<String, dynamic>>[];

    for (var ti = 0; ti < t.types.length; ti++) {
      final type = t.types[ti];
      final items = <Map<String, dynamic>>[];

      for (var ii = 0; ii < type.checklistItems.length; ii++) {
        final item = type.checklistItems[ii];
        final key = '$ti:$ii';

        final g = _grade[key];
        final rating = _gradeToRating(g);
        final status = _gradeToStatus(g);

        final remarksText = _remarks[key]!.text.trim();

        items.add({
          'position': item.position,
          'label': item.label,
          'status': status,
          'rating': rating,
          'remarks': remarksText.isEmpty ? '' : remarksText,
          'photos': _itemPhotos[key] ?? [],
        });
      }

      final overallRemarksText = type.allowOverallRemarks ? _overallRemarks[ti]?.text.trim() : null;

      out.add({
        'typeName': type.typeName,
        'checklistItems': items,
        'overallRemarks': (overallRemarksText != null && overallRemarksText.isNotEmpty) ? overallRemarksText : '',
        'overallPhotos': _overallPhotos[ti] ?? [],
        'videos': _overallVideos[ti] ?? [],
      });
    }

    return out;
  }

  Future<void> _submit() async {
    if (_submitting) return;

    if (!_applyMakeModelToControllersNoNetwork()) return;
    if (!_validateChecklistAll()) return;

    if ((_chassisNoPhotoUrl ?? '').trim().isEmpty) {
      _snack('Please upload chassis number photo', 'warning');
      return;
    }

    setState(() => _submitting = true);

    try {
      final makeName = _makeIsOther ? otherMakeCtrl.text.trim().toUpperCase() : (selectedMake ?? '').trim().toUpperCase();

      final modelName = _modelIsOther ? otherModelCtrl.text.trim().toUpperCase() : (selectedModel ?? '').trim().toUpperCase();

      String? makeId = selectedMakeId;

      if (_makeIsOther) {
        final createdId = await inspectionRequestsService.addVehicleMake(makeName);
        if (createdId != null && createdId.trim().isNotEmpty) {
          makeId = createdId.trim();
        } else {
          await _loadMakes();
          makeId = _makeIdByName[makeName];
        }
      }

      if (_modelIsOther) {
        if (makeId == null || makeId.trim().isEmpty) {
          throw Exception('makeId missing for adding model');
        }
        await inspectionRequestsService.addVehicleModel(
          makeId: makeId.trim(),
          name: modelName,
        );
      }

      makeCtrl.text = makeName;
      modelCtrl.text = modelName;

      final t = _selectedTemplate!;

      final payload = {
        'checklistTemplateId': t.id,
        'inspectionRequestId': widget.requestId,
        'inspectionDate': DateTime.now().toIso8601String(),
        'status': 'draft',
        ..._buildReportPayload(),
        'damaged_coordinates': _buildDamagedCoordinatesPayload(),
        'types': _buildTypesPayload(),
      };

      await inspectionRequestsService.submitInspection(payload);

      if (!mounted) return;
      _snack('Inspection submitted successfully', 'success');

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/dashboard/inspector');
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Submit failed: $e', 'error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}