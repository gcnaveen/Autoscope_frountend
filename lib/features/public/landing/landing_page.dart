// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:go_router/go_router.dart';
// import '../../../services/service_locator.dart';
// import '../../shared/top_snackbar.dart';
// import '../widgets/public_navbar.dart';

// // If you already have a URL open util, use it.
// // Otherwise keep WhatsApp button as no-op for now.

// class LandingPage extends StatelessWidget {
//   const LandingPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const PublicNavBar(),
//       body: SingleChildScrollView(
//         child: Column(
//           children: const [
//             _AboutUsSection(),
//             _HeroSection(),
//             _InspectionSection(),
//             // _HowItWorksSection(),
//             // _ValuationSection(),
//             _WhyAutoScopeSection(),
//             _TestimonialsSection(),
//             // _ContactUsSection(),
//             _Footer(),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _WrapWidth extends StatelessWidget {
//   final Widget child;
//   const _WrapWidth({required this.child});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: ConstrainedBox(
//         constraints: const BoxConstraints(maxWidth: 1120),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 18),
//           child: child,
//         ),
//       ),
//     );
//   }
// }

// class _SectionShell extends StatelessWidget {
//   final Color? bg;
//   final EdgeInsets padding;
//   final Widget child;

//   const _SectionShell({
//     required this.child,
//     this.bg,
//     this.padding = const EdgeInsets.symmetric(vertical: 56),
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: bg,
//       padding: padding,
//       child: _WrapWidth(child: child),
//     );
//   }
// }

// // =====================================================
// // HERO
// // =====================================================
// class _HeroSection extends StatelessWidget {
//   const _HeroSection();

//   @override
//   Widget build(BuildContext context) {
//     final w = MediaQuery.sizeOf(context).width;
//     final isMobile = w < 900;

