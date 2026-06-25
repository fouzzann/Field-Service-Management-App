import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;

  NotificationBloc({required this.notificationRepository}) : super(NotificationInitial()) {
    on<UpdateTokenEvent>(_onUpdateToken);
    on<SendPushNotificationEvent>(_onSendPushNotification);
  }

  Future<void> _onUpdateToken(
    UpdateTokenEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      await notificationRepository.updateFCMToken(event.userId);
      emit(NotificationSuccess());
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onSendPushNotification(
    SendPushNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await notificationRepository.sendTaskAssignedNotification(
        agentId: event.agentId,
        taskTitle: event.taskTitle,
        taskId: event.taskId,
      );
    } catch (_) {}
  }
}
