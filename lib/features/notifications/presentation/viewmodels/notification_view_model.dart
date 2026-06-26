import 'package:flutter/material.dart';
import '../cubit/notification_cubit.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationCubit notificationCubit;

  NotificationViewModel({required this.notificationCubit});

  Future<void> initialize() async {
    await notificationCubit.init();
  }

  Future<void> triggerNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await notificationCubit.show(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }
}
