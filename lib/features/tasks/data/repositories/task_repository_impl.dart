import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasource/task_local_datasource.dart';
import '../datasource/task_remote_datasource.dart';
import '../models/task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;

// This is the actual implementation of the TaskRepository contract.
// It decides whether to fetch data from the local database (Hive) or the cloud (Firestore/Firebase Storage),
// and handles syncing offline actions when internet is available.
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
  // Creates a new task. Requires internet connection.
  Future<void> createTask(TaskEntity task) async {
    final taskModel = TaskModel.fromEntity(task);
    final isConnected = await networkInfo.isConnected;
    
    if (isConnected) {
      try {
        await remoteDataSource.createTask(taskModel);
      } on FirebaseException catch (e) {
        throw FirebaseFailure(e.message ?? 'Failed to create task on Firestore');
      } catch (e) {
        throw ServerFailure(e.toString());
      }
    } else {
      throw const NetworkFailure('Cannot create task offline. Internet connection required.');
    }
  }

  @override
  // Updates task details. Requires internet connection.
  Future<void> updateTask(TaskEntity task) async {
    final taskModel = TaskModel.fromEntity(task);
    final isConnected = await networkInfo.isConnected;
    
    if (isConnected) {
      try {
        await remoteDataSource.updateTask(taskModel);
      } on FirebaseException catch (e) {
        throw FirebaseFailure(e.message ?? 'Failed to update task on Firestore');
      } catch (e) {
        throw ServerFailure(e.toString());
      }
    } else {
      throw const NetworkFailure('Cannot edit/reassign task offline. Internet connection required.');
    }
  }

  @override
  // Updates the status of a task (e.g. marking as "Completed").
  // This supports offline updates by saving the change locally and syncing later.
  Future<void> updateTaskStatus(String taskId, String status, {String? localPhotoPath}) async {
    try {
      // 1. Get cached tasks and update status immediately in the local cache so the UI updates instantly.
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

      // 2. Add the status update to the offline sync queue.
      await localDataSource.addPendingStatusUpdate(taskId, status);

      // 3. If a photo path is provided, add the photo upload to the offline sync queue.
      if (localPhotoPath != null) {
        await localDataSource.addPendingPhotoUpload(taskId, localPhotoPath);
      }

      // 4. If we are currently connected to the internet, run the sync process in the background.
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        syncOfflineTasks().catchError((e) {
          if (kDebugMode) print('Background sync failed: $e');
        });
      }
    } catch (e) {
      throw CacheFailure('Failed to update task locally: $e');
    }
  }

  @override
  // Deletes a task. Requires internet connection.
  Future<void> deleteTask(String taskId) async {
    final isConnected = await networkInfo.isConnected;
    if (isConnected) {
      try {
        await remoteDataSource.deleteTask(taskId);
        await localDataSource.deleteCachedTask(taskId);
      } on FirebaseException catch (e) {
        throw FirebaseFailure(e.message ?? 'Failed to delete task from Firestore');
      } catch (e) {
        throw ServerFailure(e.toString());
      }
    } else {
      throw const NetworkFailure('Cannot delete task offline. Internet connection required.');
    }
  }

  @override
  // Returns a stream of tasks.
  // It emits the local cached tasks first (for speed), then listens to the cloud Firestore stream.
  // When Firestore delivers changes, it merges any unsynced local status updates or photos into the list,
  // caches the merged list, and emits the final updated tasks list.
  Stream<List<TaskEntity>> getTasksStream() async* {
    try {
      final cached = await localDataSource.getCachedTasks();
      yield cached;
    } catch (_) {}

    yield* remoteDataSource.getTasksStream().asyncMap((remoteTasks) async {
      final pendingUpdates = await localDataSource.getPendingStatusUpdates();
      final pendingUploads = await localDataSource.getPendingPhotoUploads();
      final merged = <TaskModel>[];

      for (var remoteTask in remoteTasks) {
        var finalTask = remoteTask;

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

        // If the task has a pending status update offline, show that status instead of what Firestore has.
        if (pendingUpdate.isNotEmpty) {
          currentStatus = pendingUpdate['status'] as String;
        }
        // If the task has a pending photo upload offline, show the local file path first.
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
      final cached = await localDataSource.getCachedTasks();
      yield cached;
    });
  }

  @override
  // Loads all tasks stored on the local device.
  Future<List<TaskEntity>> getLocalTasks() async {
    try {
      return await localDataSource.getCachedTasks();
    } catch (e) {
      throw CacheFailure('Failed to load local tasks');
    }
  }

  @override
  // Fetches a list of agents from Firestore.
  Future<List<Map<String, String>>> getAgents() async {
    try {
      return await remoteDataSource.getAgents();
    } catch (_) {
      return [];
    }
  }

  bool _isSyncing = false;

  @override
  // Syncs all local changes (photo uploads and status updates) to the cloud when internet returns.
  Future<void> syncOfflineTasks() async {
    if (_isSyncing) return; // Prevent running multiple sync processes at the same time.
    if (!await networkInfo.isConnected) return;
    _isSyncing = true;

    try {
      if (kDebugMode) print('Starting offline sync queue processing...');

      final pendingUpdates = await localDataSource.getPendingStatusUpdates();
      final pendingUploads = await localDataSource.getPendingPhotoUploads();

      // 1. Process pending photo uploads first.
      for (final upload in pendingUploads) {
        if (upload['synced'] == true) continue;

        final taskId = upload['taskId'] as String;
        final localPath = upload['localPath'] as String;

        try {
          if (kDebugMode) {
            print('Sync Queue [Photo]: Syncing photo upload for task $taskId');
          }

          // Upload physical image file to Firebase Storage, get the cloud web URL.
          final downloadUrl = await remoteDataSource.uploadCompletionPhoto(taskId, localPath);

          // Update local cache and Firestore database with the new cloud URL.
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

          // Mark this photo upload task as complete and remove from offline queue.
          await localDataSource.markPhotoUploadSynced(taskId);
          await localDataSource.removePendingPhotoUpload(taskId);
        } catch (e) {
          if (kDebugMode) print('Sync Queue [Photo] fail: $e');
        }
      }

      // 2. Process pending status updates.
      for (final update in pendingUpdates) {
        if (update['synced'] == true) continue;

        final taskId = update['taskId'] as String;
        final status = update['status'] as String;

        try {
          if (kDebugMode) {
            print('Sync Queue [Status]: Syncing status update for task $taskId to $status');
          }

          // Update local cache and Firestore database with the new status.
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

          // Mark this status update as complete and remove from offline queue.
          await localDataSource.markStatusUpdateSynced(taskId);
          await localDataSource.removePendingStatusUpdate(taskId);
        } catch (e) {
          if (kDebugMode) print('Sync Queue [Status] fail: $e');
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
