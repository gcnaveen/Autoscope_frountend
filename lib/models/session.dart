import 'role.dart';

class Session {
  final String id;
  final String email;
  final Role role;
  final String? token; // JWT or similar

  const Session({required this.id, required this.email, required this.role, this.token});
}
