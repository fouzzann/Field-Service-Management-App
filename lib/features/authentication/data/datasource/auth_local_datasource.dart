import '../../../../core/services/hive_service.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<void> cacheToken(String token);
  Future<UserModel?> getCachedUser();
  Future<String?> getCachedToken();
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final HiveService hiveService;
  static const String userKey = 'cached_user';
  static const String tokenKey = 'jwt_token';

  AuthLocalDataSourceImpl(this.hiveService);

  @override
  Future<void> cacheUser(UserModel user) async {
    await hiveService.userBox.put(userKey, user);
  }

  @override
  Future<void> cacheToken(String token) async {
    await hiveService.tokenBox.put(tokenKey, token);
  }

  @override
  Future<UserModel?> getCachedUser() async {
    return hiveService.userBox.get(userKey);
  }

  @override
  Future<String?> getCachedToken() async {
    return hiveService.tokenBox.get(tokenKey);
  }

  @override
  Future<void> clearCache() async {
    await hiveService.userBox.delete(userKey);
    await hiveService.tokenBox.delete(tokenKey);
  }
}
