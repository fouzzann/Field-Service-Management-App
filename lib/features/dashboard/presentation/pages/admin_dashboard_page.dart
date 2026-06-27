import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/text_styles.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../tasks/presentation/cubit/sync_cubit.dart';
import '../../../tasks/presentation/cubit/sync_state.dart';
import '../../../tasks/presentation/cubit/task_cubit.dart';
import '../../../tasks/presentation/cubit/task_state.dart';
import '../../../tasks/presentation/pages/create_task_page.dart';
import '../../../tasks/presentation/pages/task_list_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../settings/presentation/cubit/theme_cubit.dart';
import '../viewmodels/admin_dashboard_view_model.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/dependency_injection/injection_container.dart' as di;

// This is the Admin Dashboard Page.
// Admins see task completion charts, overall metrics (pending/in-progress/completed), and can navigate to Settings, Profile, or Manage Tasks.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // ViewModel helper to coordinate loading dashboard metrics and listening to task changes.
  late AdminDashboardViewModel _viewModel;

  @override
  // Runs when the admin dashboard opens.
  void initState() {
    super.initState();
    _viewModel = AdminDashboardViewModel(
      taskCubit: context.read<TaskCubit>(),
      syncCubit: context.read<SyncCubit>(),
      networkInfo: di.sl<NetworkInfo>(),
    );
    _viewModel.load(); // Fetch initial task list & compute dashboard statistics.
  }

  @override
  // Runs when closing the dashboard (e.g. logging out).
  void dispose() {
    _viewModel.dispose(); // Clean up listeners.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-draw UI when light/dark theme switches.
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: const Text('Admin Dashboard'),
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
            // MultiBlocListener listens for updates from multiple Cubits without rebuilding the UI tree.
            // This is ideal for showing snackbars, dialogs, or page routing triggers.
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
                  } else if (state is TaskError) {
                    return AppErrorWidget(
                      message: state.message,
                      onRetry: _viewModel.load,
                    );
                  } else if (state is TasksLoaded) {
                    final tasks = state.allTasks;
                    final pending = tasks.where((t) => t.status == 'Pending').length;
                    final inProgress = tasks.where((t) => t.status == 'In Progress').length;
                    final completed = tasks.where((t) => t.status == 'Completed').length;
                    final total = tasks.length;

                    return ListenableBuilder(
                      listenable: _viewModel,
                      builder: (context, _) {
                        return RefreshIndicator(
                          onRefresh: () async {
                            await _viewModel.load();
                            await _viewModel.syncData();
                          },
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            children: [
                              // Connection Status bar
                              _buildSyncStatusBanner(),
                              const SizedBox(height: 20),

                              // Metrics Grid
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricCard(
                                      'Total Tasks',
                                      '$total',
                                      Icons.assignment_outlined,
                                      AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildMetricCard(
                                      'Pending',
                                      '$pending',
                                      Icons.hourglass_empty_outlined,
                                      AppColors.statusPending,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricCard(
                                      'In Progress',
                                      '$inProgress',
                                      Icons.trending_up,
                                      AppColors.statusInProgress,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildMetricCard(
                                      'Completed',
                                      '$completed',
                                      Icons.check_circle_outline,
                                      AppColors.statusCompleted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Modern Navigation to full task list
                              Container(
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const TaskListPage()),
                                  ),
                                  icon: const Icon(Icons.list_alt_outlined, size: 20),
                                  label: const Text('Manage & Filter Tasks'),
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
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Charts Section
                              if (total == 0)
                                const EmptyStateWidget(
                                  title: 'No Task Metrics',
                                  description: 'Create tasks to view statistical charts here.',
                                  icon: Icons.pie_chart_outline,
                                )
                              else ...[
                                Text('Status Distribution', style: AppTextStyles.title),
                                const SizedBox(height: 16),
                                _buildChartCard(
                                  child: _buildPieChart(pending, inProgress, completed, total),
                                ),
                                const SizedBox(height: 32),
                                Text('Task Count Comparison', style: AppTextStyles.title),
                                const SizedBox(height: 16),
                                _buildChartCard(
                                  child: _buildBarChart(pending, inProgress, completed),
                                ),
                                const SizedBox(height: 100),
                              ]
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateTaskPage()),
            ),
            label: const Text('Create Task'),
            icon: const Icon(Icons.add),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
        );
      },
    );
  }

  Widget _buildChartCard({required Widget child}) {
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
      child: child,
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
                      : (isOnline ? 'System Online (Real-time updates active)' : 'System Offline (Updates saved locally)'),
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
                  onPressed: _viewModel.syncData,
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

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: AppTextStyles.heading1.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(int pending, int inProgress, int completed, int total) {
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 32,
                sections: [
                  if (pending > 0)
                    PieChartSectionData(
                      color: AppColors.statusPending,
                      value: pending.toDouble(),
                      title: '${((pending / total) * 100).toStringAsFixed(0)}%',
                      radius: 46,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  if (inProgress > 0)
                    PieChartSectionData(
                      color: AppColors.statusInProgress,
                      value: inProgress.toDouble(),
                      title: '${((inProgress / total) * 100).toStringAsFixed(0)}%',
                      radius: 46,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  if (completed > 0)
                    PieChartSectionData(
                      color: AppColors.statusCompleted,
                      value: completed.toDouble(),
                      title: '${((completed / total) * 100).toStringAsFixed(0)}%',
                      radius: 46,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem('Pending', AppColors.statusPending),
                const SizedBox(height: 10),
                _buildLegendItem('In Progress', AppColors.statusInProgress),
                const SizedBox(height: 10),
                _buildLegendItem('Completed', AppColors.statusCompleted),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodySecondary.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(int pending, int inProgress, int completed) {
    final maxCount = [pending, inProgress, completed].reduce((a, b) => a > b ? a : b).toDouble();
    final double maxY = maxCount == 0 ? 5 : maxCount + 1;

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final style = TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  );
                  switch (value.toInt()) {
                    case 0:
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('Pending', style: style),
                      );
                    case 1:
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('Progress', style: style),
                      );
                    case 2:
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('Completed', style: style),
                      );
                    default:
                      return const Text('');
                  }
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.surfaceLight.withValues(alpha: 0.35),
                strokeWidth: 0.8,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: pending.toDouble(),
                  color: AppColors.statusPending,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                )
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: inProgress.toDouble(),
                  color: AppColors.statusInProgress,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                )
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: completed.toDouble(),
                  color: AppColors.statusCompleted,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
