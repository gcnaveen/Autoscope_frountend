// import 'package:flutter/foundation.dart';
// import '../models/role.dart';
// import '../models/session.dart';
// import 'api_client.dart';

// class AuthService {
//   final ApiClient apiClient;
//   final ValueNotifier<Session?> session = ValueNotifier<Session?>(null);

//   AuthService({required this.apiClient});

//   Role _parseRole(dynamic v) {
//     final s = (v ?? '').toString().toLowerCase();
//     if (s.contains('admin')) return Role.admin;
//     if (s.contains('inspector')) return Role.inspector;
//     return Role.user;
//   }

//   void _setSession({
//     required String email,
//     required Role role,
//     required String token,
//   }) {
//     final s = Session(email: email.toLowerCase(), role: role, token: token);
//     session.value = s;
//     apiClient.setToken(token);
//   }

//   // =========================================================
//   // USER OTP FLOW (only Role.user allowed)
//   // =========================================================

//   /// Send OTP for user login
//   Future<bool> requestOtp(String email) async {
//     final e = email.trim().toLowerCase();
//     if (e.isEmpty) return false;

//     try {
//       await apiClient.postJson('/auth/send-otp', {'email': e});
//       return true;
//     } on ApiException catch (ex) {
//       if (ex.statusCode == 404) return false;
//       rethrow;
//     }
//   }

//   /// Verify OTP for user login (enforce: must be Role.user)
//   Future<Session?> verifyOtpUser({
//     required String email,
//     required String otp,
//   }) async {
//     final e = email.trim().toLowerCase();
//     final code = otp.trim();
//     if (e.isEmpty || code.isEmpty) return null;

//     final res = await apiClient.postJson('/auth/verify-otp', {
//       'email': e,
//       'otp': code,
//     });

//     final data = res['data'] ?? res;

//     final token = (data['token'] ?? data['accessToken'] ?? data['jwt'])?.toString();
//     final role = _parseRole(data['user']?['role'] ?? data['role']);

//     if (token == null || token.isEmpty) {
//       throw ApiException(500, 'Token missing in verify-otp response');
//     }

//     // ✅ Enforce: OTP login is only for USER
//     if (role != Role.user) {
//       // Clear any accidental state
//       logout();
//       throw ApiException(403, 'OTP login is only allowed for users.');
//     }

//     _setSession(email: e, role: role, token: token);
//     return session.value;
//   }

//   // =========================================================
//   // STAFF PASSWORD FLOW (only Role.admin / Role.inspector allowed)
//   // =========================================================

//   /// Email+Password login for staff (admin/inspector)
//   Future<Session?> loginWithPassword({
//     required String email,
//     required String password,
//   }) async {
//     final e = email.trim().toLowerCase();
//     final p = password.trim();
//     if (e.isEmpty || p.isEmpty) return null;

//     final res = await apiClient.postJson('/auth/login', {
//       'email': e,
//       'password': p,
//     });

//     final data = res['data'] ?? res;

//     final token = (data['token'] ?? data['accessToken'] ?? data['jwt'])?.toString();
//     final role = _parseRole(data['user']?['role'] ?? data['role']);

//     if (token == null || token.isEmpty) {
//       throw ApiException(500, 'Token missing in login response');
//     }

//     // ✅ Enforce: Password login NOT allowed for USER
//     if (role == Role.user) {
//       logout();
//       throw ApiException(403, 'Users must login via OTP. Staff login is only for Admin/Inspector.');
//     }

//     _setSession(email: e, role: role, token: token);
//     return session.value;
//   }

//   // =========================================================
//   // Optional: Register user (used during request submission)
//   // =========================================================
//   Future<void> registerUserIfNeeded({
//     required String email,
//     String? name,
//     String? phone,
//   }) async {
//     try {
//       await apiClient.postJson('/auth/register', {
//         'email': email.toLowerCase(),
//         if (name != null) 'name': name,
//         if (phone != null) 'phone': phone,
//         'role': 'user',
//       });
//     } catch (e) {
//       if (e is ApiException && (e.statusCode == 409)) return;
//       rethrow;
//     }
//   }

//   void logout() {
//     session.value = null;
//     apiClient.setToken(null);
//   }
// }


