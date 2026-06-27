import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/init_notifications_usecase.dart';
import '../../domain/usecases/show_notification_usecase.dart';

// States for our Notification Cubit.
abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {} // Initial state.
class NotificationSuccess extends NotificationState {} // Successfully set up.
class NotificationFailure extends NotificationState { // Failed to set up or show.
  final String error;
  const NotificationFailure(this.error);
  @override
  List<Object?> get props => [error];
}

// This Cubit manages when and how the app triggers local notifications on the device.
class NotificationCubit extends Cubit<NotificationState> {
  final InitNotificationsUseCase initNotificationsUseCase;
  final ShowNotificationUseCase showNotificationUseCase;

  NotificationCubit({
    required this.initNotificationsUseCase,
    required this.showNotificationUseCase,
  }) : super(NotificationInitial());

  // Sets up notification permissions and configuration when the app starts.
  Future<void> init() async {
    try {
      await initNotificationsUseCase();
      emit(NotificationSuccess()); // Ready to show notifications!
    } catch (e) {
      emit(NotificationFailure(e.toString()));
    }
  }

  // Tells the operating system to immediately popup a notification banner.
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
