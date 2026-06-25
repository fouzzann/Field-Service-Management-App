import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';
import '../models/sync_queue_item.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final TaskLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<void> createTask(TaskEntity task) async {
    final taskModel = TaskModel.fromEntity(task);
    final isConnected = await networkInfo.isConnected;
    if (isConnected) {
      await remoteDataSource.createTask(taskModel);
    } else {
      throw Exception('Cannot create task offline. Internet connection required.');
    }
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    final taskModel = TaskModel.fromEntity(task);
    final isConnected = await networkInfo.isConnected;
    if (isConnected) {
      await remoteDataSource.updateTask(taskModel);
    } else {
      throw Exception('Cannot edit/reassign task offline. Internet connection required.');
    }
  }

  @override
  Future<void> updateTaskStatus(String taskId, String status, {String? localPhotoPath}) async {
    // 1. Update status locally immediately (Local Wins)
    final cachedTasks = await localDataSource.getCachedTasks();
    final index = cachedTasks.indexWhere((t) => t.taskId == taskId);

    if (index != -1) {
      var task = cachedTasks[index];
      task = TaskModel(
        taskId: task.taskId,
        title: task.title,
        description: task.description,
        priority: task.priority,
        status: status,
        assignedAgentId: task.assignedAgentId,
        completionPhoto: localPhotoPath ?? task.completionPhoto,
        createdAt: task.createdAt,
        updatedAt: DateTime.now(),
      );
      await localDataSource.cacheTask(task);
    }

    // 2. Queue status update action
    final statusItem = SyncQueueItem(
      id: const Uuid().v4(),
      taskId: taskId,
      actionType: 'updateStatus',
      payload: status,
      timestamp: DateTime.now(),
    );
    await localDataSource.addToSyncQueue(statusItem);

    // 3. Queue photo upload action if provided
    if (localPhotoPath != null) {
      final photoItem = SyncQueueItem(
        id: const Uuid().v4(),
        taskId: taskId,
        actionType: 'uploadPhoto',
        payload: localPhotoPath,
        timestamp: DateTime.now(),
      );
      await localDataSource.addToSyncQueue(photoItem);
    }

    // 4. Trigger auto-sync if online
    final isConnected = await networkInfo.isConnected;
    if (isConnected) {
      // Run sync in the background
      syncOfflineTasks().catchError((e) {
        if (kDebugMode) print('Background sync failed: $e');
      });
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    final isConnected = await networkInfo.isConnected;
    if (isConnected) {
      await remoteDataSource.deleteTask(taskId);
      await localDataSource.deleteCachedTask(taskId);
    } else {
      throw Exception('Cannot delete task offline. Internet connection required.');
    }
  }

  @override
  Stream<List<TaskEntity>> getTasksStream() async* {
    // Return local cached tasks first
    try {
      final cached = await localDataSource.getCachedTasks();
      yield cached;
    } catch (_) {}

    // Yield firestore tasks merged with local updates (Conflict Resolution)
    yield* remoteDataSource.getTasksStream().asyncMap((remoteTasks) async {
      final syncQueue = await localDataSource.getSyncQueue();
      final merged = <TaskModel>[];

      for (var remoteTask in remoteTasks) {
        var finalTask = remoteTask;

        // Apply Local Wins for status/completionPhoto if they are pending in local sync queue
        final pendingActions = syncQueue.where((item) => item.taskId == remoteTask.taskId).toList();
        if (pendingActions.isNotEmpty) {
          String currentStatus = remoteTask.status;
          String currentPhoto = remoteTask.completionPhoto;

          for (var action in pendingActions) {
            if (action.actionType == 'updateStatus') {
              currentStatus = action.payload;
            } else if (action.actionType == 'uploadPhoto') {
              currentPhoto = action.payload;
            }
          }

          finalTask = TaskModel(
            taskId: remoteTask.taskId,
            title: remoteTask.title,
            description: remoteTask.description,
            priority: remoteTask.priority,
            status: currentStatus,
            assignedAgentId: remoteTask.assignedAgentId,
            completionPhoto: currentPhoto,
            createdAt: remoteTask.createdAt,
            updatedAt: remoteTask.updatedAt,
          );
        }

        merged.add(finalTask);
      }

      await localDataSource.cacheTasks(merged);
      return merged;
    }).handleError((error) async* {
      // On connection error, return local cache
      final cached = await localDataSource.getCachedTasks();
      yield cached;
    });
  }

  @override
  Future<List<TaskEntity>> getLocalTasks() async {
    return localDataSource.getCachedTasks();
  }

  @override
  Future<List<Map<String, String>>> getAgents() async {
    try {
      return await remoteDataSource.getAgents();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> syncOfflineTasks() async {
    if (!await networkInfo.isConnected) return;

    final queue = await localDataSource.getSyncQueue();
    if (queue.isEmpty) return;

    for (final item in queue) {
      try {
        final cachedTasks = await localDataSource.getCachedTasks();
        final taskIndex = cachedTasks.indexWhere((t) => t.taskId == item.taskId);
        if (taskIndex == -1) {
          // Task no longer exists in cache, remove action
          await localDataSource.removeFromSyncQueue(item.id);
          continue;
        }

        var task = cachedTasks[taskIndex];

        if (item.actionType == 'uploadPhoto') {
          // 1. Upload photo to Firebase Storage
          final downloadUrl = await remoteDataSource.uploadCompletionPhoto(item.taskId, item.payload);

          // 2. Update task local model with URL
          task = TaskModel(
            taskId: task.taskId,
            title: task.title,
            description: task.description,
            priority: task.priority,
            status: task.status,
            assignedAgentId: task.assignedAgentId,
            completionPhoto: downloadUrl,
            createdAt: task.createdAt,
            updatedAt: DateTime.now(),
          );
          await localDataSource.cacheTask(task);

          // 3. Sync to firestore
          await remoteDataSource.updateTask(task);
        } else if (item.actionType == 'updateStatus') {
          // 1. Prepare updated model
          task = TaskModel(
            taskId: task.taskId,
            title: task.title,
            description: task.description,
            priority: task.priority,
            status: item.payload,
            assignedAgentId: task.assignedAgentId,
            completionPhoto: task.completionPhoto,
            createdAt: task.createdAt,
            updatedAt: DateTime.now(),
          );
          await localDataSource.cacheTask(task);

          // 2. Sync to firestore
          await remoteDataSource.updateTask(task);
        }

        // Remove successfully synced item from local queue
        await localDataSource.removeFromSyncQueue(item.id);
      } catch (e) {
        if (kDebugMode) print('Failed to sync queue item ${item.id}: $e');
        // Stop execution to preserve order of execution of queue (or keep retry on next online event)
        break;
      }
    }
  }
}
