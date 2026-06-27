import '../repositories/task_repository.dart';

// A UseCase represents a single action the user can perform.
// This UseCase handles updating a task's status (e.g. marking it as Completed).
class UpdateTaskStatusUseCase {
  final TaskRepository repository;

  UpdateTaskStatusUseCase(this.repository);

  // The 'call' method allows us to execute the UseCase like a function:
  // e.g. updateTaskStatusUseCase(taskId, status)
  Future<void> call(String taskId, String status, {String? localPhotoPath}) {
    return repository.updateTaskStatus(taskId, status, localPhotoPath: localPhotoPath);
  }
}
