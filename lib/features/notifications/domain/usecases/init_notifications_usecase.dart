import '../repositories/notification_repository.dart';

class InitNotificationsUseCase {
  final NotificationRepository repository;

  InitNotificationsUseCase(this.repository);

  Future<void> call() async {
    await repository.init();
  }
}
