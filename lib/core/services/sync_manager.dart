import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../features/tasks/domain/usecases/sync_tasks_usecase.dart';

// This manager listens to network changes (like turning on cellular data or Wi-Fi).
// When connection is restored, it triggers the automatic upload/download sync of offline tasks.
class SyncManager {
  // Use case containing the logic to upload pending changes to Firestore.
  final SyncTasksUseCase syncTasksUseCase;
  
  // A subscription that listens to network change events. We store it to cancel it later.
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SyncManager({required this.syncTasksUseCase});

  // Starts monitoring the device's internet connectivity state.
  void startAutoSync() {
    // Cancel any old subscription to prevent double-listening or memory leaks.
    _connectivitySubscription?.cancel();
    
    // Listen to changes in internet connection.
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      // Check if the device is connected to any active network (Wi-Fi, mobile data, ethernet).
      final hasConnection = results.any((result) => result != ConnectivityResult.none);
      
      // If we got our internet back, trigger the sync process immediately in the background.
      if (hasConnection) {
        if (kDebugMode) print('Connectivity restored. Triggering auto-sync...');
        syncTasksUseCase().catchError((e) {
          if (kDebugMode) print('Auto-sync failed: $e');
        });
      }
    });
  }

  // Stops monitoring connectivity (useful when logging out or closing the app).
  void stopAutoSync() {
    _connectivitySubscription?.cancel();
  }
}
