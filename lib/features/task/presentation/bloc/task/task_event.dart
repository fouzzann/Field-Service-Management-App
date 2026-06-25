import 'package:equatable/equatable.dart';
import '../../../domain/entities/task_entity.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasks extends TaskEvent {}

class TasksUpdated extends TaskEvent {
  final List<TaskEntity> tasks;

  const TasksUpdated(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class CreateTaskEvent extends TaskEvent {
  final TaskEntity task;

  const CreateTaskEvent(this.task);

  @override
  List<Object?> get props => [task];
}

class UpdateTaskEvent extends TaskEvent {
  final TaskEntity task;

  const UpdateTaskEvent(this.task);

  @override
  List<Object?> get props => [task];
}

class UpdateStatusEvent extends TaskEvent {
  final String taskId;
  final String status;
  final String? localPhotoPath;

  const UpdateStatusEvent({
    required this.taskId,
    required this.status,
    this.localPhotoPath,
  });

  @override
  List<Object?> get props => [taskId, status, localPhotoPath];
}

class DeleteTaskEvent extends TaskEvent {
  final String taskId;

  const DeleteTaskEvent(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class FilterTasksEvent extends TaskEvent {
  final String? status;
  final String? agentId;

  const FilterTasksEvent({this.status, this.agentId});

  @override
  List<Object?> get props => [status, agentId];
}
