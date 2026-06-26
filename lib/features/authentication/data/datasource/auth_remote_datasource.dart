import '../../../../core/services/auth_service.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final AuthService authService;

  AuthRemoteDataSourceImpl({required this.authService});

  @override
  Future<UserModel> login(String email, String password) async {
    return authService.login(email, password);
  }

  @override
  Future<void> logout() async {
    return authService.logout();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return authService.getCurrentUser();
  }
}