//     return Container(
//       height: isMobile ? 520 : 560,
//       decoration: const BoxDecoration(color: Color(0xFF0B1220)),
//       child: Stack(
//         children: [
//           Positioned.fill(
//             child: Opacity(
//               opacity: 1,
//               child: Image.asset(
//                 'assets/images/inspection-1.jpg',
//                 fit: BoxFit.cover,
//                 errorBuilder: (_, __, ___) => const DecoratedBox(
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [Color(0xFF0B1220), Color(0xFF1A2B55)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           Positioned.fill(
//             child: DecoratedBox(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     const Color(0xFF0B1220).withOpacity(0.90),
//                     const Color(0xFF0B1220).withOpacity(0.35),
//                   ],
//                   begin: Alignment.centerLeft,
//                   end: Alignment.centerRight,
//                 ),
//               ),
//             ),
//           ),
//           _WrapWidth(
//             child: Align(
//               alignment: Alignment.centerLeft,
//               child: ConstrainedBox(
//                 constraints: const BoxConstraints(maxWidth: 720),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Vehicle Inspection &\nValuation',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 54,
//                         height: 1.04,
//                         fontWeight: FontWeight.w900,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     const Text(
//                       'Buy Smart. Sell Confident.',
//                       style: TextStyle(
//                         color: Colors.white70,
//                         fontSize: 18,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     const Text(
//                       'Professional vehicle inspection and accurate market valuation that helps you buy, sell, or negotiate with confidence.',
//                       style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.55),
//                     ),
//                     const SizedBox(height: 18),
//                     Wrap(
//                       spacing: 12,
//                       runSpacing: 12,
//                       children: [
//                         FilledButton.icon(
//                           onPressed: () => context.go('/products'),
//                           icon: const Icon(Icons.task_alt),
//                           label: const Text('Get Started'),
//                         ),
//                         // OutlinedButton.icon(
//                         //   onPressed: () => _openSampleReport(context),
//                         //   icon: const Icon(Icons.description, color: Colors.white),
//                         //   label: const Text('View Sample Report', style: TextStyle(color: Colors.white)),
//                         // ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   static void _openSampleReport(BuildContext context) {
//     showTopSnack(context, 'Sample report page will be connected here.', variant: 'success');
//   }
// }

// class _HeroChip extends StatelessWidget {
//   final String text;
//   const _HeroChip({required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: Colors.white.withOpacity(0.12)),
//       ),
//       child: Text(text, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
//     );
//   }
// }

// // =====================================================
// // ABOUT US
// // =====================================================
// class _AboutUsSection extends StatelessWidget {
//   const _AboutUsSection();

//   @override
//   Widget build(BuildContext context) {
//     final w = MediaQuery.sizeOf(context).width;
//     final isMobile = w < 900;

//     return _SectionShell(
//       bg: const Color(0xFFF6F8FC),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('About Auto Scope', style: Theme.of(context).textTheme.headlineMedium),
//           const SizedBox(height: 10),
//           const Text(
//             'Auto Scope is a UAE-based services company specializing in vehicle inspection and valuation support.\n'
//             'We were founded with a clear objective: to bring clarity, transparency, and professionalism to the used car buying and selling process.\n'
//             'With years of hands-on experience in the vehicle remarketing industry, our team understands how vehicles are evaluated, priced, and traded in real market conditions — not just on paper',
//             style: TextStyle(color: Colors.black54, height: 1.6),
//           ),
//           const SizedBox(height: 18),
//           if (isMobile)
//             Column(
//               children: [
//                 _AboutImage(),
//                 const SizedBox(height: 14),
//                 _AboutCards(),
//               ],
//             )
//           else
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: const [
//                 Expanded(flex: 6, child: _AboutImage()),
//                 SizedBox(width: 18),
//                 Expanded(flex: 6, child: _AboutCards()),
//               ],
//             ),
//         ],
//       ),
//     );
//   }
// }

// class _AboutImage extends StatelessWidget {
//   const _AboutImage();

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(16),
//         child: AspectRatio(
//           aspectRatio: 16 / 10,
//           child: Image.asset(
//             'assets/images/inspection-2.jpg',
//             fit: BoxFit.cover,
//             errorBuilder: (_, __, ___) => const DecoratedBox(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xFF0B1220), Color(0xFF1A2B55)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _AboutCards extends StatelessWidget {
//   const _AboutCards();

//   @override
//   Widget build(BuildContext context) {
//     Widget card({required String title, required String body, required IconData icon}) {
//       return Card(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: 44,
//                 height: 44,
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
//                     Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
//                     const SizedBox(height: 6),
//                     Text(body, style: const TextStyle(color: Colors.black54, height: 1.45)),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return Column(
//       children: [
//         card(
//           title: 'Our Approach',
//           body: 'Honest and unbiased inspections. Realistic, market-driven valuations. Clear information before making decisions.',
//           icon: Icons.fact_check_outlined,
//         ),
//         const SizedBox(height: 12),
//         card(
//           title: 'Who We Work With',
//           body: 'Individual buyers & sellers, corporate & fleet customers, leasing and rental companies.',
//           icon: Icons.groups_outlined,
//         ),
//         const SizedBox(height: 12),
//         card(
//           title: 'Our Promise',
//           body: 'Professional service, transparent reporting, practical advice, and ethical business practices.',
//           icon: Icons.verified_outlined,
//         ),
//       ],
//     );
//   }
// }

// // =====================================================
// // HOW IT WORKS (3 steps)
// // =====================================================
// class _HowItWorksSection extends StatelessWidget {
//   const _HowItWorksSection();

//   @override
//   Widget build(BuildContext context) {
//     final steps = const [
//       (Icons.event_available, 'Book Online', 'Choose inspection or valuation and submit your request.'),
//       (Icons.car_repair, 'Onsite Inspection', 'We inspect at your location (home/office/seller).'),
//       (Icons.description, 'Get Digital Report', 'Receive a detailed report and clear next steps.'),
//     ];

//     return _SectionShell(
//       bg: Colors.white,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Get professional inspection in three easy steps', style: Theme.of(context).textTheme.headlineMedium),
//           const SizedBox(height: 10),
//           const Text('Simple process. Clear results.', style: TextStyle(color: Colors.black54, height: 1.5)),
//           const SizedBox(height: 18),
//           Wrap(
//             spacing: 14,
//             runSpacing: 14,
//             children: steps
//                 .map(
//                   (s) => SizedBox(
//                     width: 340,
//                     height: 220,
//                     child: Card(
//                       child: Padding(
//                         padding: const EdgeInsets.all(18),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Icon(s.$1, size: 34, color: const Color(0xFF1E5EFF)),
//                             const SizedBox(height: 10),
//                             Text(s.$2, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
//                             const SizedBox(height: 6),
//                             Text(s.$3, style: const TextStyle(color: Colors.black54, height: 1.45)),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 )
//                 .toList(),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // =====================================================
// // INSPECTION SECTION
// // =====================================================
// class _InspectionSection extends StatelessWidget {
//   const _InspectionSection();

//   @override
//   Widget build(BuildContext context) {
//     final w = MediaQuery.sizeOf(context).width;
//     final isMobile = w < 900;

//     final bulletsText1 = const [
//       'Exterior body & paint condition',
//       'Interior condition & functionality',
//       'Engine & basic mechanical checks',
//       'Transmission & drivetrain performance',
//       'Brakes, suspension & steering',
//       'Tyres, wheels & wear indicators',
//       'Electrical systems & warning lights',
//       'Road test (where permitted)',
//       'Visual indicators of accident or damage',
//     ];

//     final bulletsText2 = const [
//       'Market demand & pricing trends',
//       'Vehicle make, model & year',
//       'Mileage & condition',
//       'Inspection findings',
//       'Repair impact (if any)',
//     ];

//     final youReceiveText2 = const [
//       'Estimated Market Value',
//       'Quick Sale Value',
//       'Expert guidance on pricing and next steps',
//     ];

//     final text1 = Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Professional Vehicle Inspection', style: Theme.of(context).textTheme.headlineMedium),
//         const SizedBox(height: 10),
//         const Text(
//           'A comprehensive, non-invasive assessment of the vehicle’s condition at the time of inspection.',
//           style: TextStyle(color: Colors.black54, height: 1.6),
//         ),
//         const SizedBox(height: 14),
//         ...bulletsText1.map(
//           (b) => Padding(
//             padding: const EdgeInsets.only(bottom: 10),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Icon(Icons.check_circle, size: 18, color: Color(0xFF1E5EFF)),
//                 const SizedBox(width: 10),
//                 Expanded(child: Text(b)),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: 14),
//         const Text('A detailed inspection report is provided after completion.', style: TextStyle(color: Colors.black54)),
//       ],
//     );

//     final text2 = Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Professional Valuation and Inspection', style: Theme.of(context).textTheme.headlineMedium),
//         const SizedBox(height: 10),
//         const Text(
//           'Get a clear and realistic understanding of your vehicle’s worth in the current UAE market.',
//           style: TextStyle(color: Colors.black54, height: 1.6),
//         ),
//         const SizedBox(height: 14),
//         const Text('Valuation is based on:', style: TextStyle(fontWeight: FontWeight.w900)),
//         const SizedBox(height: 10),
//         ...bulletsText2.map(
//           (b) => Padding(
//             padding: const EdgeInsets.only(bottom: 10),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Icon(Icons.check_circle, size: 18, color: Color(0xFF1E5EFF)),
//                 const SizedBox(width: 10),
//                 Expanded(child: Text(b)),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: 10),
//         const Text('You receive:', style: TextStyle(fontWeight: FontWeight.w900)),
//         const SizedBox(height: 10),
//         ...youReceiveText2.map(
//           (b) => Padding(
//             padding: const EdgeInsets.only(bottom: 10),
//             child: Row(
//               children: [
//                 const Icon(Icons.check, size: 18, color: Color(0xFF1E5EFF)),
//                 const SizedBox(width: 10),
//                 Expanded(child: Text(b)),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );

//     return _SectionShell(
//       bg: const Color(0xFFF6F8FC),
//       child: isMobile
//           ? Column(children: [text1, const SizedBox(height: 24), text2])
//           : Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(flex: 7, child: text1),
//                 const SizedBox(width: 18),
//                 Expanded(flex: 5, child: text2),
//               ],
//             ),
//     );
//   }
// }

// // =====================================================
// // WHY AUTOSCOPE
// // =====================================================
// class _WhyAutoScopeSection extends StatelessWidget {
//   const _WhyAutoScopeSection();

//   @override
//   Widget build(BuildContext context) {
//     final items = const [
//       (Icons.engineering_outlined, 'Experienced Professionals', 'Hands-on automotive experts and practical guidance.'),
//       (Icons.receipt_long_outlined, 'No Hidden Charges', 'Straightforward service with no surprises.'),
//       (Icons.description_outlined, 'Transparent Reporting', 'Clear findings and evidence-based notes.'),
//       (Icons.verified_outlined, 'Independent & Unbiased', 'We work in your interest — not to sell repairs.'),
//     ];

//     return _SectionShell(
//       bg: const Color(0xFFF6F8FC),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Why Choose Auto Scope', style: Theme.of(context).textTheme.headlineMedium),
//           const SizedBox(height: 10),
//           LayoutBuilder(
//             builder: (context, c) {
//               const spacing = 14.0;
//               final maxW = c.maxWidth;
//               final isMobile = maxW < 700;
//               final itemW = isMobile ? maxW : (maxW - spacing) / 2;

//               return Wrap(
//                 spacing: spacing,
//                 runSpacing: spacing,
//                 children: items
//                     .map((x) => SizedBox(
//                           width: itemW,
//                           child: Card(
//                             child: Padding(
//                               padding: const EdgeInsets.all(18),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Icon(x.$1, size: 34, color: const Color(0xFF1E5EFF)),
//                                   const SizedBox(height: 10),
//                                   Text(x.$2, style: const TextStyle(fontWeight: FontWeight.w900)),
//                                   const SizedBox(height: 6),
//                                   Text(x.$3, style: const TextStyle(color: Colors.black54, height: 1.45)),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ))
//                     .toList(),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// // =====================================================
// // TESTIMONIALS
// // =====================================================
// class _TestimonialsSection extends StatelessWidget {
//   const _TestimonialsSection();

//   @override
//   Widget build(BuildContext context) {
//     final items = const [
//       ('“The inspection report was clear and helped me negotiate confidently.”', 'Customer', 'Dubai, UAE'),
//       ('“Valuation was realistic and matched the market. Very professional.”', 'Seller', 'Sharjah, UAE'),
//       ('“Convenient onsite inspection and fast delivery of the report.”', 'Buyer', 'Abu Dhabi, UAE'),
//     ];

//     return _SectionShell(
//       bg: Colors.white,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Testimonials', style: Theme.of(context).textTheme.headlineMedium),
//           const SizedBox(height: 10),
//           const Text(
//             'Real feedback from customers who wanted clarity before buying or selling.',
//             style: TextStyle(color: Colors.black54),
//           ),
//           const SizedBox(height: 18),
//           Wrap(
//             spacing: 14,
//             runSpacing: 14,
//             children: items
//                 .map((t) => SizedBox(
//                       width: 360,
//                       child: Card(
//                         child: Padding(
//                           padding: const EdgeInsets.all(18),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Icon(Icons.format_quote, size: 30, color: Color(0xFF1E5EFF)),
//                               const SizedBox(height: 10),
//                               Text(t.$1, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.45)),
//                               const SizedBox(height: 14),
//                               Row(
//                                 children: [
//                                   CircleAvatar(
//                                     radius: 16,
//                                     backgroundColor: const Color(0xFF1E5EFF).withOpacity(0.12),
//                                     child: const Icon(Icons.person_outline, color: Color(0xFF1E5EFF)),
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(t.$2, style: const TextStyle(fontWeight: FontWeight.w900)),
//                                       Text(t.$3, style: const TextStyle(color: Colors.black54, fontSize: 12)),
//                                     ],
//                                   )
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ))
//                 .toList(),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // =====================================================
// // CONTACT US (NOW CONNECTED TO API)
// // =====================================================
// class _ContactUsSection extends StatefulWidget {
//   const _ContactUsSection();

//   @override
//   State<_ContactUsSection> createState() => _ContactUsSectionState();
// }

// class _ContactUsSectionState extends State<_ContactUsSection> {
//   final _formKey = GlobalKey<FormState>();

//   final _nameCtrl = TextEditingController();
//   final _emailCtrl = TextEditingController();
//   final _numberCtrl = TextEditingController();
//   final _messageCtrl = TextEditingController();

//   bool _submitting = false;

//   // checkbox state
//   bool _agreeTerms = false;

//   @override
//   void initState() {
//     super.initState();
//     // Ensure prefix is present immediately (formatter will enforce later too).
//     if (_numberCtrl.text.isEmpty) _numberCtrl.text = UaEPhoneInputFormatter.prefix;
//   }

//   @override
//   void dispose() {
//     _nameCtrl.dispose();
//     _emailCtrl.dispose();
//     _numberCtrl.dispose();
//     _messageCtrl.dispose();
//     super.dispose();
//   }

//   void _showTermsDialog(String title) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
//         content: const SingleChildScrollView(
//           child: Text(
//             '''
// Dummy Terms & Conditions

// 1. This form submission is for contacting Auto Scope.
// 2. Please provide accurate information.
// 3. We may contact you using the email/phone you submit.
// 4. Misuse/spam submissions may be ignored.

// Dummy Privacy Policy

// 1. We store your submitted details securely.
// 2. We do not sell your data to third parties.
// 3. Your data may be used only to respond to your inquiry.
// ''',
//             style: TextStyle(height: 1.5),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(ctx).pop(),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _submit() async {
//     final ok = _formKey.currentState?.validate() ?? false;
//     if (!ok) return;

//     if (!_agreeTerms) {
//       showTopSnack(context, 'Please accept Terms & Conditions and Privacy Policy.', variant: 'warning');
//       return;
//     }

//     setState(() => _submitting = true);

//     try {
//       await contactService.submitContact(
//         name: _nameCtrl.text.trim(),
//         email: _emailCtrl.text.trim(),
//         number: _numberCtrl.text.trim(),
//         message: _messageCtrl.text.trim(),
//       );

//       if (!mounted) return;

//       showTopSnack(context, 'Thanks! We received your message.', variant: 'success');

//       _nameCtrl.clear();
//       _emailCtrl.clear();
//       _numberCtrl.text = UaEPhoneInputFormatter.prefix; // keep prefix after clear
//       _messageCtrl.clear();

//       setState(() => _agreeTerms = false);
//     } catch (e) {
//       if (!mounted) return;
//       showTopSnack(context, 'Failed to submit: $e', variant: 'error');
//     } finally {
//       if (mounted) setState(() => _submitting = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final w = MediaQuery.sizeOf(context).width;
//     final isMobile = w < 900;

//     final form = Card(
//       child: Padding(
//         padding: const EdgeInsets.all(18),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               TextFormField(
//                 controller: _nameCtrl,
//                 decoration: const InputDecoration(labelText: 'Your name', border: OutlineInputBorder()),
//                 inputFormatters: [
//                   FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\.\-']")),
//                   LengthLimitingTextInputFormatter(60),
//                 ],
//                 validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
//               ),
//               const SizedBox(height: 12),

//               // ✅ UPDATED: Email formatter + validator
//               TextFormField(
//                 controller: _emailCtrl,
//                 keyboardType: TextInputType.emailAddress,
//                 decoration: const InputDecoration(labelText: 'Contact email', border: OutlineInputBorder()),
//                 inputFormatters: [
//                   EmailInputFormatter(), // removes spaces
//                   LengthLimitingTextInputFormatter(120),
//                 ],
//                 validator: emailValidator,
//               ),
//               const SizedBox(height: 12),

//               // ✅ UPDATED: UAE phone formatter + validator (+971 enforced, total length 13)
//               TextFormField(
//                 controller: _numberCtrl,
//                 keyboardType: TextInputType.phone,
//                 decoration: const InputDecoration(
//                   labelText: 'Phone number',
//                   hintText: '+9715XXXXXXXX',
//                   border: OutlineInputBorder(),
//                 ),
//                 inputFormatters: [
//                   UaEPhoneInputFormatter(),
//                 ],
//                 validator: uaePhoneValidator,
//                 onTap: () {
//                   if (_numberCtrl.text.isEmpty) {
//                     _numberCtrl.text = UaEPhoneInputFormatter.prefix;
//                     _numberCtrl.selection = TextSelection.collapsed(offset: _numberCtrl.text.length);
//                   }
//                 },
//               ),
//               const SizedBox(height: 12),

//               TextFormField(
//                 controller: _messageCtrl,
//                 maxLines: 4,
//                 decoration: const InputDecoration(labelText: 'Your message', border: OutlineInputBorder()),
//                 inputFormatters: [
//                   LengthLimitingTextInputFormatter(800),
//                 ],
//                 validator: (v) => (v == null || v.trim().isEmpty) ? 'Message is required' : null,
//               ),

//               // Terms checkbox row above submit
//               const SizedBox(height: 12),
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.only(top: 2),
//                     child: SizedBox(
//                       width: 24,
//                       height: 24,
//                       child: Checkbox(
//                         value: _agreeTerms,
//                         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                         visualDensity: VisualDensity.compact,
//                         onChanged: (v) {
//                           if (v == null) return;
//                           setState(() => _agreeTerms = v);
//                         },
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: Padding(
//                       padding: const EdgeInsets.only(top: 2),
//                       child: Wrap(
//                         alignment: WrapAlignment.start,
//                         crossAxisAlignment: WrapCrossAlignment.center,
//                         runSpacing: 2,
//                         children: [
//                           const Text('I agree to '),
//                           InkWell(
//                             onTap: () => _showTermsDialog('Terms & Conditions'),
//                             child: const Text(
//                               'Terms & Conditions',
//                               style: TextStyle(
//                                 color: Colors.blue,
//                                 decoration: TextDecoration.underline,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                           ),
//                           const Text(' and '),
//                           InkWell(
//                             onTap: () => _showTermsDialog('Privacy Policy'),
//                             child: const Text(
//                               'Privacy Policy',
//                               style: TextStyle(
//                                 color: Colors.blue,
//                                 decoration: TextDecoration.underline,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                           ),
//                           const Text('.'),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 14),
//               SizedBox(
//                 width: double.infinity,
//                 height: 46,
//                 child: FilledButton(
//                   onPressed: (_submitting || !_agreeTerms) ? null : _submit,
//                   child: Text(_submitting ? 'Submitting...' : 'Submit'),
//                 ),
//               ),

//               const SizedBox(height: 10),
//               const Text(
//                 'By submitting this form you agree to our terms and conditions and privacy policy.',
//                 style: TextStyle(color: Colors.black54, fontSize: 12),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );

//     final info = Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Card(
//           child: Padding(
//             padding: const EdgeInsets.all(18),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: const [
//                 Text('Contact us', style: TextStyle(fontWeight: FontWeight.w900)),
//                 SizedBox(height: 10),
//                 Row(children: [Icon(Icons.email, size: 18), SizedBox(width: 10), Text('support@autoscope.com')]),
//                 SizedBox(height: 8),
//                 Row(children: [Icon(Icons.phone, size: 18), SizedBox(width: 10), Text('+971 50 000 0000')]),
//                 SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Icon(Icons.location_on, size: 18),
//                     SizedBox(width: 10),
//                     Expanded(child: Text('UAE')),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: 12),
//         Card(
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(16),
//             child: AspectRatio(
//               aspectRatio: 16 / 10,
//               child: Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   // Background gradient (always there)
//                   const DecoratedBox(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [Color(0xFF0B1220), Color.fromARGB(255, 255, 3, 3)],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                     ),
//                   ),

//                   // Image on top
//                   Image.asset(
//                     'assets/images/contactus-1.jpg',
//                     fit: BoxFit.cover,
//                     gaplessPlayback: true,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );


//     return _SectionShell(
//       bg: const Color(0xFFF6F8FC),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Ready to Inspect?', style: Theme.of(context).textTheme.headlineMedium),
//           const SizedBox(height: 10),
//           const Text(
//             'Make informed decisions and avoid costly surprises. Book your vehicle inspection today.',
//             style: TextStyle(color: Colors.black54),
//           ),
//           const SizedBox(height: 18),
//           isMobile
//               ? Column(children: [form, const SizedBox(height: 14), info])
//               : Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(flex: 7, child: form),
//                     const SizedBox(width: 18),
//                     Expanded(flex: 5, child: info),
//                   ],
//                 ),
//           const SizedBox(height: 18),
//           const Text(
//             'Inspections are visual and non-invasive assessments conducted at the time of inspection. '
//             'Valuations are indicative and subject to market conditions.',
//             style: TextStyle(color: Colors.black54, fontSize: 12),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // =====================================================
// // FOOTER
// // =====================================================
// class _Footer extends StatelessWidget {
//   const _Footer();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: const Color(0xFF0B1220),
//       padding: const EdgeInsets.symmetric(vertical: 26),
//       child: const _WrapWidth(
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     'Auto Scope • Buy Smart. Sell Confident.',
//                     style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 12),
//             Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 '© 2026 Auto Scope. All rights reserved.',
//                 style: TextStyle(color: Colors.white54),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // =====================================================
// // ✅ INPUT FORMATTERS + VALIDATORS (added for Landing page)
// // =====================================================

// class EmailInputFormatter extends TextInputFormatter {
//   @override
//   TextEditingValue formatEditUpdate(
//     TextEditingValue oldValue,
//     TextEditingValue newValue,
//   ) {
//     // Remove spaces only (common issue)
//     final text = newValue.text.replaceAll(' ', '');
//     return TextEditingValue(
//       text: text,
//       selection: TextSelection.collapsed(offset: text.length),
//     );
//   }
// }

// String? emailValidator(String? v) {
//   final s = (v ?? '').trim();
//   if (s.isEmpty) return 'Email is required';

//   // Must contain @ and .
//   if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
//     return 'Enter a valid email address';
//   }
//   return null;
// }

// class UaEPhoneInputFormatter extends TextInputFormatter {
//   static const prefix = '+971';

//   @override
//   TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
//     // Always enforce prefix
//     if (!newValue.text.startsWith(prefix)) {
//       return TextEditingValue(
//         text: prefix,
//         selection: const TextSelection.collapsed(offset: prefix.length),
//       );
//     }

//     // Keep only + and digits
//     final filtered = newValue.text.replaceAll(RegExp(r'[^0-9+]'), '');

//     // Max length: 13 chars total (+ + 12 digits?) per your requirement:
//     // "+971" + 9 digits = 13 characters total.
//     final truncated = filtered.length > 13 ? filtered.substring(0, 13) : filtered;

//     // Prevent deleting prefix (if user tries)
//     if (truncated.length < prefix.length) {
//       return TextEditingValue(
//         text: prefix,
//         selection: const TextSelection.collapsed(offset: prefix.length),
//       );
//     }

//     return TextEditingValue(
//       text: truncated,
//       selection: TextSelection.collapsed(offset: truncated.length),
//     );
//   }
// }

// // Validator: "+971" + 9 digits
// String? uaePhoneValidator(String? v) {
//   final s = (v ?? '').trim();
//   if (s.isEmpty) return 'Phone number is required';

//   // +971XXXXXXXXX (9 digits after 971)
//   if (!RegExp(r'^\+971\d{9}$').hasMatch(s)) {
//     return 'Enter valid UAE number (+971XXXXXXXXX)';
//   }

//   return null;
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../services/service_locator.dart';
import '../../shared/top_snackbar.dart';
import '../widgets/public_navbar.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);

    // ✅ Simple, plain, professional theme just for landing page
    final themed = base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      dividerColor: Colors.black.withOpacity(0.06),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1E5EFF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: Colors.black.withOpacity(0.14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
    return Theme(
      data: themed,
      child: Scaffold(
        appBar: const PublicNavBar(),
        body: SingleChildScrollView(
          child: Column(
            children: const [
              _HeroSection(),
              _AboutUsSection(),
              _ServicesIntroSection(),
              _InspectionSection(),
              _BookServiceCtaSection(),
              _WhyAutoScopeSection(),
              _TestimonialsSection(),
              // _HowItWorksSection(),
              // _ContactUsSection(),
              _Footer(),
            ],
          ),
        ),

        // ✅ Floating "Get Started" (same as Book Service)
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/products'),
          icon: const Icon(Icons.task_alt),
          label: const Text('Get Started'),
        ),
      ),
    );
  }
}

