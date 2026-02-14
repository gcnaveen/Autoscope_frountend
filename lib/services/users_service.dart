import '../models/app_user.dart';
import 'api_client.dart';

class UsersService {
  final ApiClient apiClient;
  UsersService({required this.apiClient});

  Future<List<AppUser>> listUsers() async {
    // final res = await apiClient.getJson('/users');
    final ts = DateTime.now().millisecondsSinceEpoch;
    final res = await apiClient.getJson('/users?ts=$ts');

    List<dynamic> items = [];

    if (res is Map<String, dynamic>) {
      final v1 = res['items'];
      if (v1 is List) items = v1;

      final data = res['data'];
      if (items.isEmpty && data is Map<String, dynamic>) {
        final v2 = data['users'];
        if (v2 is List) items = v2;
      }

      final v3 = res['users'];
      if (items.isEmpty && v3 is List) items = v3;
    }

    return items
        .whereType<Map>()
        .map((x) => AppUser.fromJson(Map<String, dynamic>.from(x)))
        .toList();
  }


  Future<AppUser> createUser({
    required String email,
    required String role,
    String? firstName,
    String? lastName,
    String? phone,
    String? password,
  }) async {
    final payload = <String, dynamic>{
      'email': email.toLowerCase(),
      'role': role,
      if (firstName != null && firstName.trim().isNotEmpty) 'firstName': firstName.trim(),
      if (lastName != null && lastName.trim().isNotEmpty) 'lastName': lastName.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (password != null && password.trim().isNotEmpty) 'password': password.trim(),
    };

    final res = await apiClient.postJson('/users', payload);

    // handle multiple backend response shapes
    Map<String, dynamic>? raw;

    if (res is Map<String, dynamic>) {
      // common shapes:
      // 1) { data: { user: {...} } }
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        final u = data['user'];
        if (u is Map<String, dynamic>) raw = u;

        // 2) { data: {...user fields...} }
        raw ??= data;
      }

      // 3) { user: {...} }
      final user = res['user'];
      if (raw == null && user is Map<String, dynamic>) raw = user;

      // 4) { ...user fields... }
      raw ??= res;
    }

    if (raw == null) {
      throw ApiException(500, 'Unexpected createUser response');
    }

    return AppUser.fromJson(raw);
  }

  Future<AppUser> createInspector({
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
  }) async {
    final res = await apiClient.postJson('/users', {
      'email': email.trim().toLowerCase(),
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'phone': phone.trim(),
      'role': 'inspector',
      'password': password.trim(),
    });

    Map<String, dynamic> raw;

    if (res is Map<String, dynamic>) {
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        raw = Map<String, dynamic>.from(data['user'] ?? data);
      } else {
        raw = Map<String, dynamic>.from(res['user'] ?? res);
      }
    } else {
      throw ApiException(500, 'Unexpected createInspector response');
    }

    return AppUser.fromJson(raw);
  }

  Future<void> blockUser(String id) async {
    await apiClient.putJson('/users/$id/block', {});
  }

  Future<AppUser> updateUser({
    required String id,
    String? firstName,
    String? lastName,
    String? phone,
    String? status,
    String? password, // ✅ add this
  }) async {
    final payload = <String, dynamic>{
      if (firstName != null) 'firstName': firstName.trim(),
      if (lastName != null) 'lastName': lastName.trim(),
      if (phone != null) 'phone': phone.trim(),
      if (status != null) 'status': status.trim(),
      if (password != null && password.trim().isNotEmpty) 'password': password.trim(),
    };

    final res = await apiClient.putJson('/users/$id', payload);

    Map<String, dynamic> raw;
    if (res is Map<String, dynamic>) {
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        raw = Map<String, dynamic>.from(data['user'] ?? data);
      } else {
        raw = Map<String, dynamic>.from(res['user'] ?? res);
      }
    } else {
      throw ApiException(500, 'Unexpected updateUser response');
    }

    return AppUser.fromJson(raw);
  }
}
