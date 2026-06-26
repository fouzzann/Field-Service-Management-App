import 'package:hive_flutter/hive_flutter.dart';
import '../../features/authentication/data/models/user_model.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../../features/tasks/data/models/sync_queue_item.dart';

class HiveService {
  static const String userBoxName = 'user_box';
  static const String tokenBoxName = 'token_box';
  static const String tasksBoxName = 'tasks_box';
  static const String syncQueueBoxName = 'sync_queue_box';
  static const String pendingStatusUpdatesBoxName = 'pending_status_updates';
  static const String pendingPhotoUploadsBoxName = 'pending_photo_uploads';
  static const String settingsBoxName = 'settings_box';

  Future<void> init() async {
    await Hive.initFlutter();

    // Register manual TypeAdapters
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(SyncQueueItemAdapter());

    // Open standard boxes
    await Hive.openBox<UserModel>(userBoxName);
    await Hive.openBox<String>(tokenBoxName);
    await Hive.openBox<TaskModel>(tasksBoxName);
    await Hive.openBox<SyncQueueItem>(syncQueueBoxName);
    await Hive.openBox<Map>(pendingStatusUpdatesBoxName);
    await Hive.openBox<Map>(pendingPhotoUploadsBoxName);
    await Hive.openBox(settingsBoxName);
  }

  Box<UserModel> get userBox => Hive.box<UserModel>(userBoxName);
  Box<String> get tokenBox => Hive.box<String>(tokenBoxName);
  Box<TaskModel> get tasksBox => Hive.box<TaskModel>(tasksBoxName);
  Box<SyncQueueItem> get syncQueueBox => Hive.box<SyncQueueItem>(syncQueueBoxName);
  Box<Map> get pendingStatusUpdatesBox => Hive.box<Map>(pendingStatusUpdatesBoxName);
  Box<Map> get pendingPhotoUploadsBox => Hive.box<Map>(pendingPhotoUploadsBoxName);
  Box get settingsBox => Hive.box(settingsBoxName);

  Future<void> clearAll() async {
    await tasksBox.clear();
    await syncQueueBox.clear();
    await userBox.clear();
    await tokenBox.clear();
    await pendingStatusUpdatesBox.clear();
    await pendingPhotoUploadsBox.clear();
    await settingsBox.clear();
  }
}
