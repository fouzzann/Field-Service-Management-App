import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/init_notifications_usecase.dart';
import '../../domain/usecases/show_notification_usecase.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationSuccess extends NotificationState {}

class NotificationFailure extends NotificationState {
  final String error;
  const NotificationFailure(this.error);
  @override
  List<Object?> get props => [error];
}

class NotificationCubit extends Cubit<NotificationState> {
  final InitNotificationsUseCase initNotificationsUseCase;
  final ShowNotificationUseCase showNotificationUseCase;

  NotificationCubit({
    required this.initNotificationsUseCase,
    required this.showNotificationUseCase,
  }) : super(NotificationInitial());

  Future<void> init() async {
    try {
      await initNotificationsUseCase();
      emit(NotificationSuccess());
    } catch (e) {
      emit(NotificationFailure(e.toString()));
    }
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await showNotificationUseCase(
        id: id,
        title: title,
        body: body,
        payload: payload,
      );
    } catch (e) {
      emit(NotificationFailure(e.toString()));
    }
  }
}
