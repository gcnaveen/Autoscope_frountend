import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import '../../../services/auth_service.dart';
import '../../../services/service_locator.dart';
import '../../shared/top_snackbar.dart';


class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final email = TextEditingController();
  final otp = TextEditingController();

  bool otpSent = false;
  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    otp.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-fill email if passed like /auth?email=...
    final prefill = GoRouterState.of(context).uri.queryParameters['email'];
    if (prefill != null && prefill.isNotEmpty && email.text.isEmpty) {
      email.text = prefill;
    }
  }

  Future<void> _sendOtp() async {
    final e = email.text.trim().toLowerCase();
    if (e.isEmpty) {
      showTopSnack(context, 'Emter email', variant: 'warning');
      // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter email')));
      return;
    }

    setState(() => loading = true);
    final ok = await authService.requestOtp(e);
    setState(() => loading = false);

    if (!mounted) return;

    if (!ok) {
      showTopSnack(context, 'No existing requests found for this email. Please Get Started.', variant: 'warning');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('No existing requests found for this email. Please Get Started.')),
      // );
      context.go('/valuation');
      return;
    }

    setState(() => otpSent = true);
    showTopSnack(context, 'OTP sent', variant: 'success');
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(content: Text('OTP sent (demo: use 123456 or check terminal).')),
    // );
  }

  Future<void> _verifyOtp() async {
    final e = email.text.trim().toLowerCase();
    final code = otp.text.trim();

    if (code.isEmpty) {
      showTopSnack(context, 'Enter OTP', variant: 'warning');
      // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter OTP')));
      return;
    }

    setState(() => loading = true);
    final s = await authService.verifyOtpUser(email: e, otp: code);
    setState(() => loading = false);

    if (!mounted) return;

    if (s == null) {
      showTopSnack(context, 'Invalid OTP', variant: 'error');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Invalid OTP. Try again.')),
      // );
      return;
    }

    // router redirect will send to correct dashboard based on role
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Login', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Enter your email to receive OTP.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),

        TextField(
          controller: email,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        if (otpSent) ...[
          TextField(
            controller: otp,
            decoration: const InputDecoration(
              labelText: 'OTP',
              prefixIcon: Icon(Icons.lock_open_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        SizedBox(
          width: 200,
          height: 40,
          child: FilledButton(
            onPressed: loading ? null : (otpSent ? _verifyOtp : _sendOtp),
            child: Text(loading ? 'Please wait...' : (otpSent ? 'Verify OTP' : 'Send OTP')),
          ),
        ),

        if (otpSent) ...[
          const SizedBox(height: 10),
          TextButton(
            onPressed: loading ? null : _sendOtp,
            child: const Text('Resend OTP'),
          ),
        ],
      ],
    );
  }
}
