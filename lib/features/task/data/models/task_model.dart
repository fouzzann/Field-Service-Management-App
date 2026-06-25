import 'package:hive/hive.dart';
import '../../domain/entities/task_entity.dart';

class TaskModel extends TaskEntity {
  const TaskModel({
    required super.taskId,
    required super.title,
    required super.description,
    required super.priority,
    required super.status,
    required super.assignedAgentId,
    required super.completionPhoto,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      taskId: json['taskId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priority: json['priority'] as String? ?? 'Medium',
      status: json['status'] as String? ?? 'Pending',
      assignedAgentId: json['assignedAgentId'] as String? ?? '',
      completionPhoto: json['completionPhoto'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'assignedAgentId': assignedAgentId,
      'completionPhoto': completionPhoto,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      taskId: entity.taskId,
      title: entity.title,
      description: entity.description,
      priority: entity.priority,
      status: entity.status,
      assignedAgentId: entity.assignedAgentId,
      completionPhoto: entity.completionPhoto,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

class TaskAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 1;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskModel(
      taskId: fields[0] as String? ?? '',
      title: fields[1] as String? ?? '',
      description: fields[2] as String? ?? '',
      priority: fields[3] as String? ?? 'Medium',
      status: fields[4] as String? ?? 'Pending',
      assignedAgentId: fields[5] as String? ?? '',
      completionPhoto: fields[6] as String? ?? '',
      createdAt: fields[7] as DateTime? ?? DateTime.now(),
      updatedAt: fields[8] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.taskId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.priority)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.assignedAgentId)
      ..writeByte(6)
      ..write(obj.completionPhoto)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }
}
