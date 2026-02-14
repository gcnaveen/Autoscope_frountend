import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/service_locator.dart';
import '../../shared/top_snackbar.dart';

class OtpLoginForm extends StatefulWidget {
  const OtpLoginForm({super.key});

  @override
  State<OtpLoginForm> createState() => _OtpLoginFormState();
}

class _OtpLoginFormState extends State<OtpLoginForm> {
  final email = TextEditingController();
  final otp = TextEditingController();

  bool otpSent = false;
  bool sending = false;
  bool verifying = false;

  @override
  void dispose() {
    email.dispose();
    otp.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final e = email.text.trim().toLowerCase();
    if (e.isEmpty) {
      _snack('Please enter email','warning');
      return;
    }

    setState(() => sending = true);

    try {
      final ok = await authService.requestOtp(e);

      if (!mounted) return;

      if (!ok) {
        _snack('No existing requests for this email. Redirecting to Services…','error');
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        context.go('/products');
        return;
      }

      setState(() => otpSent = true);
      _snack('OTP sent. Please check your email.','success');
    } catch (err) {
      if (!mounted) return;
      _snack('OTP request failed: $err','error');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _verifyOtp() async {
    final e = email.text.trim().toLowerCase();
    final code = otp.text.trim();

    if (e.isEmpty || code.isEmpty) {
      _snack('Enter email and OTP','warning');
      return;
    }

    setState(() => verifying = true);

    try {
      await authService.verifyOtpUser(email: e, otp: code);
      // GoRouter redirect handles dashboard navigation after session is set.
    } catch (err) {
      if (!mounted) return;
      _snack('Verify failed: $err', 'error');
    } finally {
      if (mounted) setState(() => verifying = false);
    }
  }

  void _snack(String msg, String status) {
    showTopSnack(context, msg , variant: status);
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'example@domain.com',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton(
            onPressed: (sending || verifying) ? null : _sendOtp,
            child: Text(sending ? 'Sending…' : (otpSent ? 'Resend OTP' : 'Send OTP')),
          ),
        ),

        if (otpSent) ...[
          const SizedBox(height: 16),
          TextField(
            controller: otp,
            decoration: const InputDecoration(
              labelText: 'OTP',
              hintText: 'Enter the 6-digit OTP',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: verifying ? null : _verifyOtp,
              icon: const Icon(Icons.verified_user),
              label: Text(verifying ? 'Verifying…' : 'Verify & Login'),
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Demo info box
        // Container(
        //   width: double.infinity,
        //   padding: const EdgeInsets.all(12),
        //   decoration: BoxDecoration(
        //     color: const Color(0xFFF1F4FA),
        //     borderRadius: BorderRadius.circular(12),
        //     border: Border.all(color: Colors.black12),
        //   ),
        //   child: const Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       Text('Demo accounts (depends on backend data)',
        //           style: TextStyle(fontWeight: FontWeight.w800)),
        //       SizedBox(height: 6),
        //       Text('Admin: admin@autoscope.com'),
        //       Text('User: user@autoscope.com'),
        //       SizedBox(height: 6),
        //       Text(
        //         'If email is not found, you’ll be redirected to Products to raise a request.',
        //         style: TextStyle(color: Colors.black54),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}
