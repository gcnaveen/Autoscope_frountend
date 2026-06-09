import 'package:flutter/material.dart';
import 'inspection_report_page.dart';

/// Publicly accessible report page — no login required.
/// Route: /viewreport/:inspectionId
class ViewReportPage extends StatelessWidget {
  final String inspectionId;
  const ViewReportPage({super.key, required this.inspectionId});

  @override
  Widget build(BuildContext context) {
    return InspectionReportPage(
      inspectionId: inspectionId,
      isAdminContext: false,
      printMode: false,
      isForApproval: false,
      noShell: true,
    );
  }
}
