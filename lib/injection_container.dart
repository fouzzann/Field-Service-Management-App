import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'core/network/network_info.dart';
import 'core/services/hive_service.dart';

// Auth Feature
import 'core/services/auth_service.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Task Feature
import 'features/task/data/datasources/task_local_data_source.dart';
import 'features/task/data/datasources/task_remote_data_source.dart';
import 'features/task/data/repositories/task_repository_impl.dart';
import 'features/task/domain/repositories/task_repository.dart';
import 'features/task/domain/usecases/create_task_usecase.dart';
import 'features/task/domain/usecases/delete_task_usecase.dart';
import 'features/task/domain/usecases/get_tasks_usecase.dart';
import 'features/task/domain/usecases/sync_tasks_usecase.dart';
import 'features/task/domain/usecases/update_task_status_usecase.dart';
import 'features/task/presentation/bloc/sync/sync_bloc.dart';
import 'features/task/presentation/bloc/task/task_bloc.dart';
import 'features/task/presentation/bloc/theme/theme_cubit.dart';



final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  // BLoC
  sl.registerFactory(() => AuthBloc(
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
      ));

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(
        authService: sl(),
      ));
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl(sl()));


  //! Features - Task
  // BLoC
  sl.registerFactory(() => TaskBloc(
        getTasksUseCase: sl(),
        createTaskUseCase: sl(),
        updateTaskStatusUseCase: sl(),
        deleteTaskUseCase: sl(),
        taskRepository: sl(),
      ));
  sl.registerFactory(() => SyncBloc(
        networkInfo: sl(),
        syncTasksUseCase: sl(),
      ));
  sl.registerLazySingleton(() => ThemeCubit(sl()));

  // Use cases
  sl.registerLazySingleton(() => GetTasksUseCase(sl()));
  sl.registerLazySingleton(() => CreateTaskUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTaskStatusUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTaskUseCase(sl()));
  sl.registerLazySingleton(() => SyncTasksUseCase(sl()));

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


  //! Core / External
  final hiveService = HiveService();
  await hiveService.init();
  sl.registerLazySingleton(() => hiveService);

  sl.registerLazySingleton(() => AuthService(
        firebaseAuth: sl(),
        firestore: sl(),
      ));

  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // External APIs
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => Connectivity());
}
