import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasource/task_local_datasource.dart';
import '../datasource/task_remote_datasource.dart';
import '../models/task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;

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
  Future<void> updateTaskStatus(String taskId, String status, {String? localPhotoPath}) async {
    try {
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

      await localDataSource.addPendingStatusUpdate(taskId, status);

      if (localPhotoPath != null) {
        await localDataSource.addPendingPhotoUpload(taskId, localPhotoPath);
      }

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
      final cached = await localDataSource.getCachedTasks();
      yield cached;
    });
  }

  @override
  Future<List<TaskEntity>> getLocalTasks() async {
    try {
      return await localDataSource.getCachedTasks();
    } catch (e) {
      throw CacheFailure('Failed to load local tasks');
    }
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

      for (final upload in pendingUploads) {
        if (upload['synced'] == true) continue;

        final taskId = upload['taskId'] as String;
        final localPath = upload['localPath'] as String;

        try {
          if (kDebugMode) {
            print('Sync Queue [Photo]: Syncing photo upload for task $taskId');
          }

          final downloadUrl = await remoteDataSource.uploadCompletionPhoto(taskId, localPath);

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

          await localDataSource.markPhotoUploadSynced(taskId);
          await localDataSource.removePendingPhotoUpload(taskId);
        } catch (e) {
          if (kDebugMode) print('Sync Queue [Photo] fail: $e');
        }
      }

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
