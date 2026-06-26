import '../../domain/entities/task_entity.dart';
import '../models/task_model.dart';

class TaskMapper {
  static TaskEntity toEntity(TaskModel model) {
    return TaskEntity(
      taskId: model.taskId,
      title: model.title,
      description: model.description,
      priority: model.priority,
      status: model.status,
      assignedAgentId: model.assignedAgentId,
      completionPhoto: model.completionPhoto,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  static TaskModel toModel(TaskEntity entity) {
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
