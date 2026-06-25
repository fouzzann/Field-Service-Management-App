import '../entities/task_entity.dart';

abstract class TaskRepository {
  Future<void> createTask(TaskEntity task);
  Future<void> updateTask(TaskEntity task);
  Future<void> updateTaskStatus(String taskId, String status, {String? localPhotoPath});
  Future<void> deleteTask(String taskId);
  Stream<List<TaskEntity>> getTasksStream();
  Future<List<TaskEntity>> getLocalTasks();
  Future<void> syncOfflineTasks();
  Future<List<Map<String, String>>> getAgents(); // Returns list of agents [{uid: '', name: ''}]
}
