// import 'package:flutter/material.dart';
// import '../../../models/role.dart';
// import '../../../services/auth_service.dart';

// class RegisterForm extends StatefulWidget {
//   const RegisterForm({super.key});

//   @override
//   State<RegisterForm> createState() => _RegisterFormState();
// }

// class _RegisterFormState extends State<RegisterForm> {
//   final email = TextEditingController();
//   final pass = TextEditingController();
//   final confirmPass = TextEditingController();

//   bool loading = false;

//   @override
//   void dispose() {
//     email.dispose();
//     pass.dispose();
//     confirmPass.dispose();
//     super.dispose();
//   }

//   Future<void> _register() async {
//     final e = email.text.trim();
//     final p = pass.text.trim();
//     final cp = confirmPass.text.trim();

//     if (e.isEmpty || p.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Email and password are required.')),
//       );
//       return;
//     }

//     if (p.length < 6) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Password must be at least 6 characters.')),
//       );
//       return;
//     }

//     if (p != cp) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Passwords do not match.')),
//       );
//       return;
//     }

//     setState(() => loading = true);

//     // ✅ Only USER registration allowed
//     final s = await authService.register(
//       email: e,
//       password: p,
//       role: Role.user,
//     );

//     setState(() => loading = false);

//     if (!mounted) return;

//     if (s == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Registration failed (email exists).')),
//       );
//       return;
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Account created. Please login.')),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // ✅ remove role selection UI entirely
//         // Container(
//         //   width: double.infinity,
//         //   padding: const EdgeInsets.all(12),
//         //   decoration: BoxDecoration(
//         //     color: const Color(0xFFF1F4FA),
//         //     borderRadius: BorderRadius.circular(12),
//         //   ),
//         //   child: const Text(
//         //     'Only car owners (Users) can register.\nInspectors are added by Admin.',
//         //     textAlign: TextAlign.center,
//         //     style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
//         //   ),
//         // ),
//         // const SizedBox(height: 14),

//         TextField(
//           controller: email,
//           decoration: const InputDecoration(
//             labelText: 'Email',
//             prefixIcon: Icon(Icons.email_outlined),
//             border: OutlineInputBorder(),
//           ),
//         ),
//         const SizedBox(height: 12),

//         TextField(
//           controller: pass,
//           obscureText: true,
//           decoration: const InputDecoration(
//             labelText: 'Password',
//             prefixIcon: Icon(Icons.lock_outline),
//             border: OutlineInputBorder(),
//           ),
//         ),
//         const SizedBox(height: 12),

//         TextField(
//           controller: confirmPass,
//           obscureText: true,
//           decoration: const InputDecoration(
//             labelText: 'Confirm Password',
//             prefixIcon: Icon(Icons.lock_reset_outlined),
//             border: OutlineInputBorder(),
//           ),
//         ),
//         const SizedBox(height: 14),

//         SizedBox(
//           width: double.infinity,
//           child: FilledButton(
//             onPressed: loading ? null : _register,
//             child: Text(loading ? 'Please wait...' : 'Create Account'),
//           ),
//         ),
//         const SizedBox(height: 10),

//         const Text(
//           'Admin account is pre-created and can only login.',
//           textAlign: TextAlign.center,
//           style: TextStyle(color: Colors.black54),
//         ),
//       ],
//     );
//   }
// }
