class Inspection {
  final String id;
  final String userEmail;
  final String productType; // inspection | valuation
  final String status;
  final String? assignedInspectorEmail;

  // request details
  final String ownerName;
  final String phone;
  final String carBrand;
  final String carModel;
  final String regNumber;
  final String location;

  const Inspection({
    required this.id,
    required this.userEmail,
    required this.productType,
    required this.status,
    required this.ownerName,
    required this.phone,
    required this.carBrand,
    required this.carModel,
    required this.regNumber,
    required this.location,
    this.assignedInspectorEmail,
  });

  factory Inspection.fromJson(Map<String, dynamic> j) {
    String s(dynamic x) => (x ?? '').toString();
    return Inspection(
      id: s(j['id'] ?? j['_id'] ?? j['inspectionId']),
      userEmail: s(j['email'] ?? j['userEmail'] ?? j['user_email']).toLowerCase(),
      productType: s(j['productType'] ?? j['product_type'] ?? j['type'] ?? 'inspection'),
      status: s(j['status'] ?? 'created'),
      assignedInspectorEmail: (j['assignedInspectorEmail'] ?? j['assignedTo'] ?? j['inspectorEmail'])?.toString(),
      ownerName: s(j['ownerName'] ?? j['owner_name'] ?? j['name']),
      phone: s(j['phone'] ?? j['mobile'] ?? j['contactNumber']),
      carBrand: s(j['carBrand'] ?? j['brand']),
      carModel: s(j['carModel'] ?? j['model']),
      regNumber: s(j['regNumber'] ?? j['registrationNumber'] ?? j['reg_no']),
      location: s(j['location']),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'email': userEmail,
        'productType': productType,
        'ownerName': ownerName,
        'phone': phone,
        'carBrand': carBrand,
        'carModel': carModel,
        'regNumber': regNumber,
        'location': location,
      };
}
