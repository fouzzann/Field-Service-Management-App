import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/task_entity.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import '../../../settings/presentation/cubit/theme_cubit.dart';
import '../viewmodels/create_task_view_model.dart';

class CreateTaskPage extends StatefulWidget {
  final TaskEntity? taskToEdit;
  final String? agentId;

  const CreateTaskPage({super.key, this.taskToEdit, this.agentId});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
  late CreateTaskViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CreateTaskViewModel(
      taskCubit: context.read<TaskCubit>(),
    );
    _viewModel.initialize(widget.taskToEdit, widget.agentId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _onSave() {
    final success = _viewModel.submit(_formKey, widget.taskToEdit, context);
    if (success) {
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
            title: Text(widget.taskToEdit != null ? 'Edit Task' : 'Create Task'),
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
            child: BlocBuilder<TaskCubit, TaskState>(
              builder: (context, state) {
                List<Map<String, String>> agents = [];
                if (state is TasksLoaded) {
                  agents = state.agents;
                }

                return Form(
                  key: _formKey,
                  child: ListenableBuilder(
                    listenable: _viewModel,
                    builder: (context, _) {
                      return ListView(
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
                                  controller: _viewModel.titleController,
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
                                  controller: _viewModel.descriptionController,
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
                                  initialValue: _viewModel.selectedPriority,
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
                                      _viewModel.setPriority(val);
                                    }
                                  },
                                ),
                                const SizedBox(height: 20),
                                // Agent Dropdown
                                DropdownButtonFormField<String?>(
                                  initialValue: _viewModel.selectedAgentId,
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
                                    const DropdownMenuItem<String?>(value: null, child: Text('Unassigned')),
                                    ...agents.map((agent) {
                                      return DropdownMenuItem<String?>(
                                        value: agent['uid'],
                                        child: Text(agent['name'] ?? 'Agent'),
                                      );
                                    }),
                                  ],
                                  onChanged: (val) {
                                    _viewModel.setAgentId(val);
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
                              child: Text(widget.taskToEdit != null ? 'Save Changes' : 'Create Task'),
                            ),
                          ),
                        ],
                      );
                    },
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