class _WrapWidth extends StatelessWidget {
  final Widget child;
  const _WrapWidth({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: child,
        ),
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  final Color? bg;
  final EdgeInsets padding;
  final Widget child;

  const _SectionShell({
    required this.child,
    this.bg,
    this.padding = const EdgeInsets.symmetric(vertical: 64),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg ?? Colors.white,
      padding: padding,
      child: _WrapWidth(child: child),
    );
  }
}


// =====================================================
// Hero section
// =====================================================
class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 900;

    return Container(
      height: isMobile ? 520 : 560,
      decoration: const BoxDecoration(color: Color(0xFF0B1220)),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 1,
              child: Image.asset(
                'assets/images/inspection-1.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B1220), Color(0xFF1A2B55)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0B1220).withOpacity(0.70),
                    const Color(0xFF0B1220).withOpacity(0.25),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          _WrapWidth(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Auto Scope',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 54,
                        height: 1.04,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Buy Smart. Sell Confident.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Auto Scope is a UAE-based services company specializing in vehicle inspection and valuation support.\n'
                      'We were founded with a clear objective: to bring clarity, transparency, and professionalism to the used car buying and selling process.\n'
                      'With years of hands-on experience in the vehicle remarketing industry, our team understands how vehicles are evaluated, priced, and traded in real market conditions — not just on paper',
                      style: TextStyle(color: Colors.white, fontSize: 16 , height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// ABOUT US
// =====================================================
class _AboutUsSection extends StatelessWidget {
  const _AboutUsSection();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 900;
    return Container(
  // keep same spacing as _SectionShell
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Stack(
        children: [
          // Background image (like hero)
          Positioned.fill(
            child: Opacity(
              opacity: 1, // keep subtle

            ),
          ),

          // Soft overlay so content is readable
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF6F8FC).withOpacity(0.96),
                    const Color(0xFFF6F8FC).withOpacity(0.88),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Your existing About content
          _WrapWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text('About Auto Scope', style: Theme.of(context).textTheme.headlineMedium),
                // const SizedBox(height: 10),
                // const Text(
                //   'Auto Scope is a UAE-based services company specializing in vehicle inspection and valuation support.\n'
                //   'We were founded with a clear objective: to bring clarity, transparency, and professionalism to the used car buying and selling process.\n'
                //   'With years of hands-on experience in the vehicle remarketing industry, our team understands how vehicles are evaluated, priced, and traded in real market conditions — not just on paper',
                //   style: TextStyle(color: Colors.black54, height: 1.6),
                // ),
                const SizedBox(height: 18),
                if (isMobile)
                  Column(
                    children: [
                      const _AboutImage(),
                      const SizedBox(height: 14),
                      const _AboutCards(),
                    ],
                  )
                else
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: _AboutImage()),
                      SizedBox(width: 18),
                      Expanded(flex: 6, child: _AboutCards()),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutImage extends StatelessWidget {
  const _AboutImage();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Image.asset(
            'assets/images/inspection-2.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B1220), Color(0xFF1A2B55)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutCards extends StatelessWidget {
  const _AboutCards();

  @override
  Widget build(BuildContext context) {
    Widget card({required String title, required String body, required IconData icon}) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E5EFF).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF1E5EFF)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(body, style: const TextStyle(color: Colors.black54, height: 1.55)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        card(
          title: 'Our Approach',
          body: 'Honest and unbiased inspections. Realistic, market-driven valuations. Clear information before making decisions.',
          icon: Icons.fact_check_outlined,
        ),
        const SizedBox(height: 12),
        card(
          title: 'Who We Work With',
          body: 'Individual buyers & sellers, corporate & fleet customers, leasing and rental companies.',
          icon: Icons.groups_outlined,
        ),
        const SizedBox(height: 12),
        card(
          title: 'Our Promise',
          body: 'Professional service, transparent reporting, practical advice, and ethical business practices.',
          icon: Icons.verified_outlined,
        ),
      ],
    );
  }
}

// =====================================================
// SERVICES INTRO (simple header before services)
// =====================================================
class _ServicesIntroSection extends StatelessWidget {
  const _ServicesIntroSection();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 900;

    return _SectionShell(
      bg: Colors.white,
      padding: const EdgeInsets.only(top: 54, bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Our Services', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          const Text(
            'Vehicle inspection and valuation services designed to help you buy, sell, or negotiate with confidence.',
            style: TextStyle(color: Colors.black54, height: 1.6),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Pill(
                icon: Icons.location_on_outlined,
                text: 'Onsite in UAE',
                compact: isMobile,
              ),
              _Pill(
                icon: Icons.description_outlined,
                text: 'Digital report',
                compact: isMobile,
              ),
              _Pill(
                icon: Icons.verified_outlined,
                text: 'Independent & unbiased',
                compact: isMobile,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool compact;

  const _Pill({required this.icon, required this.text, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14, vertical: compact ? 10 : 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1E5EFF)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// =====================================================
// SERVICES (Inspection + Valuation)
// =====================================================
class _InspectionSection extends StatelessWidget {
  const _InspectionSection();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 900;

    final bulletsText1 = const [
      'Exterior body & paint condition',
      'Interior condition & functionality',
      'Engine & basic mechanical checks',
      'Transmission & drivetrain performance',
      'Brakes, suspension & steering',
      'Tyres, wheels & wear indicators',
      'Electrical systems & warning lights',
      'Road test (where permitted)',
      'Visual indicators of accident or damage',
    ];

    final bulletsText2 = const [
      'Market demand & pricing trends',
      'Vehicle make, model & year',
      'Mileage & condition',
      'Inspection findings',
      'Repair impact (if any)',
    ];

    final youReceiveText2 = const [
      'Estimated Market Value',
      'Quick Sale Value',
      'Expert guidance on pricing and next steps',
    ];

    Widget bullet(String b, {bool subtle = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, size: 18, color: Color(0xFF1E5EFF)),
            const SizedBox(width: 10),
            Expanded(child: Text(b, style: TextStyle(height: 1.4, color: subtle ? Colors.black54 : null))),
          ],
        ),
      );
    }

    final inspectionCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Professional Vehicle Inspection', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            const Text(
              'A comprehensive, non-invasive assessment of the vehicle’s condition at the time of inspection.',
              style: TextStyle(color: Colors.black54, height: 1.6),
            ),
            const SizedBox(height: 14),
            ...bulletsText1.map((b) => bullet(b)),
            const SizedBox(height: 8),
            const Text(
              'A detailed inspection report is provided after completion.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );

    final valuationCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Professional Inspection & Valuation', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            const Text(
              'Get a clear and realistic understanding of your vehicle’s worth in the current UAE market.',
              style: TextStyle(color: Colors.black54, height: 1.6),
            ),
            const SizedBox(height: 14),
            const Text('Valuation is based on:', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ...bulletsText2.map((b) => bullet(b, subtle: true)),
            const SizedBox(height: 10),
            const Text('You receive:', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ...youReceiveText2.map((b) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 18, color: Color(0xFF1E5EFF)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(b)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );

    return _SectionShell(
      bg: const Color(0xFFF6F8FC),
      padding: const EdgeInsets.only(top: 18, bottom: 64),
      child: isMobile
          ? Column(
              children: [
                inspectionCard,
                const SizedBox(height: 14),
                valuationCard,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: inspectionCard),
                const SizedBox(width: 18),
                Expanded(flex: 5, child: valuationCard),
              ],
            ),
    );
  }
}

// =====================================================
// BOOK SERVICE CTA (after services - client request)
// =====================================================
class _BookServiceCtaSection extends StatelessWidget {
  const _BookServiceCtaSection();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 900;

    return _SectionShell(
      bg: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 52),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FC),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        padding: const EdgeInsets.all(22),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CtaLeft(),
                  const SizedBox(height: 16),
                  _CtaRight(),
                ],
              )
            : Row(
                children: const [
                  Expanded(flex: 7, child: _CtaLeft()),
                  SizedBox(width: 18),
                  Expanded(flex: 5, child: _CtaRight()),
                ],
              ),
      ),
    );
  }
}

