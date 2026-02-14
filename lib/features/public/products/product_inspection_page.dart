import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/public_navbar.dart';

class ProductInspectionPage extends StatelessWidget {
  const ProductInspectionPage({super.key});

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
                    const Text('Car Inspection',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    const Text(
                      'We inspect your car at the location and provide a structured checklist report with defects and condition notes.',
                      style: TextStyle(color: Colors.black54, height: 1.5),
                    ),
                    const SizedBox(height: 16),

                    const Text('What you get',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: const [
                        _Bullet('Exterior & body condition'),
                        _Bullet('Interior checks'),
                        _Bullet('Engine & fluids'),
                        _Bullet('Tyres & brakes'),
                        _Bullet('Photo evidence & notes'),
                        _Bullet('Final inspection report'),
                      ],
                    ),

                    const SizedBox(height: 18),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.go('/inspection'),
                          icon: const Icon(Icons.send),
                          label: const Text('Request Inspection'),
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
