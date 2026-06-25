import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:field_service_management_app/core/network/network_info.dart';
import 'package:field_service_management_app/features/task/domain/usecases/sync_tasks_usecase.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/sync/sync_bloc.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/sync/sync_event.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/sync/sync_state.dart';

class MockNetworkInfo extends Mock implements NetworkInfo {}
class MockSyncTasksUseCase extends Mock implements SyncTasksUseCase {}

void main() {
  late MockNetworkInfo mockNetworkInfo;
  late MockSyncTasksUseCase mockSyncTasksUseCase;
  late SyncBloc syncBloc;

  setUp(() {
    mockNetworkInfo = MockNetworkInfo();
    mockSyncTasksUseCase = MockSyncTasksUseCase();
    syncBloc = SyncBloc(
      networkInfo: mockNetworkInfo,
      syncTasksUseCase: mockSyncTasksUseCase,
    );
  });

  tearDown(() {
    syncBloc.close();
  });

  test('initial state should be SyncInitial', () {
    expect(syncBloc.state, equals(SyncInitial()));
  });

  group('TriggerSync', () {
    blocTest<SyncBloc, SyncState>(
      'should emit [SyncInProgress, SyncSuccess] when online and sync is successful',
      build: () {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockSyncTasksUseCase()).thenAnswer((_) async => {});
        return syncBloc;
      },
      act: (bloc) => bloc.add(TriggerSync()),
      expect: () => [
        SyncInProgress(),
        SyncSuccess(),
      ],
      verify: (_) {
        verify(() => mockSyncTasksUseCase()).called(1);
      },
    );

    blocTest<SyncBloc, SyncState>(
      'should emit [SyncInProgress, SyncFailure] when sync throws an exception',
      build: () {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockSyncTasksUseCase()).thenThrow(Exception('Server error'));
        return syncBloc;
      },
      act: (bloc) => bloc.add(TriggerSync()),
      expect: () => [
        SyncInProgress(),
        const SyncFailure('Exception: Server error'),
      ],
    );
  });
}
