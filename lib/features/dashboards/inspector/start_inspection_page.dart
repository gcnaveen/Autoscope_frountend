// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'
//     show rootBundle, FilteringTextInputFormatter, LengthLimitingTextInputFormatter, TextInputFormatter;
// import 'package:go_router/go_router.dart';

// import '../../../models/checklist_template.dart';
// import '../../../services/service_locator.dart';
// import '../../shared/app_shell.dart';
// import '../../shared/top_snackbar.dart';
// import '../../shared/widgets/image_uploader.dart';
// import '../../shared/widgets/video_uploader.dart';

// // ✅ NEW
// import 'widgets/damage_marker_editor.dart';

// class StartInspectionPage extends StatefulWidget {
//   final String requestId; // inspection-request _id
//   const StartInspectionPage({super.key, required this.requestId});

//   @override
//   State<StartInspectionPage> createState() => _StartInspectionPageState();
// }

// class _StartInspectionPageState extends State<StartInspectionPage> {
//   late Future<List<ChecklistTemplate>> _future;
//   ChecklistTemplate? _selectedTemplate;

//   // Wizard section index:
//   // 0 Vehicle Details
//   // 1 Service & Warranty
//   // 2 Interior Details
//   // 3 Exterior Details
//   // 4 Damaged Coordinates ✅ NEW
//   // 5.. (Checklist types)
//   int _section = 0;

//   // ✅ Start inspection API state
//   bool _startingInspection = false;
//   bool _inspectionStarted = false;
//   String? _startError;

//   bool _submitting = false;

//   final _scrollCtrl = ScrollController();

//   // ============================
//   // FORM KEYS
//   // ============================
//   final _vehicleFormKey = GlobalKey<FormState>();
//   final _serviceFormKey = GlobalKey<FormState>();
//   final _interiorFormKey = GlobalKey<FormState>();
//   final _exteriorFormKey = GlobalKey<FormState>();

//   // ============================
//   // REPORT INPUT CONTROLLERS
//   // ============================

//   // Vehicle Details
//   final makeCtrl = TextEditingController();
//   final modelCtrl = TextEditingController();
//   final gradeVariantCtrl = TextEditingController();
//   final engineCapacityCtrl = TextEditingController();
//   final modelYearCtrl = TextEditingController();
//   final cylinderSizeCtrl = TextEditingController();
//   final transmissionCtrl = TextEditingController();
//   final fuelTypeCtrl = TextEditingController();
//   final driveTrainCtrl = TextEditingController();
//   final specsCtrl = TextEditingController();
//   final odometerCtrl = TextEditingController();
//   final registrationNoCtrl = TextEditingController();
//   final emiratesRegAtCtrl = TextEditingController();
//   final chassisNoCtrl = TextEditingController();
//   final ownershipTypeCtrl = TextEditingController();

//   // Service & Warranty Overview
//   String? serviceHistory; // Available / Not Available
//   final servicedWithCtrl = TextEditingController(); // Agency / Third party
//   final lastServiceDateCtrl = TextEditingController(); // yyyy-mm-dd (picked)
//   String? warrantyAvailable; // Yes/No
//   final warrantyEndsInCtrl = TextEditingController(); // MMM-yy (picked)
//   String? hadAccidents; // Yes/No

//   // Interior Details
//   final seatsCtrl = TextEditingController();
//   final interiorColorCtrl = TextEditingController();
//   final upholsteryCtrl = TextEditingController();
//   final numberOfKeysCtrl = TextEditingController();
//   String? interiorModificationDone; // Yes/No

//   // Exterior Details
//   final exteriorColorCtrl = TextEditingController();
//   final doorsCtrl = TextEditingController();
//   final wheelSizeCtrl = TextEditingController();
//   String? exteriorModificationDone; // Yes/No

//   // ============================
//   // ✅ DAMAGED COORDINATES (NEW)
//   // ============================
//   // Put your image here (and add to pubspec.yaml assets)
//   static const String _carTopImageAsset = 'assets/images/car_views/top.jpg';
//   List<DamageCoordinate> _damagedCoordinates = [];

//   Map<String, dynamic> _buildDamagedCoordinatesPayload() {
//     return {
//       'data': _damagedCoordinates.map((d) => d.toApiJson()).toList(),
//     };
//   }

//   // ============================
//   // ✅ Make/Model dropdown like RequestPage (LOCAL JSON)
//   // ============================
//   bool loadingMakes = false;
//   bool loadingModels = false;
//   final Map<String, List<String>> _catalog = {};
//   List<String> makes = [];
//   List<String> models = [];
//   String? selectedMake;
//   String? selectedModel;

//   Future<void> _loadCatalogFromAsset() async {
//     setState(() {
//       loadingMakes = true;
//       loadingModels = false;
//     });

//     try {
//       final raw = await rootBundle.loadString('assets/data/vehicle_catalog_uae.json');
//       final data = jsonDecode(raw) as Map<String, dynamic>;
//       final list = (data['makes'] as List).cast<Map<String, dynamic>>();

//       _catalog.clear();
//       for (final item in list) {
//         final name = (item['name'] ?? '').toString().trim();
//         final m = (item['models'] as List).map((e) => e.toString().trim()).where((x) => x.isNotEmpty).toList();
//         if (name.isNotEmpty) _catalog[name] = m;
//       }

//       final makeList = _catalog.keys.toList()..sort();
//       if (!mounted) return;

//       setState(() => makes = makeList);
//     } catch (e) {
//       if (!mounted) return;
//       _snack('Failed to load vehicle catalog: $e', 'error');
//     } finally {
//       if (mounted) setState(() => loadingMakes = false);
//     }
//   }

//   Future<void> _loadModelsForMakeLocal(String make) async {
//     setState(() {
//       loadingModels = true;
//       models = [];
//       selectedModel = null;
//       modelCtrl.text = '';
//     });

//     await Future<void>.delayed(const Duration(milliseconds: 30));
//     final list = (_catalog[make] ?? []).toList()..sort();

//     if (!mounted) return;
//     setState(() {
//       models = list;
//       loadingModels = false;
//     });
//   }

//   // ============================
//   // CHECKLIST STATE
//   // ============================

//   /// One dropdown replaces status+rating:
//   /// Excellent(5), Good(4), Average(3), Poor(1), Not Applicable
//   final Map<String, String?> _grade = {}; // selected option label
//   final Map<String, TextEditingController> _remarks = {};
//   final Map<String, List<String>> _itemPhotos = {};

//   /// overall remarks & photos per type (ti)
//   final Map<int, TextEditingController> _overallRemarks = {};
//   final Map<int, List<String>> _overallPhotos = {};

//   /// ✅ overall videos per type (ti)
//   final Map<int, List<String>> _overallVideos = {};

//   static const List<String> _gradeOptions = [
//     'Excellent (5)',
//     'Good (4)',
//     'Average (3)',
//     'Poor (1)',
//     'Not Applicable',
//   ];

//   static const List<String> _transmissionOptions = [
//     'Automatic',
//     'Manual',
//   ];

//   static const List<String> _fuelTypeOptions = [
//     'Petrol',
//     'Diesel',
//     'Hybrid',
//     'Electric',
//   ];

//   double? _gradeToRating(String? v) {
//     if (v == null) return null;
//     if (v.startsWith('Excellent')) return 5;
//     if (v.startsWith('Good')) return 4;
//     if (v.startsWith('Average')) return 3;
//     if (v.startsWith('Poor')) return 1;
//     return null; // Not Applicable -> null
//   }

//   String? _gradeToStatus(String? v) {
//     if (v == null) return null;
//     if (v == 'Not Applicable') return 'Not Applicable';
//     return v.split(' ').first.trim(); // "Excellent (5)" -> "Excellent"
//   }

//   @override
//   void initState() {
//     super.initState();
//     _future = _loadTemplates();
//     _loadCatalogFromAsset();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _startInspectionIfNeeded();
//     });
//   }

//   @override
//   void dispose() {
//     _scrollCtrl.dispose();

//     for (final c in _remarks.values) {
//       c.dispose();
//     }
//     for (final c in _overallRemarks.values) {
//       c.dispose();
//     }

//     // Report controllers
//     makeCtrl.dispose();
//     modelCtrl.dispose();
//     gradeVariantCtrl.dispose();
//     engineCapacityCtrl.dispose();
//     modelYearCtrl.dispose();
//     cylinderSizeCtrl.dispose();
//     transmissionCtrl.dispose();
//     fuelTypeCtrl.dispose();
//     driveTrainCtrl.dispose();
//     specsCtrl.dispose();
//     odometerCtrl.dispose();
//     registrationNoCtrl.dispose();
//     emiratesRegAtCtrl.dispose();
//     chassisNoCtrl.dispose();
//     ownershipTypeCtrl.dispose();

//     servicedWithCtrl.dispose();
//     lastServiceDateCtrl.dispose();
//     warrantyEndsInCtrl.dispose();

//     seatsCtrl.dispose();
//     interiorColorCtrl.dispose();
//     upholsteryCtrl.dispose();
//     numberOfKeysCtrl.dispose();

//     exteriorColorCtrl.dispose();
//     doorsCtrl.dispose();
//     wheelSizeCtrl.dispose();

//     super.dispose();
//   }

//   void _snack(String msg, String variant) {
//     showTopSnack(context, msg, variant: variant);
//   }

//   void _scrollToTop() {
//     if (!_scrollCtrl.hasClients) return;
//     _scrollCtrl.animateTo(
//       0,
//       duration: const Duration(milliseconds: 220),
//       curve: Curves.easeOut,
//     );
//   }

//   // ============================
//   // START INSPECTION API
//   // ============================

//   Future<void> _startInspectionIfNeeded() async {
//     if (_inspectionStarted || _startingInspection) return;

