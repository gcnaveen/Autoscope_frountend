import 'package:flutter/foundation.dart';
import '../models/role.dart';
import '../models/session.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient apiClient;
  final ValueNotifier<Session?> session = ValueNotifier<Session?>(null);

  AuthService({required this.apiClient});

  Role _parseRole(dynamic v) {
    final s = (v ?? '').toString().toLowerCase();
    if (s.contains('admin')) return Role.admin;
    if (s.contains('inspector')) return Role.inspector;
    return Role.user;
  }

  void _setSession({
    required String email,
    required Role role,
    required String token,
  }) {
    final s = Session(email: email.toLowerCase(), role: role, token: token);
    session.value = s;
    apiClient.setToken(token);
  }

  // =========================================================
  // USER OTP FLOW (only Role.user allowed)
  // =========================================================

  /// Send OTP for user login
  Future<bool> requestOtp(String email) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) return false;

    try {
      await apiClient.postJson('/auth/send-otp', {'email': e});
      return true;
    } on ApiException catch (ex) {
      if (ex.statusCode == 404) return false;
      rethrow;
    }
  }

  /// Verify OTP for user login (enforce: must be Role.user)
  Future<Session?> verifyOtpUser({
    required String email,
    required String otp,
  }) async {
    final e = email.trim().toLowerCase();
    final code = otp.trim();
    if (e.isEmpty || code.isEmpty) return null;

    final res = await apiClient.postJson('/auth/verify-otp', {
      'email': e,
      'otp': code,
    });

    final data = res['data'] ?? res;

    final token = (data['token'] ?? data['accessToken'] ?? data['jwt'])?.toString();
    final role = _parseRole(data['user']?['role'] ?? data['role']);

    if (token == null || token.isEmpty) {
      throw ApiException(500, 'Token missing in verify-otp response');
    }

    // ✅ Enforce: OTP login is only for USER
    if (role != Role.user) {
      // Clear any accidental state
      logout();
      throw ApiException(403, 'OTP login is only allowed for users.');
    }

    _setSession(email: e, role: role, token: token);
    return session.value;
  }

  // =========================================================
  // STAFF PASSWORD FLOW (only Role.admin / Role.inspector allowed)
  // =========================================================

  /// Email+Password login for staff (admin/inspector)
  Future<Session?> loginWithPassword({
    required String email,
    required String password,
  }) async {
    final e = email.trim().toLowerCase();
    final p = password.trim();
    if (e.isEmpty || p.isEmpty) return null;

    final res = await apiClient.postJson('/auth/login', {
      'email': e,
      'password': p,
    });

    final data = res['data'] ?? res;

    final token = (data['token'] ?? data['accessToken'] ?? data['jwt'])?.toString();
    final role = _parseRole(data['user']?['role'] ?? data['role']);

    if (token == null || token.isEmpty) {
      throw ApiException(500, 'Token missing in login response');
    }

    // ✅ Enforce: Password login NOT allowed for USER
    if (role == Role.user) {
      logout();
      throw ApiException(403, 'Users must login via OTP. Staff login is only for Admin/Inspector.');
    }

    _setSession(email: e, role: role, token: token);
    return session.value;
  }

  // =========================================================
  // Optional: Register user (used during request submission)
  // =========================================================
  Future<void> registerUserIfNeeded({
    required String email,
    String? name,
    String? phone,
  }) async {
    try {
      await apiClient.postJson('/auth/register', {
        'email': email.toLowerCase(),
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        'role': 'user',
      });
    } catch (e) {
      if (e is ApiException && (e.statusCode == 409)) return;
      rethrow;
    }
  }

  void logout() {
    session.value = null;
    apiClient.setToken(null);
  }
}
