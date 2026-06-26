import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_colors.dart';
import 'core/dependency_injection/injection_container.dart' as di;
import 'firebase_options.dart';

// Authentication Feature
import 'features/authentication/presentation/cubit/auth_cubit.dart';
import 'features/authentication/presentation/cubit/auth_state.dart';
import 'features/authentication/presentation/pages/login_page.dart';
import 'features/authentication/presentation/pages/splash_page.dart';

// Tasks Feature
import 'features/tasks/presentation/cubit/task_cubit.dart';
import 'features/tasks/presentation/cubit/sync_cubit.dart';
import 'features/tasks/presentation/pages/agent_tasks_page.dart';

// Settings Feature
import 'features/settings/presentation/cubit/theme_cubit.dart';

// Dashboard Feature
import 'features/dashboard/presentation/pages/admin_dashboard_page.dart';

// Notifications Feature
import 'features/notifications/presentation/cubit/notification_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize DI container, Hive, and other services
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
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => di.sl<AuthCubit>()..checkAuth(),
        ),
        BlocProvider<TaskCubit>(
          create: (_) => di.sl<TaskCubit>()..loadTasks(),
        ),
        BlocProvider<SyncCubit>(
          create: (_) => di.sl<SyncCubit>(),
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => di.sl<ThemeCubit>(),
        ),
        BlocProvider<NotificationCubit>(
          create: (_) => di.sl<NotificationCubit>()..init(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          final isDark = themeMode == ThemeMode.dark ||
              (themeMode == ThemeMode.system &&
                  WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
          AppColors.isDark = isDark;

          return MaterialApp(
            navigatorKey: _navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Field Service Management',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: const SplashPage(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          // Pop all pushed routes back to the root login wrapper on logout
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      builder: (context, state) {
        if (state is Authenticated) {
          if (state.user.isAdmin) {
            return const AdminDashboardPage();
          } else {
            return const AgentTasksPage();
          }
        } else if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}