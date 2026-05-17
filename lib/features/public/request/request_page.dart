// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:go_router/go_router.dart';

// import '../../../services/service_locator.dart';
// import '../../shared/top_snackbar.dart';
// import '../widgets/public_navbar.dart';

// import 'package:flutter/services.dart' show rootBundle, FilteringTextInputFormatter, LengthLimitingTextInputFormatter, TextInputFormatter;



// class RequestPage extends StatefulWidget {
//   const RequestPage({super.key});

//   @override
//   State<RequestPage> createState() => _RequestPageState();
// }

// class _RequestPageState extends State<RequestPage> {
//   final _formKey = GlobalKey<FormState>();
//   bool _agreeTerms = false;


//   // Owner
//   final firstNameCtrl = TextEditingController();
//   final lastNameCtrl = TextEditingController();
//   final phoneCtrl = TextEditingController();
//   final emailCtrl = TextEditingController();

//   // Vehicle (keep controllers for payload compatibility)
//   final makeCtrl = TextEditingController();
//   final modelCtrl = TextEditingController();
//   final yearCtrl = TextEditingController();
//   final vinCtrl = TextEditingController();
//   final licensePlateCtrl = TextEditingController();
//   final mileageCtrl = TextEditingController();
//   final colorCtrl = TextEditingController();

//   // Preferred slot
//   DateTime? preferredDate;
//   final preferredTimeCtrl = TextEditingController(text: '10:00 AM');

//   // Location
//   final addressCtrl = TextEditingController();
//   final cityCtrl = TextEditingController();
//   final stateCtrl = TextEditingController();
//   final zipCtrl = TextEditingController();

//   // Notes
//   final notesCtrl = TextEditingController();

//   bool loading = false;

//   // Product type dropdown
//   // 'inspection' | 'inspection_and_valuation'
//   String _productType = 'inspection';

//   // ✅ Make/Model from LOCAL JSON
//   bool loadingMakes = false;
//   bool loadingModels = false;

//   // Make -> models map
//   final Map<String, List<String>> _catalog = {};

//   // Dropdown state
//   List<String> makes = [];
//   List<String> models = [];
//   String? selectedMake;
//   String? selectedModel;

//   @override
//   void initState() {
//     super.initState();
//     _loadCatalogFromAsset();
//   }

//   @override
//   void dispose() {
//     firstNameCtrl.dispose();
//     lastNameCtrl.dispose();
//     phoneCtrl.dispose();
//     emailCtrl.dispose();

//     makeCtrl.dispose();
//     modelCtrl.dispose();
//     yearCtrl.dispose();
//     vinCtrl.dispose();
//     licensePlateCtrl.dispose();
//     mileageCtrl.dispose();
//     colorCtrl.dispose();

//     preferredTimeCtrl.dispose();

//     addressCtrl.dispose();
//     cityCtrl.dispose();
//     stateCtrl.dispose();
//     zipCtrl.dispose();

//     notesCtrl.dispose();
//     super.dispose();
//   }

//   // -----------------------------
//   // ✅ Validators (helpers)
//   // -----------------------------

//   String? _req(String? v, {String msg = 'Required'}) {
//     if (v == null) return msg;
//     if (v.trim().isEmpty) return msg;
//     return null;
//   }

//   String? _nameValidator(String? v, {required String fieldName}) {
//     final r = _req(v, msg: '$fieldName is required');
//     if (r != null) return r;

//     final s = v!.trim();
//     if (s.length < 2) return '$fieldName must be at least 2 characters';
//     final ok = RegExp(r"^[A-Za-z\s'.-]+$").hasMatch(s);
//     if (!ok) return '$fieldName can contain only letters and spaces';
//     return null;
//   }

//   String? _emailValidator(String? v) {
//     final r = _req(v, msg: 'Email is required');
//     if (r != null) return r;

//     final s = v!.trim();
//     final ok = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$").hasMatch(s);
//     if (!ok) return 'Enter a valid email address';
//     return null;
//   }

//   String? _uaePhoneValidator(String? v) {
//     if (v == null || v.isEmpty) return 'Phone number is required';

//     if (!v.startsWith('+971')) {
//       return 'Phone must start with +971';
//     }

//     if (v.length != 13) {
//       return 'Phone must be +971 followed by 9 digits';
//     }

//     if (!RegExp(r'^\+971\d{9}$').hasMatch(v)) {
//       return 'Invalid UAE phone number';
//     }

//     return null;
//   }


//   String? _yearValidator(String? v) {
//     final r = _req(v, msg: 'Year is required');
//     if (r != null) return r;

//     final year = int.tryParse(v!.trim());
//     if (year == null) return 'Year must be a number';
//     final now = DateTime.now().year;
//     if (year < 1980 || year > now + 1) return 'Enter a valid year (1980 - ${now + 1})';
//     return null;
//   }

//   String? _vinValidator(String? v) {
//     final r = _req(v, msg: 'VIN is required');
//     if (r != null) return r;

//     final s = v!.trim().toUpperCase();
//     // VIN length normally 17; allow 11-17 to be tolerant
//     if (s.length < 11 || s.length > 17) return 'VIN should be 11 to 17 characters';
//     if (!RegExp(r"^[A-Z0-9]+$").hasMatch(s)) return 'VIN must be alphanumeric (no spaces)';
//     return null;
//   }

//   String? _plateValidator(String? v) {
//     final r = _req(v, msg: 'License plate is required');
//     if (r != null) return r;

//     final s = v!.trim().toUpperCase();
//     if (s.length < 3 || s.length > 10) return 'License plate should be 3 to 10 characters';
//     if (!RegExp(r"^[A-Z0-9\-]+$").hasMatch(s)) return 'Only letters, numbers and "-" allowed';
//     return null;
//   }

//   String? _mileageValidator(String? v) {
//     final r = _req(v, msg: 'Mileage is required');
//     if (r != null) return r;

//     final s = v!.trim();
//     final m = int.tryParse(s);
//     if (m == null) return 'Mileage must be a number';
//     if (m < 0 || m > 2000000) return 'Enter a valid mileage (0 - 2,000,000)';
//     return null;
//   }

//   String? _colorValidator(String? v) {
//     final r = _req(v, msg: 'Color is required');
//     if (r != null) return r;

//     final s = v!.trim();
//     if (!RegExp(r"^[A-Za-z\s]+$").hasMatch(s)) return 'Color can contain only letters and spaces';
//     return null;
//   }

//   String? _zipValidator(String? v) {
//     final r = _req(v, msg: 'Zip code is required');
//     if (r != null) return r;

//     final s = v!.trim();
//     if (s.length < 3 || s.length > 10) return 'Zip code should be 3 to 10 characters';
//     if (!RegExp(r"^[A-Za-z0-9\-]+$").hasMatch(s)) return 'Zip code can contain letters/numbers and "-"';
//     return null;
//   }

//   // -----------------------------
//   // ✅ Input formatters
//   // -----------------------------

//   List<TextInputFormatter> _nameFormatters({int max = 40}) => [
//     LengthLimitingTextInputFormatter(max),
//     FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s'.-]")),
//   ];

