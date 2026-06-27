import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_state.dart';

// This Cubit manages the user login session.
// It tracks whether a user is logged in (Authenticated) or logged out (Unauthenticated).
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthCubit({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(AuthInitial()); // Start at Initial state.

  // Checks if the user is already logged in (run when the app launches).
  Future<void> checkAuth() async {
    try {
      final user = await getCurrentUserUseCase();
      if (user != null) {
        emit(Authenticated(user)); // Yes, user session found. Go to home page.
      } else {
        emit(Unauthenticated()); // No user found. Go to login page.
      }
    } catch (_) {
      emit(Unauthenticated()); // Fallback to unauthenticated on error.
    }
  }

  // Logs the user in using their email and password.
  Future<void> login(String email, String password) async {
    emit(AuthLoading()); // Show spinner/progress indicators in UI.
    try {
      final user = await loginUseCase(email, password);
      emit(Authenticated(user)); // Successfully logged in.
    } catch (e) {
      // Login failed. Tell UI the error message.
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // Logs out the current user session.
  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await logoutUseCase();
      emit(Unauthenticated()); // Successfully logged out.
    } catch (e) {
      // Logout failed.
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
