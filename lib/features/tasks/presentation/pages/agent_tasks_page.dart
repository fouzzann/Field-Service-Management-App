import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/text_styles.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart' as core_err;
import '../../domain/entities/task_entity.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import '../cubit/sync_cubit.dart';
import '../cubit/sync_state.dart';
import '../viewmodels/task_list_view_model.dart';
import '../../../authentication/presentation/cubit/auth_cubit.dart';
import '../../../authentication/presentation/cubit/auth_state.dart';
import '../../../settings/presentation/cubit/theme_cubit.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../../core/dependency_injection/injection_container.dart' as di;
import '../../../../core/network/network_info.dart';
import 'task_detail_page.dart';

class AgentTasksPage extends StatefulWidget {
  const AgentTasksPage({super.key});

  @override
  State<AgentTasksPage> createState() => _AgentTasksPageState();
}

class _AgentTasksPageState extends State<AgentTasksPage> {
  late TaskListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TaskListViewModel(
      taskCubit: context.read<TaskCubit>(),
      syncCubit: context.read<SyncCubit>(),
      networkInfo: di.sl<NetworkInfo>(),
    );
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: Text('Not Authenticated')),
      );
    }
    final currentAgentId = authState.user.uid;

    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: const Text('Agent Dashboard'),
            leading: IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ),
              ),
            ],
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
            child: MultiBlocListener(
              listeners: [
                BlocListener<SyncCubit, SyncState>(
                  listener: (context, state) {
                    if (state is SyncSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Offline modifications synced successfully! 🚀'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      _viewModel.load();
                    } else if (state is SyncFailure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sync failed: ${state.error}'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
              child: BlocBuilder<TaskCubit, TaskState>(
                builder: (context, state) {
                  if (state is TaskLoading) {
                    return const LoadingWidget();
                  }
                  
                  if (state is TaskError) {
                    return core_err.AppErrorWidget(
                      message: state.message,
                      onRetry: _viewModel.load,
                    );
                  }
                  
                  if (state is TasksLoaded) {
                    final myTasks = state.allTasks
                        .where((task) => task.assignedAgentId == currentAgentId)
                        .toList();

                    return ListenableBuilder(
                      listenable: _viewModel,
                      builder: (context, _) {
                        return RefreshIndicator(
                          onRefresh: _viewModel.refresh,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            children: [
                              _buildSyncStatusBanner(),
                              const SizedBox(height: 16),
                              _buildWelcomeHeader(authState.user.name),
                              const SizedBox(height: 16),
                              _buildAgentMetricsRow(myTasks),
                              const SizedBox(height: 28),
                              Text('My Tasks List', style: AppTextStyles.title),
                              const SizedBox(height: 12),
                              if (myTasks.isEmpty)
                                const EmptyStateWidget(
                                  title: 'No Tasks Assigned',
                                  description: 'You currently have no tasks assigned to you.',
                                  icon: Icons.assignment_turned_in_outlined,
                                )
                              else
                                ...myTasks.map((task) => _buildAgentTaskCard(context, task)),
                              const SizedBox(height: 20),
                            ],
                          ),
                        );
                      },
                    );
                  }
                  return const LoadingWidget();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(String name) {
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.engineering_outlined,
              color: AppColors.primaryLight,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back,',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: AppTextStyles.title.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Here is your overview for today',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentMetricsRow(List<TaskEntity> tasks) {
    final total = tasks.length;
    final pending = tasks.where((t) => t.status == 'Pending').length;
    final inProgress = tasks.where((t) => t.status == 'In Progress').length;
    final completed = tasks.where((t) => t.status == 'Completed').length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildMiniMetricCard('Assigned', '$total', Icons.assignment_outlined, AppColors.primary),
          const SizedBox(width: 10),
          _buildMiniMetricCard('Pending', '$pending', Icons.hourglass_empty_outlined, AppColors.statusPending),
          const SizedBox(width: 10),
          _buildMiniMetricCard('Active', '$inProgress', Icons.trending_up, AppColors.statusInProgress),
          const SizedBox(width: 10),
          _buildMiniMetricCard('Done', '$completed', Icons.check_circle_outline, AppColors.statusCompleted),
        ],
      ),
    );
  }

  Widget _buildMiniMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusBanner() {
    return BlocBuilder<SyncCubit, SyncState>(
      builder: (context, state) {
        bool isOnline = _viewModel.isOnline;
        bool isSyncing = state is SyncInProgress;

        final bannerColor = isSyncing
            ? AppColors.primary
            : (isOnline ? AppColors.success : AppColors.statusPending);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bannerColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: bannerColor.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bannerColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSyncing
                      ? Icons.sync
                      : (isOnline ? Icons.wifi : Icons.wifi_off),
                  color: bannerColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
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
                  onPressed: _viewModel.refresh,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.statusPending.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Sync Now',
                    style: TextStyle(
                      color: AppColors.statusPending,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                )
            ],
          ),
        );
      },
    );
  }

  Widget _buildAgentTaskCard(BuildContext context, TaskEntity task) {
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
              builder: (_) => TaskDetailPage(taskId: task.taskId),
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
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Builder(
                          builder: (context) {
                            final date = task.updatedAt;
                            final period = date.hour >= 12 ? 'PM' : 'AM';
                            final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
                            final hourStr = hour12.toString().padLeft(2, '0');
                            final minuteStr = date.minute.toString().padLeft(2, '0');
                            return Text(
                              'Updated: $hourStr:$minuteStr $period',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: AppColors.primaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 11,
                          color: AppColors.primaryLight,
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
