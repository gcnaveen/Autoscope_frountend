import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/public_navbar.dart';

class ProductValuationPage extends StatelessWidget {
  const ProductValuationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PublicNavBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Car Valuation',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    const Text(
                      'Get an estimated value for your car. Valuation includes the inspection checklist to justify the price.',
                      style: TextStyle(color: Colors.black54, height: 1.5),
                    ),
                    const SizedBox(height: 16),

                    const Text('Includes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: const [
                        _Bullet('All inspection checklist points'),
                        _Bullet('Condition summary'),
                        _Bullet('Defects & remarks'),
                        _Bullet('Photos & evidence'),
                        _Bullet('Estimated market value'),
                      ],
                    ),

                    const SizedBox(height: 18),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.go('/valuation'),
                          icon: const Icon(Icons.send),
                          label: const Text('Get Valuation'),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => context.go('/products'),
                          child: const Text('Back to Services'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Color(0xFF1E5EFF)),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
