import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/app_shell.dart';

class VehicleInputsHubPage extends StatelessWidget {
  const VehicleInputsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Vehicle Details Inputs',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 32),
            children: [
              Text(
                'Vehicle Details Inputs',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage all vehicle-related inputs used across inspection forms.',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 28),
              _HubCard(
                title: 'Makes & Models',
                subtitle:
                    'Add, edit, or remove vehicle makes and their model variants. Used in dependent dropdowns on the inspection form.',
                icon: Icons.directions_car_filled_outlined,
                onTap: () => context.go('/dashboard/admin/vehicle-catalog'),
              ),
              const SizedBox(height: 14),
              _HubCard(
                title: 'Configured Inputs',
                subtitle:
                    'Manage dropdown options shown in the inspection form — fuel type, transmission, exterior color, specs, and more.',
                icon: Icons.tune_outlined,
                onTap: () => context.go('/dashboard/admin/configure-inputs'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF1E5EFF);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.07)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_forward_ios,
                    size: 14, color: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
