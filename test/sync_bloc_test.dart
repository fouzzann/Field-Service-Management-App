import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:field_service_management_app/core/network/network_info.dart';
import 'package:field_service_management_app/features/tasks/domain/usecases/sync_tasks_usecase.dart';
import 'package:field_service_management_app/features/tasks/presentation/cubit/sync_cubit.dart';
import 'package:field_service_management_app/features/tasks/presentation/cubit/sync_state.dart';

class MockNetworkInfo extends Mock implements NetworkInfo {}
class MockSyncTasksUseCase extends Mock implements SyncTasksUseCase {}

void main() {
  late MockNetworkInfo mockNetworkInfo;
  late MockSyncTasksUseCase mockSyncTasksUseCase;
  late SyncCubit syncCubit;

  setUp(() {
    mockNetworkInfo = MockNetworkInfo();
    mockSyncTasksUseCase = MockSyncTasksUseCase();
    syncCubit = SyncCubit(
      networkInfo: mockNetworkInfo,
      syncTasksUseCase: mockSyncTasksUseCase,
    );
  });

  tearDown(() {
    syncCubit.close();
  });

  test('initial state should be SyncInitial', () {
    expect(syncCubit.state, equals(SyncInitial()));
  });

  group('syncTasks', () {
    blocTest<SyncCubit, SyncState>(
      'should emit [SyncInProgress, SyncSuccess] when online and sync is successful',
      build: () {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockSyncTasksUseCase()).thenAnswer((_) async => {});
        return syncCubit;
      },
      act: (cubit) => cubit.syncTasks(),
      expect: () => [
        SyncInProgress(),
        SyncSuccess(),
      ],
      verify: (_) {
        verify(() => mockSyncTasksUseCase()).called(1);
      },
    );

    blocTest<SyncCubit, SyncState>(
      'should emit [SyncInProgress, SyncFailure] when sync throws an exception',
      build: () {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockSyncTasksUseCase()).thenThrow(Exception('Server error'));
        return syncCubit;
      },
      act: (cubit) => cubit.syncTasks(),
      expect: () => [
        SyncInProgress(),
        const SyncFailure('Exception: Server error'),
      ],
    );
  });
}
