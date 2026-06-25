import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:field_service_management_app/core/utils/app_colors.dart';
import 'package:field_service_management_app/core/utils/text_styles.dart';
import 'package:field_service_management_app/core/utils/validators.dart';
import 'package:field_service_management_app/features/task/domain/entities/task_entity.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/task/task_bloc.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/task/task_event.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/task/task_state.dart';
import 'package:field_service_management_app/features/task/domain/usecases/sync_tasks_usecase.dart';
import 'package:field_service_management_app/injection_container.dart' as di;

class CreateTaskScreen extends StatefulWidget {
  final TaskEntity? taskToEdit;

  const CreateTaskScreen({super.key, this.taskToEdit});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _priority = 'Medium';
  String? _assignedAgentId;

  bool get isEditMode => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _titleController.text = widget.taskToEdit!.title;
      _descriptionController.text = widget.taskToEdit!.description;
      _priority = widget.taskToEdit!.priority;
      _assignedAgentId = widget.taskToEdit!.assignedAgentId.isEmpty ? null : widget.taskToEdit!.assignedAgentId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final taskBloc = context.read<TaskBloc>();

      if (isEditMode) {
        final updated = widget.taskToEdit!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          assignedAgentId: _assignedAgentId ?? '',
          updatedAt: DateTime.now(),
        );
        taskBloc.add(UpdateTaskEvent(updated));
      } else {
        final task = TaskEntity(
          taskId: const Uuid().v4(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          status: 'Pending',
          assignedAgentId: _assignedAgentId ?? '',
          completionPhoto: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        taskBloc.add(CreateTaskEvent(task));
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Task' : 'Create Task'),
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          List<Map<String, String>> agents = [];
          if (state is TasksLoaded) {
            agents = state.agents;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                TextFormField(
                  controller: _titleController,
                  validator: (v) => AppValidators.validateRequired(v, 'Title'),
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    prefixIcon: Icon(Icons.title, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descriptionController,
                  validator: (v) => AppValidators.validateRequired(v, 'Description'),
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Task Description',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 48.0),
                      child: Icon(Icons.description, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Priority Dropdown
                DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    prefixIcon: Icon(Icons.priority_high, color: AppColors.textSecondary),
                  ),
                  items: ['Low', 'Medium', 'High'].map((p) {
                    return DropdownMenuItem(value: p, child: Text(p));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _priority = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                // Agent Dropdown
                DropdownButtonFormField<String>(
                  value: _assignedAgentId,
                  decoration: const InputDecoration(
                    labelText: 'Assign Agent',
                    prefixIcon: Icon(Icons.person, color: AppColors.textSecondary),
                  ),
                  hint: const Text('Unassigned'),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('Unassigned')),
                    ...agents.map((agent) {
                      return DropdownMenuItem(
                        value: agent['uid'],
                        child: Text(agent['name'] ?? 'Agent'),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _assignedAgentId = val;
                    });
                  },
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _onSave,
                  child: Text(isEditMode ? 'Save Changes' : 'Create Task'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
