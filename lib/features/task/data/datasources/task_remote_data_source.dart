import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/task_model.dart';

abstract class TaskRemoteDataSource {
  Future<void> createTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String taskId);
  Stream<List<TaskModel>> getTasksStream();
  Future<List<Map<String, String>>> getAgents();
  Future<String> uploadCompletionPhoto(String taskId, String localPath);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  TaskRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
  });

  @override
  Future<void> createTask(TaskModel task) async {
    await firestore.collection('tasks').doc(task.taskId).set(task.toJson());
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    await firestore.collection('tasks').doc(task.taskId).update(task.toJson());
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await firestore.collection('tasks').doc(taskId).delete();
  }

  @override
  Stream<List<TaskModel>> getTasksStream() {
    return firestore
        .collection('tasks')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromJson(doc.data()))
          .toList();
    });
  }

  @override
  Future<List<Map<String, String>>> getAgents() async {
    final query = await firestore
        .collection('users')
        .where('role', isEqualTo: 'agent')
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      return {
        'uid': (data['uid'] ?? doc.id) as String,
        'name': (data['name'] ?? 'Agent') as String,
        'email': (data['email'] ?? '') as String,
      };
    }).toList();
  }

  @override
  Future<String> uploadCompletionPhoto(String taskId, String localPath) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Photo file does not exist at $localPath');
    }
    final ref = storage.ref().child('completion_photos').child('$taskId.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}
