import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class GetTasksUseCase {
  final TaskRepository repository;

  GetTasksUseCase(this.repository);

  Stream<List<TaskEntity>> getStream() {
    return repository.getTasksStream();
  }

  Future<List<TaskEntity>> getLocal() {
    return repository.getLocalTasks();
  }

  Future<List<Map<String, String>>> getAgents() {
    return repository.getAgents();
  }
}
