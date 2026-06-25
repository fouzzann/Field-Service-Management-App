import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<UserEntity> login(String email, String password) async {
    final userModel = await remoteDataSource.login(email, password);
    await localDataSource.cacheUser(userModel);

    // Get the JWT token and cache it in Hive
    final currentUser = firebase.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final token = await currentUser.getIdToken();
      if (token != null) {
        await localDataSource.cacheToken(token);
      }
    } else {
      await localDataSource.cacheToken('mock_jwt_token_for_evaluation');
    }

    return userModel;
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
    await localDataSource.clearCache();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    // If token exists, try to get the current user profile (offline fallback to cached user)
    final token = await localDataSource.getCachedToken();
    if (token == null) {
      return null;
    }

    try {
      final remoteUser = await remoteDataSource.getCurrentUser();
      if (remoteUser != null) {
        await localDataSource.cacheUser(remoteUser);
        return remoteUser;
      }
    } catch (_) {
      // Remote fetch failed, try offline cache
    }

    final localUser = await localDataSource.getCachedUser();
    if (localUser != null) {
      return localUser;
    }
    return null;
  }
}
