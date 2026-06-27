import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/task_model.dart';

// In Clean Architecture, a "DataSource" handles direct communication with a database or service.
// This is the Remote DataSource: it performs cloud operations using Firebase Firestore and Firebase Storage.
abstract class TaskRemoteDataSource {
  // Saves a new task document to Firestore.
  Future<void> createTask(TaskModel task);
  
  // Updates an existing task document in Firestore.
  Future<void> updateTask(TaskModel task);
  
  // Deletes a task document from Firestore.
  Future<void> deleteTask(String taskId);
  
  // Listens to real-time updates from Firestore tasks collection.
  Stream<List<TaskModel>> getTasksStream();
  
  // Gets all users registered as "agents" from Firestore.
  Future<List<Map<String, String>>> getAgents();
  
  // Uploads a task completion photo to Firebase Storage and returns the public download URL.
  Future<String> uploadCompletionPhoto(String taskId, String localPath);
}

// Implementation of Remote DataSource using actual Firebase services.
class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  TaskRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
  });

  @override
  // Writes a task document inside the 'tasks' collection in Firestore.
  Future<void> createTask(TaskModel task) async {
    await firestore.collection('tasks').doc(task.taskId).set(task.toJson());
  }

  @override
  // Updates fields of an existing task document in Firestore.
  Future<void> updateTask(TaskModel task) async {
    await firestore.collection('tasks').doc(task.taskId).update(task.toJson());
  }

  @override
  // Deletes a task document from Firestore.
  Future<void> deleteTask(String taskId) async {
    await firestore.collection('tasks').doc(taskId).delete();
  }

  @override
  // Subscribes to the 'tasks' collection so we get new lists of tasks automatically whenever data changes.
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
  // Queries Firestore to find users whose role field is 'agent'.
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
  // Uploads local files to Firebase Storage.
  Future<String> uploadCompletionPhoto(String taskId, String localPath) async {
    // Defines where the photo will be stored: e.g. completion_photos/task123.jpg
    final ref = storage.ref().child('completion_photos').child('$taskId.jpg');
    
    if (kIsWeb) {
      // 1. Web browser: Read the file as binary bytes and upload using putData.
      final bytes = await XFile(localPath).readAsBytes();
      await ref.putData(bytes);
    } else {
      // 2. Mobile (Android/iOS): Upload the file using putFile.
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('Photo file does not exist at $localPath');
      }
      await ref.putFile(file);
    }
    
    // 3. Return the web URL so we can save it in Firestore.
    return await ref.getDownloadURL();
  }
}
