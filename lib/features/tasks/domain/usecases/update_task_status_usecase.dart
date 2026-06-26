import '../repositories/task_repository.dart';

class UpdateTaskStatusUseCase {
  final TaskRepository repository;

  UpdateTaskStatusUseCase(this.repository);

  Future<void> call(String taskId, String status, {String? localPhotoPath}) {
    return repository.updateTaskStatus(taskId, status, localPhotoPath: localPhotoPath);
  }
}