//   List<TextInputFormatter> _uaePhoneFormatters() => [
//     LengthLimitingTextInputFormatter(13), // +9715XXXXXXXX (13 chars)
//     FilteringTextInputFormatter.allow(RegExp(r"[0-9\+]")),
//   ];

//   List<TextInputFormatter> _yearFormatters() => [
//     LengthLimitingTextInputFormatter(4),
//     FilteringTextInputFormatter.digitsOnly,
//   ];

//   List<TextInputFormatter> _vinFormatters() => [
//     LengthLimitingTextInputFormatter(17),
//     FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z0-9]")),
//     // uppercase automatically happens in payload, but user input will be limited already
//   ];

//   List<TextInputFormatter> _plateFormatters() => [
//     LengthLimitingTextInputFormatter(7),
//     FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z0-9\-]")),
//   ];

//   List<TextInputFormatter> _mileageFormatters() => [
//     LengthLimitingTextInputFormatter(7), // up to 2000000
//     FilteringTextInputFormatter.digitsOnly,
//   ];

//   List<TextInputFormatter> _colorFormatters() => [
//     LengthLimitingTextInputFormatter(20),
//     FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s]")),
//   ];

//   List<TextInputFormatter> _zipFormatters() => [
//     LengthLimitingTextInputFormatter(10),
//     FilteringTextInputFormatter.allow(RegExp(r"[0-9\-]")),
//   ];

//   // -----------------------------
//   // ✅ Load catalog from asset JSON
//   // -----------------------------
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
//         final m = (item['models'] as List)
//             .map((e) => e.toString().trim())
//             .where((x) => x.isNotEmpty)
//             .toList();
//         if (name.isNotEmpty) _catalog[name] = m;
//       }

//       final makeList = _catalog.keys.toList()..sort();

//       if (!mounted) return;
//       setState(() => makes = makeList);
//     } catch (e) {
//       if (!mounted) return;
//       showTopSnack(context, 'Failed to load vehicle catalog JSON: $e', variant: 'error');
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

//     await Future<void>.delayed(const Duration(milliseconds: 50));

//     final list = (_catalog[make] ?? []).toList()..sort();

//     if (!mounted) return;
//     setState(() {
//       models = list;
//       loadingModels = false;
//     });
//   }

//   // -----------------------------
//   // Existing type resolve helpers
//   // -----------------------------

//   String _resolveType(BuildContext context) {
//     try {
//       final uri = GoRouterState.of(context).uri;
//       final t = uri.queryParameters['type'];
//       if (t != null && t.isNotEmpty) return t;
//     } catch (_) {}

//     final frag = Uri.base.fragment;
//     final qIndex = frag.indexOf('?');
//     if (qIndex != -1) {
//       final qp = Uri.splitQueryString(frag.substring(qIndex + 1));
//       final t = qp['type'];
//       if (t != null && t.isNotEmpty) return t;
//     }
//     return 'inspection';
//   }

//   String _normalizeToProductType(String type) {
//     final t = type.toLowerCase();
//     if (t.contains('valuation') || t.contains('inspection_and_valuation')) {
//       return 'inspection_and_valuation';
//     }
//     return 'inspection';
//   }

//   String _toUrlType(String productType) {
//     return productType == 'inspection_and_valuation' ? 'inspection_and_valuation' : 'inspection';
//   }

//   String _requestTypeForApi(String type) {
//     final pt = _normalizeToProductType(type);
//     if (pt == 'inspection_and_valuation') return 'car inspection and valuation';
//     return 'car inspection';
//   }

//   String _labelFor(String type) {
//     final pt = _normalizeToProductType(type);
//     if (pt == 'inspection_and_valuation') return 'Inspection and Valuation';
//     return 'Inspection';
//   }

//   IconData _iconFor(String type) => Icons.fact_check;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final typeFromUrl = _resolveType(context);
//     final normalized = _normalizeToProductType(typeFromUrl);
//     if (_productType != normalized) {
//       setState(() => _productType = normalized);
//     }
//   }

//   Future<void> _pickDate() async {
//     final now = DateTime.now();
//     final initial = preferredDate ?? now.add(const Duration(days: 1));
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: initial,
//       firstDate: now.subtract(const Duration(days: 0)),
//       lastDate: now.add(const Duration(days: 365)),
//     );
//     if (picked == null) return;
//     setState(() => preferredDate = DateTime(picked.year, picked.month, picked.day));
//   }

//   Future<void> _submit(String type) async {
//     final valid = _formKey.currentState?.validate() ?? false;
//     if (!valid) {
//       showTopSnack(context, 'Please fix the highlighted fields.', variant: 'warning');
//       return;
//     }

//     if (preferredDate == null) {
//       showTopSnack(context, 'Please select preferred date.', variant: 'warning');
//       return;
//     }

//     setState(() => loading = true);

//     try {
//       final year = int.parse(yearCtrl.text.trim());
//       final mileage = int.parse(mileageCtrl.text.trim());
//       final preferredDateIso = preferredDate!.toUtc().toIso8601String();

//       final payload = {
//         "email": emailCtrl.text.trim().toLowerCase(),
//         "firstName": firstNameCtrl.text.trim(),
//         "lastName": lastNameCtrl.text.trim(),
//         "phone": phoneCtrl.text.trim().replaceAll(' ', ''),
//         "requestType": _requestTypeForApi(type),
//         "vehicleInfo": {
//           "make": makeCtrl.text.trim(),
//           "model": modelCtrl.text.trim(),
//           "year": year,
//           "vin": vinCtrl.text.trim().toUpperCase(),
//           "licensePlate": licensePlateCtrl.text.trim().toUpperCase(),
//           "mileage": mileage,
//           "color": colorCtrl.text.trim(),
//         },
//         "preferredDate": preferredDateIso,
//         "preferredTime": preferredTimeCtrl.text.trim(),
//         "location": {
//           "address": addressCtrl.text.trim(),
//           "city": cityCtrl.text.trim(),
//           "state": stateCtrl.text.trim(),
//           "zipCode": zipCtrl.text.trim(),
//         },
//         "notes": notesCtrl.text.trim(),
//       };

//       await apiClient.postJson('/inspection-requests', payload);

//       if (!mounted) return;
//       showTopSnack(context, 'Request submitted successfully', variant: 'success');
//       context.go('/products');
//     } catch (e) {
//       if (!mounted) return;
//       showTopSnack(context, 'Submit failed: $e', variant: 'error');
//     } finally {
//       if (mounted) setState(() => loading = false);
//     }
//   }

//   InputDecoration _dec({
//     required String label,
//     String? hint,
//     required IconData icon,
//   }) {
//     return InputDecoration(
//       labelText: label,
//       hintText: hint,
//       prefixIcon: Icon(icon),
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

//   Widget _sectionTitle(String title, {IconData? icon}) {
//     return Row(
//       children: [
//         if (icon != null) ...[
//           Icon(icon, size: 18, color: Colors.black87),
//           const SizedBox(width: 8),
//         ],
//         Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
//       ],
//     );
//   }

