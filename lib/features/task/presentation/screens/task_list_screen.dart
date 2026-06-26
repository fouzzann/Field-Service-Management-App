import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:field_service_management_app/core/utils/app_colors.dart';
import 'package:field_service_management_app/core/utils/text_styles.dart';
import 'package:field_service_management_app/core/widgets/empty_state_widget.dart';
import 'package:field_service_management_app/core/widgets/loading_widget.dart';
import 'package:field_service_management_app/features/task/domain/entities/task_entity.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/task/task_bloc.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/task/task_event.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/task/task_state.dart';
import 'package:field_service_management_app/features/task/presentation/screens/create_task_screen.dart';
import 'package:field_service_management_app/features/task/presentation/screens/task_detail_screen.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/theme/theme_cubit.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: const Text('Manage Tasks'),
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
                if (state is TasksLoaded) {
                  return Column(
                    children: [
                      _buildFilterSection(context, state),
                      Expanded(
                        child: state.filteredTasks.isEmpty
                            ? const EmptyStateWidget(
                                title: 'No Tasks Found',
                                description: 'Try adjusting your filters or create a new task.',
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                itemCount: state.filteredTasks.length,
                                itemBuilder: (context, index) {
                                  final task = state.filteredTasks[index];
                                  final agentName = state.agents.firstWhere(
                                    (a) => a['uid'] == task.assignedAgentId,
                                    orElse: () => {'name': 'Unassigned'},
                                  )['name']!;
                                  return _buildTaskCard(context, task, agentName);
                                },
                              ),
                      )
                    ],
                  );
                }
                return const LoadingWidget();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterSection(BuildContext context, TasksLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceLight.withValues(alpha: 0.2),
            width: 1,
          ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Status Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip(
                  context: context,
                  label: 'All Statuses',
                  isSelected: state.selectedStatusFilter == null,
                  onSelected: () => context.read<TaskBloc>().add(
                        const FilterTasksEvent(status: ''),
                      ),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context: context,
                  label: 'Pending',
                  isSelected: state.selectedStatusFilter == 'Pending',
                  onSelected: () => context.read<TaskBloc>().add(
                        const FilterTasksEvent(status: 'Pending'),
                      ),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context: context,
                  label: 'In Progress',
                  isSelected: state.selectedStatusFilter == 'In Progress',
                  onSelected: () => context.read<TaskBloc>().add(
                        const FilterTasksEvent(status: 'In Progress'),
                      ),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context: context,
                  label: 'Completed',
                  isSelected: state.selectedStatusFilter == 'Completed',
                  onSelected: () => context.read<TaskBloc>().add(
                        const FilterTasksEvent(status: 'Completed'),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Agent Dropdown Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.filter_list, color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 12),
                Text(
                  'Agent:',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.surfaceLight.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: state.selectedAgentFilter,
                        hint: Text('All Agents', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        dropdownColor: AppColors.surface,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.primaryLight),
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.textPrimary, 
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Agents'),
                          ),
                          ...state.agents.map((agent) {
                            return DropdownMenuItem<String>(
                              value: agent['uid'],
                              child: Text(agent['name'] ?? 'Agent'),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          context.read<TaskBloc>().add(
                                FilterTasksEvent(agentId: val ?? ''),
                              );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: AppColors.primary.withValues(alpha: 0.18),
        backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.4),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.surfaceLight.withValues(alpha: 0.2),
          width: 1,
        ),
        labelStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskEntity task, String agentName) {
    Color statusColor;
    switch (task.status) {
      case 'Pending':
        statusColor = AppColors.statusPending;
        break;
      case 'In Progress':
        statusColor = AppColors.statusInProgress;
        break;
      case 'Completed':
        statusColor = AppColors.statusCompleted;
        break;
      default:
        statusColor = AppColors.textMuted;
    }

    Color priorityColor;
    switch (task.priority) {
      case 'Low':
        priorityColor = AppColors.priorityLow;
        break;
      case 'Medium':
        priorityColor = AppColors.priorityMedium;
        break;
      case 'High':
        priorityColor = AppColors.priorityHigh;
        break;
      default:
        priorityColor = AppColors.textMuted;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceLight.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(taskId: task.taskId),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        task.status,
                        style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Priority Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: priorityColor.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${task.priority} Priority',
                        style: AppTextStyles.caption.copyWith(
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  task.title,
                  style: AppTextStyles.title.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySecondary.copyWith(
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: AppColors.surfaceLight.withValues(alpha: 0.4), height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person_outline, size: 14, color: AppColors.primaryLight),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Agent: $agentName',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.primaryLight, size: 18),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CreateTaskScreen(taskToEdit: task),
                            ),
                          ),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                          onPressed: () => _confirmDelete(context, task.taskId),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('Are you sure you want to permanently delete this task? This action is sync\'ed with the server.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TaskBloc>().add(DeleteTaskEvent(taskId));
              Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