class _CtaLeft extends StatelessWidget {
  const _CtaLeft();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ready to book a service?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        const Text(
          'Choose an inspection or valuation service and submit your request in minutes. '
          'We’ll coordinate the visit and share a clear report after completion.',
          style: TextStyle(color: Colors.black54, height: 1.6),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _MiniBadge(icon: Icons.timer_outlined, text: 'Quick booking'),
            _MiniBadge(icon: Icons.pin_drop_outlined, text: 'Onsite visit'),
            _MiniBadge(icon: Icons.description_outlined, text: 'Digital report'),
          ],
        ),
      ],
    );
  }
}

class _CtaRight extends StatelessWidget {
  const _CtaRight();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton.icon(
            // ✅ route based on your current app (change if booking route differs)
            onPressed: () => context.go('/products'),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Book Service'),
          ),
        ),
        // const SizedBox(height: 12),
        // SizedBox(
        //   width: double.infinity,
        //   height: 46,
        //   child: OutlinedButton.icon(
        //     onPressed: () => context.go('/products'),
        //     icon: const Icon(Icons.task_alt),
        //     label: const Text('Get Started'),
        //   ),
        // ),
        // const SizedBox(height: 10),
        // Text(
        //   'No spam. Clear pricing. Professional service.',
        //   style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
        //   textAlign: TextAlign.center,
        // ),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MiniBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1E5EFF)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// =====================================================
