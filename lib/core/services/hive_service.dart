import 'package:hive_flutter/hive_flutter.dart';
import '../../features/authentication/data/models/user_model.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../../features/tasks/data/models/sync_queue_item.dart';

// Hive is a fast, lightweight key-value database that runs locally on the user's device.
// This HiveService class manages setting up and opening our local database boxes (tables).
class HiveService {
  // Names of different local "boxes" (like tables in a database)
  static const String userBoxName = 'user_box';
  static const String tokenBoxName = 'token_box';
  static const String tasksBoxName = 'tasks_box';
  static const String syncQueueBoxName = 'sync_queue_box';
  static const String pendingStatusUpdatesBoxName = 'pending_status_updates';
  static const String pendingPhotoUploadsBoxName = 'pending_photo_uploads';
  static const String settingsBoxName = 'settings_box';

  // This method initializes Hive and opens all boxes. Call this before the app starts!
  Future<void> init() async {
    // 1. Initialize Hive for Flutter applications.
    await Hive.initFlutter();

    // 2. Register Adapters.
    // Hive needs to know how to convert custom Dart classes (like UserModel) to binary format.
    // Adapters tell Hive how to read/write these custom objects.
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(SyncQueueItemAdapter());

    // 3. Open the boxes.
    // Opening a box loads its contents into memory so we can read and write instantly.
    await Hive.openBox<UserModel>(userBoxName);
    await Hive.openBox<String>(tokenBoxName);
    await Hive.openBox<TaskModel>(tasksBoxName);
    await Hive.openBox<SyncQueueItem>(syncQueueBoxName);
    await Hive.openBox<Map>(pendingStatusUpdatesBoxName);
    await Hive.openBox<Map>(pendingPhotoUploadsBoxName);
    await Hive.openBox(settingsBoxName);
  }

  // Helper getters to easily grab a specific Box from anywhere in the app.
  Box<UserModel> get userBox => Hive.box<UserModel>(userBoxName);
  Box<String> get tokenBox => Hive.box<String>(tokenBoxName);
  Box<TaskModel> get tasksBox => Hive.box<TaskModel>(tasksBoxName);
  Box<SyncQueueItem> get syncQueueBox => Hive.box<SyncQueueItem>(syncQueueBoxName);
  Box<Map> get pendingStatusUpdatesBox => Hive.box<Map>(pendingStatusUpdatesBoxName);
  Box<Map> get pendingPhotoUploadsBox => Hive.box<Map>(pendingPhotoUploadsBoxName);
  Box get settingsBox => Hive.box(settingsBoxName);

  // Clears all stored data from the local database (useful when logging out).
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
