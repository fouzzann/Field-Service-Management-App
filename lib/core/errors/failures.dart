import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server Error occurred.']);
}

class FirebaseFailure extends Failure {
  const FirebaseFailure([super.message = 'Firebase Error occurred.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No Internet Connection.']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'File Storage Error occurred.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local Cache Error occurred.']);
}
