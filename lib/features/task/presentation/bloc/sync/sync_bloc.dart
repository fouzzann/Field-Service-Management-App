import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:field_service_management_app/core/network/network_info.dart';
import 'package:field_service_management_app/features/task/domain/usecases/sync_tasks_usecase.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final NetworkInfo networkInfo;
  final SyncTasksUseCase syncTasksUseCase;

  StreamSubscription? _connectivitySubscription;
  bool _wasOffline = false;

  SyncBloc({
    required this.networkInfo,
    required this.syncTasksUseCase,
  }) : super(SyncInitial()) {
    on<MonitorConnection>(_onMonitorConnection);
    on<ConnectionChanged>(_onConnectionChanged);
    on<TriggerSync>(_onTriggerSync);
  }

  Future<void> _onMonitorConnection(
    MonitorConnection event,
    Emitter<SyncState> emit,
  ) async {
    final isOnline = await networkInfo.isConnected;
    emit(ConnectivityStatus(isOnline: isOnline));

    await _connectivitySubscription?.cancel();

    _connectivitySubscription = networkInfo.onConnectivityChanged.listen((results) {
      add(ConnectionChanged(results));
    });
  }

  Future<void> _onConnectionChanged(
    ConnectionChanged event,
    Emitter<SyncState> emit,
  ) async {
    final isOnline = event.connectionResults.any((result) => result != ConnectivityResult.none);
    emit(ConnectivityStatus(isOnline: isOnline));

    if (isOnline) {
      if (_wasOffline) {
        _wasOffline = false;
        add(TriggerSync());
      }
    } else {
      _wasOffline = true;
    }
  }

  Future<void> _onTriggerSync(
    TriggerSync event,
    Emitter<SyncState> emit,
  ) async {
    final isOnline = await networkInfo.isConnected;
    if (!isOnline) {
      emit(const SyncFailure('Cannot sync: device is offline.'));
      return;
    }

    emit(SyncInProgress());
    try {
      await syncTasksUseCase();
      emit(SyncSuccess());
    } catch (e) {
      emit(SyncFailure(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
