import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class UpdateTokenEvent extends NotificationEvent {
  final String userId;

  const UpdateTokenEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class SendPushNotificationEvent extends NotificationEvent {
  final String agentId;
  final String taskTitle;
  final String taskId;

  const SendPushNotificationEvent({
    required this.agentId,
    required this.taskTitle,
    required this.taskId,
  });

  @override
  List<Object?> get props => [agentId, taskTitle, taskId];
}
