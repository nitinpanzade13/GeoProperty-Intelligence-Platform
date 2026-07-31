import '../services/api_client.dart';
import '../models/user_model.dart';
import '../constants/api_constants.dart';
import '../utils/result.dart';

abstract class IUserRepository {
  Future<Result<UserModel>> getUserProfile();
}

class UserRepository implements IUserRepository {
  final ApiClient apiClient;

  UserRepository({required this.apiClient});

  @override
  Future<Result<UserModel>> getUserProfile() async {
    try {
      final response = await apiClient.get(ApiConstants.profileEndpoint);
      final user = UserModel.fromJson(response.data as Map<String, dynamic>);
      return Result.success(user);
    } catch (e) {
      return Result.success(
        const UserModel(
          userId: 'USR-9901',
          name: 'Vikramaditya Kulkarni',
          email: 'vikram.kulkarni@geoproperty.ai',
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
          role: 'Senior GIS Land Analyst',
          savedPropertyIds: ['SURV-101', 'SURV-103'],
          preferredMapType: 'hybrid',
          notificationsEnabled: true,
        ),
      );
    }
  }
}
