// class AdminDashboardData {
//   final int totalUsers;
//   final int totalInspectors;
//   final int totalChecklistTemplates;

//   final int totalRequests;
//   final int openRequests;

//   final List<DashboardLatestRequest> latestRequests;
//   final List<DashboardActivity> recentActivities;

//   AdminDashboardData({
//     required this.totalUsers,
//     required this.totalInspectors,
//     required this.totalChecklistTemplates,
//     required this.totalRequests,
//     required this.openRequests,
//     required this.latestRequests,
//     required this.recentActivities,
//   });

//   factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
//     // Your API docs: top-level { success, message, data: {...} }
//     final data = (json['data'] is Map<String, dynamic>)
//         ? (json['data'] as Map<String, dynamic>)
//         : json;

//     final inspectionRequests = (data['inspection_requests'] is Map<String, dynamic>)
//         ? (data['inspection_requests'] as Map<String, dynamic>)
//         : const <String, dynamic>{};

//     final latest = (inspectionRequests['latest_requests'] is List)
//         ? (inspectionRequests['latest_requests'] as List)
//         : const [];

//     final activities = (data['recent_activities'] is List)
//         ? (data['recent_activities'] as List)
//         : const [];

//     return AdminDashboardData(
//       totalUsers: _asInt(data['user_role_stats']['user']),
//       totalInspectors: _asInt(data['user_role_stats']['inspector']),
//       totalChecklistTemplates: _asInt(data['total_checklist_templates']),
//       totalRequests: _asInt(inspectionRequests['total_requests']),
//       openRequests: _asInt(inspectionRequests['open_requests']),
//       latestRequests: latest
//           .whereType<Map>()
//           .map((x) => DashboardLatestRequest.fromJson(Map<String, dynamic>.from(x)))
//           .toList(),
//       recentActivities: activities
//           .whereType<Map>()
//           .map((x) => DashboardActivity.fromJson(Map<String, dynamic>.from(x)))
//           .toList(),
//     );
//   }

//   static int _asInt(dynamic v) {
//     if (v is int) return v;
//     if (v is num) return v.toInt();
//     return int.tryParse((v ?? '').toString()) ?? 0;
//   }
// }

// class DashboardLatestRequest {
//   final String id;
//   final String type;
//   final String location;
//   final String status;

//   DashboardLatestRequest({
//     required this.id,
//     required this.type,
//     required this.location,
//     required this.status,
//   });

//   factory DashboardLatestRequest.fromJson(Map<String, dynamic> json) {
//     // docs: request_id, request_type, request_location, request_status
//     return DashboardLatestRequest(
//       id: (json['request_id'] ?? json['id'] ?? '').toString(),
//       type: (json['request_type'] ?? json['requestType'] ?? '').toString(),
//       location: (json['request_location'] ?? json['location'] ?? '').toString(),
//       status: (json['request_status'] ?? json['status'] ?? '').toString(),
//     );
//   }
// }

// class DashboardActivity {
//   final String action;
//   final String description;

//   DashboardActivity({required this.action, required this.description});

//   factory DashboardActivity.fromJson(Map<String, dynamic> json) {
//     return DashboardActivity(
//       action: (json['action'] ?? '').toString(),
//       description: (json['description'] ?? '').toString(),
//     );
//   }
// }

class AdminDashboardData {
  final int totalUsers;
  final int totalInspectors;
  final int totalChecklistTemplates;

  final UserRoleStats userRoleStats;
  final UsersByStatus usersByStatus;
  final InspectorsByStatus inspectorsByStatus;
  final InspectionRequestsSummary inspectionRequests;

  final List<DashboardLatestRequest> latestRequests;
  final List<DashboardActivity> recentActivities;

