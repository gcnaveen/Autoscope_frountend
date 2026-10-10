import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../public/widgets/public_navbar.dart';
import 'widgets/otp_login_form.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PublicNavBar(),
      body: Center(
        child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LoginHeader(
                      title: 'User Login',
                      subtitle: 'We’ll send an OTP to your email to verify.',
                      badgeText: 'OTP',
                      onSwitch: () => context.go('/auth/staff'),
                      switchText: 'Staff Login',
                    ),
                    const SizedBox(height: 18),
                    const OtpLoginForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final String switchText;
  final VoidCallback onSwitch;

  const _LoginHeader({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.switchText,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    // Same breakpoint as the staff login header: on narrow phones the switch
    // button moves below so the title row never gets cramped.
    final isMobile = MediaQuery.sizeOf(context).width < 420;

    final switchBtn = TextButton(
      onPressed: onSwitch,
      child: Text(switchText),
    );

    final headerRow = Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0B1220),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.directions_car, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F4FA),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(width: 12),
          switchBtn,
        ],
      ],
    );

    if (!isMobile) return headerRow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        headerRow,
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerRight, child: switchBtn),
      ],
    );
  }
}