// WHY AUTOSCOPE
// =====================================================
class _WhyAutoScopeSection extends StatelessWidget {
  const _WhyAutoScopeSection();

  @override
  Widget build(BuildContext context) {
    final items = const [
      (Icons.engineering_outlined, 'Experienced Professionals', 'Hands-on automotive experts and practical guidance.'),
      (Icons.receipt_long_outlined, 'No Hidden Charges', 'Straightforward service with no surprises.'),
      (Icons.description_outlined, 'Transparent Reporting', 'Clear findings and evidence-based notes.'),
      (Icons.verified_outlined, 'Independent & Unbiased', 'We work in your interest — not to sell repairs.'),
    ];

    return _SectionShell(
      bg: const Color(0xFFF6F8FC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Why Choose Auto Scope', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) {
              const spacing = 14.0;
              final maxW = c.maxWidth;
              final isMobile = maxW < 700;
              final itemW = isMobile ? maxW : (maxW - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: items
                    .map((x) => SizedBox(
                          width: itemW,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(x.$1, size: 34, color: const Color(0xFF1E5EFF)),
                                  const SizedBox(height: 10),
                                  Text(x.$2, style: const TextStyle(fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 6),
                                  Text(x.$3, style: const TextStyle(color: Colors.black54, height: 1.55)),
                                ],
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =====================================================
// TESTIMONIALS
// =====================================================
class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection();

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('“The inspection report was clear and helped me negotiate confidently.”', 'Customer', 'Dubai, UAE'),
      ('“Valuation was realistic and matched the market. Very professional.”', 'Seller', 'Sharjah, UAE'),
      ('“Convenient onsite inspection and fast delivery of the report.”', 'Buyer', 'Abu Dhabi, UAE'),
    ];

    return _SectionShell(
      bg: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Testimonials', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          const Text(
            'Real feedback from customers who wanted clarity before buying or selling.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: items
                .map((t) => SizedBox(
                      width: 360,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.format_quote, size: 30, color: Color(0xFF1E5EFF)),
                              const SizedBox(height: 10),
                              Text(t.$1, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.55)),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFF1E5EFF).withOpacity(0.12),
                                    child: const Icon(Icons.person_outline, color: Color(0xFF1E5EFF)),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t.$2, style: const TextStyle(fontWeight: FontWeight.w900)),
                                      Text(t.$3, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                    ],
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// HOW IT WORKS (3 steps)
// =====================================================
class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    final steps = const [
      (Icons.event_available, 'Book Online', 'Choose inspection or valuation and submit your request.'),
      (Icons.car_repair, 'Onsite Inspection', 'We inspect at your location (home/office/seller).'),
      (Icons.description, 'Get Digital Report', 'Receive a detailed report and clear next steps.'),
    ];

    return _SectionShell(
      bg: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How it works', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          const Text('Simple process. Clear results.', style: TextStyle(color: Colors.black54, height: 1.5)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: steps
                .map(
                  (s) => SizedBox(
                    width: 340,
                    height: 220,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(s.$1, size: 34, color: const Color(0xFF1E5EFF)),
                            const SizedBox(height: 10),
                            Text(s.$2, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            const SizedBox(height: 6),
                            Text(s.$3, style: const TextStyle(color: Colors.black54, height: 1.55)),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// CONTACT US (API)
// =====================================================
class _ContactUsSection extends StatefulWidget {
  const _ContactUsSection();

  @override
  State<_ContactUsSection> createState() => _ContactUsSectionState();
}

class _ContactUsSectionState extends State<_ContactUsSection> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  bool _submitting = false;
  bool _agreeTerms = false;

  @override
  void initState() {
    super.initState();
    if (_numberCtrl.text.isEmpty) _numberCtrl.text = UaEPhoneInputFormatter.prefix;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _numberCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _showTermsDialog(String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: const SingleChildScrollView(
          child: Text(
            '''
Dummy Terms & Conditions

1. This form submission is for contacting Auto Scope.
2. Please provide accurate information.
3. We may contact you using the email/phone you submit.
4. Misuse/spam submissions may be ignored.

Dummy Privacy Policy

1. We store your submitted details securely.
2. We do not sell your data to third parties.
3. Your data may be used only to respond to your inquiry.
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

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    if (!_agreeTerms) {
      showTopSnack(context, 'Please accept Terms & Conditions and Privacy Policy.', variant: 'warning');
      return;
    }

    setState(() => _submitting = true);

    try {
      await contactService.submitContact(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        number: _numberCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
      );

      if (!mounted) return;

      showTopSnack(context, 'Thanks! We received your message.', variant: 'success');

      _nameCtrl.clear();
      _emailCtrl.clear();
      _numberCtrl.text = UaEPhoneInputFormatter.prefix;
      _messageCtrl.clear();

      setState(() => _agreeTerms = false);
    } catch (e) {
      if (!mounted) return;
      showTopSnack(context, 'Failed to submit: $e', variant: 'error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 900;

    final form = Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Your name', border: OutlineInputBorder()),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\.\-']")),
                  LengthLimitingTextInputFormatter(60),
                ],
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Contact email', border: OutlineInputBorder()),
                inputFormatters: [
                  EmailInputFormatter(),
                  LengthLimitingTextInputFormatter(120),
                ],
                validator: emailValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numberCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: '+9715XXXXXXXX',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [
                  UaEPhoneInputFormatter(),
                ],
                validator: uaePhoneValidator,
                onTap: () {
                  if (_numberCtrl.text.isEmpty) {
                    _numberCtrl.text = UaEPhoneInputFormatter.prefix;
                    _numberCtrl.selection = TextSelection.collapsed(offset: _numberCtrl.text.length);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Your message', border: OutlineInputBorder()),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(800),
                ],
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Message is required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreeTerms,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _agreeTerms = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 2,
                        children: [
                          const Text('I agree to '),
                          InkWell(
                            onTap: () => _showTermsDialog('Terms & Conditions'),
                            child: const Text(
                              'Terms & Conditions',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Text(' and '),
                          InkWell(
                            onTap: () => _showTermsDialog('Privacy Policy'),
                            child: const Text(
                              'Privacy Policy',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Text('.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: (_submitting || !_agreeTerms) ? null : _submit,
                  child: Text(_submitting ? 'Submitting...' : 'Submit'),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'By submitting this form you agree to our terms and conditions and privacy policy.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Contact us', style: TextStyle(fontWeight: FontWeight.w900)),
                SizedBox(height: 10),
                Row(children: [Icon(Icons.email, size: 18), SizedBox(width: 10), Text('support@autoscope.com')]),
                SizedBox(height: 8),
                Row(children: [Icon(Icons.phone, size: 18), SizedBox(width: 10), Text('+971 50 000 0000')]),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18),
                    SizedBox(width: 10),
                    Expanded(child: Text('UAE')),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0B1220), Color.fromARGB(255, 255, 3, 3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/images/contactus-1.jpg',
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    return _SectionShell(
      bg: const Color(0xFFF6F8FC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact Auto Scope', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          const Text(
            'Have a question or want to book a service? Send us a message and we’ll get back to you.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          isMobile
              ? Column(children: [form, const SizedBox(height: 14), info])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: form),
                    const SizedBox(width: 18),
                    Expanded(flex: 5, child: info),
                  ],
                ),
          const SizedBox(height: 18),
          const Text(
            'Inspections are visual and non-invasive assessments conducted at the time of inspection. '
            'Valuations are indicative and subject to market conditions.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// FOOTER
// =====================================================
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B1220),
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: const _WrapWidth(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Auto Scope • Buy Smart. Sell Confident.',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '© 2026 Auto Scope. All rights reserved.',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// INPUT FORMATTERS + VALIDATORS
// =====================================================
class EmailInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

String? emailValidator(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Email is required';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
    return 'Enter a valid email address';
  }
  return null;
}

class UaEPhoneInputFormatter extends TextInputFormatter {
  static const prefix = '+971';

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (!newValue.text.startsWith(prefix)) {
      return const TextEditingValue(
        text: prefix,
        selection: TextSelection.collapsed(offset: prefix.length),
      );
    }

    final filtered = newValue.text.replaceAll(RegExp(r'[^0-9+]'), '');
    final truncated = filtered.length > 13 ? filtered.substring(0, 13) : filtered;

    if (truncated.length < prefix.length) {
      return const TextEditingValue(
        text: prefix,
        selection: TextSelection.collapsed(offset: prefix.length),
      );
    }

    return TextEditingValue(
      text: truncated,
      selection: TextSelection.collapsed(offset: truncated.length),
    );
  }
}

String? uaePhoneValidator(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Phone number is required';
  if (!RegExp(r'^\+971\d{9}$').hasMatch(s)) {
    return 'Enter valid UAE number (+971XXXXXXXXX)';
  }
  return null;
}
