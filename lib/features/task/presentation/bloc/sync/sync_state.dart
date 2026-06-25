import 'package:equatable/equatable.dart';

abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {}

class SyncInProgress extends SyncState {
  final bool isOnline;

  const SyncInProgress({this.isOnline = true});

  @override
  List<Object?> get props => [isOnline];
}

class SyncSuccess extends SyncState {
  final bool isOnline;

  const SyncSuccess({this.isOnline = true});

  @override
  List<Object?> get props => [isOnline];
}

class SyncFailure extends SyncState {
  final String message;
  final bool isOnline;

  const SyncFailure(this.message, {this.isOnline = true});

  @override
  List<Object?> get props => [message, isOnline];
}

class ConnectivityStatus extends SyncState {
  final bool isOnline;

  const ConnectivityStatus({required this.isOnline});

  @override
  List<Object?> get props => [isOnline];
}
