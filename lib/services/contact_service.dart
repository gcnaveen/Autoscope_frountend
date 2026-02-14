import 'api_client.dart';

class ContactService {
  final ApiClient apiClient;
  ContactService({required this.apiClient});

  Future<void> submitContact({
    required String name,
    required String email,
    required String number,
    required String message,
  }) async {
    await apiClient.postJson('/contact', {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'number': number.trim(),
      'message': message.trim(),
    });
  }
}