  AdminDashboardData({
    required this.totalUsers,
    required this.totalInspectors,
    required this.totalChecklistTemplates,
    required this.userRoleStats,
    required this.usersByStatus,
    required this.inspectorsByStatus,
    required this.inspectionRequests,
    required this.latestRequests,
    required this.recentActivities,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;

    return AdminDashboardData(
      totalUsers: _toInt(data['total_users']),
      totalInspectors: _toInt(data['total_inspectors']),
      totalChecklistTemplates: _toInt(data['total_checklist_templates']),
      userRoleStats: UserRoleStats.fromJson(
        (data['user_role_stats'] ?? {}) as Map<String, dynamic>,
      ),
      usersByStatus: UsersByStatus.fromJson(
        (data['users_by_status'] ?? {}) as Map<String, dynamic>,
      ),
      inspectorsByStatus: InspectorsByStatus.fromJson(
        (data['inspectors_by_status'] ?? {}) as Map<String, dynamic>,
      ),
      inspectionRequests: InspectionRequestsSummary.fromJson(
        (data['inspection_requests'] ?? {}) as Map<String, dynamic>,
      ),
      latestRequests: ((data['inspection_requests']?['latest_requests'] ?? data['latest_requests'] ?? []) as List)
          .map((x) => DashboardLatestRequest.fromJson(x as Map<String, dynamic>))
          .toList(),
      recentActivities: ((data['recent_activities'] ?? []) as List)
          .map((x) => DashboardActivity.fromJson(x as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UserRoleStats {
  final int admin;
  final int inspector;
  final int user;

  UserRoleStats({required this.admin, required this.inspector, required this.user});

  factory UserRoleStats.fromJson(Map<String, dynamic> json) => UserRoleStats(
        admin: _toInt(json['admin']),
        inspector: _toInt(json['inspector']),
        user: _toInt(json['user']),
      );
}

class UsersByStatus {
  final int active;
  final int inactive;
  final int blocked;
  final int total;

  UsersByStatus({
    required this.active,
    required this.inactive,
    required this.blocked,
    required this.total,
  });

  factory UsersByStatus.fromJson(Map<String, dynamic> json) => UsersByStatus(
        active: _toInt(json['active']),
        inactive: _toInt(json['inactive']),
        blocked: _toInt(json['blocked']),
        total: _toInt(json['total']),
      );
}

class InspectorsByStatus {
  final int active;
  final int busy;
  final int inactive;
  final int blocked;
  final int total;

  InspectorsByStatus({
    required this.active,
    required this.busy,
    required this.inactive,
    required this.blocked,
    required this.total,
  });

  factory InspectorsByStatus.fromJson(Map<String, dynamic> json) => InspectorsByStatus(
        active: _toInt(json['active']),
        busy: _toInt(json['busy']),
        inactive: _toInt(json['inactive']),
        blocked: _toInt(json['blocked']),
        total: _toInt(json['total']),
      );
}

class InspectionRequestsSummary {
  final int totalRequests;
  final int openRequests;
  final RequestsByStatus byStatus;

  InspectionRequestsSummary({
    required this.totalRequests,
    required this.openRequests,
    required this.byStatus,
  });

  factory InspectionRequestsSummary.fromJson(Map<String, dynamic> json) => InspectionRequestsSummary(
        totalRequests: _toInt(json['total_requests']),
        openRequests: _toInt(json['open_requests']),
        byStatus: RequestsByStatus.fromJson((json['by_status'] ?? {}) as Map<String, dynamic>),
      );
}

class RequestsByStatus {
  final int pending;
  final int assigned;
  final int inProgress;
  final int completed;
  final int cancelled;
  final int total;

  RequestsByStatus({
    required this.pending,
    required this.assigned,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
    required this.total,
  });

  factory RequestsByStatus.fromJson(Map<String, dynamic> json) => RequestsByStatus(
        pending: _toInt(json['pending']),
        assigned: _toInt(json['assigned']),
        inProgress: _toInt(json['in_progress']),
        completed: _toInt(json['completed']),
        cancelled: _toInt(json['cancelled']),
        total: _toInt(json['total']),
      );
}

class DashboardLatestRequest {
  final String id;
  final String type;
  final String status;
  final String location;

  DashboardLatestRequest({
    required this.id,
    required this.type,
    required this.status,
    required this.location,
  });

  factory DashboardLatestRequest.fromJson(Map<String, dynamic> json) => DashboardLatestRequest(
        id: (json['request_id']  ?? '').toString(),
        type: (json['request_type'] ?? '').toString(),
        status: (json['request_status'] ?? '').toString(),
        location: (json['request_location'] ?? '').toString(),
      );
}

class DashboardActivity {
  final String action;
  final String description;

  DashboardActivity({required this.action, required this.description});

  factory DashboardActivity.fromJson(Map<String, dynamic> json) => DashboardActivity(
        action: (json['action'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
      );
}

// -------- helpers --------
int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? 0;
}
