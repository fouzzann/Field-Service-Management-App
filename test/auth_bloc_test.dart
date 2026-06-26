import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:field_service_management_app/features/authentication/domain/entities/user_entity.dart';
import 'package:field_service_management_app/features/authentication/domain/usecases/get_current_user_usecase.dart';
import 'package:field_service_management_app/features/authentication/domain/usecases/login_usecase.dart';
import 'package:field_service_management_app/features/authentication/domain/usecases/logout_usecase.dart';
import 'package:field_service_management_app/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:field_service_management_app/features/authentication/presentation/cubit/auth_state.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

void main() {
  late MockLoginUseCase mockLoginUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late AuthCubit authCubit;

  const tUser = UserEntity(
    uid: '123',
    name: 'TEST ADMIN',
    email: 'admin@test.com',
    role: 'admin',
  );

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    authCubit = AuthCubit(
      loginUseCase: mockLoginUseCase,
      logoutUseCase: mockLogoutUseCase,
      getCurrentUserUseCase: mockGetCurrentUserUseCase,
    );
  });

  tearDown(() {
    authCubit.close();
  });

  test('initial state should be AuthInitial', () {
    expect(authCubit.state, equals(AuthInitial()));
  });

  group('login', () {
    blocTest<AuthCubit, AuthState>(
      'should emit [AuthLoading, Authenticated] when login is successful',
      build: () {
        when(() => mockLoginUseCase(any(), any())).thenAnswer((_) async => tUser);
        return authCubit;
      },
      act: (cubit) => cubit.login('admin@test.com', 'password'),
      expect: () => [
        AuthLoading(),
        const Authenticated(tUser),
      ],
      verify: (_) {
        verify(() => mockLoginUseCase('admin@test.com', 'password')).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'should emit [AuthLoading, AuthError] when login fails',
      build: () {
        when(() => mockLoginUseCase(any(), any())).thenThrow(Exception('Invalid credentials'));
        return authCubit;
      },
      act: (cubit) => cubit.login('admin@test.com', 'wrong'),
      expect: () => [
        AuthLoading(),
        const AuthError('Invalid credentials'),
      ],
    );
  });

  group('logout', () {
    blocTest<AuthCubit, AuthState>(
      'should emit [AuthLoading, Unauthenticated] when logout is successful',
      build: () {
        when(() => mockLogoutUseCase()).thenAnswer((_) async => {});
        return authCubit;
      },
      act: (cubit) => cubit.logout(),
      expect: () => [
        AuthLoading(),
        Unauthenticated(),
      ],
      verify: (_) {
        verify(() => mockLogoutUseCase()).called(1);
      },
    );
  });
}