//   Widget _productTypeDropdown(double width) {
//     return SizedBox(
//       width: width,
//       child: DropdownButtonFormField<String>(
//         value: _productType,
//         decoration: _dec(label: 'Service Type', hint: 'Select Service type', icon: Icons.shopping_bag_outlined),
//         items: const [
//           DropdownMenuItem(value: 'inspection', child: Text('Inspection')),
//           DropdownMenuItem(value: 'inspection_and_valuation', child: Text('Inspection and Valuation')),
//         ],
//         onChanged: (v) {
//           if (v == null) return;
//           setState(() => _productType = v);
//           final newType = _toUrlType(v);
//           context.go('/request?type=$newType');
//         },
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final type = _toUrlType(_productType);

//     return Scaffold(
//       appBar: const PublicNavBar(),
//       body: SingleChildScrollView(
//         child: Center(
//           child: ConstrainedBox(
//             constraints: const BoxConstraints(maxWidth: 1040),
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Container(
//                         height: 46,
//                         width: 46,
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF0B1220),
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: Icon(_iconFor(type), color: Colors.white),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               "Request Vehicle Inspection Service",
//                               style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
//                             ),
//                             const SizedBox(height: 6),
//                             Wrap(
//                               spacing: 10,
//                               runSpacing: 8,
//                               children: [
//                                 _Pill(icon: _iconFor(type), text: 'Service: ${_labelFor(type)}'),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),

//                   Container(
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF4F6FB),
//                       borderRadius: BorderRadius.circular(22),
//                       border: Border.all(color: Colors.black.withOpacity(0.06)),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.06),
//                           blurRadius: 24,
//                           offset: const Offset(0, 12),
//                         )
//                       ],
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(18),
//                       child: Form(
//                         key: _formKey,
//                         child: LayoutBuilder(
//                           builder: (context, c) {
//                             final isWide = c.maxWidth >= 820;
//                             final w = c.maxWidth;
//                             final gap = 14.0;
//                             final fieldW = isWide ? (w - gap) / 2 : w;

//                             Widget field(Widget child) => SizedBox(width: fieldW, child: child);

//                             return Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 _sectionTitle('Service', icon: Icons.shopping_bag_outlined),
//                                 const SizedBox(height: 10),
//                                 _productTypeDropdown(fieldW),
//                                 const SizedBox(height: 18),
//                                 Divider(color: Colors.black.withOpacity(0.08)),
//                                 const SizedBox(height: 18),

//                                 _sectionTitle('Owner Details', icon: Icons.person_outline),
//                                 const SizedBox(height: 10),
//                                 Wrap(
//                                   spacing: gap,
//                                   runSpacing: gap,
//                                   children: [
//                                     field(TextFormField(
//                                       controller: firstNameCtrl,
//                                       inputFormatters: _nameFormatters(),
//                                       decoration: _dec(label: 'First Name', hint: 'John', icon: Icons.person_outline),
//                                       validator: (v) => _nameValidator(v, fieldName: 'First name'),
//                                     )),
//                                     field(TextFormField(
//                                       controller: lastNameCtrl,
//                                       inputFormatters: _nameFormatters(),
//                                       decoration: _dec(label: 'Last Name', hint: 'Doe', icon: Icons.person_outline),
//                                       validator: (v) => _nameValidator(v, fieldName: 'Last name'),
//                                     )),
//                                     field(TextFormField(
//                                       controller: phoneCtrl,
//                                       keyboardType: TextInputType.phone,
//                                       decoration: _dec(
//                                         label: 'Phone',
//                                         hint: '+9715XXXXXXXX',
//                                         icon: Icons.phone_outlined,
//                                       ),
//                                       inputFormatters: [
//                                         UaEPhoneInputFormatter(),
//                                       ],
//                                       validator: _uaePhoneValidator,
//                                       onTap: () {
//                                         // Auto insert prefix if field is empty
//                                         if (phoneCtrl.text.isEmpty) {
//                                           phoneCtrl.text = '+971';
//                                           phoneCtrl.selection =
//                                               TextSelection.collapsed(offset: phoneCtrl.text.length);
//                                         }
//                                       },
//                                     )),
//                                     field(TextFormField(
//                                       controller: emailCtrl,
//                                       keyboardType: TextInputType.emailAddress,
//                                       decoration: _dec(label: 'Email', hint: 'you@example.com', icon: Icons.email_outlined),
//                                       validator: _emailValidator,
//                                     )),
//                                   ],
//                                 ),

//                                 const SizedBox(height: 18),
//                                 Divider(color: Colors.black.withOpacity(0.08)),
//                                 const SizedBox(height: 18),

//                                 _sectionTitle('Vehicle Info', icon: Icons.directions_car_outlined),
//                                 const SizedBox(height: 10),
//                                 Wrap(
//                                   spacing: gap,
//                                   runSpacing: gap,
//                                   children: [
//                                     field(
//                                       DropdownButtonFormField<String>(
//                                         value: selectedMake,
//                                         items: makes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
//                                         onChanged: loadingMakes
//                                             ? null
//                                             : (v) async {
//                                                 if (v == null) return;
//                                                 setState(() {
//                                                   selectedMake = v;
//                                                   makeCtrl.text = v;
//                                                   selectedModel = null;
//                                                   modelCtrl.text = '';
//                                                   models = [];
//                                                 });
//                                                 await _loadModelsForMakeLocal(v);
//                                               },
//                                         decoration: _dec(
//                                           label: 'Make',
//                                           hint: loadingMakes ? 'Loading makes…' : 'Select make',
//                                           icon: Icons.directions_car_outlined,
//                                         ),
//                                         validator: (v) => v == null ? 'Make is required' : null,
//                                       ),
//                                     ),
//                                     field(
//                                       DropdownButtonFormField<String>(
//                                         value: selectedModel,
//                                         items: models.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
//                                         onChanged: (selectedMake == null || loadingModels)
//                                             ? null
//                                             : (v) {
//                                                 if (v == null) return;
//                                                 setState(() {
//                                                   selectedModel = v;
//                                                   modelCtrl.text = v;
//                                                 });
//                                               },
//                                         decoration: _dec(
//                                           label: 'Model',
//                                           hint: selectedMake == null
//                                               ? 'Select make first'
//                                               : (loadingModels ? 'Loading models…' : 'Select model'),
//                                           icon: Icons.car_repair_outlined,
//                                         ),
//                                         validator: (v) => v == null ? 'Model is required' : null,
//                                       ),
//                                     ),

