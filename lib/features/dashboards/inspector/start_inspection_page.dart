import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../models/checklist_template.dart';
import '../../../services/service_locator.dart';
import '../../shared/app_shell.dart';
import '../../shared/top_snackbar.dart';
import '../../shared/widgets/image_uploader.dart';
import '../../shared/widgets/media_uploader.dart';

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

  static const List<String> _transmissionOptions = [
    'Automatic',
    'Manual',
  ];

  static const List<String> _fuelTypeOptions = [
    'Petrol',
    'Diesel',
    'Hybrid',
    'Electric',
  ];

  static const List<String> _gradeVariantOptions = ['XLE', 'LIMITED'];
  static const List<String> _cylinderSizeOptions = ['3', '4', '6', '8'];
  static const List<String> _driveTrainOptions = ['FWD', 'RWD', '4X4'];
  static const List<String> _specsOptions = [
    'GCC',
    'AMERICAN',
    'EUROPEAN',
    'JAPANESE',
    'KOREAN',
    'CANADIAN',
    'AUSTRALIAN',
    'CHINESE',
    'OTHER',
  ];
  static const List<String> _wheelSizeOptions = [
    '14"', '15"', '16"', '17"', '18"', '19"', '20"', '21"', '22"', '23"', 'Other',
  ];
  static const List<String> _wheelTypeOptions = [
    'Alloy Wheel',
    'Steel Wheel',
    'Other',
  ];
  static const List<String> _ownershipTypeOptions = ['INDIVIDUAL', 'COMPANY'];
  static const List<String> _servicedWithOptions = ['AGENCY', 'THIRD PARTY'];
  static const List<String> _seatsOptions = ['2', '4', '5', '6', '7', '8', '9'];
  static const List<String> _colorOptions = [
    'WHITE',
    'BLACK',
    'GRAY / GREY',
    'SILVER',
    'BLUE',
    'RED',
    'BEIGE / TAN',
    'BROWN / CHOCOLATE',
    'GOLD',
    'GREEN',
    'ORANGE',
    'PURPLE / VIOLET',
    'MAROON / BURGUNDY',
    'YELLOW',
    'PINK',
  ];
  static const List<String> _upholsteryOptions = ['LEATHER', 'FABRIC'];
  static const List<String> _numberOfKeysOptions = ['1', '2', '3', '4', '5'];
  static const List<String> _doorsOptions = ['2', '3', '4', '5'];

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

    super.dispose();
  }

  void _snack(String msg, String variant) {
    showTopSnack(context, msg, variant: variant);
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
        engineCapacityCtrl.text = (d['engineCapacity'] ?? engineCapacityCtrl.text).toString().trim();
        modelYearCtrl.text = (d['modelYear'] ?? modelYearCtrl.text).toString().trim();
        cylinderSizeCtrl.text = (d['cylinderSize'] ?? cylinderSizeCtrl.text).toString().trim();
        transmissionCtrl.text = (d['transmission'] ?? transmissionCtrl.text).toString().trim();
        fuelTypeCtrl.text = (d['fuelType'] ?? fuelTypeCtrl.text).toString().trim();
        driveTrainCtrl.text = (d['driveTrain'] ?? driveTrainCtrl.text).toString().trim();
        specsCtrl.text = (d['specs'] ?? specsCtrl.text).toString().trim();
        // Migrate old 'US SPECS' to renamed 'AMERICAN'
        if (specsCtrl.text == 'US SPECS') specsCtrl.text = 'AMERICAN';
        specsOtherCtrl.text = (d['specsOther'] ?? specsOtherCtrl.text).toString().trim();
        _specsIsOther = specsCtrl.text == 'OTHER';
        odometerCtrl.text = (d['odometerReading'] ?? odometerCtrl.text).toString().trim();
        registrationNoCtrl.text = (d['registrationNo'] ?? registrationNoCtrl.text).toString().trim();
        emiratesRegAtCtrl.text = (d['emiratesRegAt'] ?? emiratesRegAtCtrl.text).toString().trim();

        // ✅ chassisNo restored (URL expected)
        final rawChassis = (d['chassisNo'] ?? '').toString().trim();
        chassisNoCtrl.text = rawChassis;
        _chassisNoPhotoUrl = _isHttpUrl(rawChassis) ? rawChassis : null;

        ownershipTypeCtrl.text = (d['ownershipType'] ?? ownershipTypeCtrl.text).toString().trim();
        break;

      case 'service_warranty_overview':
        serviceHistory = (d['serviceHistory'] ?? serviceHistory)?.toString();
        servicedWithCtrl.text = (d['servicedWith'] ?? servicedWithCtrl.text).toString().trim();
        lastServiceDateCtrl.text = (d['lastServiceDate'] ?? lastServiceDateCtrl.text).toString().trim();
        warrantyAvailable = (d['warrantyAvailable'] ?? warrantyAvailable)?.toString();
        warrantyEndsInCtrl.text = (d['warrantyEndsIn'] ?? warrantyEndsInCtrl.text).toString().trim();
        hadAccidents = (d['hadAccidents'] ?? hadAccidents)?.toString();
        break;

      case 'interior_details':
        seatsCtrl.text = (d['seats'] ?? seatsCtrl.text).toString().trim();
        interiorColorCtrl.text = (d['interiorColor'] ?? interiorColorCtrl.text).toString().trim();
        upholsteryCtrl.text = (d['upholstery'] ?? upholsteryCtrl.text).toString().trim();
        numberOfKeysCtrl.text = (d['numberOfKeys'] ?? numberOfKeysCtrl.text).toString().trim();
        interiorModificationDone = (d['modificationDone'] ?? interiorModificationDone)?.toString();
        break;

      case 'exterior_details':
        exteriorColorCtrl.text = (d['exteriorColor'] ?? exteriorColorCtrl.text).toString().trim();
        doorsCtrl.text = (d['doors'] ?? doorsCtrl.text).toString().trim();
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
      return {
        'make': makeCtrl.text.trim(),
        'model': modelCtrl.text.trim(),
        'gradeVariant': gradeVariantCtrl.text.trim(),
        'engineCapacity': engineCapacityCtrl.text.trim(),
        'modelYear': modelYearCtrl.text.trim(),
        'cylinderSize': cylinderSizeCtrl.text.trim(),
        'transmission': transmissionCtrl.text.trim(),
        'fuelType': fuelTypeCtrl.text.trim(),
        'driveTrain': driveTrainCtrl.text.trim(),
        'specs': specsCtrl.text.trim(),
        'specsOther': _specsIsOther ? specsOtherCtrl.text.trim() : '',
        'odometerReading': odometerCtrl.text.trim(),
        'registrationNo': registrationNoCtrl.text.trim(),
        'emiratesRegAt': emiratesRegAtCtrl.text.trim(),

        // ✅ chassisNo now holds the uploaded photo URL
        'chassisNo': chassisNoCtrl.text.trim(),

        'ownershipType': ownershipTypeCtrl.text.trim(),
      };
    }

    if (index == 1) {
      return {
        'serviceHistory': serviceHistory,
        'servicedWith': servicedWithCtrl.text.trim(),
        'lastServiceDate': lastServiceDateCtrl.text.trim(),
        'warrantyAvailable': warrantyAvailable,
        'warrantyEndsIn': warrantyEndsInCtrl.text.trim(),
        'hadAccidents': hadAccidents,
      };
    }

    if (index == 2) {
      return {
        'seats': seatsCtrl.text.trim(),
        'interiorColor': interiorColorCtrl.text.trim(),
        'upholstery': upholsteryCtrl.text.trim(),
        'numberOfKeys': numberOfKeysCtrl.text.trim(),
        'modificationDone': interiorModificationDone,
      };
    }

    if (index == 3) {
      return {
        'exteriorColor': exteriorColorCtrl.text.trim(),
        'doors': doorsCtrl.text.trim(),
        'wheelSize': wheelSizeCtrl.text.trim(),
        'wheelSizeOther': _wheelSizeIsOther ? wheelSizeOtherCtrl.text.trim() : '',
        'wheelType': _wheelType == 'Other' ? wheelTypeOtherCtrl.text.trim() : (_wheelType ?? ''),
        'modificationDone': exteriorModificationDone,
      };
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

            _dropField(
              label: 'Grade / Variant',
              value: gradeVariantCtrl.text.isEmpty ? null : gradeVariantCtrl.text,
              options: _gradeVariantOptions,
              icon: Icons.badge_outlined,
              hint: 'Select grade / variant',
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

            _dropField(
              label: 'Cylinder Size',
              value: cylinderSizeCtrl.text.isEmpty ? null : cylinderSizeCtrl.text,
              options: _cylinderSizeOptions,
              icon: Icons.settings_outlined,
              hint: 'Select cylinder size',
              validator: (v) => v == null ? 'Cylinder Size is required' : null,
              onChanged: (v) => setState(() => cylinderSizeCtrl.text = v ?? ''),
            ),

            const SizedBox(height: 12),

            _dropField(
              label: 'Transmission',
              value: transmissionCtrl.text.isEmpty ? null : transmissionCtrl.text,
              options: _transmissionOptions,
              icon: Icons.swap_horiz_outlined,
              hint: 'Select transmission',
              validator: (v) => v == null ? 'Transmission is required' : null,
              onChanged: (v) => setState(() => transmissionCtrl.text = v ?? ''),
            ),

            const SizedBox(height: 12),

            _dropField(
              label: 'Fuel Type',
              value: fuelTypeCtrl.text.isEmpty ? null : fuelTypeCtrl.text,
              options: _fuelTypeOptions,
              icon: Icons.local_gas_station_outlined,
              hint: 'Select fuel type',
              validator: (v) => v == null ? 'Fuel Type is required' : null,
              onChanged: (v) => setState(() => fuelTypeCtrl.text = v ?? ''),
            ),

            const SizedBox(height: 12),

            _dropField(
              label: 'Drive Train',
              value: driveTrainCtrl.text.isEmpty ? null : driveTrainCtrl.text,
              options: _driveTrainOptions,
              icon: Icons.grid_on_outlined,
              hint: 'Select drive train',
              validator: (v) => v == null ? 'Drive Train is required' : null,
              onChanged: (v) => setState(() => driveTrainCtrl.text = v ?? ''),
            ),

            const SizedBox(height: 12),

            _dropField(
              label: 'Specs',
              value: specsCtrl.text.isEmpty ? null : specsCtrl.text,
              options: _specsOptions,
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

            // ✅ CHASSIS PHOTO FIELD (single image -> URL stored into chassisNoCtrl)
            FormField<String>(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (_) {
                if ((_chassisNoPhotoUrl ?? '').trim().isEmpty) {
                  return 'Chassis photo is required';
                }
                return null;
              },
              builder: (state) {
                final has = (_chassisNoPhotoUrl ?? '').trim().isNotEmpty;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.numbers_outlined, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Chassis Number (Photo)',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        if (has)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _chassisNoPhotoUrl = null;
                                chassisNoCtrl.text = '';
                              });
                              state.didChange('');
                            },
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Remove'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ImageUploader(
                      typeName: 'vehicle_details',
                      inspectionRequestId: widget.requestId,
                      title: 'Upload / Capture',
                      initialImages: has ? [_chassisNoPhotoUrl!] : const [],
                      onChanged: (urls) {
                        final next = urls.isEmpty ? '' : urls.last; // keep last => single
                        setState(() {
                          _chassisNoPhotoUrl = next.isEmpty ? null : next;
                          chassisNoCtrl.text = next; // ✅ keeps existing API key working
                        });
                        state.didChange(next);
                      },
                      enabled: true,
                      mediaType: 'photos',
                    ),
                    if (state.hasError) ...[
                      const SizedBox(height: 8),
                      Text(
                        state.errorText ?? '',
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
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
            _dropField(
              label: 'Serviced With',
              value: servicedWithCtrl.text.isEmpty ? null : servicedWithCtrl.text,
              options: _servicedWithOptions,
              icon: Icons.build_outlined,
              hint: 'Select',
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
            _dropField(
              label: 'Seats',
              value: seatsCtrl.text.isEmpty ? null : seatsCtrl.text,
              options: _seatsOptions,
              icon: Icons.event_seat_outlined,
              hint: 'Select seats',
              validator: (v) => v == null ? 'Seats is required' : null,
              onChanged: (v) => setState(() => seatsCtrl.text = v ?? ''),
            ),
            const SizedBox(height: 12),
            _dropField(
              label: 'Interior Color',
              value: interiorColorCtrl.text.isEmpty ? null : interiorColorCtrl.text,
              options: _colorOptions,
              icon: Icons.palette_outlined,
              hint: 'Select color',
              validator: (v) => v == null ? 'Interior Color is required' : null,
              onChanged: (v) => setState(() => interiorColorCtrl.text = v ?? ''),
            ),
            const SizedBox(height: 12),
            _dropField(
              label: 'Upholstery',
              value: upholsteryCtrl.text.isEmpty ? null : upholsteryCtrl.text,
              options: _upholsteryOptions,
              icon: Icons.texture_outlined,
              hint: 'Select upholstery',
              validator: (v) => v == null ? 'Upholstery is required' : null,
              onChanged: (v) => setState(() => upholsteryCtrl.text = v ?? ''),
            ),
            const SizedBox(height: 12),
            _dropField(
              label: 'Number of Keys',
              value: numberOfKeysCtrl.text.isEmpty ? null : numberOfKeysCtrl.text,
              options: _numberOfKeysOptions,
              icon: Icons.key_outlined,
              hint: 'Select keys count',
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
            _dropField(
              label: 'Exterior Color',
              value: exteriorColorCtrl.text.isEmpty ? null : exteriorColorCtrl.text,
              options: _colorOptions,
              icon: Icons.palette_outlined,
              hint: 'Select color',
              validator: (v) => v == null ? 'Exterior Color is required' : null,
              onChanged: (v) => setState(() => exteriorColorCtrl.text = v ?? ''),
            ),
            const SizedBox(height: 12),
            _dropField(
              label: 'Doors',
              value: doorsCtrl.text.isEmpty ? null : doorsCtrl.text,
              options: _doorsOptions,
              icon: Icons.door_front_door_outlined,
              hint: 'Select doors',
              validator: (v) => v == null ? 'Doors is required' : null,
              onChanged: (v) => setState(() => doorsCtrl.text = v ?? ''),
            ),
            const SizedBox(height: 12),
            _dropField(
              label: 'Wheel Size',
              value: wheelSizeCtrl.text.isEmpty ? null : wheelSizeCtrl.text,
              options: _wheelSizeOptions,
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
              options: _wheelTypeOptions,
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
    return {
      'vehicleDetails': {
        'make': makeCtrl.text.trim(),
        'model': modelCtrl.text.trim(),
        'gradeVariant': gradeVariantCtrl.text.trim(),
        'engineCapacity': engineCapacityCtrl.text.trim(),
        'modelYear': modelYearCtrl.text.trim(),
        'cylinderSize': cylinderSizeCtrl.text.trim(),
        'transmission': transmissionCtrl.text.trim(),
        'fuelType': fuelTypeCtrl.text.trim(),
        'driveTrain': driveTrainCtrl.text.trim(),
        'specs': _specsIsOther ? specsOtherCtrl.text.trim() : specsCtrl.text.trim(),
        'odometerReading': odometerCtrl.text.trim(),
        'registrationNo': registrationNoCtrl.text.trim(),
        'emiratesRegAt': emiratesRegAtCtrl.text.trim(),

        // ✅ still chassisNo key, but value is URL of chassis photo
        'chassisNo': chassisNoCtrl.text.trim(),

        'ownershipType': ownershipTypeCtrl.text.trim(),
      },
      'serviceWarrantyOverview': {
        'serviceHistory': serviceHistory,
        'servicedWith': servicedWithCtrl.text.trim(),
        'lastServiceDate': lastServiceDateCtrl.text.trim(),
        'warrantyAvailable': warrantyAvailable,
        'warrantyEndsIn': warrantyEndsInCtrl.text.trim(),
        'hadAccidents': hadAccidents,
      },
      'interiorDetails': {
        'seats': seatsCtrl.text.trim(),
        'interiorColor': interiorColorCtrl.text.trim(),
        'upholstery': upholsteryCtrl.text.trim(),
        'numberOfKeys': numberOfKeysCtrl.text.trim(),
        'modificationDone': interiorModificationDone,
      },
      'exteriorDetails': {
        'exteriorColor': exteriorColorCtrl.text.trim(),
        'doors': doorsCtrl.text.trim(),
        'wheelSize': _wheelSizeIsOther ? wheelSizeOtherCtrl.text.trim() : wheelSizeCtrl.text.trim(),
        'wheelType': _wheelType == 'Other' ? wheelTypeOtherCtrl.text.trim() : (_wheelType ?? ''),
        'modificationDone': exteriorModificationDone,
      },
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

    // ✅ Ensure chassis photo exists before submit
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