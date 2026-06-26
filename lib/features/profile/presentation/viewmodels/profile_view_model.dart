import 'package:flutter/material.dart';
import '../../../authentication/presentation/cubit/auth_cubit.dart';
import '../../../tasks/presentation/cubit/task_cubit.dart';
import '../../../tasks/presentation/cubit/task_state.dart';

class ProfileViewModel extends ChangeNotifier {
  final AuthCubit authCubit;
  final TaskCubit taskCubit;

  ProfileViewModel({
    required this.authCubit,
    required this.taskCubit,
  });

  void loadTasksIfNeeded() {
    if (taskCubit.state is! TasksLoaded) {
      taskCubit.loadTasks();
    }
  }

  Future<void> logout() async {
    await authCubit.logout();
  }
}
