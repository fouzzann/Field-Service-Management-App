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

    // 2. Queue status update action in Hive
    await localDataSource.addPendingStatusUpdate(taskId, status);

    // 3. Queue photo upload action in Hive if provided
    if (localPhotoPath != null) {
      await localDataSource.addPendingPhotoUpload(taskId, localPhotoPath);
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
      final pendingUpdates = await localDataSource.getPendingStatusUpdates();
      final pendingUploads = await localDataSource.getPendingPhotoUploads();
      final merged = <TaskModel>[];

      for (var remoteTask in remoteTasks) {
        var finalTask = remoteTask;

        // Apply Local Wins for status/completionPhoto if they are pending in local sync boxes
        final pendingUpdate = pendingUpdates.firstWhere(
          (item) => item['taskId'] == remoteTask.taskId && item['synced'] == false,
          orElse: () => {},
        );
        final pendingUpload = pendingUploads.firstWhere(
          (item) => item['taskId'] == remoteTask.taskId && item['synced'] == false,
          orElse: () => {},
        );

        String currentStatus = remoteTask.status;
        String currentPhoto = remoteTask.completionPhoto;

        if (pendingUpdate.isNotEmpty) {
          currentStatus = pendingUpdate['status'] as String;
        }
        if (pendingUpload.isNotEmpty) {
          currentPhoto = pendingUpload['localPath'] as String;
        }

        if (pendingUpdate.isNotEmpty || pendingUpload.isNotEmpty) {
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

  bool _isSyncing = false;

  @override
  Future<void> syncOfflineTasks() async {
    if (_isSyncing) return;
    if (!await networkInfo.isConnected) return;
    _isSyncing = true;

    try {
      if (kDebugMode) print('Starting offline sync queue processing...');

      final pendingUpdates = await localDataSource.getPendingStatusUpdates();
      final pendingUploads = await localDataSource.getPendingPhotoUploads();
      final hadPendingChanges = pendingUpdates.isNotEmpty || pendingUploads.isNotEmpty;

      // 1. Process pending photo uploads
      for (final upload in pendingUploads) {
        if (upload['synced'] == true) continue;

        final taskId = upload['taskId'] as String;
        final localPath = upload['localPath'] as String;

        try {
          if (kDebugMode) {
            print('Sync Queue [Photo]: Syncing photo upload for task $taskId with local path $localPath');
          }

          // Upload photo to Firebase Storage and get download URL
          final downloadUrl = await remoteDataSource.uploadCompletionPhoto(taskId, localPath);

          // Get latest cached task
          final cachedTasks = await localDataSource.getCachedTasks();
          final index = cachedTasks.indexWhere((t) => t.taskId == taskId);
          if (index != -1) {
            var task = cachedTasks[index];
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
            await remoteDataSource.updateTask(task);
          }

          // Mark photo upload as synced and remove pending record
          await localDataSource.markPhotoUploadSynced(taskId);
          await localDataSource.removePendingPhotoUpload(taskId);

          if (kDebugMode) {
            print('Sync Queue [Photo]: Task $taskId photo sync success.');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Sync Queue [Photo]: Failed to sync photo upload for task $taskId: $e');
          }
        }
      }

      // 2. Process pending status updates
      for (final update in pendingUpdates) {
        if (update['synced'] == true) continue;

        final taskId = update['taskId'] as String;
        final status = update['status'] as String;

        try {
          if (kDebugMode) {
            print('Sync Queue [Status]: Syncing status update for task $taskId to $status');
          }

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
              completionPhoto: task.completionPhoto,
              createdAt: task.createdAt,
              updatedAt: DateTime.now(),
            );
            await localDataSource.cacheTask(task);
            await remoteDataSource.updateTask(task);
          }

          // Mark status update as synced and remove pending record
          await localDataSource.markStatusUpdateSynced(taskId);
          await localDataSource.removePendingStatusUpdate(taskId);

          if (kDebugMode) {
            print('Sync Queue [Status]: Task $taskId status sync success.');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Sync Queue [Status]: Failed to sync status update for task $taskId: $e');
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