//     setState(() {
//       _startingInspection = true;
//       _startError = null;
//     });

//     try {
//       await inspectionRequestsService.startInspection(widget.requestId);

//       if (!mounted) return;
//       setState(() => _inspectionStarted = true);
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _startError = e.toString());
//       _snack('Failed to start inspection: $e', 'error');
//     } finally {
//       if (mounted) setState(() => _startingInspection = false);
//     }
//   }

//   // ============================
//   // TEMPLATES
//   // ============================

//   Future<List<ChecklistTemplate>> _loadTemplates() async {
//     final raw = await checklistTemplatesService.listActiveTemplates();
//     final templates = raw.map((x) => ChecklistTemplate.fromJson(x)).toList();

//     if (templates.isNotEmpty) {
//       _selectedTemplate = templates.first;
//       _primeChecklistControllers();
//     }
//     return templates;
//   }

//   void _primeChecklistControllers() {
//     for (final c in _remarks.values) {
//       c.dispose();
//     }
//     for (final c in _overallRemarks.values) {
//       c.dispose();
//     }

//     _remarks.clear();
//     _overallRemarks.clear();
//     _grade.clear();
//     _itemPhotos.clear();
//     _overallPhotos.clear();
//     _overallVideos.clear();

//     final t = _selectedTemplate;
//     if (t == null) return;

//     for (var ti = 0; ti < t.types.length; ti++) {
//       final type = t.types[ti];

//       if (type.allowOverallRemarks) {
//         _overallRemarks[ti] = TextEditingController();
//       }

//       _overallPhotos[ti] = [];
//       _overallVideos[ti] = [];

//       for (var ii = 0; ii < type.checklistItems.length; ii++) {
//         final key = '$ti:$ii';
//         _grade[key] = null;
//         _remarks[key] = TextEditingController();
//         _itemPhotos[key] = [];
//       }
//     }
//   }

//   // ============================
//   // WIZARD
//   // ============================

//   int _totalSections(ChecklistTemplate selected) => 5 + selected.types.length;

//   String _sectionTitle(ChecklistTemplate selected, int index) {
//     if (index == 0) return 'Vehicle Details';
//     if (index == 1) return 'Service & Warranty Overview';
//     if (index == 2) return 'Interior Details';
//     if (index == 3) return 'Exterior Details';
//     if (index == 4) return 'Damaged Coordinates';
//     final ti = index - 5;
//     return selected.types[ti].typeName;
//   }

//   bool _isLastSection(ChecklistTemplate selected) => _section == _totalSections(selected) - 1;

//   bool _validateCurrentSection() {
//     if (_section == 0) return _vehicleFormKey.currentState?.validate() ?? false;
//     if (_section == 1) return _serviceFormKey.currentState?.validate() ?? false;
//     if (_section == 2) return _interiorFormKey.currentState?.validate() ?? false;
//     if (_section == 3) return _exteriorFormKey.currentState?.validate() ?? false;
//     return true;
//   }

//   void _next(ChecklistTemplate selected) {
//     if (_section <= 3) {
//       final ok = _validateCurrentSection();
//       if (!ok) {
//         _snack('Please fix the highlighted fields.', 'warning');
//         return;
//       }
//     }

//     final total = _totalSections(selected);
//     if (_section < total - 1) {
//       setState(() => _section++);
//       _scrollToTop();
//     }
//   }

//   void _back() {
//     if (_section > 0) {
//       setState(() => _section--);
//       _scrollToTop();
//     }
//   }

//   // ============================
//   // VALIDATION (CHECKLIST)
//   // ============================

//   bool _validateChecklist() {
//     final t = _selectedTemplate;
//     if (t == null) {
//       _snack('No active checklist template found', 'error');
//       return false;
//     }

//     for (var ti = 0; ti < t.types.length; ti++) {
//       final type = t.types[ti];
//       for (var ii = 0; ii < type.checklistItems.length; ii++) {
//         final item = type.checklistItems[ii];
//         if (!item.isRequired) continue;

//         final key = '$ti:$ii';
//         final g = _grade[key];
//         if (g == null || g.trim().isEmpty) {
//           _snack('Please select: ${type.typeName} → ${item.label}', 'warning');
//           return false;
//         }
//       }
//     }
//     return true;
//   }

//   Map<String, dynamic> _buildReportPayload() {
//     return {
//       'vehicleDetails': {
//         'make': makeCtrl.text.trim(),
//         'model': modelCtrl.text.trim(),
//         'gradeVariant': gradeVariantCtrl.text.trim(),
//         'engineCapacity': engineCapacityCtrl.text.trim(),
//         'modelYear': modelYearCtrl.text.trim(),
//         'cylinderSize': cylinderSizeCtrl.text.trim(),
//         'transmission': transmissionCtrl.text.trim(),
//         'fuelType': fuelTypeCtrl.text.trim(),
//         'driveTrain': driveTrainCtrl.text.trim(),
//         'specs': specsCtrl.text.trim(),
//         'odometerReading': odometerCtrl.text.trim(),
//         'registrationNo': registrationNoCtrl.text.trim(),
//         'emiratesRegAt': emiratesRegAtCtrl.text.trim(),
//         'chassisNo': chassisNoCtrl.text.trim(),
//         'ownershipType': ownershipTypeCtrl.text.trim(),
//       },
//       'serviceWarrantyOverview': {
//         'serviceHistory': serviceHistory,
//         'servicedWith': servicedWithCtrl.text.trim(),
//         'lastServiceDate': lastServiceDateCtrl.text.trim(),
//         'warrantyAvailable': warrantyAvailable,
//         'warrantyEndsIn': warrantyEndsInCtrl.text.trim(),
//         'hadAccidents': hadAccidents,
//       },
//       'interiorDetails': {
//         'seats': seatsCtrl.text.trim(),
//         'interiorColor': interiorColorCtrl.text.trim(),
//         'upholstery': upholsteryCtrl.text.trim(),
//         'numberOfKeys': numberOfKeysCtrl.text.trim(),
//         'modificationDone': interiorModificationDone,
//       },
//       'exteriorDetails': {
//         'exteriorColor': exteriorColorCtrl.text.trim(),
//         'doors': doorsCtrl.text.trim(),
//         'wheelSize': wheelSizeCtrl.text.trim(),
//         'modificationDone': exteriorModificationDone,
//       },
//     };
//   }

//   List<Map<String, dynamic>> _buildTypesPayload() {
//     final t = _selectedTemplate!;
//     final out = <Map<String, dynamic>>[];

//     for (var ti = 0; ti < t.types.length; ti++) {
//       final type = t.types[ti];
//       final items = <Map<String, dynamic>>[];

//       for (var ii = 0; ii < type.checklistItems.length; ii++) {
//         final item = type.checklistItems[ii];
//         final key = '$ti:$ii';

//         final g = _grade[key];
//         final rating = _gradeToRating(g);
//         final status = _gradeToStatus(g);

//         final remarksText = _remarks[key]!.text.trim();

//         items.add({
//           'position': item.position,
//           'label': item.label,
//           'status': status,
//           'rating': rating,
//           'remarks': remarksText.isEmpty ? '' : remarksText,
//           'photos': _itemPhotos[key] ?? [],
//         });
//       }

//       final overallRemarksText = type.allowOverallRemarks ? _overallRemarks[ti]?.text.trim() : null;

//       out.add({
//         'typeName': type.typeName,
//         'checklistItems': items,
//         'overallRemarks': (overallRemarksText != null && overallRemarksText.isNotEmpty) ? overallRemarksText : '',
//         'overallPhotos': _overallPhotos[ti] ?? [],
//         'videos': _overallVideos[ti] ?? [],
//       });
//     }

//     return out;
//   }

//   bool _validateReportData() {
//     // Vehicle Details
//     final v1 = _alphaNumValidator(makeCtrl.text, fieldName: 'Make', min: 2);
//     if (v1 != null) {
//       _snack(v1, 'warning');
//       return false;
//     }
//     final v2 = _alphaNumValidator(modelCtrl.text, fieldName: 'Model', min: 2);
//     if (v2 != null) {
//       _snack(v2, 'warning');
//       return false;
//     }
//     final v3 = _alphaNumValidator(gradeVariantCtrl.text, fieldName: 'Grade / Variant', min: 2);
//     if (v3 != null) {
//       _snack(v3, 'warning');
//       return false;
//     }
//     final v4 = _alphaNumValidator(engineCapacityCtrl.text, fieldName: 'Engine Capacity', min: 1);
//     if (v4 != null) {
//       _snack(v4, 'warning');
//       return false;
//     }
//     final v5 = _yearValidator(modelYearCtrl.text);
//     if (v5 != null) {
//       _snack(v5, 'warning');
//       return false;
//     }
//     final v6 = _alphaNumValidator(cylinderSizeCtrl.text, fieldName: 'Cylinder Size', min: 1);
//     if (v6 != null) {
//       _snack(v6, 'warning');
//       return false;
//     }

//     if (transmissionCtrl.text.trim().isEmpty) {
//       _snack('Transmission is required', 'warning');
//       return false;
//     }
//     if (fuelTypeCtrl.text.trim().isEmpty) {
//       _snack('Fuel Type is required', 'warning');
//       return false;
//     }

