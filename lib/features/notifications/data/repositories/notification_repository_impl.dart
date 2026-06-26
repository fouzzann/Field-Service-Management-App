import '../../../../core/services/notification_service.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationService notificationService;

  NotificationRepositoryImpl({required this.notificationService});

  @override
  Future<void> init() async {
    await notificationService.init();
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await notificationService.showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }
}
