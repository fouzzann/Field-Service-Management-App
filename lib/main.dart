import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/task/presentation/screens/admin_dashboard_screen.dart';
import 'features/task/presentation/screens/agent_tasks_screen.dart';
import 'features/task/presentation/bloc/task/task_bloc.dart';
import 'features/task/presentation/bloc/sync/sync_bloc.dart';
import 'features/task/presentation/bloc/theme/theme_cubit.dart';
import 'package:field_service_management_app/core/utils/app_colors.dart';
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
        BlocProvider<ThemeCubit>(
          create: (_) => di.sl<ThemeCubit>(),
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
            home: const AuthWrapper(),
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
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
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