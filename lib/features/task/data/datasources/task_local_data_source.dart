import '../../../../core/services/hive_service.dart';
import '../models/task_model.dart';
import '../models/sync_queue_item.dart';

abstract class TaskLocalDataSource {
  Future<void> cacheTasks(List<TaskModel> tasks);
  Future<List<TaskModel>> getCachedTasks();
  Future<void> cacheTask(TaskModel task);
  Future<void> deleteCachedTask(String taskId);
  Future<void> addToSyncQueue(SyncQueueItem item);
  Future<List<SyncQueueItem>> getSyncQueue();
  Future<void> removeFromSyncQueue(String id);
  Future<void> clearSyncQueue();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final HiveService hiveService;

  TaskLocalDataSourceImpl(this.hiveService);

  @override
  Future<void> cacheTasks(List<TaskModel> tasks) async {
    await hiveService.tasksBox.clear();
    final Map<String, TaskModel> taskMap = {
      for (var task in tasks) task.taskId: task
    };
    await hiveService.tasksBox.putAll(taskMap);
  }

  @override
  Future<List<TaskModel>> getCachedTasks() async {
    return hiveService.tasksBox.values.toList();
  }

  @override
  Future<void> cacheTask(TaskModel task) async {
    await hiveService.tasksBox.put(task.taskId, task);
  }

  @override
  Future<void> deleteCachedTask(String taskId) async {
    await hiveService.tasksBox.delete(taskId);
  }

  @override
  Future<void> addToSyncQueue(SyncQueueItem item) async {
    await hiveService.syncQueueBox.put(item.id, item);
  }

  @override
  Future<List<SyncQueueItem>> getSyncQueue() async {
    final list = hiveService.syncQueueBox.values.toList();
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  @override
  Future<void> removeFromSyncQueue(String id) async {
    await hiveService.syncQueueBox.delete(id);
  }

  @override
  Future<void> clearSyncQueue() async {
    await hiveService.syncQueueBox.clear();
  }
}
