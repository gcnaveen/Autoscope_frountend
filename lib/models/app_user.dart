class AppUser {
  final String id;
  final String email;

  final String? firstName;
  final String? lastName;

  /// Backend returns: role: "admin" | "user" | "inspector"
  final String role;

  /// Backend returns: status: "active" | "inactive" | etc
  final String status;

  final String? phone;

  /// Backend returns availableStatus (null or string)
  final String? availableStatus;

  final bool? isAssigned;
  final bool? otpVerified;

  /// Backend does not return this yet (see Autoscope Backend Brief ticket on
  /// workload-based inspector assignment ordering). Defaults to null until
  /// the backend adds support for it; parsed defensively from a couple of
  /// reasonable key name candidates so it starts working automatically
  /// (with zero frontend changes) once the backend ships one of them.
  final int? assignedInspectionsCount;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.firstName,
    this.lastName,
    this.phone,
    this.availableStatus,
    this.isAssigned,
    this.otpVerified,
    this.assignedInspectionsCount,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName {
    final n = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return n.isEmpty ? email.split('@').first : n;
  }

  factory AppUser.fromJson(Map<String, dynamic> j) {
    DateTime? dt(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    int? assignedCount(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return AppUser(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      firstName: j['firstName']?.toString(),
      lastName: j['lastName']?.toString(),
      role: (j['role'] ?? 'user').toString(),
      status: (j['status'] ?? 'unknown').toString(),
      phone: j['phone']?.toString(),
      availableStatus: j['availableStatus']?.toString(),
      isAssigned: j['is_assigned'] == true,
      otpVerified: j['otpVerified'] == true,
      assignedInspectionsCount: assignedCount(
        j['assignedInspectionsCount'] ?? j['assigned_inspections_count'] ?? j['activeAssignmentsCount'],
      ),
      createdAt: dt(j['createdAt']),
      updatedAt: dt(j['updatedAt']),
    );
  }
}
