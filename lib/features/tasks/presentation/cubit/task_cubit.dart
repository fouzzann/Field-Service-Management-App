import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../domain/usecases/delete_task_usecase.dart';
import '../../domain/usecases/get_tasks_usecase.dart';
import '../../domain/usecases/update_task_status_usecase.dart';
import '../../domain/usecases/update_task_usecase.dart';
import 'task_state.dart';

// In Flutter, a "Cubit" is a simple state management tool (part of the BLoC library).
// It acts as a bridge between the business logic (UseCases) and the visual interface (UI).
// The Cubit gets actions from the UI, runs UseCases, and outputs "States" (e.g. Loading, Error, Success) back to the UI.
class TaskCubit extends Cubit<TaskState> {
  final GetTasksUseCase getTasksUseCase;
  final CreateTaskUseCase createTaskUseCase;
  final UpdateTaskStatusUseCase updateTaskStatusUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;
  final UpdateTaskUseCase updateTaskUseCase;

  // A stream listener that receives real-time task updates from Firestore.
  StreamSubscription? _tasksSubscription;

  TaskCubit({
    required this.getTasksUseCase,
    required this.createTaskUseCase,
    required this.updateTaskStatusUseCase,
    required this.deleteTaskUseCase,
    required this.updateTaskUseCase,
  }) : super(TaskInitial()); // Starts in the "Initial" state when the app boots.

  // Subscribes to the live task list stream.
  Future<void> loadTasks() async {
    emit(TaskLoading()); // 1. Tell UI to show a loading spinner.
    await _tasksSubscription?.cancel(); // Cancel any old listener to avoid memory leaks.

    // 2. Start listening to the task list updates.
    _tasksSubscription = getTasksUseCase.getStream().listen(
      (tasks) {
        _onTasksUpdated(tasks); // Runs when new task lists are received.
      },
      onError: (error) {
        emit(TaskError(error.toString())); // Runs if an error happens.
      },
    );
  }

  // Merges the updated task list with the active UI filters (status, agent) and emits a Loaded state.
  Future<void> _onTasksUpdated(List<TaskEntity> tasks) async {
    final currentState = state;
    List<Map<String, String>> agents = [];
    
    // Attempt to reuse already fetched list of agents to save network data usage.
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

    // Apply filters (e.g. only show "Completed" tasks)
    final filtered = _applyFilters(tasks, statusFilter, agentFilter);

    // Emit the loaded state containing all tasks and filtered lists.
    emit(TasksLoaded(
      allTasks: tasks,
      filteredTasks: filtered,
      agents: agents,
      selectedStatusFilter: statusFilter,
      selectedAgentFilter: agentFilter,
    ));
  }

  // Triggers the CreateTask usecase.
  Future<void> createTask(TaskEntity task) async {
    try {
      await createTaskUseCase(task);
    } catch (e) {
      emit(TaskError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // Triggers the UpdateTask usecase (e.g., changing title, description, or assigned agent).
  Future<void> updateTask(TaskEntity task) async {
    try {
      await updateTaskUseCase(task);
    } catch (e) {
      emit(TaskError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // Triggers the UpdateTaskStatus usecase (e.g., marking task as Completed).
  Future<void> updateStatus(String taskId, String status, {String? localPhotoPath}) async {
    try {
      await updateTaskStatusUseCase(taskId, status, localPhotoPath: localPhotoPath);
    } catch (e) {
      emit(TaskError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // Triggers the DeleteTask usecase.
  Future<void> deleteTask(String taskId) async {
    try {
      await deleteTaskUseCase(taskId);
    } catch (e) {
      emit(TaskError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // Filters tasks when the user selects different filters in the UI header.
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

  // Helper method: Loops through tasks and keeps only those that match status and agentId.
  List<TaskEntity> _applyFilters(List<TaskEntity> tasks, String? status, String? agentId) {
    return tasks.where((task) {
      final matchesStatus = status == null || task.status.toLowerCase() == status.toLowerCase();
      final matchesAgent = agentId == null || task.assignedAgentId == agentId;
      return matchesStatus && matchesAgent;
    }).toList();
  }

  @override
  // Cleans up resources when this Cubit is destroyed.
  Future<void> close() {
    _tasksSubscription?.cancel();
    return super.close();
  }
}
