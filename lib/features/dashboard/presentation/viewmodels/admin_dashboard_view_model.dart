import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../../../core/network/network_info.dart';
import '../../../tasks/presentation/cubit/sync_cubit.dart';
import '../../../tasks/presentation/cubit/task_cubit.dart';

class AdminDashboardViewModel extends ChangeNotifier {
  final TaskCubit taskCubit;
  final SyncCubit syncCubit;
  final NetworkInfo networkInfo;

  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  AdminDashboardViewModel({
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

  Future<void> load() async {
    await taskCubit.loadTasks();
  }

  Future<void> syncData() async {
    await syncCubit.syncTasks();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
