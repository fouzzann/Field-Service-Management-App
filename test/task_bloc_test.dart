import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:field_service_management_app/features/task/domain/entities/task_entity.dart';
import 'package:field_service_management_app/features/task/domain/usecases/create_task_usecase.dart';
import 'package:field_service_management_app/features/task/domain/usecases/delete_task_usecase.dart';
import 'package:field_service_management_app/features/task/domain/usecases/get_tasks_usecase.dart';
import 'package:field_service_management_app/features/task/domain/usecases/update_task_status_usecase.dart';
import 'package:field_service_management_app/features/task/domain/repositories/task_repository.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/task/task_bloc.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/task/task_event.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/task/task_state.dart';

class MockGetTasksUseCase extends Mock implements GetTasksUseCase {}
class MockCreateTaskUseCase extends Mock implements CreateTaskUseCase {}
class MockUpdateTaskStatusUseCase extends Mock implements UpdateTaskStatusUseCase {}
class MockDeleteTaskUseCase extends Mock implements DeleteTaskUseCase {}
class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockGetTasksUseCase mockGetTasksUseCase;
  late MockCreateTaskUseCase mockCreateTaskUseCase;
  late MockUpdateTaskStatusUseCase mockUpdateTaskStatusUseCase;
  late MockDeleteTaskUseCase mockDeleteTaskUseCase;
  late MockTaskRepository mockTaskRepository;
  late TaskBloc taskBloc;

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
    mockTaskRepository = MockTaskRepository();

    // Stub default usecase return values
    when(() => mockGetTasksUseCase.getAgents()).thenAnswer((_) async => tAgents);

    taskBloc = TaskBloc(
      getTasksUseCase: mockGetTasksUseCase,
      createTaskUseCase: mockCreateTaskUseCase,
      updateTaskStatusUseCase: mockUpdateTaskStatusUseCase,
      deleteTaskUseCase: mockDeleteTaskUseCase,
      taskRepository: mockTaskRepository,
    );
  });

  tearDown(() {
    taskBloc.close();
  });

  test('initial state should be TaskInitial', () {
    expect(taskBloc.state, equals(TaskInitial()));
  });

  group('LoadTasks', () {
    blocTest<TaskBloc, TaskState>(
      'should subscribe to stream and emit [TasksLoaded] when tasks are loaded',
      build: () {
        when(() => mockGetTasksUseCase.getStream()).thenAnswer((_) => Stream.value(tTasks));
        return taskBloc;
      },
      act: (bloc) => bloc.add(LoadTasks()),
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

  group('UpdateStatusEvent', () {
    blocTest<TaskBloc, TaskState>(
      'should call UpdateTaskStatusUseCase and emit no state changes on success (stream updates state)',
      build: () {
        when(() => mockUpdateTaskStatusUseCase(any(), any(), localPhotoPath: any(named: 'localPhotoPath')))
            .thenAnswer((_) async => {});
        return taskBloc;
      },
      act: (bloc) => bloc.add(const UpdateStatusEvent(taskId: '1', status: 'In Progress')),
      expect: () => [],
      verify: (_) {
        verify(() => mockUpdateTaskStatusUseCase('1', 'In Progress')).called(1);
      },
    );
  });
}
