import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../../../core/network/network_info.dart';
import '../cubit/task_cubit.dart';
import '../cubit/sync_cubit.dart';

class TaskListViewModel extends ChangeNotifier {
  final TaskCubit taskCubit;
  final SyncCubit syncCubit;
  final NetworkInfo networkInfo;

  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  TaskListViewModel({
    required this.taskCubit,
    required this.syncCubit,
    required this.networkInfo,
  }) {
    _initConnectivity();
  }

  bool get isOnline => _isOnline;

  Future<void> _initConnectivity() async {
    _isOnline = await networkInfo.isConnected;
    notifyListeners();

    _connectivitySubscription = networkInfo.onConnectivityChanged.listen((results) async {
      _isOnline = await networkInfo.isConnected;
      notifyListeners();
    });
  }

  void load() {
    taskCubit.loadTasks();
  }

  Future<void> refresh() async {
    await syncCubit.syncTasks();
    await taskCubit.loadTasks();
  }

  void applyStatusFilter(String? status) {
    taskCubit.filterTasks(status: status);
  }

  void applyAgentFilter(String? agentId) {
    taskCubit.filterTasks(agentId: agentId);
  }

  void deleteTask(String taskId) {
    taskCubit.deleteTask(taskId);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
