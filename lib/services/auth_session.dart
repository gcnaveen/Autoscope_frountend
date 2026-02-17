import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSession extends ChangeNotifier {
  AuthSession({void Function(String? token)? onTokenChanged})
      : _onTokenChanged = onTokenChanged;

  static const _kToken = 'auth_token';
  static const _kExpiryMs = 'auth_expiry_ms';

  final void Function(String? token)? _onTokenChanged;

  String? _token;
  DateTime? _expiry;
  bool _ready = false;
  Timer? _logoutTimer;

  bool get ready => _ready;
  String? get token => _token;
  DateTime? get expiry => _expiry;

  bool get isExpired => _expiry != null && DateTime.now().isAfter(_expiry!);
  bool get isLoggedIn => _token != null && _token!.isNotEmpty && !isExpired;

  /// Call in main() BEFORE runApp()
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    final expiryMs = prefs.getInt(_kExpiryMs);
    _expiry = expiryMs == null ? null : DateTime.fromMillisecondsSinceEpoch(expiryMs);

    if (_token != null && isExpired) {
      await logout(); // clears stored values
    } else {
      _scheduleLogoutAtExpiry();
      _onTokenChanged?.call(_token); // restore token into ApiClient
    }

    _ready = true;
    notifyListeners();
  }

  /// Use this after login success (OTP or Staff).
  /// Example: authSession.login(token: tokenFromApi, ttl: Duration(hours: 8));
  Future<void> login({
    required String token,
    Duration ttl = const Duration(hours: 8), // ✅ force logout after 8 hours
  }) async {
    final prefs = await SharedPreferences.getInstance();

    _token = token;
    _expiry = DateTime.now().add(ttl);

    await prefs.setString(_kToken, _token!);
    await prefs.setInt(_kExpiryMs, _expiry!.millisecondsSinceEpoch);

    _onTokenChanged?.call(_token);
    _scheduleLogoutAtExpiry();
    notifyListeners();
  }

  Future<void> logout() async {
    _logoutTimer?.cancel();
    _logoutTimer = null;

    _token = null;
    _expiry = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kExpiryMs);

    _onTokenChanged?.call(null);
    notifyListeners();
  }

  void _scheduleLogoutAtExpiry() {
    _logoutTimer?.cancel();
    if (_expiry == null) return;

    final diff = _expiry!.difference(DateTime.now());
    if (diff.isNegative) {
      logout();
      return;
    }

    _logoutTimer = Timer(diff, () {
      logout();
    });
  }

  /// Optional: logout at a FIXED time daily (example 23:00).
  void scheduleDailyLogout({required int hour, required int minute}) {
    _logoutTimer?.cancel();

    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute);
    if (!target.isAfter(now)) target = target.add(const Duration(days: 1));

    _logoutTimer = Timer(target.difference(now), () {
      logout();
    });
  }
}
