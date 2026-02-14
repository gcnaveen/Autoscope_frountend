import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/public_navbar.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final scroll = ScrollController();

  final kHome = GlobalKey();
  final kFeatures = GlobalKey();
  final kPricing = GlobalKey();
  final kFaq = GlobalKey();
  final kContact = GlobalKey();

  void scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PublicNavBar(
        // onHome: () => scrollTo(kHome),
        // onFeatures: () => scrollTo(kFeatures),
        // onPricing: () => scrollTo(kPricing),
        // onFaq: () => scrollTo(kFaq),
        // onContact: () => scrollTo(kContact),
      ),
      body: SingleChildScrollView(
        controller: scroll,
        child: Column(
          children: [
            _HeroSection(key: kHome),
            _Section(
              key: kFeatures,
              title: 'Why Auto Scope',
              subtitle: 'A structured, reliable car inspection experience for customers, inspectors, and admins.',
              child: _FeatureGrid(),
            ),
            _AltSection(
              title: 'How it works',
              subtitle: 'Simple workflow from request → assignment → inspection → report.',
              child: _HowItWorks(),
            ),
            _Section(
              key: kPricing,
              title: 'Our Platform Package',
              subtitle: 'Simple plans (replace with real pricing later).',
              child: _Pricing(),
            ),
            _AltSection(
              title: 'Consistency for every inspection',
              subtitle: 'Standard checklist + notes + photos so results stay reliable.',
              child: _Highlights(),
            ),
            _Section(
              key: kFaq,
              title: 'Frequently asked questions',
              subtitle: 'Answers to common questions about inspections and reports.',
              child: _Faq(),
            ),
            _AltSection(
              key: kContact,
              title: 'Contact us',
              subtitle: 'Have questions? Send us a message and we’ll get back to you.',
              child: _Contact(),
            ),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

// ---------------- Layout helpers ----------------
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

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Section({super.key, required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: _WrapWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _AltSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _AltSection({super.key, required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: _WrapWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

// ---------------- Hero ----------------
class _HeroSection extends StatelessWidget {
  const _HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 900;

    return Container(
      height: isMobile ? 420 : 520,
      decoration: const BoxDecoration(color: Color(0xFF0B1220)),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.55,
              child: Image.network(
                'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=1600&q=80',
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
                    const Color(0xFF0B1220).withOpacity(0.85),
                    const Color(0xFF0B1220).withOpacity(0.30),
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
                constraints: const BoxConstraints(maxWidth: 650),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Car Inspection\nMade Easy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Raise an inspection request, get an inspector assigned, and receive a detailed checklist report — all in one platform.',
                      style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.go('/auth'),
                          icon: const Icon(Icons.login),
                          label: const Text('Get Started'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.description, color: Colors.white),
                          label: const Text('View Sample Report', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: const [
                        _HeroBadge(icon: Icons.check_circle, text: 'Role based access'),
                        _HeroBadge(icon: Icons.photo_library, text: 'Photos & evidence'),
                        _HeroBadge(icon: Icons.checklist, text: 'Structured checklist'),
                      ],
                    )
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

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

// ---------------- Features ----------------
class _FeatureGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 900;

    final left = Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Image.network(
            'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?auto=format&fit=crop&w=1400&q=80',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFE9EEF8),
              child: const Center(child: Icon(Icons.directions_car, size: 64)),
            ),
          ),
        ),
      ),
    );

    final right = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Built for real inspections', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            SizedBox(height: 10),
            _Bullet(text: 'Customer raises request with car + location details'),
            _Bullet(text: 'Admin assigns available inspector'),
            _Bullet(text: 'Inspector completes checklist onsite'),
            _Bullet(text: 'Final report generated with notes & photos'),
          ],
        ),
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          left,
          const SizedBox(height: 12),
          right,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 14),
        Expanded(child: right),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 18, color: Color(0xFF1E5EFF)),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

// ---------------- How it works ----------------
class _HowItWorks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = const [
      (Icons.edit_note, 'Raise Request', 'Customer submits inspection request'),
      (Icons.admin_panel_settings, 'Admin Assigns', 'Admin assigns available inspector'),
      (Icons.location_on, 'Onsite Inspection', 'Inspector visits car location'),
      (Icons.description, 'Report Generated', 'Checklist + photos + notes'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map((x) => SizedBox(
                width: 260,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(x.$1, size: 30, color: const Color(0xFF1E5EFF)),
                        const SizedBox(height: 10),
                        Text(x.$2, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(x.$3, style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ---------------- Pricing ----------------
class _Pricing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget card({
      required String title,
      required String price,
      required List<String> bullets,
      required bool featured,
    }) {
      return SizedBox(
        width: 360,
        child: Card(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: featured ? const Color(0xFF1E5EFF) : Colors.black12),
              color: featured ? const Color(0xFF1E5EFF).withOpacity(0.05) : Colors.white,
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(price, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                ...bullets.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check, size: 18, color: Color(0xFF1E5EFF)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(b)),
                        ],
                      ),
                    )),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go('/auth'),
                    child: const Text('Choose Plan'),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        card(
          title: 'Basic',
          price: '₹ 999 / inspection',
          bullets: const ['Checklist report', 'Photos upload', 'Customer tracking'],
          featured: false,
        ),
        card(
          title: 'Pro',
          price: '₹ 1,499 / inspection',
          bullets: const ['Everything in Basic', 'Priority assignment', 'Detailed notes & highlights'],
          featured: true,
        ),
      ],
    );
  }
}

// ---------------- Highlights ----------------
class _Highlights extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = const [
      (Icons.speed, 'Faster Process', 'Reduce inspection time with structured workflow.'),
      (Icons.verified, 'Consistent Results', 'Standard checklist ensures repeatable reporting.'),
      (Icons.shield, 'Role Based', 'User/Admin/Inspector access separation.'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map((x) => SizedBox(
                width: 330,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(x.$1, size: 30, color: const Color(0xFF1E5EFF)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(x.$2, style: const TextStyle(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 6),
                              Text(x.$3, style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ---------------- FAQ ----------------
class _Faq extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = const [
      ('How do I request an inspection?', 'Create an account and submit your car + location details.'),
      ('How is an inspector assigned?', 'Admins assign an available inspector to your request.'),
      ('What does the inspection include?', 'A structured checklist with notes, observations, and photos.'),
      ('How do I get my report?', 'Once inspection is completed, the report becomes available in your dashboard.'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: items
              .map((x) => ExpansionTile(
                    title: Text(x.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(x.$2, style: const TextStyle(color: Colors.black54)),
                      )
                    ],
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ---------------- Contact ----------------
class _Contact extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 900;

    final form = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            const TextField(
              maxLines: 4,
              decoration: InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                child: const Text('Send'),
              ),
            )
          ],
        ),
      ),
    );

    final info = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Reach us', style: TextStyle(fontWeight: FontWeight.w900)),
            SizedBox(height: 10),
            Row(children: [Icon(Icons.email, size: 18), SizedBox(width: 10), Text('support@autoscope.com')]),
            SizedBox(height: 8),
            Row(children: [Icon(Icons.phone, size: 18), SizedBox(width: 10), Text('+91 90000 00000')]),
            SizedBox(height: 8),
            Row(children: [Icon(Icons.location_on, size: 18), SizedBox(width: 10), Expanded(child: Text('Bangalore, India'))]),
          ],
        ),
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          form,
          const SizedBox(height: 12),
          info,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: form),
        const SizedBox(width: 14),
        Expanded(child: info),
      ],
    );
  }
}

// ---------------- Footer ----------------
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B1220),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: const _WrapWidth(
        child: Row(
          children: [
            Expanded(
              child: Text(
                '© 2026 Auto Scope • All rights reserved',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            Text('Privacy', style: TextStyle(color: Colors.white70)),
            SizedBox(width: 18),
            Text('Terms', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