import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/role.dart';
import '../models/session.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient apiClient;

  /// Your app already listens to this in router.dart
  final ValueNotifier<Session?> session = ValueNotifier<Session?>(null);

  /// NEW: router will wait until init() finishes (prevents redirect flicker/wrong redirect)
  final ValueNotifier<bool> ready = ValueNotifier<bool>(false);

  // =========================
  // Session policy (force logout)
  // =========================

  /// Force logout after this duration since login (default: 8 hours)
  Duration sessionTtl = const Duration(hours: 8);

  /// Optional: force logout at a fixed daily time (e.g., 22:30).
  /// If set, logout will happen at min(expiry, dailyLogoutTime).
  int? dailyLogoutHour;
  int? dailyLogoutMinute;

  // =========================
  // Storage keys
  // =========================
  static const String _kToken = 'autoscope_auth_token';
  static const String _kEmail = 'autoscope_auth_email';
  static const String _kRole = 'autoscope_auth_role';
  static const String _kExpiryMs = 'autoscope_auth_expiry_ms';

  Timer? _logoutTimer;

  AuthService({required this.apiClient});

  Role _parseRole(dynamic v) {
    final s = (v ?? '').toString().toLowerCase();
    if (s.contains('admin')) return Role.admin;
    if (s.contains('inspector')) return Role.inspector;
    return Role.user;
  }

  // =========================
  // INIT: restore session after refresh
  // =========================
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString(_kToken);
      final email = prefs.getString(_kEmail);
      final roleStr = prefs.getString(_kRole);
      final expiryMs = prefs.getInt(_kExpiryMs);

      if (token == null || token.isEmpty || email == null || email.isEmpty || roleStr == null) {
        // nothing stored
        session.value = null;
        apiClient.setToken(null);
        return;
      }

      final expiry = expiryMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expiryMs);

      // If expiry is missing, treat as logged out (safer)
      if (expiry == null || DateTime.now().isAfter(expiry)) {
        await logout();
        return;
      }

      final role = _parseRole(roleStr);

      // Restore
      final s = Session(email: email.toLowerCase(), role: role, token: token);
      session.value = s;
      apiClient.setToken(token);

      _scheduleLogout(expiry: expiry);
    } finally {
      ready.value = true;
    }
  }

  // =========================
  // Public helpers to configure force logout rules
  // =========================

  /// Example: authService.setSessionTtl(const Duration(hours: 6));
  void setSessionTtl(Duration ttl) {
    sessionTtl = ttl;
    // if already logged in, reschedule based on stored expiry in prefs
    _rescheduleFromPrefs();
  }

  /// Example: authService.setDailyLogoutTime(hour: 22, minute: 30);
  void setDailyLogoutTime({required int hour, required int minute}) {
    dailyLogoutHour = hour;
    dailyLogoutMinute = minute;
    _rescheduleFromPrefs();
  }

  Future<void> _rescheduleFromPrefs() async {
    if (session.value == null) return;
    final prefs = await SharedPreferences.getInstance();
    final expiryMs = prefs.getInt(_kExpiryMs);
    if (expiryMs == null) return;
    final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
    if (DateTime.now().isAfter(expiry)) {
      await logout();
      return;
    }
    _scheduleLogout(expiry: expiry);
  }

  // =========================
  // Internal: persist + schedule
  // =========================

  Future<void> _persistSession({
    required String email,
    required Role role,
    required String token,
    required DateTime expiry,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEmail, email.toLowerCase());
    await prefs.setString(_kRole, role.name); // stores: admin/user/inspector
    await prefs.setString(_kToken, token);
    await prefs.setInt(_kExpiryMs, expiry.millisecondsSinceEpoch);
  }

  void _scheduleLogout({required DateTime expiry}) {
    _logoutTimer?.cancel();
    _logoutTimer = null;

    DateTime target = expiry;

    // If daily logout time is set, logout earlier of (expiry, nextDailyLogout)
    if (dailyLogoutHour != null && dailyLogoutMinute != null) {
      final nextDaily = _nextDailyTime(dailyLogoutHour!, dailyLogoutMinute!);
      if (nextDaily.isBefore(target)) target = nextDaily;
    }

    final diff = target.difference(DateTime.now());
    if (diff.isNegative || diff.inMilliseconds == 0) {
      // already expired
      logout();
      return;
    }

    _logoutTimer = Timer(diff, () {
      logout();
    });
  }

  DateTime _nextDailyTime(int hour, int minute) {
    final now = DateTime.now();
    var t = DateTime(now.year, now.month, now.day, hour, minute);
    if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
    return t;
  }

  void _setSession({
    required String email,
    required Role role,
    required String token,
  }) async {
    final s = Session(email: email.toLowerCase(), role: role, token: token);
    session.value = s;
    apiClient.setToken(token);

    // expiry based on TTL
    final expiry = DateTime.now().add(sessionTtl);

    await _persistSession(email: email, role: role, token: token, expiry: expiry);
    _scheduleLogout(expiry: expiry);
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
      await logout();
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
      await logout();
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

  Future<void> logout() async {
    _logoutTimer?.cancel();
    _logoutTimer = null;

    session.value = null;
    apiClient.setToken(null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kEmail);
    await prefs.remove(_kRole);
    await prefs.remove(_kExpiryMs);
  }
}
