import '../config/api_config.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'checklist_templates_service.dart';
import 'upload_service.dart';
import 'users_service.dart';
import 'checklists_service.dart';
import 'admin_dashboard_service.dart';
import 'inspection_requests_service.dart';
import 'contact_service.dart';
import 'user_requests_service.dart';
import 'reviews_service.dart';
import 'dropdown_config_service.dart';


final apiClient = ApiClient(baseUrl: ApiConfig.apiBaseUrl);
final dropdownConfigService = DropdownConfigService(apiClient: apiClient);

final authService = AuthService(apiClient: apiClient);
final usersService = UsersService(apiClient: apiClient);
final checklistsService = ChecklistsService(apiClient: apiClient);
final adminDashboardService = AdminDashboardService(apiClient: apiClient);
final inspectionRequestsService = InspectionRequestsService(apiClient: apiClient);
final contactService = ContactService(apiClient: apiClient);
final userRequestsService = UserRequestsService(apiClient: apiClient);
final checklistTemplatesService = ChecklistTemplatesService(apiClient: apiClient);
final uploadService = UploadService(apiClient: apiClient);
final reviewsService = ReviewsService(apiClient: apiClient);




