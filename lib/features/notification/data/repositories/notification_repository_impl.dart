import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/services/fcm_service.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore firestore;
  final FCMService fcmService;

  NotificationRepositoryImpl({
    required this.firestore,
    required this.fcmService,
  });

  @override
  Future<void> updateFCMToken(String userId) async {
    try {
      final token = await fcmService.getToken();
      if (token != null) {
        await firestore.collection('users').doc(userId).update({
          'fcmToken': token,
        });
        if (kDebugMode) {
          print('FCM Token registered in database for user $userId: $token');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating FCM Token in Firestore: $e');
      }
    }
  }

  @override
  Future<void> sendTaskAssignedNotification({
    required String agentId,
    required String taskTitle,
    required String taskId,
  }) async {
    try {
      final agentDoc = await firestore.collection('users').doc(agentId).get();
      if (!agentDoc.exists) return;

      final fcmToken = agentDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) {
        if (kDebugMode) {
          print('No FCM token found for agent: $agentId. Cannot send push.');
        }
        return;
      }

      if (kDebugMode) {
        print('Sending FCM Notification to Agent: $agentId for Task: $taskId');
      }

      // Legacy FCM HTTP API (for demonstration/mocking client request).
      // Standard FCM v1 usually requires server OAuth. We implement Legacy POST and catch/log failures.
      final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=MOCK_SERVER_KEY',
        },
        body: jsonEncode({
          'to': fcmToken,
          'notification': {
            'title': 'New Task Assigned',
            'body': 'You have been assigned a task: $taskTitle',
            'sound': 'default',
          },
          'data': {
            'taskId': taskId,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          }
        }),
      );

      if (kDebugMode) {
        print('FCM Response Status: ${response.statusCode}');
        print('FCM Response Body: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending FCM push: $e');
      }
    }
  }
}
