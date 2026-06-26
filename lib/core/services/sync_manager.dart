import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../features/tasks/domain/usecases/sync_tasks_usecase.dart';

class SyncManager {
  final SyncTasksUseCase syncTasksUseCase;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SyncManager({required this.syncTasksUseCase});

  void startAutoSync() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      // If any of the connection types is not none, trigger sync
      final hasConnection = results.any((result) => result != ConnectivityResult.none);
      if (hasConnection) {
        if (kDebugMode) print('Connectivity restored. Triggering auto-sync...');
        syncTasksUseCase().catchError((e) {
          if (kDebugMode) print('Auto-sync failed: $e');
        });
      }
    });
  }

  void stopAutoSync() {
    _connectivitySubscription?.cancel();
  }
}
