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
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final isMobile = w < 900;

    // ✅ Full available height: screen - appbar - statusbar padding
    final fullH = mq.size.height - kToolbarHeight - mq.padding.top;

    // ✅ Keep sensible minimum height so content never feels cramped
    final heroHeight = (isMobile ? fullH : fullH).clamp(560.0, 900.0);

    return Container(
      height: heroHeight,
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
                      style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 1,
            ),
          ),
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
          _WrapWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
          body:
              'Honest and unbiased inspections. Realistic, market-driven valuations. Clear information before making decisions.',
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
            Text('Professional Vehicle Inspection',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
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
            Text('Professional Inspection & Valuation',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
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
            onPressed: () => context.go('/products'),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Book Service'),
          ),
        ),
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