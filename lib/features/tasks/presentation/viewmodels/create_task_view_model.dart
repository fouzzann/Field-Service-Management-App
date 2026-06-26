import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/task_entity.dart';
import '../cubit/task_cubit.dart';

class CreateTaskViewModel extends ChangeNotifier {
  final TaskCubit taskCubit;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  String selectedPriority = 'Medium';
  String? selectedAgentId;

  CreateTaskViewModel({required this.taskCubit});

  void initialize(TaskEntity? taskToEdit, String? agentId) {
    if (taskToEdit != null) {
      titleController.text = taskToEdit.title;
      descriptionController.text = taskToEdit.description;
      selectedPriority = taskToEdit.priority;
      selectedAgentId = taskToEdit.assignedAgentId.isEmpty ? null : taskToEdit.assignedAgentId;
    } else if (agentId != null) {
      selectedAgentId = agentId;
    }
  }

  void setPriority(String priority) {
    selectedPriority = priority;
    notifyListeners();
  }

  void setAgentId(String? agentId) {
    selectedAgentId = agentId;
    notifyListeners();
  }

  bool submit(GlobalKey<FormState> formKey, TaskEntity? taskToEdit, BuildContext context) {
    if (formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      
      final task = TaskEntity(
        taskId: taskToEdit?.taskId ?? const Uuid().v4(),
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        priority: selectedPriority,
        status: taskToEdit?.status ?? 'Pending',
        assignedAgentId: selectedAgentId ?? '',
        completionPhoto: taskToEdit?.completionPhoto ?? '',
        createdAt: taskToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (taskToEdit != null) {
        taskCubit.updateTask(task);
      } else {
        taskCubit.createTask(task);
      }
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
