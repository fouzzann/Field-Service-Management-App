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

  Future<void> addPendingStatusUpdate(String taskId, String status);
  Future<List<Map<String, dynamic>>> getPendingStatusUpdates();
  Future<void> removePendingStatusUpdate(String taskId);
  Future<void> markStatusUpdateSynced(String taskId);

  Future<void> addPendingPhotoUpload(String taskId, String localPath);
  Future<List<Map<String, dynamic>>> getPendingPhotoUploads();
  Future<void> removePendingPhotoUpload(String taskId);
  Future<void> markPhotoUploadSynced(String taskId);
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

  @override
  Future<void> addPendingStatusUpdate(String taskId, String status) async {
    await hiveService.pendingStatusUpdatesBox.put(taskId, {
      'taskId': taskId,
      'status': status,
      'synced': false,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingStatusUpdates() async {
    final list = hiveService.pendingStatusUpdatesBox.values.toList();
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<void> removePendingStatusUpdate(String taskId) async {
    await hiveService.pendingStatusUpdatesBox.delete(taskId);
  }

  @override
  Future<void> markStatusUpdateSynced(String taskId) async {
    final current = hiveService.pendingStatusUpdatesBox.get(taskId);
    if (current != null) {
      final updated = Map<String, dynamic>.from(current);
      updated['synced'] = true;
      await hiveService.pendingStatusUpdatesBox.put(taskId, updated);
    }
  }

  @override
  Future<void> addPendingPhotoUpload(String taskId, String localPath) async {
    await hiveService.pendingPhotoUploadsBox.put(taskId, {
      'taskId': taskId,
      'localPath': localPath,
      'timestamp': DateTime.now().toIso8601String(),
      'synced': false,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingPhotoUploads() async {
    final list = hiveService.pendingPhotoUploadsBox.values.toList();
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<void> removePendingPhotoUpload(String taskId) async {
    await hiveService.pendingPhotoUploadsBox.delete(taskId);
  }

  @override
  Future<void> markPhotoUploadSynced(String taskId) async {
    final current = hiveService.pendingPhotoUploadsBox.get(taskId);
    if (current != null) {
      final updated = Map<String, dynamic>.from(current);
      updated['synced'] = true;
      await hiveService.pendingPhotoUploadsBox.put(taskId, updated);
    }
  }
}
