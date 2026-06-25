import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:field_service_management_app/features/auth/domain/entities/user_entity.dart';
import 'package:field_service_management_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:field_service_management_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:field_service_management_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:field_service_management_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:field_service_management_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:field_service_management_app/features/auth/presentation/bloc/auth_state.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

void main() {
  late MockLoginUseCase mockLoginUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late AuthBloc authBloc;

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
    authBloc = AuthBloc(
      loginUseCase: mockLoginUseCase,
      logoutUseCase: mockLogoutUseCase,
      getCurrentUserUseCase: mockGetCurrentUserUseCase,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  test('initial state should be AuthInitial', () {
    expect(authBloc.state, equals(AuthInitial()));
  });

  group('LoginSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, Authenticated] when login is successful',
      build: () {
        when(() => mockLoginUseCase(any(), any())).thenAnswer((_) async => tUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(const LoginSubmitted(email: 'admin@test.com', password: 'password')),
      expect: () => [
        AuthLoading(),
        const Authenticated(tUser),
      ],
      verify: (_) {
        verify(() => mockLoginUseCase('admin@test.com', 'password')).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, AuthError] when login fails',
      build: () {
        when(() => mockLoginUseCase(any(), any())).thenThrow(Exception('Invalid credentials'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const LoginSubmitted(email: 'admin@test.com', password: 'wrong')),
      expect: () => [
        AuthLoading(),
        const AuthError('Invalid credentials'),
      ],
    );
  });

  group('LogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, Unauthenticated] when logout is successful',
      build: () {
        when(() => mockLogoutUseCase()).thenAnswer((_) async => {});
        return authBloc;
      },
      act: (bloc) => bloc.add(LogoutRequested()),
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
