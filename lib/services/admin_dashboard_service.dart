// import '../models/admin_dashboard_data.dart';
// import 'api_client.dart';

// class AdminDashboardService {
//   final ApiClient apiClient;
//   AdminDashboardService({required this.apiClient});

//   Future<AdminDashboardData> getDashboard() async {
//     // NOTE: Your ApiClient should already prefix "/api" or not based on how you built it.
//     // In your other services you call "/users", so here use "/admin/dashboard".
//     final res = await apiClient.getJson('/admin/dashboard');

//     if (res is Map<String, dynamic>) {
//       return AdminDashboardData.fromJson(res);
//     }
//     throw ApiException(500, 'Unexpected dashboard response');
//   }
// }


import '../models/admin_dashboard_data.dart';
import 'api_client.dart';

class AdminDashboardService {
  final ApiClient apiClient;
  AdminDashboardService({required this.apiClient});

  Future<AdminDashboardData> getDashboard() async {
    // ✅ change endpoint if yours differs
    final res = await apiClient.getJson('/admin/dashboard');

    // API returns: { success, message, data: {...} }
    return AdminDashboardData.fromJson(res as Map<String, dynamic>);
  }
}