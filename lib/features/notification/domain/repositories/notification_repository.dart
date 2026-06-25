abstract class NotificationRepository {
  Future<void> updateFCMToken(String userId);
  Future<void> sendTaskAssignedNotification({
    required String agentId,
    required String taskTitle,
    required String taskId,
  });
}
