import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/create_task_usecase.dart';
import '../../../domain/usecases/delete_task_usecase.dart';
import '../../../domain/usecases/get_tasks_usecase.dart';
import '../../../domain/usecases/update_task_status_usecase.dart';
import '../../../../task/domain/repositories/task_repository.dart';
import '../../../../task/domain/entities/task_entity.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasksUseCase getTasksUseCase;
  final CreateTaskUseCase createTaskUseCase;
  final UpdateTaskStatusUseCase updateTaskStatusUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;
  final TaskRepository taskRepository;

  StreamSubscription? _tasksSubscription;

  TaskBloc({
    required this.getTasksUseCase,
    required this.createTaskUseCase,
    required this.updateTaskStatusUseCase,
    required this.deleteTaskUseCase,
    required this.taskRepository,
  }) : super(TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<TasksUpdated>(_onTasksUpdated);
    on<CreateTaskEvent>(_onCreateTask);
    on<UpdateTaskEvent>(_onUpdateTask);
    on<UpdateStatusEvent>(_onUpdateStatus);
    on<DeleteTaskEvent>(_onDeleteTask);
    on<FilterTasksEvent>(_onFilterTasks);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    
    await _tasksSubscription?.cancel();

    _tasksSubscription = getTasksUseCase.getStream().listen(
      (tasks) {
        add(TasksUpdated(tasks));
      },
      onError: (error) {
        emit(TaskError(error.toString()));
      },
    );
  }

  Future<void> _onTasksUpdated(TasksUpdated event, Emitter<TaskState> emit) async {
    final currentState = state;
    List<Map<String, String>> agents = [];
    if (currentState is TasksLoaded) {
      agents = currentState.agents;
    } else {
      try {
        agents = await getTasksUseCase.getAgents();
      } catch (_) {}
    }

    String? statusFilter;
    String? agentFilter;
    if (currentState is TasksLoaded) {
      statusFilter = currentState.selectedStatusFilter;
      agentFilter = currentState.selectedAgentFilter;
    }

    final filtered = _applyFilters(event.tasks, statusFilter, agentFilter);

    emit(TasksLoaded(
      allTasks: event.tasks,
      filteredTasks: filtered,
      agents: agents,
      selectedStatusFilter: statusFilter,
      selectedAgentFilter: agentFilter,
    ));
  }

  Future<void> _onCreateTask(CreateTaskEvent event, Emitter<TaskState> emit) async {
    try {
      await createTaskUseCase(event.task);
    } catch (e) {
      emit(TaskError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateTask(UpdateTaskEvent event, Emitter<TaskState> emit) async {
    try {
      await taskRepository.updateTask(event.task);
    } catch (e) {
      emit(TaskError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateStatus(UpdateStatusEvent event, Emitter<TaskState> emit) async {
    try {
      await updateTaskStatusUseCase(
        event.taskId,
        event.status,
        localPhotoPath: event.localPhotoPath,
      );
    } catch (e) {
      emit(TaskError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteTask(DeleteTaskEvent event, Emitter<TaskState> emit) async {
    try {
      await deleteTaskUseCase(event.taskId);
    } catch (e) {
      emit(TaskError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onFilterTasks(FilterTasksEvent event, Emitter<TaskState> emit) {
    final currentState = state;
    if (currentState is TasksLoaded) {
      final status = event.status == '' ? null : (event.status ?? currentState.selectedStatusFilter);
      final agent = event.agentId == '' ? null : (event.agentId ?? currentState.selectedAgentFilter);

      final filtered = _applyFilters(currentState.allTasks, status, agent);

      emit(currentState.copyWith(
        filteredTasks: filtered,
        selectedStatusFilter: status,
        selectedAgentFilter: agent,
        clearStatus: event.status == '',
        clearAgent: event.agentId == '',
      ));
    }
  }

  List<TaskEntity> _applyFilters(List<TaskEntity> tasks, String? status, String? agentId) {
    return tasks.where((task) {
      final matchesStatus = status == null || task.status.toLowerCase() == status.toLowerCase();
      final matchesAgent = agentId == null || task.assignedAgentId == agentId;
      return matchesStatus && matchesAgent;
    }).toList();
  }

  @override
  Future<void> close() {
    _tasksSubscription?.cancel();
    return super.close();
  }
}
