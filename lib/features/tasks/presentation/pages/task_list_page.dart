import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/text_styles.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart' as core_err;
import '../../../../core/widgets/task_card.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import '../cubit/sync_cubit.dart';
import '../viewmodels/task_list_view_model.dart';
import '../../../settings/presentation/cubit/theme_cubit.dart';
import 'create_task_page.dart';
import 'task_detail_page.dart';
import '../../../../core/dependency_injection/injection_container.dart' as di;
import '../../../../core/network/network_info.dart';

// This is the UI screen that displays the list of all tasks.
// It is a StatefulWidget because it needs to set up a ViewModel and clean it up when closed.
class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  // We use a ViewModel to hold the logic and data state for this page, keeping the UI code clean.
  late TaskListViewModel _viewModel;

  @override
  // initState is called exactly once when the page is loaded into memory.
  void initState() {
    super.initState();
    // Initialize our ViewModel helper with the Cubits and Network information.
    _viewModel = TaskListViewModel(
      taskCubit: context.read<TaskCubit>(),
      syncCubit: context.read<SyncCubit>(),
      networkInfo: di.sl<NetworkInfo>(),
    );
    _viewModel.load(); // Fetch the initial list of tasks.
  }

  @override
  // dispose is called when the user leaves the page permanently.
  void dispose() {
    _viewModel.dispose(); // Clean up any active subscriptions or listeners in the ViewModel.
    super.dispose();
  }

  @override
  // The build method draws the UI. It runs every time the state changes.
  Widget build(BuildContext context) {
    // BlocBuilder rebuilt the screen when the ThemeCubit updates (e.g. Light mode to Dark mode).
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
            // BlocBuilder rebuilds this section of the screen when our Task list state changes (e.g. from Loading to Loaded).
            child: BlocBuilder<TaskCubit, TaskState>(
              builder: (context, state) {
                if (state is TaskLoading) {
                  return const LoadingWidget(); // Show loading spinner.
                }

                if (state is TaskError) {
                  return core_err.AppErrorWidget(
                    message: state.message,
                    onRetry: _viewModel.load,
                  );
                }

                if (state is TasksLoaded) {
                  return RefreshIndicator(
                    onRefresh: _viewModel.refresh,
                    child: Column(
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
                                    
                                    return TaskCard(
                                      task: task,
                                      agentName: agentName,
                                      isAdmin: true,
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TaskDetailPage(taskId: task.taskId),
                                        ),
                                      ),
                                      onEdit: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => CreateTaskPage(taskToEdit: task),
                                        ),
                                      ),
                                      onDelete: () => _confirmDelete(context, task.taskId),
                                    );
                                  },
                                ),
                        )
                      ],
                    ),
                  );
                }

                return const EmptyStateWidget(
                  title: 'No Data Found',
                  description: 'Load tasks to get started.',
                );
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
                  onSelected: () => _viewModel.applyStatusFilter(''),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context: context,
                  label: 'Pending',
                  isSelected: state.selectedStatusFilter == 'Pending',
                  onSelected: () => _viewModel.applyStatusFilter('Pending'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context: context,
                  label: 'In Progress',
                  isSelected: state.selectedStatusFilter == 'In Progress',
                  onSelected: () => _viewModel.applyStatusFilter('In Progress'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context: context,
                  label: 'Completed',
                  isSelected: state.selectedStatusFilter == 'Completed',
                  onSelected: () => _viewModel.applyStatusFilter('Completed'),
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
                        onChanged: (val) => _viewModel.applyAgentFilter(val ?? ''),
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

  void _confirmDelete(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Task?',
        content: 'Are you sure you want to permanently delete this task? This action is sync\'ed with the server.',
        confirmLabel: 'Delete',
        confirmColor: AppColors.error,
        onConfirm: () => _viewModel.deleteTask(taskId),
      ),
    );
  }
}
