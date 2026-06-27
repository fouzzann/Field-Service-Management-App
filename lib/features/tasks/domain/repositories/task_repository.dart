import '../entities/task_entity.dart';

// An abstract class (interface) that acts as a contract.
// It defines the actions we can perform on tasks, but does NOT contain the code to perform them.
// The data layer will implement this class to write details to Firestore/Hive.
abstract class TaskRepository {
  // Creates a new task.
  Future<void> createTask(TaskEntity task);

  // Updates an existing task (e.g. details, description, assigned agent).
  Future<void> updateTask(TaskEntity task);

  // Updates only the status (Pending -> In Progress -> Completed) of a task.
  // Optional localPhotoPath can be supplied when completing a task.
  Future<void> updateTaskStatus(String taskId, String status, {String? localPhotoPath});

  // Deletes a task by its ID.
  Future<void> deleteTask(String taskId);

  // A stream that emits the list of tasks whenever they update.
  Stream<List<TaskEntity>> getTasksStream();

  // Loads the list of tasks from local storage (offline mode).
  Future<List<TaskEntity>> getLocalTasks();

  // Uploads/syncs any changes made offline up to Firestore server.
  Future<void> syncOfflineTasks();

  // Fetches a list of agents available in the app to assign tasks to.
  Future<List<Map<String, String>>> getAgents();
}
