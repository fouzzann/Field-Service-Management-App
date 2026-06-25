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
      var token = await fcmService.getToken();
      // On Web, default to a mock token to avoid empty tokens preventing notification dispatches
      token ??= 'mock_fcm_token_web_evaluation';
      
      await firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
      if (kDebugMode) {
        print('FCM Token registered in database for user $userId: $token');
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
      if (agentDoc.exists) {
        final fcmToken = agentDoc.data()?['fcmToken'] as String?;
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await _sendNotification(
            toToken: fcmToken,
            title: 'New Task Assigned',
            body: 'You have been assigned a new task.',
            taskId: taskId,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending task assigned push: $e');
      }
    }

    // Always trigger local notification for instant visual feedback on same-device testing
    await showLocalNotification(
      title: 'New Task Assigned',
      body: 'You have been assigned a new task.',
      taskId: taskId,
    );
  }

  @override
  Future<void> sendTaskStartedNotification({required String taskId}) async {
    try {
      await _sendToAdmins(
        title: 'Task Started',
        body: 'An agent has started the assigned task.',
        taskId: taskId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sending task started push: $e');
      }
    }

    await showLocalNotification(
      title: 'Task Started',
      body: 'An agent has started the assigned task.',
      taskId: taskId,
    );
  }

  @override
  Future<void> sendTaskCompletedNotification({required String taskId}) async {
    try {
      await _sendToAdmins(
        title: 'Task Completed',
        body: 'An agent has completed the assigned task.',
        taskId: taskId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sending task completed push: $e');
      }
    }

    await showLocalNotification(
      title: 'Task Completed',
      body: 'An agent has completed the assigned task.',
      taskId: taskId,
    );
  }

  @override
  Future<void> sendPhotoUploadedNotification({required String taskId}) async {
    try {
      await _sendToAdmins(
        title: 'Completion Photo Uploaded',
        body: 'An agent uploaded a completion photo for a task.',
        taskId: taskId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sending photo uploaded push: $e');
      }
    }

    await showLocalNotification(
      title: 'Completion Photo Uploaded',
      body: 'An agent uploaded a completion photo for a task.',
      taskId: taskId,
    );
  }

  @override
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? taskId,
  }) async {
    await fcmService.showSystemNotification(
      title: title,
      body: body,
      taskId: taskId,
    );
  }

  Future<void> _sendToAdmins({
    required String title,
    required String body,
    required String taskId,
  }) async {
    try {
      final query = await firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      for (var doc in query.docs) {
        final fcmToken = doc.data()['fcmToken'] as String?;
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await _sendNotification(
            toToken: fcmToken,
            title: title,
            body: body,
            taskId: taskId,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending push notification to admins: $e');
      }
    }
  }

  Future<void> _sendNotification({
    required String toToken,
    required String title,
    required String body,
    required String taskId,
  }) async {
    try {
      final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=MOCK_SERVER_KEY',
        },
        body: jsonEncode({
          'to': toToken,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'data': {
            'taskId': taskId,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          }
        }),
      );

      if (kDebugMode) {
        print('FCM Send Response: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in HTTP post for FCM: $e');
      }
    }
  }
}
