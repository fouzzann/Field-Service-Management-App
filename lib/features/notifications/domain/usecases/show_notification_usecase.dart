import '../repositories/notification_repository.dart';

class ShowNotificationUseCase {
  final NotificationRepository repository;

  ShowNotificationUseCase(this.repository);

  Future<void> call({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await repository.showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }
}
