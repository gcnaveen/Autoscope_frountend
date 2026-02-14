import 'package:flutter/material.dart';

class SectionBlock extends StatelessWidget {
  final String title;
  final String text;
  const SectionBlock({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(text),
          ],
        ),
      ),
    );
  }
}