//     final v7 = _alphaNumValidator(driveTrainCtrl.text, fieldName: 'Drive Train', min: 1);
//     if (v7 != null) {
//       _snack(v7, 'warning');
//       return false;
//     }
//     final v8 = _alphaNumValidator(specsCtrl.text, fieldName: 'Specs', min: 1);
//     if (v8 != null) {
//       _snack(v8, 'warning');
//       return false;
//     }
//     final v9 = _numberValidator(odometerCtrl.text, fieldName: 'Odometer Reading', max: 10);
//     if (v9 != null) {
//       _snack(v9, 'warning');
//       return false;
//     }
//     final v10 = _alphaNumValidator(registrationNoCtrl.text, fieldName: 'Registration No', min: 3);
//     if (v10 != null) {
//       _snack(v10, 'warning');
//       return false;
//     }
//     final v11 = _alphaNumValidator(emiratesRegAtCtrl.text, fieldName: 'Emirates Reg. At', min: 2);
//     if (v11 != null) {
//       _snack(v11, 'warning');
//       return false;
//     }
//     final v12 = _alphaNumValidator(chassisNoCtrl.text, fieldName: 'Chassis No', min: 6);
//     if (v12 != null) {
//       _snack(v12, 'warning');
//       return false;
//     }
//     final v13 = _alphaNumValidator(ownershipTypeCtrl.text, fieldName: 'Ownership Type', min: 2);
//     if (v13 != null) {
//       _snack(v13, 'warning');
//       return false;
//     }

//     // Service & Warranty
//     if (serviceHistory == null) {
//       _snack('Service History is required', 'warning');
//       return false;
//     }
//     final s1 = _alphaNumValidator(servicedWithCtrl.text, fieldName: 'Serviced With', min: 2);
//     if (s1 != null) {
//       _snack(s1, 'warning');
//       return false;
//     }
//     final s2 = _req(lastServiceDateCtrl.text, msg: 'Last Service Date is required');
//     if (s2 != null) {
//       _snack(s2, 'warning');
//       return false;
//     }
//     if (warrantyAvailable == null) {
//       _snack('Warranty Available is required', 'warning');
//       return false;
//     }
//     final s3 = _req(warrantyEndsInCtrl.text, msg: 'Warranty Ends In is required');
//     if (s3 != null) {
//       _snack(s3, 'warning');
//       return false;
//     }
//     if (hadAccidents == null) {
//       _snack('Had Accidents is required', 'warning');
//       return false;
//     }

//     // Interior
//     final i1 = _numberValidator(seatsCtrl.text, fieldName: 'Seats', max: 2);
//     if (i1 != null) {
//       _snack(i1, 'warning');
//       return false;
//     }
//     final i2 = _alphaNumValidator(interiorColorCtrl.text, fieldName: 'Interior Color', min: 2);
//     if (i2 != null) {
//       _snack(i2, 'warning');
//       return false;
//     }
//     final i3 = _alphaNumValidator(upholsteryCtrl.text, fieldName: 'Upholstery', min: 2);
//     if (i3 != null) {
//       _snack(i3, 'warning');
//       return false;
//     }
//     final i4 = _numberValidator(numberOfKeysCtrl.text, fieldName: 'Number of Keys', max: 1);
//     if (i4 != null) {
//       _snack(i4, 'warning');
//       return false;
//     }
//     if (interiorModificationDone == null) {
//       _snack('Interior Modification Done is required', 'warning');
//       return false;
//     }

//     // Exterior
//     final e1 = _alphaNumValidator(exteriorColorCtrl.text, fieldName: 'Exterior Color', min: 2);
//     if (e1 != null) {
//       _snack(e1, 'warning');
//       return false;
//     }
//     final e2 = _numberValidator(doorsCtrl.text, fieldName: 'Doors', max: 1);
//     if (e2 != null) {
//       _snack(e2, 'warning');
//       return false;
//     }
//     final e3 = _numberValidator(wheelSizeCtrl.text, fieldName: 'Wheel Size', max: 2);
//     if (e3 != null) {
//       _snack(e3, 'warning');
//       return false;
//     }
//     if (exteriorModificationDone == null) {
//       _snack('Exterior Modification Done is required', 'warning');
//       return false;
//     }

//     return true;
//   }

//   Future<void> _submit() async {
//     if (_submitting) return;

//     if (!_validateReportData()) {
//       _snack('Please fix the highlighted fields in report sections.', 'warning');
//       return;
//     }

//     if (!_validateChecklist()) return;

//     setState(() => _submitting = true);

//     try {
//       final t = _selectedTemplate!;

//       final payload = {
//         'checklistTemplateId': t.id,
//         'inspectionRequestId': widget.requestId,
//         'inspectionDate': DateTime.now().toIso8601String(),
//         'status': 'draft',
//         ..._buildReportPayload(),

//         // ✅ NEW
//         'damaged_coordinates': _buildDamagedCoordinatesPayload(),

//         'types': _buildTypesPayload(),
//       };

//       await inspectionRequestsService.submitInspection(payload);

//       if (!mounted) return;
//       _snack('Inspection submitted successfully', 'success');

//       if (context.canPop()) {
//         context.pop();
//       } else {
//         context.go('/dashboard/inspector');
//       }
//     } catch (e) {
//       if (!mounted) return;
//       _snack('Submit failed: $e', 'error');
//     } finally {
//       if (mounted) setState(() => _submitting = false);
//     }
//   }

//   // ============================
//   // VALIDATORS + FORMATTERS
//   // ============================

//   String? _req(String? v, {String msg = 'Required'}) {
//     if (v == null) return msg;
//     if (v.trim().isEmpty) return msg;
//     return null;
//   }

//   String? _alphaNumValidator(String? v, {required String fieldName, int min = 2}) {
//     final r = _req(v, msg: '$fieldName is required');
//     if (r != null) return r;
//     final s = v!.trim();
//     if (s.length < min) return '$fieldName must be at least $min characters';
//     if (!RegExp(r"^[A-Za-z0-9\s'./-]+$").hasMatch(s)) {
//       return '$fieldName contains invalid characters';
//     }
//     return null;
//   }

//   String? _yearValidator(String? v) {
//     final r = _req(v, msg: 'Model Year is required');
//     if (r != null) return r;
//     final year = int.tryParse(v!.trim());
//     if (year == null) return 'Model Year must be a number';
//     final now = DateTime.now().year;
//     if (year < 1980 || year > now + 1) return 'Enter a valid year (1980 - ${now + 1})';
//     return null;
//   }

//   String? _numberValidator(String? v, {required String fieldName, int max = 12}) {
//     final r = _req(v, msg: '$fieldName is required');
//     if (r != null) return r;
//     final s = v!.trim();
//     if (!RegExp(r'^\d+$').hasMatch(s)) return '$fieldName must be numeric';
//     if (s.length > max) return '$fieldName is too long';
//     return null;
//   }

//   List<TextInputFormatter> _freeTextFormatters({int max = 40}) => [
//         LengthLimitingTextInputFormatter(max),
//         FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z0-9\s'./-]")),
//       ];

//   List<TextInputFormatter> _digitsFormatters({int max = 12}) => [
//         LengthLimitingTextInputFormatter(max),
//         FilteringTextInputFormatter.digitsOnly,
//       ];

//   List<TextInputFormatter> _yearFormatters() => [
//         LengthLimitingTextInputFormatter(4),
//         FilteringTextInputFormatter.digitsOnly,
//       ];

//   // ============================
//   // DATE PICKERS
//   // ============================

//   Future<void> _pickLastServiceDate() async {
//     final now = DateTime.now();
//     DateTime initial = now;
//     final raw = lastServiceDateCtrl.text.trim();
//     final parts = raw.split('-');
//     if (parts.length == 3) {
//       final y = int.tryParse(parts[0]);
//       final m = int.tryParse(parts[1]);
//       final d = int.tryParse(parts[2]);
//       if (y != null && m != null && d != null) {
//         initial = DateTime(y, m, d);
//       }
//     }

//     final picked = await showDatePicker(
//       context: context,
//       initialDate: initial,
//       firstDate: DateTime(1990, 1, 1),
//       lastDate: now.add(const Duration(days: 365 * 2)),
//     );

//     if (picked == null) return;
//     final s = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
//     setState(() => lastServiceDateCtrl.text = s);
//   }

//   Future<void> _pickWarrantyEndsMonthYear() async {
//     final now = DateTime.now();
//     DateTime initial = DateTime(now.year, now.month, 1);

//     final picked = await showDatePicker(
//       context: context,
//       initialDate: initial,
//       firstDate: DateTime(1990, 1, 1),
//       lastDate: DateTime(now.year + 10, 12, 31),
//       helpText: 'Select warranty end month (pick any day)',
//     );

//     if (picked == null) return;

//     const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
//     final mmmyy = '${months[picked.month - 1]}-${(picked.year % 100).toString().padLeft(2, '0')}';
//     setState(() => warrantyEndsInCtrl.text = mmmyy);
//   }

//   // ============================
//   // UI HELPERS (shared style)
//   // ============================

//   InputDecoration _dec({required String label, String? hint, IconData? icon}) {
//     return InputDecoration(
//       labelText: label,
//       hintText: hint,
//       prefixIcon: icon == null ? null : Icon(icon),
//       filled: true,
//       fillColor: Colors.white,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(color: Color(0xFF1E5EFF), width: 1.6),
//       ),
//       errorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(color: Colors.redAccent),
//       ),
//       focusedErrorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
//       ),
//     );
//   }

