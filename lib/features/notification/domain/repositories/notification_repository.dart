abstract class NotificationRepository {
  Future<void> updateFCMToken(String userId);
  
  Future<void> sendTaskAssignedNotification({
    required String agentId,
    required String taskTitle,
    required String taskId,
  });

  Future<void> sendTaskStartedNotification({
    required String taskId,
  });

  Future<void> sendTaskCompletedNotification({
    required String taskId,
  });

  Future<void> sendPhotoUploadedNotification({
    required String taskId,
  });

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? taskId,
  });
}
