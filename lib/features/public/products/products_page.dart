import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/public_navbar.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String? _selectedType; // 'inspection' | 'valuation'

  // Supports:
  // - /products?focus=inspection
  // - #/products?focus=inspection (web hash routing)
  String? _resolveFocus(BuildContext context) {
    // 1) try go_router
    try {
      final uri = GoRouterState.of(context).uri;
      return uri.queryParameters['focus'];
    } catch (_) {}

    // 2) fallback for hash routing
    final frag = Uri.base.fragment; // "/products?focus=inspection"
    final qIndex = frag.indexOf('?');
    if (qIndex != -1) {
      final qp = Uri.splitQueryString(frag.substring(qIndex + 1));
      return qp['focus'];
    }
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_selectedType != null) return;

    final focus = (_resolveFocus(context) ?? '').toLowerCase();
    if (focus.contains('valuation')) {
      _selectedType = 'valuation';
    } else if (focus.contains('inspection')) {
      _selectedType = 'inspection';
    } else {
      _selectedType = 'inspection';
    }
  }

  void _goNext() {
    final t = _selectedType ?? 'inspection';
    context.go('/request?type=$t');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PublicNavBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const _ProductsHero(),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final isWide = c.maxWidth >= 980;

                      final inspectionCard = _ProductCard(
                        selected: _selectedType == 'inspection',
                        // chipText: 'Most popular',
                        title: 'Car Inspection',
                        subtitle:
                            'Get a detailed car condition report with defects & checklist.',
                        imageUrl: '',
                        bullets: const [
                          'Exterior + interior checks',
                          'Mechanical basics + warning lights',
                          'Tyres, brakes, suspension',
                          'Report after completion',
                        ],
                        icon: Icons.fact_check,
                        onTap: () => setState(() => _selectedType = 'inspection'),
                      );

                      final valuationCard = _ProductCard(
                        selected: _selectedType == 'valuation',
                        // chipText: 'Includes inspection',
                        title: 'Car Valuation and Inspection',
                        subtitle:
                            'Know your car’s value based on condition + market demand.',
                        imageUrl: '',
                        bullets: const [
                          'Market demand & trends',
                          'Estimated market value',
                          'Condition + inspection findings',
                        ],
                        // ✅ AED icon instead of rupee
                        iconWidget: const _CurrencyBadge(text: 'AED'),
                        onTap: () => setState(() => _selectedType = 'valuation'),
                      );

                      final cards = isWide
                          ? IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: inspectionCard),
                                  const SizedBox(width: 18),
                                  Expanded(child: valuationCard),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                inspectionCard,
                                const SizedBox(height: 16),
                                valuationCard,
                              ],
                            );

                      final primaryBtnText = (_selectedType == 'valuation')
                          ? 'Request Valuation'
                          : 'Request Inspection';

                      return Column(
                        children: [
                          cards,
                          const SizedBox(height: 18),
                          SizedBox(
                            width: isWide ? 420 : double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed: _goNext,
                              child: Text(primaryBtnText),
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
    );
  }
}

class _ProductsHero extends StatelessWidget {
  const _ProductsHero();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 900;

    return Container(
      height: isMobile ? 260 : 320,
      decoration: const BoxDecoration(color: Color(0xFF0B1220)),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 1,
              child: Image.asset(
                'assets/images/inspection-6.jpg',
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
                    const Color(0xFF0B1220).withOpacity(0.90),
                    const Color(0xFF0B1220).withOpacity(0.35),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Services',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Choose a service to raise your request.',
                            style: TextStyle(
                              color: Colors.white70,
                              height: 1.4,
                              fontSize: 15,
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
        ],
      ),
    );
  }
}

/// ✅ Small "AED" badge that fits like an icon
class _CurrencyBadge extends StatelessWidget {
  final String text;
  const _CurrencyBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final bool selected;
  // final String chipText;
  final String title;
  final String subtitle;
  final String imageUrl;
  final List<String> bullets;

  // OLD: final IconData icon;
  final IconData? icon;
  final Widget? iconWidget;

  final VoidCallback onTap;

  const _ProductCard({
    required this.selected,
    // required this.chipText,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.bullets,
    this.icon,
    this.iconWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? const Color(0xFF1E5EFF) : Colors.black.withOpacity(0.10);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: selected ? 1.6 : 1.0),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 14),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Opacity(
                      opacity: 0.10,
                      child: SizedBox(
                        width: 220,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E5EFF).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: DefaultTextStyle(
                              style: const TextStyle(color: Color(0xFF1E5EFF)),
                              child: IconTheme(
                                data: const IconThemeData(
                                  color: Color(0xFF1E5EFF),
                                ),
                                child: iconWidget ??
                                    Icon(icon ?? Icons.local_offer_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          // Container(
                          //   padding: const EdgeInsets.symmetric(
                          //       horizontal: 10, vertical: 6),
                          //   decoration: BoxDecoration(
                          //     color: selected
                          //         ? const Color(0xFF1E5EFF).withOpacity(0.12)
                          //         : Colors.black.withOpacity(0.06),
                          //     borderRadius: BorderRadius.circular(999),
                          //   ),
                          //   child: Text(
                          //     chipText,
                          //     style: TextStyle(
                          //       fontWeight: FontWeight.w800,
                          //       color: selected
                          //           ? const Color(0xFF1E5EFF)
                          //           : Colors.black54,
                          //       fontSize: 12,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...bullets.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 18,
                                color: Color(0xFF1E5EFF),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(b)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 18,
                            color: selected
                                ? const Color(0xFF1E5EFF)
                                : Colors.black38,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selected ? 'Selected' : 'Tap to select',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? const Color(0xFF1E5EFF)
                                  : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
