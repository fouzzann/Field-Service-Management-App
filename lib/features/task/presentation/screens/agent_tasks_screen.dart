import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:field_service_management_app/core/utils/app_colors.dart';
import 'package:field_service_management_app/core/utils/text_styles.dart';
import 'package:field_service_management_app/core/widgets/empty_state_widget.dart';
import 'package:field_service_management_app/core/widgets/loading_widget.dart';
import 'package:field_service_management_app/core/widgets/error_widget.dart';
import 'package:field_service_management_app/features/task/domain/entities/task_entity.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/sync/sync_bloc.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/sync/sync_event.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/sync/sync_state.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/task/task_bloc.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/task/task_event.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/task/task_state.dart';
import 'package:field_service_management_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:field_service_management_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:field_service_management_app/features/auth/presentation/screens/profile_screen.dart';
import 'package:field_service_management_app/features/task/presentation/screens/settings_screen.dart';
import 'package:field_service_management_app/features/task/presentation/screens/task_detail_screen.dart';

class AgentTasksScreen extends StatefulWidget {
  const AgentTasksScreen({super.key});

  @override
  State<AgentTasksScreen> createState() => _AgentTasksScreenState();
}

class _AgentTasksScreenState extends State<AgentTasksScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(LoadTasks());
    context.read<SyncBloc>().add(MonitorConnection());
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: Text('Not Authenticated')),
      );
    }
    final currentAgentId = authState.user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Assigned Tasks'),
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<SyncBloc, SyncState>(
            listener: (context, state) {
              if (state is SyncSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Offline modifications synced successfully! 🚀'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                context.read<TaskBloc>().add(LoadTasks());
              } else if (state is SyncFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sync failed: ${state.message}'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            if (state is TaskLoading) {
              return const LoadingWidget();
            } else if (state is TaskError) {
              return AppErrorWidget(
                message: state.message,
                onRetry: () => context.read<TaskBloc>().add(LoadTasks()),
              );
            } else if (state is TasksLoaded) {
              // Filter to show only tasks assigned to the logged-in agent
              final myTasks = state.allTasks
                  .where((task) => task.assignedAgentId == currentAgentId)
                  .toList();

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<TaskBloc>().add(LoadTasks());
                  context.read<SyncBloc>().add(TriggerSync());
                },
                child: Column(
                  children: [
                    _buildSyncStatusBanner(),
                    Expanded(
                      child: myTasks.isEmpty
                          ? const EmptyStateWidget(
                              title: 'No Tasks Assigned',
                              description: 'You currently have no tasks assigned to you.',
                              icon: Icons.assignment_turned_in_outlined,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: myTasks.length,
                              itemBuilder: (context, index) {
                                final task = myTasks[index];
                                return _buildTaskCard(context, task);
                              },
                            ),
                    ),
                  ],
                ),
              );
            }
            return const LoadingWidget();
          },
        ),
      ),
    );
  }

  Widget _buildSyncStatusBanner() {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        bool isOnline = true;
        bool isSyncing = false;

        if (state is ConnectivityStatus) {
          isOnline = state.isOnline;
        } else if (state is SyncInProgress) {
          isSyncing = true;
        }

        return Container(
          margin: const EdgeInsets.only(left: 20, right: 20, top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSyncing
                ? AppColors.primary.withOpacity(0.1)
                : (isOnline ? AppColors.success.withOpacity(0.1) : AppColors.statusPending.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSyncing
                  ? AppColors.primaryLight
                  : (isOnline ? AppColors.statusCompleted : AppColors.statusPending),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSyncing
                    ? Icons.sync
                    : (isOnline ? Icons.wifi : Icons.wifi_off),
                color: isSyncing
                    ? AppColors.primaryLight
                    : (isOnline ? AppColors.statusCompleted : AppColors.statusPending),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isSyncing
                      ? 'Syncing offline modifications...'
                      : (isOnline ? 'System Online (Ready to sync)' : 'System Offline (Status updates saved locally)'),
                  style: AppTextStyles.caption.copyWith(
                    color: isSyncing
                        ? AppColors.primaryLight
                        : (isOnline ? AppColors.textPrimary : AppColors.statusPending),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!isOnline)
                TextButton(
                  onPressed: () {
                    context.read<SyncBloc>().add(TriggerSync());
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Sync Now', style: TextStyle(color: AppColors.primaryLight, fontSize: 12)),
                )
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskEntity task) {
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
                  Text(
                    'Updated: ${task.updatedAt.hour}:${task.updatedAt.minute.toString().padLeft(2, '0')}',
                    style: AppTextStyles.caption,
                  ),
                  const Row(
                    children: [
                      Text('Details', style: TextStyle(color: AppColors.primaryLight, fontSize: 12)),
                      Icon(Icons.chevron_right, size: 16, color: AppColors.primaryLight),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
