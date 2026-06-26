import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';

import '../network/network_info.dart';
import '../services/hive_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/sync_manager.dart';

// Authentication Feature
import '../../features/authentication/data/datasource/auth_local_datasource.dart';
import '../../features/authentication/data/datasource/auth_remote_datasource.dart';
import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/domain/usecases/get_current_user_usecase.dart';
import '../../features/authentication/domain/usecases/login_usecase.dart';
import '../../features/authentication/domain/usecases/logout_usecase.dart';
import '../../features/authentication/presentation/cubit/auth_cubit.dart';

// Tasks Feature
import '../../features/tasks/data/datasource/task_local_datasource.dart';
import '../../features/tasks/data/datasource/task_remote_datasource.dart';
import '../../features/tasks/data/repositories/task_repository_impl.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';
import '../../features/tasks/domain/usecases/create_task_usecase.dart';
import '../../features/tasks/domain/usecases/delete_task_usecase.dart';
import '../../features/tasks/domain/usecases/get_tasks_usecase.dart';
import '../../features/tasks/domain/usecases/sync_tasks_usecase.dart';
import '../../features/tasks/domain/usecases/update_task_status_usecase.dart';
import '../../features/tasks/domain/usecases/update_task_usecase.dart';
import '../../features/tasks/presentation/cubit/sync_cubit.dart';
import '../../features/tasks/presentation/cubit/task_cubit.dart';

// Settings Feature
import '../../features/settings/presentation/cubit/theme_cubit.dart';

// Dashboard Feature
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';

// Notifications Feature
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/usecases/init_notifications_usecase.dart';
import '../../features/notifications/domain/usecases/show_notification_usecase.dart';
import '../../features/notifications/presentation/cubit/notification_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Authentication
  // Cubit
  sl.registerFactory(() => AuthCubit(
        loginUseCase: sl(),
        logoutUseCase: sl(),
        getCurrentUserUseCase: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ));

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(
        authService: sl(),
      ));
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl(sl()));

  //! Features - Tasks
  // Cubits
  sl.registerFactory(() => TaskCubit(
        getTasksUseCase: sl(),
        createTaskUseCase: sl(),
        updateTaskStatusUseCase: sl(),
        deleteTaskUseCase: sl(),
        updateTaskUseCase: sl(),
      ));
  sl.registerFactory(() => SyncCubit(
        networkInfo: sl(),
        syncTasksUseCase: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => GetTasksUseCase(sl()));
  sl.registerLazySingleton(() => CreateTaskUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTaskStatusUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTaskUseCase(sl()));
  sl.registerLazySingleton(() => SyncTasksUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTaskUseCase(sl()));

  // Repository
  sl.registerLazySingleton<TaskRepository>(() => TaskRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ));

  // Data Sources
  sl.registerLazySingleton<TaskRemoteDataSource>(() => TaskRemoteDataSourceImpl(
        firestore: sl(),
        storage: sl(),
      ));
  sl.registerLazySingleton<TaskLocalDataSource>(() => TaskLocalDataSourceImpl(sl()));

  //! Features - Settings
  sl.registerLazySingleton(() => ThemeCubit(sl()));

  //! Features - Dashboard
  sl.registerFactory(() => DashboardCubit());

  //! Features - Notifications
  // Cubit
  sl.registerFactory(() => NotificationCubit(
        initNotificationsUseCase: sl(),
        showNotificationUseCase: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => InitNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => ShowNotificationUseCase(sl()));

  // Repository
  sl.registerLazySingleton<NotificationRepository>(() => NotificationRepositoryImpl(
        notificationService: sl(),
      ));

  //! Core / External
  final hiveService = HiveService();
  await hiveService.init();
  sl.registerLazySingleton(() => hiveService);

  sl.registerLazySingleton(() => AuthService(
        firebaseAuth: sl(),
        firestore: sl(),
      ));

  sl.registerLazySingleton(() => NotificationService());

  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  sl.registerLazySingleton(() => SyncManager(syncTasksUseCase: sl()));

  // External APIs
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => Connectivity());
}