//                                     // field(TextFormField(
//                                     //   controller: yearCtrl,
//                                     //   keyboardType: TextInputType.number,
//                                     //   inputFormatters: _yearFormatters(),
//                                     //   decoration: _dec(label: 'Year', hint: '2020', icon: Icons.calendar_today_outlined),
//                                     //   validator: _yearValidator,
//                                     // )),
//                                     // field(TextFormField(
//                                     //   controller: vinCtrl,
//                                     //   inputFormatters: _vinFormatters(),
//                                     //   decoration: _dec(label: 'VIN', hint: '4T1BF1FK5EU123456', icon: Icons.numbers_outlined),
//                                     //   validator: _vinValidator,
//                                     // )),
//                                     // field(TextFormField(
//                                     //   controller: licensePlateCtrl,
//                                     //   inputFormatters: _plateFormatters(),
//                                     //   decoration: _dec(label: 'License Plate', hint: 'ABC123', icon: Icons.confirmation_number_outlined),
//                                     //   validator: _plateValidator,
//                                     // )),
//                                     // field(TextFormField(
//                                     //   controller: mileageCtrl,
//                                     //   keyboardType: TextInputType.number,
//                                     //   inputFormatters: _mileageFormatters(),
//                                     //   decoration: _dec(label: 'Mileage', hint: '50000', icon: Icons.speed_outlined),
//                                     //   validator: _mileageValidator,
//                                     // )),
//                                     // field(TextFormField(
//                                     //   controller: colorCtrl,
//                                     //   inputFormatters: _colorFormatters(),
//                                     //   decoration: _dec(label: 'Color', hint: 'Silver', icon: Icons.palette_outlined),
//                                     //   validator: _colorValidator,
//                                     // )),
//                                   ],
//                                 ),

//                                 const SizedBox(height: 18),
//                                 Divider(color: Colors.black.withOpacity(0.08)),
//                                 const SizedBox(height: 18),

