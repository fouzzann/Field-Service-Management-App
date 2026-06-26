import 'package:equatable/equatable.dart';
import '../../domain/entities/task_entity.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskError extends TaskState {
  final String message;

  const TaskError(this.message);

  @override
  List<Object?> get props => [message];
}

class TasksLoaded extends TaskState {
  final List<TaskEntity> allTasks;
  final List<TaskEntity> filteredTasks;
  final List<Map<String, String>> agents;
  final String? selectedStatusFilter;
  final String? selectedAgentFilter;

  const TasksLoaded({
    required this.allTasks,
    required this.filteredTasks,
    required this.agents,
    this.selectedStatusFilter,
    this.selectedAgentFilter,
  });

  TasksLoaded copyWith({
    List<TaskEntity>? allTasks,
    List<TaskEntity>? filteredTasks,
    List<Map<String, String>>? agents,
    String? selectedStatusFilter,
    String? selectedAgentFilter,
    bool clearStatus = false,
    bool clearAgent = false,
  }) {
    return TasksLoaded(
      allTasks: allTasks ?? this.allTasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
      agents: agents ?? this.agents,
      selectedStatusFilter: clearStatus ? null : (selectedStatusFilter ?? this.selectedStatusFilter),
      selectedAgentFilter: clearAgent ? null : (selectedAgentFilter ?? this.selectedAgentFilter),
    );
  }

  @override
  List<Object?> get props => [
        allTasks,
        filteredTasks,
        agents,
        selectedStatusFilter,
        selectedAgentFilter,
      ];
}
