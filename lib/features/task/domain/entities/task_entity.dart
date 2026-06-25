import 'package:equatable/equatable.dart';

class TaskEntity extends Equatable {
  final String taskId;
  final String title;
  final String description;
  final String priority; // 'Low' | 'Medium' | 'High'
  final String status; // 'Pending' | 'In Progress' | 'Completed'
  final String assignedAgentId;
  final String completionPhoto; // URL or local path
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskEntity({
    required this.taskId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.assignedAgentId,
    required this.completionPhoto,
    required this.createdAt,
    required this.updatedAt,
  });

  TaskEntity copyWith({
    String? taskId,
    String? title,
    String? description,
    String? priority,
    String? status,
    String? assignedAgentId,
    String? completionPhoto,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskEntity(
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedAgentId: assignedAgentId ?? this.assignedAgentId,
      completionPhoto: completionPhoto ?? this.completionPhoto,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        taskId,
        title,
        description,
        priority,
        status,
        assignedAgentId,
        completionPhoto,
        createdAt,
        updatedAt,
      ];
}
