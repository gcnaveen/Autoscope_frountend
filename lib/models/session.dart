import 'role.dart';

class Session {
  final String email;
  final Role role;
  final String? token; // JWT or similar

  const Session({required this.email, required this.role, this.token});
}
