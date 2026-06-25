import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class MonitorConnection extends SyncEvent {}

class ConnectionChanged extends SyncEvent {
  final List<ConnectivityResult> connectionResults;

  const ConnectionChanged(this.connectionResults);

  @override
  List<Object?> get props => [connectionResults];
}

class TriggerSync extends SyncEvent {}
