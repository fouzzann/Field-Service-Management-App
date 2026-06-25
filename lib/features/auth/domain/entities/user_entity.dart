import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String role; // 'admin' or 'agent'

  const UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isAgent => role.toLowerCase() == 'agent';

  @override
  List<Object?> get props => [uid, name, email, role];
}
