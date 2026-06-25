import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/services/fcm_service.dart';
import 'core/utils/app_colors.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/task/presentation/screens/admin_dashboard_screen.dart';
import 'features/task/presentation/screens/agent_tasks_screen.dart';
import 'features/task/presentation/screens/task_detail_screen.dart';
import 'features/task/presentation/bloc/task/task_bloc.dart';
import 'features/task/presentation/bloc/sync/sync_bloc.dart';
import 'features/notification/presentation/bloc/notification_bloc.dart';
import 'features/notification/presentation/bloc/notification_event.dart';
import 'injection_container.dart' as di;
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize DI container, Hive and FCM Services
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Listen to notification taps to route directly to task details
    di.sl<FCMService>().onNotificationTap.listen((taskId) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => TaskDetailScreen(taskId: taskId),
        ),
      );
    });

    // Listen to foreground messages and show SnackBar banner
    di.sl<FCMService>().onForegroundMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        final context = _navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.surface,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body ?? '',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
              action: SnackBarAction(
                label: 'View',
                textColor: AppColors.primary,
                onPressed: () {
                  final taskId = message.data['taskId'] as String?;
                  if (taskId != null) {
                    _navigatorKey.currentState?.push(
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(taskId: taskId),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
      }
    });

    // Listen to local notifications (like Sync Complete)
    di.sl<FCMService>().onLocalNotification.listen((payload) {
      final context = _navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payload.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  payload.body,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider<TaskBloc>(
          create: (_) => di.sl<TaskBloc>(),
        ),
        BlocProvider<SyncBloc>(
          create: (_) => di.sl<SyncBloc>(),
        ),
        BlocProvider<NotificationBloc>(
          create: (_) => di.sl<NotificationBloc>(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Field Service Management',
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Register the user's FCM token in Firestore on login success
          context.read<NotificationBloc>().add(UpdateTokenEvent(state.user.uid));
        } else if (state is Unauthenticated) {
          // Pop all pushed routes back to the root login wrapper on logout
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      builder: (context, state) {
        if (state is Authenticated) {
          if (state.user.isAdmin) {
            return const AdminDashboardScreen();
          } else {
            return const AgentTasksScreen();
          }
        } else if (state is AuthInitial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}