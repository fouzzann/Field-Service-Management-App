import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:field_service_management_app/features/tasks/domain/entities/task_entity.dart';
import 'package:field_service_management_app/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:field_service_management_app/features/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:field_service_management_app/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:field_service_management_app/features/tasks/domain/usecases/update_task_status_usecase.dart';
import 'package:field_service_management_app/features/tasks/domain/usecases/update_task_usecase.dart';
import 'package:field_service_management_app/features/tasks/presentation/cubit/task_cubit.dart';
import 'package:field_service_management_app/features/tasks/presentation/cubit/task_state.dart';

class MockGetTasksUseCase extends Mock implements GetTasksUseCase {}
class MockCreateTaskUseCase extends Mock implements CreateTaskUseCase {}
class MockUpdateTaskStatusUseCase extends Mock implements UpdateTaskStatusUseCase {}
class MockDeleteTaskUseCase extends Mock implements DeleteTaskUseCase {}
class MockUpdateTaskUseCase extends Mock implements UpdateTaskUseCase {}

void main() {
  late MockGetTasksUseCase mockGetTasksUseCase;
  late MockCreateTaskUseCase mockCreateTaskUseCase;
  late MockUpdateTaskStatusUseCase mockUpdateTaskStatusUseCase;
  late MockDeleteTaskUseCase mockDeleteTaskUseCase;
  late MockUpdateTaskUseCase mockUpdateTaskUseCase;
  late TaskCubit taskCubit;

  final tTasks = [
    TaskEntity(
      taskId: '1',
      title: 'Fix AC',
      description: 'Ac cooling issue',
      priority: 'High',
      status: 'Pending',
      assignedAgentId: 'agent123',
      completionPhoto: '',
      createdAt: DateTime.utc(2026, 6, 25),
      updatedAt: DateTime.utc(2026, 6, 25),
    ),
  ];

  final tAgents = [
    {'uid': 'agent123', 'name': 'John Agent'}
  ];

  setUp(() {
    mockGetTasksUseCase = MockGetTasksUseCase();
    mockCreateTaskUseCase = MockCreateTaskUseCase();
    mockUpdateTaskStatusUseCase = MockUpdateTaskStatusUseCase();
    mockDeleteTaskUseCase = MockDeleteTaskUseCase();
    mockUpdateTaskUseCase = MockUpdateTaskUseCase();

    // Stub default usecase return values
    when(() => mockGetTasksUseCase.getAgents()).thenAnswer((_) async => tAgents);

    taskCubit = TaskCubit(
      getTasksUseCase: mockGetTasksUseCase,
      createTaskUseCase: mockCreateTaskUseCase,
      updateTaskStatusUseCase: mockUpdateTaskStatusUseCase,
      deleteTaskUseCase: mockDeleteTaskUseCase,
      updateTaskUseCase: mockUpdateTaskUseCase,
    );
  });

  tearDown(() {
    taskCubit.close();
  });

  test('initial state should be TaskInitial', () {
    expect(taskCubit.state, equals(TaskInitial()));
  });

  group('loadTasks', () {
    blocTest<TaskCubit, TaskState>(
      'should subscribe to stream and emit [TaskLoading, TasksLoaded] when tasks are loaded',
      build: () {
        when(() => mockGetTasksUseCase.getStream()).thenAnswer((_) => Stream.value(tTasks));
        return taskCubit;
      },
      act: (cubit) => cubit.loadTasks(),
      expect: () => [
        TaskLoading(),
        TasksLoaded(
          allTasks: tTasks,
          filteredTasks: tTasks,
          agents: tAgents,
          selectedStatusFilter: null,
          selectedAgentFilter: null,
        ),
      ],
      verify: (_) {
        verify(() => mockGetTasksUseCase.getStream()).called(1);
      },
    );
  });

  group('updateStatus', () {
    blocTest<TaskCubit, TaskState>(
      'should call UpdateTaskStatusUseCase and emit no state changes on success (stream updates state)',
      build: () {
        when(() => mockUpdateTaskStatusUseCase(any(), any(), localPhotoPath: any(named: 'localPhotoPath')))
            .thenAnswer((_) async => {});
        return taskCubit;
      },
      act: (cubit) => cubit.updateStatus('1', 'In Progress'),
      expect: () => [],
      verify: (_) {
        verify(() => mockUpdateTaskStatusUseCase('1', 'In Progress')).called(1);
      },
    );
  });
}