//                                 _sectionTitle('Preferred Slot', icon: Icons.event_available_outlined),
//                                 const SizedBox(height: 10),
//                                 Wrap(
//                                   spacing: gap,
//                                   runSpacing: gap,
//                                   children: [
//                                     SizedBox(
//                                       width: fieldW,
//                                       child: InkWell(
//                                         onTap: _pickDate,
//                                         borderRadius: BorderRadius.circular(14),
//                                         child: InputDecorator(
//                                           decoration: _dec(
//                                             label: 'Preferred Date',
//                                             hint: 'Select date',
//                                             icon: Icons.date_range_outlined,
//                                           ),
//                                           child: Text(
//                                             preferredDate == null
//                                                 ? 'Select date'
//                                                 : '${preferredDate!.year}-${preferredDate!.month.toString().padLeft(2, '0')}-${preferredDate!.day.toString().padLeft(2, '0')}',
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     field(DropdownButtonFormField<String>(
//                                       value: preferredTimeCtrl.text,
//                                       items: const [
//                                         '09:00 AM',
//                                         '10:00 AM',
//                                         '11:00 AM',
//                                         '12:00 PM',
//                                         '01:00 PM',
//                                         '02:00 PM',
//                                         '03:00 PM',
//                                         '04:00 PM',
//                                         '05:00 PM',
//                                         '06:00 PM',
//                                         '07:00 PM',
//                                       ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
//                                       onChanged: (v) {
//                                         if (v == null) return;
//                                         setState(() => preferredTimeCtrl.text = v);
//                                       },
//                                       decoration: _dec(label: 'Preferred Time', hint: 'Select time', icon: Icons.schedule_outlined),
//                                     )),
//                                   ],
//                                 ),

//                                 const SizedBox(height: 18),
//                                 Divider(color: Colors.black.withOpacity(0.08)),
//                                 const SizedBox(height: 18),

//                                 _sectionTitle('Location', icon: Icons.location_on_outlined),
//                                 const SizedBox(height: 10),
//                                 Wrap(
//                                   spacing: gap,
//                                   runSpacing: gap,
//                                   children: [
//                                     field(TextFormField(
//                                       controller: addressCtrl,
//                                       inputFormatters: [LengthLimitingTextInputFormatter(80)],
//                                       decoration: _dec(label: 'Address', hint: '123 Main Street', icon: Icons.home_outlined),
//                                       validator: (v) => _req(v, msg: 'Address is required'),
//                                     )),
//                                     field(TextFormField(
//                                       controller: cityCtrl,
//                                       inputFormatters: _nameFormatters(max: 30),
//                                       decoration: _dec(label: 'City', hint: 'Dubai', icon: Icons.location_city_outlined),
//                                       validator: (v) => _req(v, msg: 'City is required'),
//                                     )),
//                                     field(TextFormField(
//                                       controller: stateCtrl,
//                                       inputFormatters: _nameFormatters(max: 30),
//                                       decoration: _dec(label: 'State', hint: 'UAE', icon: Icons.map_outlined),
//                                       validator: (v) => _req(v, msg: 'State is required'),
//                                     )),
//                                     field(TextFormField(
//                                       controller: zipCtrl,
//                                       inputFormatters: _zipFormatters(),
//                                       decoration: _dec(label: 'Zip Code', hint: '00000', icon: Icons.local_post_office_outlined),
//                                       validator: _zipValidator,
//                                     )),
//                                   ],
//                                 ),

//                                 const SizedBox(height: 18),
//                                 Divider(color: Colors.black.withOpacity(0.08)),
//                                 const SizedBox(height: 18),

//                                 _sectionTitle('Notes', icon: Icons.notes_outlined),
//                                 const SizedBox(height: 10),
//                                 TextFormField(
//                                   controller: notesCtrl,
//                                   maxLines: 4,
//                                   decoration: _dec(label: 'Notes', hint: 'Any special instructions...', icon: Icons.notes_outlined),
//                                 ),

//                                 const SizedBox(height: 18),

//                                 Container(
//                                   width: double.infinity,
//                                   padding: const EdgeInsets.all(14),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     borderRadius: BorderRadius.circular(18),
//                                     border: Border.all(color: Colors.black.withOpacity(0.08)),
//                                   ),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       const Text(
//                                         'By submitting, you confirm the details are accurate.',
//                                         style: TextStyle(color: Colors.black54),
//                                       ),
//                                       const SizedBox(height: 12),
//                                       SizedBox(
//                                         width: double.infinity,
//                                         height: 48,
//                                         child: FilledButton.icon(
//                                           onPressed: loading ? null : () => _submit(type),
//                                           icon: const Icon(Icons.send),
//                                           label: Text(loading ? 'Submitting…' : 'Submit Request'),
//                                         ),
//                                       ),
//                                       const SizedBox(height: 10),
//                                       TextButton.icon(
//                                         onPressed: () => context.go('/products'),
//                                         icon: const Icon(Icons.arrow_back),
//                                         label: const Text('Back to Services'),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _Pill extends StatelessWidget {
//   final IconData icon;
//   final String text;

//   const _Pill({required this.icon, required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: Colors.black.withOpacity(0.10)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 16, color: Colors.black87),
//           const SizedBox(width: 8),
//           Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
//         ],
//       ),
//     );
//   }
// }

// class UaEPhoneInputFormatter extends TextInputFormatter {
//   static const String prefix = '+971';

//   @override
//   TextEditingValue formatEditUpdate(
//     TextEditingValue oldValue,
//     TextEditingValue newValue,
//   ) {
//     // Always keep prefix
//     if (!newValue.text.startsWith(prefix)) {
//       return TextEditingValue(
//         text: prefix,
//         selection: TextSelection.collapsed(offset: prefix.length),
//       );
//     }

//     // Allow only + and digits
//     final filtered = newValue.text.replaceAll(RegExp(r'[^0-9+]'), '');

//     // Max length = 13 characters (+971 + 9 digits)
//     final truncated =
//         filtered.length > 13 ? filtered.substring(0, 13) : filtered;

//     return TextEditingValue(
//       text: truncated,
//       selection: TextSelection.collapsed(offset: truncated.length),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show
        FilteringTextInputFormatter,
        LengthLimitingTextInputFormatter,
        TextInputFormatter;
import 'package:go_router/go_router.dart';

import '../../../services/service_locator.dart';
import '../../shared/top_snackbar.dart';
import '../widgets/public_navbar.dart';

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

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final _formKey = GlobalKey<FormState>();

  // ✅ Terms checkbox
  bool _agreeTerms = false;

  // ✅ NEW: optional reason dropdown
  // null | 'sell' | 'purchase'
  String? _reason;

  // Owner
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();

  // Vehicle (keep controllers for payload compatibility)
  final makeCtrl = TextEditingController();
  final modelCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
  final vinCtrl = TextEditingController();
  final licensePlateCtrl = TextEditingController();
  final mileageCtrl = TextEditingController();
  final colorCtrl = TextEditingController();

  // Preferred slot
  DateTime? preferredDate;
  final preferredTimeCtrl = TextEditingController(text: '10:00 AM');

  // Location
  final addressCtrl = TextEditingController();
  String? selectedCity;
  bool _cityIsOther = false;
  final otherCityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();

  // Notes
  final notesCtrl = TextEditingController();

  bool loading = false;

  // Product type dropdown
  // 'inspection' | 'inspection_and_valuation'
  String _productType = 'inspection';

  // ✅ Make/Model from API (same style as StartInspection)
  bool loadingMakes = false;
  bool loadingModels = false;

  // what user sees
  List<String> makes = [];
  List<String> models = [];

  String? selectedMake; // MAKE NAME (UPPERCASE)
  String? selectedMakeId; // MAKE ID (backend)
  String? selectedModel; // MODEL NAME (UPPERCASE)

  // mapping MAKE_NAME -> makeId
  final Map<String, String> _makeIdByName = {};

  bool _makeIsOther = false;
  bool _modelIsOther = false;
  final otherMakeCtrl = TextEditingController();
  final otherModelCtrl = TextEditingController();

  // ✅ Uppercase formatter
  final _upper = UpperCaseTextFormatter();

  @override
  void initState() {
    super.initState();

    // ✅ Load makes from API once
    _loadMakes();

    if (phoneCtrl.text.isEmpty) phoneCtrl.text = UaEPhoneInputFormatter.prefix;
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();

    makeCtrl.dispose();
    modelCtrl.dispose();
    yearCtrl.dispose();
    vinCtrl.dispose();
    licensePlateCtrl.dispose();
    mileageCtrl.dispose();
    colorCtrl.dispose();

    preferredTimeCtrl.dispose();

    addressCtrl.dispose();
    stateCtrl.dispose();

    notesCtrl.dispose();

    otherMakeCtrl.dispose();
    otherModelCtrl.dispose();
    otherCityCtrl.dispose();

    super.dispose();
  }

  // -----------------------------
  // ✅ Terms dialog
  // -----------------------------
  void _showTermsDialog(String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: const SingleChildScrollView(
          child: Text(
            '''
Dummy Privacy Policy

1. We store your submitted details securely.
2. We do not sell your data to third parties.
3. Your data is used only to respond to your request.

Dummy Terms & Conditions

1. This request is for contacting Auto Scope.
2. Please provide accurate information.
3. We may contact you using the email/phone you submit.
4. Misuse/spam submissions may be ignored.
''',
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // ✅ Validators (helpers)
  // -----------------------------
  String? _req(String? v, {String msg = 'Required'}) {
    if (v == null) return msg;
    if (v.trim().isEmpty) return msg;
    return null;
  }

  String? _nameValidator(String? v, {required String fieldName}) {
    final r = _req(v, msg: '$fieldName is required');
    if (r != null) return r;

    final s = v!.trim();
    if (s.length < 2) return '$fieldName must be at least 2 characters';
    final ok = RegExp(r"^[A-Za-z\s'.-]+$").hasMatch(s);
    if (!ok) return '$fieldName can contain only letters and spaces';
    return null;
  }

  // ✅ UPDATED: basic validation that allows ONLY .com or .in
  String? _emailValidator(String? v) {
    final r = _req(v, msg: 'Email is required');
    if (r != null) return r;

    final s = v!.trim();
    final ok = RegExp(
      r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.(com|in)$',
      caseSensitive: false,
    ).hasMatch(s);

    if (!ok) {
      return 'Enter a valid email like name@domain.com or name@domain.in';
    }
    return null;
  }

  String? _uaePhoneValidator(String? v) {
    if (v == null || v.isEmpty) return 'Phone number is required';

    if (!v.startsWith('+971')) {
      return 'Phone must start with +971';
    }

    if (v.length != 13) {
      return 'Phone must be +971 followed by 9 digits';
    }

    if (!RegExp(r'^\+971\d{9}$').hasMatch(v)) {
      return 'Invalid UAE phone number';
    }

    return null;
  }

  String? _yearValidator(String? v) {
    final r = _req(v, msg: 'Year is required');
    if (r != null) return r;

    final year = int.tryParse(v!.trim());
    if (year == null) return 'Year must be a number';
    final now = DateTime.now().year;
    if (year < 1980 || year > now + 1) {
      return 'Enter a valid year (1980 - ${now + 1})';
    }
    return null;
  }

  String? _vinValidator(String? v) {
    final r = _req(v, msg: 'VIN is required');
    if (r != null) return r;

    final s = v!.trim().toUpperCase();
    if (s.length < 11 || s.length > 17) return 'VIN should be 11 to 17 characters';
    if (!RegExp(r"^[A-Z0-9]+$").hasMatch(s)) return 'VIN must be alphanumeric (no spaces)';
    return null;
  }

  String? _plateValidator(String? v) {
    final r = _req(v, msg: 'License plate is required');
    if (r != null) return r;

    final s = v!.trim().toUpperCase();
    if (s.length < 3 || s.length > 10) return 'License plate should be 3 to 10 characters';
    if (!RegExp(r"^[A-Z0-9\-]+$").hasMatch(s)) return 'Only letters, numbers and "-" allowed';
    return null;
  }

  String? _mileageValidator(String? v) {
    final r = _req(v, msg: 'Mileage is required');
    if (r != null) return r;

    final s = v!.trim();
    final m = int.tryParse(s);
    if (m == null) return 'Mileage must be a number';
    if (m < 0 || m > 2000000) return 'Enter a valid mileage (0 - 2,000,000)';
    return null;
  }

  String? _colorValidator(String? v) {
    final r = _req(v, msg: 'Color is required');
    if (r != null) return r;

    final s = v!.trim();
    if (!RegExp(r"^[A-Za-z\s]+$").hasMatch(s)) return 'Color can contain only letters and spaces';
    return null;
  }

  // ✅ for make/model OTHER textboxes (allow A4, X-TRAIL, etc.)
  String? _vehicleTextValidator(String? v, {required String fieldName, int min = 2}) {
    final r = _req(v, msg: '$fieldName is required');
    if (r != null) return r;

    final s = v!.trim();
    if (s.length < min) return '$fieldName must be at least $min characters';
    if (!RegExp(r"^[A-Za-z0-9\s'./-]+$").hasMatch(s)) {
      return '$fieldName contains invalid characters';
    }
    return null;
  }

  // -----------------------------
  // ✅ Input formatters
  // -----------------------------
  List<TextInputFormatter> _nameFormatters({int max = 40}) => [
        LengthLimitingTextInputFormatter(max),
        FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s'.-]")),
        _upper,
      ];

  List<TextInputFormatter> _yearFormatters() => [
        LengthLimitingTextInputFormatter(4),
        FilteringTextInputFormatter.digitsOnly,
        _upper,
      ];

  List<TextInputFormatter> _vinFormatters() => [
        LengthLimitingTextInputFormatter(17),
        FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z0-9]")),
        _upper,
      ];

  List<TextInputFormatter> _plateFormatters() => [
        LengthLimitingTextInputFormatter(7),
        FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z0-9\-]")),
        _upper,
      ];

  List<TextInputFormatter> _mileageFormatters() => [
        LengthLimitingTextInputFormatter(7),
        FilteringTextInputFormatter.digitsOnly,
        _upper,
      ];

  List<TextInputFormatter> _colorFormatters() => [
        LengthLimitingTextInputFormatter(20),
        FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s]")),
        _upper,
      ];

  List<TextInputFormatter> _vehicleFreeTextFormatters({int max = 40}) => [
        LengthLimitingTextInputFormatter(max),
        FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z0-9\s'./-]")),
        _upper,
      ];

  // -----------------------------
  // ✅ MAKE / MODEL API (same approach as StartInspection)
  // -----------------------------
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
      showTopSnack(context, 'Failed to load makes (API): $e', variant: 'error');
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
      showTopSnack(context, 'Failed to load models (API): $e', variant: 'error');
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
      showTopSnack(context, 'Make is required', variant: 'warning');
      return false;
    }

    final makeErr = _vehicleTextValidator(make, fieldName: 'Make', min: 2);
    if (makeErr != null) {
      showTopSnack(context, makeErr, variant: 'warning');
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
      showTopSnack(context, 'Model is required', variant: 'warning');
      return false;
    }

    final modelErr = _vehicleTextValidator(model, fieldName: 'Model', min: 1);
    if (modelErr != null) {
      showTopSnack(context, modelErr, variant: 'warning');
      return false;
    }

    makeCtrl.text = make;
    modelCtrl.text = model;
    return true;
  }

  // -----------------------------
  // Existing type resolve helpers
  // -----------------------------
  String _resolveType(BuildContext context) {
    try {
      final uri = GoRouterState.of(context).uri;
      final t = uri.queryParameters['type'];
      if (t != null && t.isNotEmpty) return t;
    } catch (_) {}

    final frag = Uri.base.fragment;
    final qIndex = frag.indexOf('?');
    if (qIndex != -1) {
      final qp = Uri.splitQueryString(frag.substring(qIndex + 1));
      final t = qp['type'];
      if (t != null && t.isNotEmpty) return t;
    }
    return 'inspection';
  }

  String _normalizeToProductType(String type) {
    final t = type.toLowerCase();
    if (t.contains('valuation') || t.contains('inspection_and_valuation')) {
      return 'inspection_and_valuation';
    }
    return 'inspection';
  }

  String _toUrlType(String productType) {
    return productType == 'inspection_and_valuation'
        ? 'inspection_and_valuation'
        : 'inspection';
  }

  String _requestTypeForApi(String type) {
    final pt = _normalizeToProductType(type);
    if (pt == 'inspection_and_valuation') return 'car valuation';
    return 'car inspection';
  }

  String _labelFor(String type) {
    final pt = _normalizeToProductType(type);
    if (pt == 'inspection_and_valuation') return 'Inspection and Valuation';
    return 'Inspection';
  }

  IconData _iconFor(String type) => Icons.fact_check;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final typeFromUrl = _resolveType(context);
    final normalized = _normalizeToProductType(typeFromUrl);
    if (_productType != normalized) {
      setState(() => _productType = normalized);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = preferredDate ?? now.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 0)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => preferredDate = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _submit(String type) async {
    // ✅ keep make/model synced before validation
    if (!_applyMakeModelToControllersNoNetwork()) return;

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      showTopSnack(context, 'Please fix the highlighted fields.', variant: 'warning');
      return;
    }

    if (preferredDate == null) {
      showTopSnack(context, 'Please select preferred date.', variant: 'warning');
      return;
    }

    if (!_agreeTerms) {
      showTopSnack(context, 'Please accept Privacy Policy & Terms and Conditions.',
          variant: 'warning');
      return;
    }

    setState(() => loading = true);

    try {
      final preferredDateIso = preferredDate!.toUtc().toIso8601String();

      final payload = {
        "email": emailCtrl.text.trim().toLowerCase(),
        "firstName": firstNameCtrl.text.trim(),
        "lastName": lastNameCtrl.text.trim(),
        "phone": phoneCtrl.text.trim().replaceAll(' ', ''),
        "requestType": _requestTypeForApi(type),

        // ✅ NEW: optional reason
        if (_reason != null && _reason!.trim().isNotEmpty) "reason": _reason,

        "vehicleInfo": {
          "make": makeCtrl.text.trim(),
          "model": modelCtrl.text.trim(),
        },
        "preferredDate": preferredDateIso,
        "preferredTime": preferredTimeCtrl.text.trim(),
        "location": {
          "address": addressCtrl.text.trim(),
          "city": _cityIsOther ? otherCityCtrl.text.trim() : (selectedCity ?? ''),
          "state": stateCtrl.text.trim(),
        },
        "notes": notesCtrl.text.trim(),
      };

      await apiClient.postJson('/inspection-requests', payload);

      if (!mounted) return;
      showTopSnack(context, 'Request submitted successfully', variant: 'success');
      context.go('/products');
    } catch (e) {
      if (!mounted) return;
      showTopSnack(context, 'Submit failed: $e', variant: 'error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  InputDecoration _dec({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
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

  Widget _sectionTitle(String title, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(width: 8),
        ],
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ],
    );
  }

  Widget _productTypeDropdown(double width) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: _productType,
        autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
        decoration: _dec(
          label: 'Service Type',
          hint: 'Select Service type',
          icon: Icons.shopping_bag_outlined,
        ),
        items: const [
          DropdownMenuItem(value: 'inspection', child: Text('Inspection')),
          DropdownMenuItem(
              value: 'inspection_and_valuation',
              child: Text('Inspection and Valuation')),
        ],
        onChanged: (v) {
          if (v == null) return;
          setState(() => _productType = v);
          final newType = _toUrlType(v);
          context.go('/request?type=$newType');
        },
      ),
    );
  }

  // ✅ NEW reason dropdown (optional)
  Widget _reasonDropdown(double width) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: _reason,
        autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
        decoration: _dec(
          label: 'Reason (optional)',
          hint: 'Select reason',
          icon: Icons.help_outline,
        ),
        items: const [
          DropdownMenuItem(value: 'sell', child: Text('Sell')),
          DropdownMenuItem(value: 'purchase', child: Text('Purchase')),
        ],
        onChanged: (v) => setState(() => _reason = v),
        validator: (_) => null, // optional
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = _toUrlType(_productType);

    return Scaffold(
      appBar: const PublicNavBar(),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1220),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(_iconFor(type), color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Request Vehicle Inspection Service",
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                _Pill(
                                  icon: _iconFor(type),
                                  text: 'Service: ${_labelFor(type)}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6FB),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Form(
                        key: _formKey,
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final isWide = c.maxWidth >= 820;
                            final w = c.maxWidth;
                            final gap = 14.0;
                            final fieldW = isWide ? (w - gap) / 2 : w;

                            Widget field(Widget child) =>
                                SizedBox(width: fieldW, child: child);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle('Service',
                                    icon: Icons.shopping_bag_outlined),
                                const SizedBox(height: 10),

                                // two fields side-by-side on wide screens
                                Wrap(
                                  spacing: gap,
                                  runSpacing: gap,
                                  children: [
                                    field(_productTypeDropdown(fieldW)),
                                    field(_reasonDropdown(fieldW)),
                                  ],
                                ),

                                const SizedBox(height: 18),
                                Divider(color: Colors.black.withOpacity(0.08)),
                                const SizedBox(height: 18),

                                _sectionTitle('Owner Details',
                                    icon: Icons.person_outline),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: gap,
                                  runSpacing: gap,
                                  children: [
                                    field(
                                      TextFormField(
                                        controller: firstNameCtrl,
                                        autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
                                        inputFormatters: _nameFormatters(),
                                        decoration: _dec(
                                          label: 'First Name',
                                          hint: 'JOHN',
                                          icon: Icons.person_outline,
                                        ),
                                        validator: (v) =>
                                            _nameValidator(v, fieldName: 'First name'),
                                      ),
                                    ),
                                    field(
                                      TextFormField(
                                        controller: lastNameCtrl,
                                        autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
                                        inputFormatters: _nameFormatters(),
                                        decoration: _dec(
                                          label: 'Last Name',
                                          hint: 'DOE',
                                          icon: Icons.person_outline,
                                        ),
                                        validator: (v) =>
                                            _nameValidator(v, fieldName: 'Last name'),
                                      ),
                                    ),
                                    field(
                                      TextFormField(
                                        controller: phoneCtrl,
                                        autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
                                        keyboardType: TextInputType.phone,
                                        decoration: _dec(
                                          label: 'Phone',
                                          hint: '+9715XXXXXXXX',
                                          icon: Icons.phone_outlined,
                                        ),
                                        inputFormatters: [
                                          UaEPhoneInputFormatter(),
                                        ],
                                        validator: _uaePhoneValidator,
                                        onTap: () {
                                          if (phoneCtrl.text.isEmpty) {
                                            phoneCtrl.text =
                                                UaEPhoneInputFormatter.prefix;
                                            phoneCtrl.selection =
                                                TextSelection.collapsed(
                                              offset: phoneCtrl.text.length,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    field(
                                      TextFormField(
                                        controller: emailCtrl,
                                        autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
                                        keyboardType: TextInputType.emailAddress,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(64),
                                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r"[A-Za-z0-9@._%+\-]")),
                                          _upper,
                                        ],
                                        decoration: _dec(
                                          label: 'Email',
                                          hint: 'NAME@DOMAIN.COM',
                                          icon: Icons.email_outlined,
                                        ),
                                        validator: _emailValidator,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),
                                Divider(color: Colors.black.withOpacity(0.08)),
                                const SizedBox(height: 18),

                                _sectionTitle('Vehicle Information',
                                    icon: Icons.directions_car_outlined),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: gap,
                                  runSpacing: gap,
                                  children: [
                                    field(
                                      DropdownButtonFormField<String>(
                                        value: selectedMake,
                                        autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
                                        items: makes
                                            .map((m) => DropdownMenuItem(
                                                value: m, child: Text(m)))
                                            .toList(),
                                        onChanged: loadingMakes
                                            ? null
                                            : (v) async {
                                                if (v == null) return;

                                                // OTHER make
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
                                                final mkId =
                                                    _makeIdByName[mkName] ?? '';

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
                                                  showTopSnack(context,
                                                      'makeId missing for selected make',
                                                      variant: 'error');
                                                  setState(() {
                                                    models = const ['OTHER'];
                                                    selectedModel = 'OTHER';
                                                    _modelIsOther = true;
                                                  });
                                                }
                                              },
                                        decoration: _dec(
                                          label: 'Make',
                                          hint: loadingMakes
                                              ? 'Loading makes…'
                                              : 'Select make',
                                          icon: Icons.directions_car_outlined,
                                        ),
                                        validator: (v) =>
                                            v == null ? 'Make is required' : null,
                                      ),
                                    ),

                                    if (_makeIsOther)
                                      field(
                                        TextFormField(
                                          controller: otherMakeCtrl,
                                          autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
                                          inputFormatters:
                                              _vehicleFreeTextFormatters(max: 40),
                                          decoration: _dec(
                                            label: 'Other Make',
                                            hint: 'ENTER MAKE',
                                            icon: Icons.edit_outlined,
                                          ),
                                          validator: (v) => _vehicleTextValidator(
                                            v,
                                            fieldName: 'Other Make',
                                            min: 2,
                                          ),
                                        ),
                                      ),

                                    field(
                                      DropdownButtonFormField<String>(
                                        value: selectedModel,
                                        autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
                                        items: models
                                            .map((m) => DropdownMenuItem(
                                                value: m, child: Text(m)))
                                            .toList(),
                                        onChanged: (selectedMake == null ||
                                                loadingModels)
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
                                              : (loadingModels
                                                  ? 'Loading models…'
                                                  : 'Select model'),
                                          icon: Icons.car_repair_outlined,
                                        ),
                                        validator: (v) =>
                                            v == null ? 'Model is required' : null,
                                      ),
                                    ),

                                    if (_modelIsOther)
                                      field(
                                        TextFormField(
                                          controller: otherModelCtrl,
                                          autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
                                          inputFormatters:
                                              _vehicleFreeTextFormatters(max: 40),
                                          decoration: _dec(
                                            label: 'Other Model',
                                            hint: 'ENTER MODEL',
                                            icon: Icons.edit_outlined,
                                          ),
                                          validator: (v) => _vehicleTextValidator(
                                            v,
                                            fieldName: 'Other Model',
                                            min: 1,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 18),
                                Divider(color: Colors.black.withOpacity(0.08)),
                                const SizedBox(height: 18),

                                _sectionTitle('Preferred Slot',
                                    icon: Icons.event_available_outlined),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: gap,
                                  runSpacing: gap,
                                  children: [
                                    SizedBox(
                                      width: fieldW,
                                      child: InkWell(
                                        onTap: _pickDate,
                                        borderRadius: BorderRadius.circular(14),
                                        child: InputDecorator(
                                          decoration: _dec(
                                            label: 'Preferred Date',
                                            hint: 'Select date',
                                            icon: Icons.date_range_outlined,
                                          ),
                                          child: Text(
                                            preferredDate == null
                                                ? 'Select date'
                                                : '${preferredDate!.year}-${preferredDate!.month.toString().padLeft(2, '0')}-${preferredDate!.day.toString().padLeft(2, '0')}',
                                          ),
                                        ),
                                      ),
                                    ),
                                    field(
                                      DropdownButtonFormField<String>(
                                        value: preferredTimeCtrl.text,
                                        autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
                                        items: const [
                                          '09:00 AM',
                                          '10:00 AM',
                                          '11:00 AM',
                                          '12:00 PM',
                                          '01:00 PM',
                                          '02:00 PM',
                                          '03:00 PM',
                                          '04:00 PM',
                                          '05:00 PM',
                                          '06:00 PM',
                                          '07:00 PM',
                                        ]
                                            .map((t) => DropdownMenuItem(
                                                value: t, child: Text(t)))
                                            .toList(),
                                        onChanged: (v) {
                                          if (v == null) return;
                                          setState(() =>
                                              preferredTimeCtrl.text = v);
                                        },
                                        decoration: _dec(
                                          label: 'Preferred Time',
                                          hint: 'Select time',
                                          icon: Icons.schedule_outlined,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),
                                Divider(color: Colors.black.withOpacity(0.08)),
                                const SizedBox(height: 18),

                                _sectionTitle('Location',
                                    icon: Icons.location_on_outlined),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: gap,
                                  runSpacing: gap,
                                  children: [
                                    field(
                                      TextFormField(
                                        controller: addressCtrl,
                                        autovalidateMode: AutovalidateMode.onUserInteraction, // ✅ only this field
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(80),
                                          _upper,
                                        ],
                                        decoration: _dec(
                                          label: 'Address',
                                          hint: '123 MAIN STREET',
                                          icon: Icons.home_outlined,
                                        ),
                                        validator: (v) =>
                                            _req(v, msg: 'Address is required'),
                                      ),
                                    ),
                                    field(
                                      DropdownButtonFormField<String>(
                                        value: selectedCity,
                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                        decoration: _dec(
                                          label: 'City',
                                          hint: 'Select city',
                                          icon: Icons.location_city_outlined,
                                        ),
                                        items: const [
                                          'Abu Dhabi',
                                          'Ajman',
                                          'Dubai',
                                          'Fujairah',
                                          'Ras Al Khaimah',
                                          'Sharjah',
                                          'Umm Al Quwain',
                                          'Other',
                                        ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                        onChanged: (v) {
                                          setState(() {
                                            selectedCity = v;
                                            _cityIsOther = v == 'Other';
                                            if (!_cityIsOther) otherCityCtrl.clear();
                                          });
                                        },
                                        validator: (v) => v == null ? 'City is required' : null,
                                      ),
                                    ),
                                    if (_cityIsOther)
                                      field(
                                        TextFormField(
                                          controller: otherCityCtrl,
                                          autovalidateMode: AutovalidateMode.onUserInteraction,
                                          inputFormatters: [
                                            LengthLimitingTextInputFormatter(40),
                                            _upper,
                                          ],
                                          decoration: _dec(
                                            label: 'Other City',
                                            hint: 'ENTER CITY NAME',
                                            icon: Icons.edit_outlined,
                                          ),
                                          validator: (v) {
                                            if (!_cityIsOther) return null;
                                            if (v == null || v.trim().isEmpty) return 'City is required';
                                            return null;
                                          },
                                        ),
                                      ),
                                    field(
                                      TextFormField(
                                        controller: stateCtrl,
                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                        inputFormatters: _nameFormatters(max: 30),
                                        decoration: _dec(
                                          label: 'State / Area',
                                          hint: 'UAE',
                                          icon: Icons.map_outlined,
                                        ),
                                        validator: (v) => _req(v, msg: 'State is required'),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),
                                Divider(color: Colors.black.withOpacity(0.08)),
                                const SizedBox(height: 18),

                                _sectionTitle('Notes',
                                    icon: Icons.notes_outlined),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: notesCtrl,
                                  maxLines: 4,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(250),
                                    _upper,
                                  ],
                                  decoration: _dec(
                                    label: 'Notes',
                                    hint: 'ANY SPECIAL INSTRUCTIONS...',
                                    icon: Icons.notes_outlined,
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // ✅ TERMS + SUBMIT ENABLE LOGIC
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 2),
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: Checkbox(
                                                value: _agreeTerms,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                onChanged: (v) {
                                                  if (v == null) return;
                                                  setState(() =>
                                                      _agreeTerms = v);
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Wrap(
                                              alignment:
                                                  WrapAlignment.start,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              runSpacing: 2,
                                              children: [
                                                const Text(
                                                  'Agree to ',
                                                  style: TextStyle(
                                                      color: Colors.black54),
                                                ),
                                                InkWell(
                                                  onTap: () => _showTermsDialog(
                                                      'Privacy Policy'),
                                                  child: const Text(
                                                    'Privacy Policy',
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      decoration: TextDecoration
                                                          .underline,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                const Text(' & ',
                                                    style: TextStyle(
                                                        color: Colors.black54)),
                                                InkWell(
                                                  onTap: () => _showTermsDialog(
                                                      'Terms and Conditions'),
                                                  child: const Text(
                                                    'Terms and Conditions',
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      decoration: TextDecoration
                                                          .underline,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: FilledButton.icon(
                                          onPressed: (loading || !_agreeTerms)
                                              ? null
                                              : () => _submit(type),
                                          icon: const Icon(Icons.send),
                                          label: Text(loading
                                              ? 'Submitting…'
                                              : 'Submit Request'),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      TextButton.icon(
                                        onPressed: () =>
                                            context.go('/products'),
                                        icon: const Icon(Icons.arrow_back),
                                        label: const Text('Back to Services'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class UaEPhoneInputFormatter extends TextInputFormatter {
  static const String prefix = '+971';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.text.startsWith(prefix)) {
      return TextEditingValue(
        text: prefix,
        selection: const TextSelection.collapsed(offset: prefix.length),
      );
    }

    final filtered = newValue.text.replaceAll(RegExp(r'[^0-9+]'), '');
    final truncated = filtered.length > 13 ? filtered.substring(0, 13) : filtered;

    if (truncated.length < prefix.length) {
      return TextEditingValue(
        text: prefix,
        selection: const TextSelection.collapsed(offset: prefix.length),
      );
    }

    return TextEditingValue(
      text: truncated,
      selection: TextSelection.collapsed(offset: truncated.length),
    );
  }
}




