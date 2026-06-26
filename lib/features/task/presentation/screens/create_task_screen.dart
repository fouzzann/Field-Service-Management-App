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
import 'package:field_service_management_app/features/task/presentation/bloc/theme/theme_cubit.dart';

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
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: Text(isEditMode ? 'Edit Task' : 'Create Task'),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.isDark
                    ? [AppColors.background, const Color(0xFF0F172A).withValues(alpha: 0.8)]
                    : [AppColors.background, const Color(0xFFF1F5F9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                List<Map<String, String>> agents = [];
                if (state is TasksLoaded) {
                  agents = state.agents;
                }

                return Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                    children: [
                      // Modern Card enclosing inputs
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.surfaceLight.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _titleController,
                              validator: (v) => AppValidators.validateRequired(v, 'Title'),
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                labelText: 'Task Title',
                                prefixIcon: Icon(Icons.title, color: AppColors.primaryLight, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _descriptionController,
                              validator: (v) => AppValidators.validateRequired(v, 'Description'),
                              maxLines: 4,
                              style: AppTextStyles.body,
                              decoration: InputDecoration(
                                labelText: 'Task Description',
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(bottom: 60.0),
                                  child: Icon(Icons.description_outlined, color: AppColors.primaryLight, size: 20),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Priority Dropdown
                            DropdownButtonFormField<String>(
                              initialValue: _priority,
                              decoration: InputDecoration(
                                labelText: 'Priority Level',
                                prefixIcon: Icon(Icons.priority_high, color: AppColors.primaryLight, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              dropdownColor: AppColors.surface,
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
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
                              initialValue: _assignedAgentId,
                              decoration: InputDecoration(
                                labelText: 'Assign Agent',
                                prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryLight, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              dropdownColor: AppColors.surface,
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Premium Save Gradient Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: AppTextStyles.button.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: Text(isEditMode ? 'Save Changes' : 'Create Task'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
