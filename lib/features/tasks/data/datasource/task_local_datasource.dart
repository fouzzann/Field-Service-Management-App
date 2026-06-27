import '../../../../core/services/hive_service.dart';
import '../models/task_model.dart';
import '../models/sync_queue_item.dart';

// In Clean Architecture, a "DataSource" handles direct communication with a database or service.
// This is the Local DataSource: it saves, updates, and reads task details locally using Hive on the device.
abstract class TaskLocalDataSource {
  // Saves a list of tasks to our local database (overwrites old tasks).
  Future<void> cacheTasks(List<TaskModel> tasks);
  
  // Reads all tasks stored locally.
  Future<List<TaskModel>> getCachedTasks();
  
  // Saves a single task to the cache.
  Future<void> cacheTask(TaskModel task);
  
  // Removes a task from the local cache.
  Future<void> deleteCachedTask(String taskId);
  
  // Adds an operation to the sync queue to process when internet returns.
  Future<void> addToSyncQueue(SyncQueueItem item);
  
  // Returns all operations waiting in the sync queue.
  Future<List<SyncQueueItem>> getSyncQueue();
  
  // Removes a synced operation from the queue.
  Future<void> removeFromSyncQueue(String id);
  
  // Clears the entire sync queue.
  Future<void> clearSyncQueue();

  // Adds a task status update (like 'Pending' -> 'Completed') to the offline queue.
  Future<void> addPendingStatusUpdate(String taskId, String status);
  
  // Reads all task status updates waiting to be uploaded to Firebase.
  Future<List<Map<String, dynamic>>> getPendingStatusUpdates();
  
  // Removes a status update from the offline queue.
  Future<void> removePendingStatusUpdate(String taskId);
  
  // Marks a status update as successfully saved to Firebase.
  Future<void> markStatusUpdateSynced(String taskId);

  // Adds a photo upload task to the offline queue.
  Future<void> addPendingPhotoUpload(String taskId, String localPath);
  
  // Reads all photo uploads waiting to be uploaded to Firebase Storage.
  Future<List<Map<String, dynamic>>> getPendingPhotoUploads();
  
  // Removes a photo upload task from the offline queue.
  Future<void> removePendingPhotoUpload(String taskId);
  
  // Marks a photo upload as successfully completed and synced to the cloud.
  Future<void> markPhotoUploadSynced(String taskId);
}

// Implementation of the Local DataSource using our HiveService.
class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final HiveService hiveService;

  TaskLocalDataSourceImpl(this.hiveService);

  @override
  // Saves all tasks. Overwrites existing local tasks.
  Future<void> cacheTasks(List<TaskModel> tasks) async {
    await hiveService.tasksBox.clear();
    final Map<String, TaskModel> taskMap = {
      for (var task in tasks) task.taskId: task
    };
    await hiveService.tasksBox.putAll(taskMap);
  }

  @override
  // Reads and returns all locally saved tasks as a list.
  Future<List<TaskModel>> getCachedTasks() async {
    return hiveService.tasksBox.values.toList();
  }

  @override
  // Saves or updates a single task locally.
  Future<void> cacheTask(TaskModel task) async {
    await hiveService.tasksBox.put(task.taskId, task);
  }

  @override
  // Deletes a single task locally.
  Future<void> deleteCachedTask(String taskId) async {
    await hiveService.tasksBox.delete(taskId);
  }

  @override
  // Saves a sync task request to run later.
  Future<void> addToSyncQueue(SyncQueueItem item) async {
    await hiveService.syncQueueBox.put(item.id, item);
  }

  @override
  // Gets all sync tasks, sorted by time so we process old ones first.
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
  // Adds a status change (e.g. marking a task as "In Progress") to the offline sync list.
  Future<void> addPendingStatusUpdate(String taskId, String status) async {
    await hiveService.pendingStatusUpdatesBox.put(taskId, {
      'taskId': taskId,
      'status': status,
      'synced': false,
    });
  }

  @override
  // Returns all status changes waiting to be synced.
  Future<List<Map<String, dynamic>>> getPendingStatusUpdates() async {
    final list = hiveService.pendingStatusUpdatesBox.values.toList();
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<void> removePendingStatusUpdate(String taskId) async {
    await hiveService.pendingStatusUpdatesBox.delete(taskId);
  }

  @override
  // Marks status update as done syncing.
  Future<void> markStatusUpdateSynced(String taskId) async {
    final current = hiveService.pendingStatusUpdatesBox.get(taskId);
    if (current != null) {
      final updated = Map<String, dynamic>.from(current);
      updated['synced'] = true;
      await hiveService.pendingStatusUpdatesBox.put(taskId, updated);
    }
  }

  @override
  // Adds a photo path on the device to the queue, so it gets uploaded later.
  Future<void> addPendingPhotoUpload(String taskId, String localPath) async {
    await hiveService.pendingPhotoUploadsBox.put(taskId, {
      'taskId': taskId,
      'localPath': localPath,
      'timestamp': DateTime.now().toIso8601String(),
      'synced': false,
    });
  }

  @override
  // Returns all photo uploads waiting to sync.
  Future<List<Map<String, dynamic>>> getPendingPhotoUploads() async {
    final list = hiveService.pendingPhotoUploadsBox.values.toList();
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<void> removePendingPhotoUpload(String taskId) async {
    await hiveService.pendingPhotoUploadsBox.delete(taskId);
  }

  @override
  // Marks photo upload as successfully synced.
  Future<void> markPhotoUploadSynced(String taskId) async {
    final current = hiveService.pendingPhotoUploadsBox.get(taskId);
    if (current != null) {
      final updated = Map<String, dynamic>.from(current);
      updated['synced'] = true;
      await hiveService.pendingPhotoUploadsBox.put(taskId, updated);
    }
  }
}
