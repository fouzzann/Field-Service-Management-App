import 'package:flutter/material.dart';
import '../cubit/task_cubit.dart';

class TaskDetailViewModel extends ChangeNotifier {
  final TaskCubit taskCubit;

  TaskDetailViewModel({required this.taskCubit});

  void updateStatus(String taskId, String status, {String? localPhotoPath}) {
    taskCubit.updateStatus(taskId, status, localPhotoPath: localPhotoPath);
  }

  void deleteTask(String taskId) {
    taskCubit.deleteTask(taskId);
  }
}
