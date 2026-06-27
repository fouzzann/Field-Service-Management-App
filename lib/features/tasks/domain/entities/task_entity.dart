import 'package:equatable/equatable.dart';

// In Clean Architecture, an "Entity" represents a core business data object.
// This is the TaskEntity. It contains only clean, raw data about a Task.
// Equatable is used so we can compare two TaskEntity objects using '==' to see if they are equal.
class TaskEntity extends Equatable {
  final String taskId;          // Unique ID of the task
  final String title;           // Title of the task (e.g. "Fix Router")
  final String description;     // Details of the task
  final String priority;        // Priority level: 'Low' | 'Medium' | 'High'
  final String status;          // Current status: 'Pending' | 'In Progress' | 'Completed'
  final String assignedAgentId; // ID of the agent assigned to this task
  final String completionPhoto; // Image URL or local file path of the completed work photo
  final DateTime createdAt;     // Date and time when the task was created
  final DateTime updatedAt;     // Date and time when the task was last updated

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

  // A helper method that lets us copy an existing TaskEntity and change only some of its fields
  // (since all fields are marked final and immutable).
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
  // List all properties that Equatable should check when comparing two objects.
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