//   Widget _sectionCard({required String title, required IconData icon, required Widget child}) {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFFF4F6FB),
//         borderRadius: BorderRadius.circular(22),
//         border: Border.all(color: Colors.black.withOpacity(0.06)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 22,
//             offset: const Offset(0, 12),
//           )
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   height: 38,
//                   width: 38,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF0B1220),
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: Icon(icon, color: Colors.white, size: 18),
//                 ),
//                 const SizedBox(width: 10),
//                 Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
//               ],
//             ),
//             const SizedBox(height: 14),
//             child,
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _dropField({
//     required String label,
//     required String? value,
//     required List<String> options,
//     required void Function(String?) onChanged,
//     String? hint,
//     IconData? icon,
//     String? Function(String?)? validator,
//   }) {
//     return DropdownButtonFormField<String>(
//       value: value,
//       items: options.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
//       onChanged: onChanged,
//       decoration: _dec(label: label, hint: hint, icon: icon),
//       validator: validator,
//     );
//   }

//   Widget _textFormField({
//     required TextEditingController c,
//     required String label,
//     String? hint,
//     IconData? icon,
//     TextInputType? keyboardType,
//     List<TextInputFormatter>? inputFormatters,
//     String? Function(String?)? validator,
//     bool readOnly = false,
//     VoidCallback? onTap,
//     int maxLines = 1,
//   }) {
//     return TextFormField(
//       controller: c,
//       keyboardType: keyboardType,
//       inputFormatters: inputFormatters,
//       validator: validator,
//       readOnly: readOnly,
//       onTap: onTap,
//       maxLines: maxLines,
//       decoration: _dec(label: label, hint: hint, icon: icon),
//     );
//   }

//   // ============================
//   // SECTION BUILDERS
//   // ============================

//   Widget _vehicleDetailsSection() {
//     return _sectionCard(
//       title: 'Vehicle Details',
//       icon: Icons.directions_car_outlined,
//       child: Form(
//         key: _vehicleFormKey,
//         child: Column(
//           children: [
//             DropdownButtonFormField<String>(
//               value: selectedMake,
//               items: makes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
//               onChanged: loadingMakes
//                   ? null
//                   : (v) async {
//                       if (v == null) return;
//                       setState(() {
//                         selectedMake = v;
//                         makeCtrl.text = v;

//                         selectedModel = null;
//                         modelCtrl.text = '';
//                         models = [];
//                       });
//                       await _loadModelsForMakeLocal(v);
//                     },
//               decoration: _dec(
//                 label: 'Make',
//                 hint: loadingMakes ? 'Loading makes…' : 'Select make',
//                 icon: Icons.directions_car_outlined,
//               ),
//               validator: (v) => v == null ? 'Make is required' : null,
//             ),
//             const SizedBox(height: 12),
//             DropdownButtonFormField<String>(
//               value: selectedModel,
//               items: models.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
//               onChanged: (selectedMake == null || loadingModels)
//                   ? null
//                   : (v) {
//                       if (v == null) return;
//                       setState(() {
//                         selectedModel = v;
//                         modelCtrl.text = v;
//                       });
//                     },
//               decoration: _dec(
//                 label: 'Model',
//                 hint: selectedMake == null ? 'Select make first' : (loadingModels ? 'Loading models…' : 'Select model'),
//                 icon: Icons.car_repair_outlined,
//               ),
//               validator: (v) => v == null ? 'Model is required' : null,
//             ),
//             const SizedBox(height: 12),
//             _textFormField(
//               c: gradeVariantCtrl,
//               label: 'Grade / Variant',
//               hint: 'e.g. XLE / Limited',
//               icon: Icons.badge_outlined,
//               inputFormatters: _freeTextFormatters(max: 40),
//               validator: (v) => _alphaNumValidator(v, fieldName: 'Grade / Variant', min: 2),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: _textFormField(
//                     c: engineCapacityCtrl,
//                     label: 'Engine Capacity',
//                     hint: 'e.g. 2.0L',
//                     icon: Icons.speed_outlined,
//                     inputFormatters: _freeTextFormatters(max: 12),
//                     validator: (v) => _alphaNumValidator(v, fieldName: 'Engine Capacity', min: 1),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _textFormField(
//                     c: modelYearCtrl,
//                     label: 'Model Year',
//                     hint: '2020',
//                     icon: Icons.calendar_today_outlined,
//                     keyboardType: TextInputType.number,
//                     inputFormatters: _yearFormatters(),
//                     validator: _yearValidator,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             _textFormField(
//               c: cylinderSizeCtrl,
//               label: 'Cylinder Size',
//               hint: 'e.g. 6 Cylinder',
//               icon: Icons.settings_outlined,
//               inputFormatters: _freeTextFormatters(max: 20),
//               validator: (v) => _alphaNumValidator(v, fieldName: 'Cylinder Size', min: 1),
//             ),
//             const SizedBox(height: 12),
//             _dropField(
//               label: 'Transmission',
//               value: transmissionCtrl.text.isEmpty ? null : transmissionCtrl.text,
//               options: _transmissionOptions,
//               icon: Icons.swap_horiz_outlined,
//               hint: 'Select transmission',
//               validator: (v) => v == null ? 'Transmission is required' : null,
//               onChanged: (v) => setState(() => transmissionCtrl.text = v ?? ''),
//             ),
//             const SizedBox(height: 12),
//             _dropField(
//               label: 'Fuel Type',
//               value: fuelTypeCtrl.text.isEmpty ? null : fuelTypeCtrl.text,
//               options: _fuelTypeOptions,
//               icon: Icons.local_gas_station_outlined,
//               hint: 'Select fuel type',
//               validator: (v) => v == null ? 'Fuel Type is required' : null,
//               onChanged: (v) => setState(() => fuelTypeCtrl.text = v ?? ''),
//             ),
//             const SizedBox(height: 12),
//             _textFormField(
//               c: driveTrainCtrl,
//               label: 'Drive Train',
//               hint: 'e.g. 4x4 / FWD',
//               icon: Icons.grid_on_outlined,
//               inputFormatters: _freeTextFormatters(max: 10),
//               validator: (v) => _alphaNumValidator(v, fieldName: 'Drive Train', min: 1),
//             ),
//             const SizedBox(height: 12),
//             _textFormField(
//               c: specsCtrl,
//               label: 'Specs',
//               hint: 'e.g. GCC',
//               icon: Icons.public_outlined,
//               inputFormatters: _freeTextFormatters(max: 10),
//               validator: (v) => _alphaNumValidator(v, fieldName: 'Specs', min: 1),
//             ),
//             const SizedBox(height: 12),
//             _textFormField(
//               c: odometerCtrl,
//               label: 'Odometer Reading',
//               hint: 'e.g. 156468',
//               icon: Icons.av_timer_outlined,
//               keyboardType: TextInputType.number,
//               inputFormatters: _digitsFormatters(max: 10),
//               validator: (v) => _numberValidator(v, fieldName: 'Odometer Reading', max: 10),
//             ),
//             const SizedBox(height: 12),
//             _textFormField(
//               c: registrationNoCtrl,
//               label: 'Registration No.',
//               hint: 'e.g. ABC123',
//               icon: Icons.confirmation_number_outlined,
//               inputFormatters: _freeTextFormatters(max: 20),
//               validator: (v) => _alphaNumValidator(v, fieldName: 'Registration No', min: 3),
//             ),
//             const SizedBox(height: 12),
//             _textFormField(
//               c: emiratesRegAtCtrl,
//               label: 'Emirates Reg. At',
//               hint: 'e.g. Dubai',
//               icon: Icons.location_city_outlined,
//               inputFormatters: _freeTextFormatters(max: 20),
//               validator: (v) => _alphaNumValidator(v, fieldName: 'Emirates Reg. At', min: 2),
//             ),
//             const SizedBox(height: 12),
//             _textFormField(
//               c: chassisNoCtrl,
//               label: 'Chassis No.',
//               hint: 'e.g. JH4KA9650MC000000',
//               icon: Icons.numbers_outlined,
//               inputFormatters: _freeTextFormatters(max: 25),
//               validator: (v) => _alphaNumValidator(v, fieldName: 'Chassis No', min: 6),
//             ),
//             const SizedBox(height: 12),
//             _textFormField(
//               c: ownershipTypeCtrl,
//               label: 'Ownership Type',
//               hint: 'e.g. Individual / Company',
//               icon: Icons.person_outline,
//               inputFormatters: _freeTextFormatters(max: 20),
//               validator: (v) => _alphaNumValidator(v, fieldName: 'Ownership Type', min: 2),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _serviceWarrantySection() {
//     return _sectionCard(
//       title: 'Service & Warranty Overview',
//       icon: Icons.assignment_outlined,
//       child: Form(
//         key: _serviceFormKey,
//         child: Column(
//           children: [
//             _dropField(
//               label: 'Service History',
//               value: serviceHistory,
//               options: const ['Available', 'Not Available'],
//               icon: Icons.history_outlined,
//               hint: 'Select',
//               validator: (v) => v == null ? 'Service History is required' : null,
//               onChanged: (v) => setState(() => serviceHistory = v),
//             ),
//             const SizedBox(height: 12),
//             _textFormField(
//               c: servicedWithCtrl,
//               label: 'Serviced With',
//               hint: 'Agency / Third Party',
//               icon: Icons.build_outlined,
//               inputFormatters: _freeTextFormatters(max: 40),
//               validator: (v) => _alphaNumValidator(v, fieldName: 'Serviced With', min: 2),
//             ),
//             const SizedBox(height: 12),
//             _textFormField(
//               c: lastServiceDateCtrl,
//               label: 'Last Service Date',
//               hint: 'Select date',
//               icon: Icons.date_range_outlined,
//               readOnly: true,
//               onTap: _pickLastServiceDate,
//               validator: (v) => _req(v, msg: 'Last Service Date is required'),
//             ),
//             const SizedBox(height: 12),
//             _dropField(
//               label: 'Warranty Available',
//               value: warrantyAvailable,
//               options: const ['Yes', 'No'],
//               icon: Icons.verified_outlined,
//               hint: 'Select',
//               validator: (v) => v == null ? 'Warranty Available is required' : null,
//               onChanged: (v) => setState(() => warrantyAvailable = v),
//             ),
//             const SizedBox(height: 12),
//             _textFormField(
//               c: warrantyEndsInCtrl,
//               label: 'Warranty Ends In (Month/Year)',
//               hint: 'Select month',
//               icon: Icons.event_outlined,
//               readOnly: true,
//               onTap: _pickWarrantyEndsMonthYear,
//               validator: (v) => _req(v, msg: 'Warranty Ends In is required'),
//             ),
//             const SizedBox(height: 12),
//             _dropField(
//               label: 'Had Accidents',
//               value: hadAccidents,
//               options: const ['Yes', 'No'],
//               icon: Icons.report_problem_outlined,
//               hint: 'Select',
//               validator: (v) => v == null ? 'Had Accidents is required' : null,
//               onChanged: (v) => setState(() => hadAccidents = v),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _interiorSection() {
//     return _sectionCard(
//       title: 'Interior Details',
//       icon: Icons.chair_outlined,
//       child: Form(
//         key: _interiorFormKey,
//         child: Column(
//           children: [
//             _textFormField(
//               c: seatsCtrl,
//               label: 'Seats',
//               hint: 'e.g. 5',
//               icon: Icons.event_seat_outlined,
//               keyboardType: TextInputType.number,
//               inputFormatters: _digitsFormatters(max: 2),
//               validator: (v) => _numberValidator(v, fieldName: 'Seats', max: 2),
//             ),
//             const SizedBox(height: 12),
//             _textFormField(
//               c: interiorColorCtrl,
//               label: 'Interior Color',
//               hint: 'e.g. Black',
//               icon: Icons.palette_outlined,
//               inputFormatters: _freeTextFormatters(max: 20),
//               validator: (v) => _alphaNumValidator(v, fieldName: 'Interior Color', min: 2),
//             ),
//             const SizedBox(height: 12),
//             _textFormField(
//               c: upholsteryCtrl,
//               label: 'Upholstery',
//               hint: 'e.g. Leather / Fabric',
//               icon: Icons.texture_outlined,
//               inputFormatters: _freeTextFormatters(max: 20),
//               validator: (v) => _alphaNumValidator(v, fieldName: 'Upholstery', min: 2),
//             ),
//             const SizedBox(height: 12),
//             _textFormField(
//               c: numberOfKeysCtrl,
//               label: 'Number of Keys',
//               hint: 'e.g. 2',
//               icon: Icons.key_outlined,
//               keyboardType: TextInputType.number,
//               inputFormatters: _digitsFormatters(max: 1),
//               validator: (v) => _numberValidator(v, fieldName: 'Number of Keys', max: 1),
//             ),
//             const SizedBox(height: 12),
//             _dropField(
//               label: 'Modification Done',
//               value: interiorModificationDone,
//               options: const ['Yes', 'No'],
//               icon: Icons.construction_outlined,
//               hint: 'Select',
//               validator: (v) => v == null ? 'Modification Done is required' : null,
//               onChanged: (v) => setState(() => interiorModificationDone = v),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _exteriorSection() {
//     return _sectionCard(
//       title: 'Exterior Details',
//       icon: Icons.directions_car_filled_outlined,
//       child: Form(
//         key: _exteriorFormKey,
//         child: Column(
//           children: [
//             _textFormField(
//               c: exteriorColorCtrl,
//               label: 'Exterior Color',
//               hint: 'e.g. White',
//               icon: Icons.palette_outlined,
//               inputFormatters: _freeTextFormatters(max: 20),
//               validator: (v) => _alphaNumValidator(v, fieldName: 'Exterior Color', min: 2),
//             ),
//             const SizedBox(height: 12),
//             _textFormField(
//               c: doorsCtrl,
//               label: 'Doors',
//               hint: 'e.g. 4',
//               icon: Icons.door_front_door_outlined,
//               keyboardType: TextInputType.number,
//               inputFormatters: _digitsFormatters(max: 1),
//               validator: (v) => _numberValidator(v, fieldName: 'Doors', max: 1),
//             ),
//             const SizedBox(height: 12),
//             _textFormField(
//               c: wheelSizeCtrl,
//               label: 'Wheel Size',
//               hint: 'e.g. 20',
//               icon: Icons.circle_outlined,
//               keyboardType: TextInputType.number,
//               inputFormatters: _digitsFormatters(max: 2),
//               validator: (v) => _numberValidator(v, fieldName: 'Wheel Size', max: 2),
//             ),
//             const SizedBox(height: 12),
//             _dropField(
//               label: 'Modification Done',
//               value: exteriorModificationDone,
//               options: const ['Yes', 'No'],
//               icon: Icons.construction_outlined,
//               hint: 'Select',
//               validator: (v) => v == null ? 'Modification Done is required' : null,
//               onChanged: (v) => setState(() => exteriorModificationDone = v),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ✅ NEW DAMAGE SECTION
//   Widget _damagedCoordinatesSection() {
//     return _sectionCard(
//       title: 'Damaged Coordinates',
//       icon: Icons.place_outlined,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Tap on the car to add a damage point. A popup will open to add description and photos.',
//             style: TextStyle(color: Colors.black.withOpacity(0.55), fontWeight: FontWeight.w700),
//           ),
//           const SizedBox(height: 12),
//           DamageMarkerEditor(
//             imageAsset: _carTopImageAsset,
//             inspectionRequestId: widget.requestId,
//             markers: _damagedCoordinates,
//             onChanged: (next) => setState(() => _damagedCoordinates = next),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton.icon(
//                   onPressed: _damagedCoordinates.isEmpty ? null : () => setState(() => _damagedCoordinates = []),
//                   icon: const Icon(Icons.clear_all),
//                   label: const Text('Clear All'),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _checklistTypeSection(ChecklistTemplate selected, int ti) {
//     final type = selected.types[ti];

//     return _sectionCard(
//       title: type.typeName,
//       icon: Icons.fact_check_outlined,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (type.allowOverallRemarks)
//             TextField(
//               controller: _overallRemarks[ti],
//               maxLines: 2,
//               decoration: _dec(label: 'Overall Remarks', hint: 'Write overall remarks', icon: Icons.notes_outlined),
//             ),
//           if (type.allowOverallPhotos) ...[
//             const SizedBox(height: 12),
//             ImageUploader(
//               typeName: type.typeName,
//               inspectionRequestId: widget.requestId,
//               title: 'Overall Photos',
//               initialImages: _overallPhotos[ti] ?? const [],
//               onChanged: (v) => setState(() => _overallPhotos[ti] = v),
//             ),
//           ],
//           const SizedBox(height: 12),
//           VideoUploader(
//             typeName: type.typeName,
//             inspectionRequestId: widget.requestId,
//             title: 'Overall Videos (MP4)',
//             initialVideos: _overallVideos[ti] ?? const [],
//             onChanged: (v) => setState(() => _overallVideos[ti] = v),
//           ),
//           const SizedBox(height: 16),
//           ...List.generate(type.checklistItems.length, (ii) {
//             final item = type.checklistItems[ii];
//             final key = '$ti:$ii';
//             final required = item.isRequired;

//             final urls = _itemPhotos[key] ?? const <String>[];

//             return Padding(
//               padding: const EdgeInsets.only(bottom: 14),
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(18),
//                   border: Border.all(color: Colors.black.withOpacity(0.07)),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(14),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         '${item.position}. ${item.label}${required ? ' *' : ''}',
//                         style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
//                       ),
//                       if ((item.description ?? '').trim().isNotEmpty) ...[
//                         const SizedBox(height: 6),
//                         Text(item.description!, style: const TextStyle(color: Colors.black54)),
//                       ],
//                       const SizedBox(height: 12),
//                       DropdownButtonFormField<String>(
//                         value: _grade[key],
//                         items: _gradeOptions.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
//                         onChanged: (v) => setState(() => _grade[key] = v),
//                         decoration: _dec(
//                           label: required ? 'Condition *' : 'Condition',
//                           hint: 'Select condition',
//                           icon: Icons.grade_outlined,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       ImageUploader(
//                         typeName: type.typeName,
//                         inspectionRequestId: widget.requestId,
//                         title: 'Photos',
//                         initialImages: urls,
//                         onChanged: (v) => setState(() => _itemPhotos[key] = v),
//                       ),
//                       const SizedBox(height: 12),
//                       TextField(
//                         controller: _remarks[key],
//                         maxLines: 2,
//                         decoration: _dec(label: 'Remarks', hint: 'Write remarks', icon: Icons.comment_outlined),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildCurrentSection(ChecklistTemplate selected) {
//     if (_section == 0) return _vehicleDetailsSection();
//     if (_section == 1) return _serviceWarrantySection();
//     if (_section == 2) return _interiorSection();
//     if (_section == 3) return _exteriorSection();
//     if (_section == 4) return _damagedCoordinatesSection();

//     final ti = _section - 5;
//     return _checklistTypeSection(selected, ti);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AppShell(
//       title: 'Start Inspection',
//       child: Center(
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 1100),
//           child: FutureBuilder<List<ChecklistTemplate>>(
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
//                   child: Text('Failed to load template: ${snap.error}'),
//                 );
//               }

//               final templates = snap.data ?? [];
//               if (templates.isEmpty) {
//                 return const Padding(
//                   padding: EdgeInsets.all(18),
//                   child: Text('No active checklist templates found.'),
//                 );
//               }

//               final selected = _selectedTemplate ?? templates.first;
//               final total = _totalSections(selected);

//               if (_section >= total) _section = total - 1;

//               final title = _sectionTitle(selected, _section);
//               final progress = total == 0 ? 0.0 : (_section + 1) / total;

//               return ListView(
//                 controller: _scrollCtrl,
//                 padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           'Start Inspection',
//                           style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
//                         ),
//                       ),
//                       if (_startingInspection)
//                         const Padding(
//                           padding: EdgeInsets.only(right: 10),
//                           child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
//                         )
//                       else if (_startError != null)
//                         TextButton.icon(
//                           onPressed: _startInspectionIfNeeded,
//                           icon: const Icon(Icons.refresh, size: 18),
//                           label: const Text('Retry start'),
//                         ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   if (templates.length > 1)
//                     Card(
//                       child: Padding(
//                         padding: const EdgeInsets.all(12),
//                         child: Row(
//                           children: [
//                             const Text('Checklist Template:', style: TextStyle(fontWeight: FontWeight.w800)),
//                             const SizedBox(width: 10),
//                             Expanded(
//                               child: DropdownButtonHideUnderline(
//                                 child: DropdownButton<ChecklistTemplate>(
//                                   value: selected,
//                                   isExpanded: true,
//                                   items: templates
//                                       .map((t) => DropdownMenuItem(value: t, child: Text(t.name ?? t.id)))
//                                       .toList(),
//                                   onChanged: (v) {
//                                     if (v == null) return;
//                                     setState(() {
//                                       _selectedTemplate = v;
//                                       _primeChecklistControllers();
//                                       _section = 0;
//                                     });
//                                   },
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   const SizedBox(height: 10),
//                   Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(12),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
//                               Text(
//                                 'Section ${_section + 1} / $total',
//                                 style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 10),
//                           LinearProgressIndicator(value: progress),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   _buildCurrentSection(selected),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton.icon(
//                           onPressed: _section == 0 ? null : _back,
//                           icon: const Icon(Icons.arrow_back),
//                           label: const Text('Back'),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: _isLastSection(selected)
//                             ? FilledButton.icon(
//                                 onPressed: _submitting ? null : _submit,
//                                 icon: _submitting
//                                     ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
//                                     : const Icon(Icons.check),
//                                 label: Text(_submitting ? 'Submitting...' : 'Submit'),
//                               )
//                             : FilledButton.icon(
//                                 onPressed: () => _next(selected),
//                                 icon: const Icon(Icons.arrow_forward),
//                                 label: const Text('Next'),
//                               ),
//                       ),
//                     ],
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

// lib/features/dashboards/inspector/start_inspection_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../models/checklist_template.dart';
import '../../../services/service_locator.dart';
import '../../shared/app_shell.dart';
import '../../shared/top_snackbar.dart';
import '../../shared/widgets/image_uploader.dart';
import '../../shared/widgets/video_uploader.dart';

// ✅ Damage marker editor
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

  // Wizard section index:
  // 0 Vehicle Details
  // 1 Service & Warranty
  // 2 Interior Details
  // 3 Exterior Details
  // 4 Damaged Coordinates
  // 5.. (Checklist types)
  int _section = 0;

  // ✅ Start inspection API state
  bool _startingInspection = false;
  bool _inspectionStarted = false;
  String? _startError;

  bool _submitting = false;

  final _scrollCtrl = ScrollController();
  final _upper = UpperCaseTextFormatter();

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
  // ✅ Make/Model dropdowns (API + OTHER)  ✅ uses services
  // ============================
  bool loadingMakes = false;
  bool loadingModels = false;

  // what user sees
  List<String> makes = [];
  List<String> models = [];

  String? selectedMake;     // MAKE NAME (UPPERCASE)
  String? selectedMakeId;   // MAKE ID (backend)
  String? selectedModel;    // MODEL NAME (UPPERCASE)

  // mapping MAKE_NAME -> makeId
  final Map<String, String> _makeIdByName = {};

  bool _makeIsOther = false;
  bool _modelIsOther = false;
  final otherMakeCtrl = TextEditingController();
  final otherModelCtrl = TextEditingController();

  // ============================
  // CHECKLIST STATE
  // ============================

  /// One dropdown replaces status+rating:
  /// Excellent(5), Good(4), Average(3), Poor(1), Not Applicable
  final Map<String, String?> _grade = {}; // selected option label
  final Map<String, TextEditingController> _remarks = {};
  final Map<String, List<String>> _itemPhotos = {};

  /// overall remarks & photos per type (ti)
  final Map<int, TextEditingController> _overallRemarks = {};
  final Map<int, List<String>> _overallPhotos = {};

  /// overall videos per type (ti)
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

  double? _gradeToRating(String? v) {
    if (v == null) return null;
    if (v.startsWith('Excellent')) return 5;
    if (v.startsWith('Good')) return 4;
    if (v.startsWith('Average')) return 3;
    if (v.startsWith('Poor')) return 1;
    return null; // Not Applicable -> null
  }

  String? _gradeToStatus(String? v) {
    if (v == null) return null;
    if (v == 'Not Applicable') return 'Not Applicable';
    return v.split(' ').first.trim(); // "Excellent (5)" -> "Excellent"
  }

  @override
  void initState() {
    super.initState();
    _future = _loadTemplates();

    // ✅ Load makes from API once
    _loadMakes();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInspectionIfNeeded();
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

    // Report controllers
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

  // ============================
  // START INSPECTION API
  // ============================

  Future<void> _startInspectionIfNeeded() async {
    if (_inspectionStarted || _startingInspection) return;

    setState(() {
      _startingInspection = true;
      _startError = null;
    });

    try {
      await inspectionRequestsService.startInspection(widget.requestId);

      if (!mounted) return;
      setState(() => _inspectionStarted = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _startError = e.toString());
      _snack('Failed to start inspection: $e', 'error');
    } finally {
      if (mounted) setState(() => _startingInspection = false);
    }
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
    return templates;
  }

  void _primeChecklistControllers() {
    for (final c in _remarks.values) {
      c.dispose();
    }
    for (final c in _overallRemarks.values) {
      c.dispose();
    }

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
  }

  // ============================
  // ✅ MAKE / MODEL API (via services)
  // ============================

  /// expects service to return list of maps like:
  /// [{id:'...', name:'TOYOTA'}]
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

      makeCtrl.text = '';
      modelCtrl.text = '';
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
      _snack('Failed to load makes (API): $e', 'error');
      setState(() => makes = const ['OTHER']);
    } finally {
      if (mounted) setState(() => loadingMakes = false);
    }
  }

  /// GET /admin/models/{makeId}
  Future<void> _loadModelsForMakeId(String makeId) async {
    setState(() {
      loadingModels = true;
      models = [];
      selectedModel = null;
      _modelIsOther = false;
      otherModelCtrl.text = '';
      modelCtrl.text = '';
    });

    try {
      final list = await inspectionRequestsService.listVehicleModels(makeId);

      if (!mounted) return;
      setState(() {
        models = [...list.map((e) => e.toString().trim().toUpperCase()), 'OTHER'];
        if (models.isEmpty) models = const ['OTHER'];
      });
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to load models (API): $e', 'error');
      setState(() {
        models = const ['OTHER'];
        selectedModel = 'OTHER';
        _modelIsOther = true;
      });
    } finally {
      if (mounted) setState(() => loadingModels = false);
    }
  }

  bool _applyMakeModelToControllersNoNetwork() {
    // MAKE
    String make = '';
    if (_makeIsOther) {
      make = otherMakeCtrl.text.trim().toUpperCase();
    } else {
      make = (selectedMake ?? '').trim().toUpperCase();
    }

    if (make.isEmpty) {
      _snack('Make is required', 'warning');
      return false;
    }

    final makeErr = _alphaNumValidator(make, fieldName: 'Make', min: 2);
    if (makeErr != null) {
      _snack(makeErr, 'warning');
      return false;
    }

    // MODEL
    String model = '';
    if (_modelIsOther) {
      model = otherModelCtrl.text.trim().toUpperCase();
    } else {
      model = (selectedModel ?? '').trim().toUpperCase();
    }

    if (model.isEmpty) {
      _snack('Model is required', 'warning');
      return false;
    }

    final modelErr = _alphaNumValidator(model, fieldName: 'Model', min: 2);
    if (modelErr != null) {
      _snack(modelErr, 'warning');
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
    if (index == 4) return 'Damaged Coordinates';
    final ti = index - 5;
    return selected.types[ti].typeName;
  }

  bool _isLastSection(ChecklistTemplate selected) =>
      _section == _totalSections(selected) - 1;

  bool _validateCurrentSection() {
    if (_section == 0) return _vehicleFormKey.currentState?.validate() ?? false;
    if (_section == 1) return _serviceFormKey.currentState?.validate() ?? false;
    if (_section == 2) return _interiorFormKey.currentState?.validate() ?? false;
    if (_section == 3) return _exteriorFormKey.currentState?.validate() ?? false;
    return true;
  }

  void _next(ChecklistTemplate selected) {
    if (_section <= 3) {
      final ok = _validateCurrentSection();
      if (!ok) {
        _snack('Please fix the highlighted fields.', 'warning');
        return;
      }
    }

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
  // VALIDATION (CHECKLIST)
  // ============================

  bool _validateChecklist() {
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
        'specs': specsCtrl.text.trim(),
        'odometerReading': odometerCtrl.text.trim(),
        'registrationNo': registrationNoCtrl.text.trim(),
        'emiratesRegAt': emiratesRegAtCtrl.text.trim(),
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
        'wheelSize': wheelSizeCtrl.text.trim(),
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

      final overallRemarksText =
          type.allowOverallRemarks ? _overallRemarks[ti]?.text.trim() : null;

      out.add({
        'typeName': type.typeName,
        'checklistItems': items,
        'overallRemarks':
            (overallRemarksText != null && overallRemarksText.isNotEmpty)
                ? overallRemarksText
                : '',
        'overallPhotos': _overallPhotos[ti] ?? [],
        'videos': _overallVideos[ti] ?? [],
      });
    }

    return out;
  }

  bool _validateReportData() {
    // ✅ ensure make/model text controllers are populated correctly (no network)
    if (!_applyMakeModelToControllersNoNetwork()) return false;

    // Vehicle Details
    final v3 = _alphaNumValidator(gradeVariantCtrl.text,
        fieldName: 'Grade / Variant', min: 2);
    if (v3 != null) {
      _snack(v3, 'warning');
      return false;
    }
    final v4 = _alphaNumValidator(engineCapacityCtrl.text,
        fieldName: 'Engine Capacity', min: 1);
    if (v4 != null) {
      _snack(v4, 'warning');
      return false;
    }
    final v5 = _yearValidator(modelYearCtrl.text);
    if (v5 != null) {
      _snack(v5, 'warning');
      return false;
    }
    final v6 = _alphaNumValidator(cylinderSizeCtrl.text,
        fieldName: 'Cylinder Size', min: 1);
    if (v6 != null) {
      _snack(v6, 'warning');
      return false;
    }

    if (transmissionCtrl.text.trim().isEmpty) {
      _snack('Transmission is required', 'warning');
      return false;
    }
    if (fuelTypeCtrl.text.trim().isEmpty) {
      _snack('Fuel Type is required', 'warning');
      return false;
    }

    final v7 = _alphaNumValidator(driveTrainCtrl.text,
        fieldName: 'Drive Train', min: 1);
    if (v7 != null) {
      _snack(v7, 'warning');
      return false;
    }
    final v8 = _alphaNumValidator(specsCtrl.text, fieldName: 'Specs', min: 1);
    if (v8 != null) {
      _snack(v8, 'warning');
      return false;
    }
    final v9 = _numberValidator(odometerCtrl.text,
        fieldName: 'Odometer Reading', max: 10);
    if (v9 != null) {
      _snack(v9, 'warning');
      return false;
    }
    final v10 = _alphaNumValidator(registrationNoCtrl.text,
        fieldName: 'Registration No', min: 3);
    if (v10 != null) {
      _snack(v10, 'warning');
      return false;
    }
    final v11 = _alphaNumValidator(emiratesRegAtCtrl.text,
        fieldName: 'Emirates Reg. At', min: 2);
    if (v11 != null) {
      _snack(v11, 'warning');
      return false;
    }
    final v12 = _alphaNumValidator(chassisNoCtrl.text,
        fieldName: 'Chassis No', min: 6);
    if (v12 != null) {
      _snack(v12, 'warning');
      return false;
    }
    final v13 = _alphaNumValidator(ownershipTypeCtrl.text,
        fieldName: 'Ownership Type', min: 2);
    if (v13 != null) {
      _snack(v13, 'warning');
      return false;
    }

    // Service & Warranty
    if (serviceHistory == null) {
      _snack('Service History is required', 'warning');
      return false;
    }
    final s1 = _alphaNumValidator(servicedWithCtrl.text,
        fieldName: 'Serviced With', min: 2);
    if (s1 != null) {
      _snack(s1, 'warning');
      return false;
    }
    final s2 = _req(lastServiceDateCtrl.text,
        msg: 'Last Service Date is required');
    if (s2 != null) {
      _snack(s2, 'warning');
      return false;
    }
    if (warrantyAvailable == null) {
      _snack('Warranty Available is required', 'warning');
      return false;
    }
    final s3 =
        _req(warrantyEndsInCtrl.text, msg: 'Warranty Ends In is required');
    if (s3 != null) {
      _snack(s3, 'warning');
      return false;
    }
    if (hadAccidents == null) {
      _snack('Had Accidents is required', 'warning');
      return false;
    }

    // Interior
    final i1 = _numberValidator(seatsCtrl.text, fieldName: 'Seats', max: 2);
    if (i1 != null) {
      _snack(i1, 'warning');
      return false;
    }
    final i2 = _alphaNumValidator(interiorColorCtrl.text,
        fieldName: 'Interior Color', min: 2);
    if (i2 != null) {
      _snack(i2, 'warning');
      return false;
    }
    final i3 = _alphaNumValidator(upholsteryCtrl.text,
        fieldName: 'Upholstery', min: 2);
    if (i3 != null) {
      _snack(i3, 'warning');
      return false;
    }
    final i4 = _numberValidator(numberOfKeysCtrl.text,
        fieldName: 'Number of Keys', max: 1);
    if (i4 != null) {
      _snack(i4, 'warning');
      return false;
    }
    if (interiorModificationDone == null) {
      _snack('Interior Modification Done is required', 'warning');
      return false;
    }

    // Exterior
    final e1 = _alphaNumValidator(exteriorColorCtrl.text,
        fieldName: 'Exterior Color', min: 2);
    if (e1 != null) {
      _snack(e1, 'warning');
      return false;
    }
    final e2 = _numberValidator(doorsCtrl.text, fieldName: 'Doors', max: 1);
    if (e2 != null) {
      _snack(e2, 'warning');
      return false;
    }
    final e3 = _numberValidator(wheelSizeCtrl.text,
        fieldName: 'Wheel Size', max: 2);
    if (e3 != null) {
      _snack(e3, 'warning');
      return false;
    }
    if (exteriorModificationDone == null) {
      _snack('Exterior Modification Done is required', 'warning');
      return false;
    }

    return true;
  }

  Future<void> _submit() async {
    if (_submitting) return;

    // ✅ keep make/model synced before validation
    if (!_applyMakeModelToControllersNoNetwork()) return;

    if (!_validateReportData()) {
      _snack('Please fix the highlighted fields in report sections.', 'warning');
      return;
    }

    if (!_validateChecklist()) return;

    setState(() => _submitting = true);

    try {
      // ✅ If OTHER selected, store new make/model via API before submitting inspection
      final makeName = _makeIsOther
          ? otherMakeCtrl.text.trim().toUpperCase()
          : (selectedMake ?? '').trim().toUpperCase();

      final modelName = _modelIsOther
          ? otherModelCtrl.text.trim().toUpperCase()
          : (selectedModel ?? '').trim().toUpperCase();

      String? makeId = selectedMakeId;

      // 1) create make if OTHER (get id)
      if (_makeIsOther) {
        final createdId = await inspectionRequestsService.addVehicleMake(makeName);
        if (createdId != null && createdId.trim().isNotEmpty) {
          makeId = createdId.trim();
        } else {
          // try refresh + lookup
          await _loadMakes();
          makeId = _makeIdByName[makeName];
        }
      }

      // 2) create model if OTHER (needs makeId)
      if (_modelIsOther) {
        if (makeId == null || makeId.trim().isEmpty) {
          throw Exception('makeId missing for adding model');
        }
        await inspectionRequestsService.addVehicleModel(
          makeId: makeId.trim(),
          name: modelName,
        );
      }

      // ✅ finally write into controllers (what gets submitted)
      makeCtrl.text = makeName;
      modelCtrl.text = modelName;

      final t = _selectedTemplate!;

      final payload = {
        'checklistTemplateId': t.id,
        'inspectionRequestId': widget.requestId,
        'inspectionDate': DateTime.now().toIso8601String(),
        'status': 'draft',
        ..._buildReportPayload(),

        // ✅ NEW
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

  // ============================
  // VALIDATORS + FORMATTERS
  // ============================

  String? _req(String? v, {String msg = 'Required'}) {
    if (v == null) return msg;
    if (v.trim().isEmpty) return msg;
    return null;
  }

  String? _alphaNumValidator(String? v,
      {required String fieldName, int min = 2}) {
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

  String? _numberValidator(String? v,
      {required String fieldName, int max = 12}) {
    final r = _req(v, msg: '$fieldName is required');
    if (r != null) return r;
    final s = v!.trim();
    if (!RegExp(r'^\d+$').hasMatch(s)) return '$fieldName must be numeric';
    if (s.length > max) return '$fieldName is too long';
    return null;
  }

  List<TextInputFormatter> _freeTextFormatters({int max = 40}) => [
        LengthLimitingTextInputFormatter(max),
        FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z0-9\s'./-]")),
      ];

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
    final s =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
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

    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final mmmyy =
        '${months[picked.month - 1]}-${(picked.year % 100).toString().padLeft(2, '0')}'.toUpperCase();
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
    return DropdownButtonFormField<String>(
      value: value,
      autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
      items: options.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
      onChanged: onChanged,
      decoration: _dec(label: label, hint: hint, icon: icon),
      validator: validator,
    );
  }

  Widget _textFormField({
    required TextEditingController c,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    final fmts = <TextInputFormatter>[
      ...(inputFormatters ?? const <TextInputFormatter>[]),
      _upper,
    ];

    return TextFormField(
      controller: c,
      autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
      keyboardType: keyboardType,
      inputFormatters: fmts,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      decoration: _dec(label: label, hint: hint, icon: icon),
    );
  }

  // ============================
  // SECTIONS
  // ============================

  Widget _vehicleDetailsSection() {
    return _sectionCard(
      title: 'Vehicle Details',
      icon: Icons.directions_car_outlined,
      child: Form(
        key: _vehicleFormKey,
        child: Column(
          children: [
            // ✅ MAKE (API) + OTHER
            DropdownButtonFormField<String>(
              value: selectedMake,
              autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
              items: makes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: loadingMakes
                  ? null
                  : (v) async {
                      if (v == null) return;

                      // OTHER
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

                      // NORMAL make
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
              _textFormField(
                c: otherMakeCtrl,
                label: 'Other Make',
                hint: 'Enter make',
                icon: Icons.edit_outlined,
                inputFormatters: _freeTextFormatters(max: 40),
                validator: (v) => _alphaNumValidator(v, fieldName: 'Other Make', min: 2),
              ),
            ],

            const SizedBox(height: 12),

            // ✅ MODEL (API) + OTHER
            DropdownButtonFormField<String>(
              value: selectedModel,
              autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
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
                hint: selectedMake == null
                    ? 'Select make first'
                    : (loadingModels ? 'Loading models…' : 'Select model'),
                icon: Icons.car_repair_outlined,
              ),
              validator: (v) => v == null ? 'Model is required' : null,
            ),

            if (_modelIsOther) ...[
              const SizedBox(height: 12),
              _textFormField(
                c: otherModelCtrl,
                label: 'Other Model',
                hint: 'Enter model',
                icon: Icons.edit_outlined,
                inputFormatters: _freeTextFormatters(max: 40),
                validator: (v) => _alphaNumValidator(v, fieldName: 'Other Model', min: 2),
              ),
            ],

            const SizedBox(height: 12),

            _textFormField(
              c: gradeVariantCtrl,
              label: 'Grade / Variant',
              hint: 'e.g. XLE / LIMITED',
              icon: Icons.badge_outlined,
              inputFormatters: _freeTextFormatters(max: 40),
              validator: (v) => _alphaNumValidator(v, fieldName: 'Grade / Variant', min: 2),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _textFormField(
                    c: engineCapacityCtrl,
                    label: 'Engine Capacity',
                    hint: 'e.g. 2.0L',
                    icon: Icons.speed_outlined,
                    inputFormatters: _freeTextFormatters(max: 12),
                    validator: (v) => _alphaNumValidator(v, fieldName: 'Engine Capacity', min: 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textFormField(
                    c: modelYearCtrl,
                    label: 'Model Year',
                    hint: '2020',
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: _yearFormatters(),
                    validator: _yearValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _textFormField(
              c: cylinderSizeCtrl,
              label: 'Cylinder Size',
              hint: 'e.g. 6 CYLINDER',
              icon: Icons.settings_outlined,
              inputFormatters: _freeTextFormatters(max: 20),
              validator: (v) => _alphaNumValidator(v, fieldName: 'Cylinder Size', min: 1),
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
            _textFormField(
              c: driveTrainCtrl,
              label: 'Drive Train',
              hint: 'e.g. 4X4 / FWD',
              icon: Icons.grid_on_outlined,
              inputFormatters: _freeTextFormatters(max: 10),
              validator: (v) => _alphaNumValidator(v, fieldName: 'Drive Train', min: 1),
            ),
            const SizedBox(height: 12),
            _textFormField(
              c: specsCtrl,
              label: 'Specs',
              hint: 'e.g. GCC',
              icon: Icons.public_outlined,
              inputFormatters: _freeTextFormatters(max: 10),
              validator: (v) => _alphaNumValidator(v, fieldName: 'Specs', min: 1),
            ),
            const SizedBox(height: 12),
            _textFormField(
              c: odometerCtrl,
              label: 'Odometer Reading',
              hint: 'e.g. 156468',
              icon: Icons.av_timer_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: _digitsFormatters(max: 10),
              validator: (v) => _numberValidator(v, fieldName: 'Odometer Reading', max: 10),
            ),
            const SizedBox(height: 12),
            _textFormField(
              c: registrationNoCtrl,
              label: 'Registration No.',
              hint: 'e.g. ABC123',
              icon: Icons.confirmation_number_outlined,
              inputFormatters: _freeTextFormatters(max: 20),
              validator: (v) => _alphaNumValidator(v, fieldName: 'Registration No', min: 3),
            ),
            const SizedBox(height: 12),
            _textFormField(
              c: emiratesRegAtCtrl,
              label: 'Emirates Reg. At',
              hint: 'e.g. DUBAI',
              icon: Icons.location_city_outlined,
              inputFormatters: _freeTextFormatters(max: 20),
              validator: (v) => _alphaNumValidator(v, fieldName: 'Emirates Reg. At', min: 2),
            ),
            const SizedBox(height: 12),
            _textFormField(
              c: chassisNoCtrl,
              label: 'Chassis No.',
              hint: 'e.g. JH4KA9650MC000000',
              icon: Icons.numbers_outlined,
              inputFormatters: _freeTextFormatters(max: 25),
              validator: (v) => _alphaNumValidator(v, fieldName: 'Chassis No', min: 6),
            ),
            const SizedBox(height: 12),
            _textFormField(
              c: ownershipTypeCtrl,
              label: 'Ownership Type',
              hint: 'e.g. INDIVIDUAL / COMPANY',
              icon: Icons.person_outline,
              inputFormatters: _freeTextFormatters(max: 20),
              validator: (v) => _alphaNumValidator(v, fieldName: 'Ownership Type', min: 2),
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
            _textFormField(
              c: servicedWithCtrl,
              label: 'Serviced With',
              hint: 'AGENCY / THIRD PARTY',
              icon: Icons.build_outlined,
              inputFormatters: _freeTextFormatters(max: 40),
              validator: (v) => _alphaNumValidator(v, fieldName: 'Serviced With', min: 2),
            ),
            const SizedBox(height: 12),
            _textFormField(
              c: lastServiceDateCtrl,
              label: 'Last Service Date',
              hint: 'Select date',
              icon: Icons.date_range_outlined,
              readOnly: true,
              onTap: _pickLastServiceDate,
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
            _textFormField(
              c: warrantyEndsInCtrl,
              label: 'Warranty Ends In (Month/Year)',
              hint: 'Select month',
              icon: Icons.event_outlined,
              readOnly: true,
              onTap: _pickWarrantyEndsMonthYear,
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
            _textFormField(
              c: seatsCtrl,
              label: 'Seats',
              hint: 'e.g. 5',
              icon: Icons.event_seat_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: _digitsFormatters(max: 2),
              validator: (v) => _numberValidator(v, fieldName: 'Seats', max: 2),
            ),
            const SizedBox(height: 12),
            _textFormField(
              c: interiorColorCtrl,
              label: 'Interior Color',
              hint: 'e.g. BLACK',
              icon: Icons.palette_outlined,
              inputFormatters: _freeTextFormatters(max: 20),
              validator: (v) => _alphaNumValidator(v, fieldName: 'Interior Color', min: 2),
            ),
            const SizedBox(height: 12),
            _textFormField(
              c: upholsteryCtrl,
              label: 'Upholstery',
              hint: 'e.g. LEATHER / FABRIC',
              icon: Icons.texture_outlined,
              inputFormatters: _freeTextFormatters(max: 20),
              validator: (v) => _alphaNumValidator(v, fieldName: 'Upholstery', min: 2),
            ),
            const SizedBox(height: 12),
            _textFormField(
              c: numberOfKeysCtrl,
              label: 'Number of Keys',
              hint: 'e.g. 2',
              icon: Icons.key_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: _digitsFormatters(max: 1),
              validator: (v) => _numberValidator(v, fieldName: 'Number of Keys', max: 1),
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
            _textFormField(
              c: exteriorColorCtrl,
              label: 'Exterior Color',
              hint: 'e.g. WHITE',
              icon: Icons.palette_outlined,
              inputFormatters: _freeTextFormatters(max: 20),
              validator: (v) => _alphaNumValidator(v, fieldName: 'Exterior Color', min: 2),
            ),
            const SizedBox(height: 12),
            _textFormField(
              c: doorsCtrl,
              label: 'Doors',
              hint: 'e.g. 4',
              icon: Icons.door_front_door_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: _digitsFormatters(max: 1),
              validator: (v) => _numberValidator(v, fieldName: 'Doors', max: 1),
            ),
            const SizedBox(height: 12),
            _textFormField(
              c: wheelSizeCtrl,
              label: 'Wheel Size',
              hint: 'e.g. 20',
              icon: Icons.circle_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: _digitsFormatters(max: 2),
              validator: (v) => _numberValidator(v, fieldName: 'Wheel Size', max: 2),
            ),
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
                  onPressed: _damagedCoordinates.isEmpty
                      ? null
                      : () => setState(() => _damagedCoordinates = []),
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
              decoration: _dec(
                label: 'Overall Remarks',
                hint: 'Write overall remarks',
                icon: Icons.notes_outlined,
              ),
            ),
          if (type.allowOverallPhotos) ...[
            const SizedBox(height: 12),
            ImageUploader(
              typeName: type.typeName,
              inspectionRequestId: widget.requestId,
              title: 'Overall Photos',
              initialImages: _overallPhotos[ti] ?? const [],
              onChanged: (v) => setState(() => _overallPhotos[ti] = v),
            ),
          ],
          const SizedBox(height: 12),
          VideoUploader(
            typeName: type.typeName,
            inspectionRequestId: widget.requestId,
            title: 'Overall Videos (MP4)',
            initialVideos: _overallVideos[ti] ?? const [],
            onChanged: (v) => setState(() => _overallVideos[ti] = v),
          ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      if ((item.description ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(item.description!, style: const TextStyle(color: Colors.black54)),
                      ],
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _grade[key],
                        autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
                        items: _gradeOptions
                            .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                            .toList(),
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
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _remarks[key],
                        maxLines: 2,
                        inputFormatters: [LengthLimitingTextInputFormatter(200), _upper],
                        decoration: _dec(
                          label: 'Remarks',
                          hint: 'Write remarks',
                          icon: Icons.comment_outlined,
                        ),
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
    if (_section == 4) return _damagedCoordinatesSection();

    final ti = _section - 5;
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
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
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
                          onPressed: _startInspectionIfNeeded,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry start'),
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
                            const Text(
                              'Checklist Template:',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<ChecklistTemplate>(
                                  value: selected,
                                  isExpanded: true,
                                  items: templates
                                      .map((t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(t.name ?? t.id),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() {
                                      _selectedTemplate = v;
                                      _primeChecklistControllers();
                                      _section = 0;
                                    });
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
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                              Text(
                                'Section ${_section + 1} / $total',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w700,
                                ),
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
                                onPressed: _submitting ? null : _submit,
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
                                onPressed: () => _next(selected),
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('Next'),
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
}

