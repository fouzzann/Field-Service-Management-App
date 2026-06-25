import '../repositories/task_repository.dart';

class SyncTasksUseCase {
  final TaskRepository repository;

  SyncTasksUseCase(this.repository);

  Future<void> call() {
    return repository.syncOfflineTasks();
  }
}
