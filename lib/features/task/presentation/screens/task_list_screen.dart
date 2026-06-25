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

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tasks'),
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
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
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
    );
  }

  Widget _buildFilterSection(BuildContext context, TasksLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceLight.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Chips
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
          const SizedBox(height: 10),
          // Agent Dropdown Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Text('Agent:', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: state.selectedAgentFilter,
                        hint: const Text('All Agents', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
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
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceLight,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.white : AppColors.textSecondary,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      showCheckmark: false,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: AppColors.surface,
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(taskId: task.taskId),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
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
              const SizedBox(height: 12),
              Text(task.title, style: AppTextStyles.title),
              const SizedBox(height: 6),
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.surfaceLight, height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        'Agent: $agentName',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
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
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                        onPressed: () => _confirmDelete(context, task.taskId),
                      ),
                    ],
                  )
                ],
              )
            ],
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
