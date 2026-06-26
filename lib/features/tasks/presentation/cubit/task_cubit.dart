import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../domain/usecases/delete_task_usecase.dart';
import '../../domain/usecases/get_tasks_usecase.dart';
import '../../domain/usecases/update_task_status_usecase.dart';
import '../../domain/usecases/update_task_usecase.dart';
import 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final GetTasksUseCase getTasksUseCase;
  final CreateTaskUseCase createTaskUseCase;
  final UpdateTaskStatusUseCase updateTaskStatusUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;
  final UpdateTaskUseCase updateTaskUseCase;

  StreamSubscription? _tasksSubscription;

  TaskCubit({
    required this.getTasksUseCase,
    required this.createTaskUseCase,
    required this.updateTaskStatusUseCase,
    required this.deleteTaskUseCase,
    required this.updateTaskUseCase,
  }) : super(TaskInitial());

  Future<void> loadTasks() async {
    emit(TaskLoading());
    await _tasksSubscription?.cancel();

    _tasksSubscription = getTasksUseCase.getStream().listen(
      (tasks) {
        _onTasksUpdated(tasks);
      },
      onError: (error) {
        emit(TaskError(error.toString()));
      },
    );
  }

  Future<void> _onTasksUpdated(List<TaskEntity> tasks) async {
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

    final filtered = _applyFilters(tasks, statusFilter, agentFilter);

    emit(TasksLoaded(
      allTasks: tasks,
      filteredTasks: filtered,
      agents: agents,
      selectedStatusFilter: statusFilter,
      selectedAgentFilter: agentFilter,
    ));
  }

  Future<void> createTask(TaskEntity task) async {
    try {
      await createTaskUseCase(task);
    } catch (e) {
      emit(TaskError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> updateTask(TaskEntity task) async {
    try {
      await updateTaskUseCase(task);
    } catch (e) {
      emit(TaskError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> updateStatus(String taskId, String status, {String? localPhotoPath}) async {
    try {
      await updateTaskStatusUseCase(taskId, status, localPhotoPath: localPhotoPath);
    } catch (e) {
      emit(TaskError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await deleteTaskUseCase(taskId);
    } catch (e) {
      emit(TaskError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void filterTasks({String? status, String? agentId}) {
    final currentState = state;
    if (currentState is TasksLoaded) {
      final sFilter = status == '' ? null : (status ?? currentState.selectedStatusFilter);
      final aFilter = agentId == '' ? null : (agentId ?? currentState.selectedAgentFilter);

      final filtered = _applyFilters(currentState.allTasks, sFilter, aFilter);

      emit(currentState.copyWith(
        filteredTasks: filtered,
        selectedStatusFilter: sFilter,
        selectedAgentFilter: aFilter,
        clearStatus: status == '',
        clearAgent: agentId == '',
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
