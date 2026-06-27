import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/image_picker_widget.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../domain/entities/task_entity.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import '../viewmodels/task_detail_view_model.dart';
import '../../../authentication/presentation/cubit/auth_cubit.dart';
import '../../../authentication/presentation/cubit/auth_state.dart';
import '../../../settings/presentation/cubit/theme_cubit.dart';
import 'create_task_page.dart';

// This page displays all the details of a single task (title, description, status, photo).
// It allows agents to change status, take completion photos, and allows admins to edit/delete tasks.
class TaskDetailPage extends StatefulWidget {
  final String taskId;

  const TaskDetailPage({super.key, required this.taskId});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  // ViewModel helper that separates UI components from business logic.
  late TaskDetailViewModel _viewModel;

  @override
  // Runs once when this page is opened.
  void initState() {
    super.initState();
    _viewModel = TaskDetailViewModel(taskCubit: context.read<TaskCubit>());
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get the current authentication state (to check who is logged in and what role they have).
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: Text('Not Authenticated')),
      );
    }
    final user = authState.user;

    // 2. React to theme changes (e.g. Light/Dark mode).
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeState) {
        final isDark = AppColors.isDark;
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: const Text('Task Details'),
          ),
          body: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.background, const Color(0xFF0F172A).withValues(alpha: 0.8)]
                    : [AppColors.background, const Color(0xFFF1F5F9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            // 3. React to updates on tasks (so if status changes or syncing completes, the details update automatically).
            child: BlocBuilder<TaskCubit, TaskState>(
              builder: (context, state) {
                if (state is TasksLoaded) {
                  final taskIndex = state.allTasks.indexWhere((t) => t.taskId == widget.taskId);
                  if (taskIndex == -1) {
                    return const Center(child: Text('Task not found. It may have been deleted.'));
                  }
                  final task = state.allTasks[taskIndex];
                  final agentName = state.agents.firstWhere(
                    (a) => a['uid'] == task.assignedAgentId,
                    orElse: () => {'name': 'Unassigned'},
                  )['name']!;

                  return Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                          children: [
                            // Header: Priority & Status Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildBadge(
                                  task.status,
                                  _getStatusColor(task.status),
                                ),
                                _buildBadge(
                                  '${task.priority} Priority',
                                  _getPriorityColor(task.priority),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Main Title Card
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
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: AppTextStyles.title.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Description',
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    task.description,
                                    style: AppTextStyles.body.copyWith(
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Assignment Metadata Card
                            Container(
                              padding: const EdgeInsets.all(16),
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
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Assigned Agent',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          agentName,
                                          style: AppTextStyles.subtitle.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Dates Detail Row (Grid Cards)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateDetailCard('Created At', task.createdAt, Icons.calendar_today_outlined),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDateDetailCard('Last Updated', task.updatedAt, Icons.update_outlined),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Completion Photo section
                            _buildCompletionPhotoSection(task),
                          ],
                        ),
                      ),

                      // Role-Based Bottom Action Bar
                      _buildBottomActions(context, user.isAdmin, task),
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

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDateDetailCard(String label, DateTime date, IconData icon) {
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final hourStr = hour12.toString().padLeft(2, '0');
    final minuteStr = date.minute.toString().padLeft(2, '0');
    final dateString = '${date.day}/${date.month}/${date.year}';
    final timeString = '$hourStr:$minuteStr $period';

    return Container(
      padding: const EdgeInsets.all(16),
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
            children: [
              Icon(icon, size: 14, color: AppColors.primaryLight),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dateString,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            timeString,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionPhotoSection(TaskEntity task) {
    if (task.status != 'Completed' && task.completionPhoto.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completion Photo Proof',
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.surfaceLight.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: task.completionPhoto.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: 48),
                        const SizedBox(height: 8),
                        Text('No completion photo uploaded', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : _loadImage(task.completionPhoto),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _loadImage(String photoPath) {
    if (kIsWeb || photoPath.startsWith('http') || photoPath.startsWith('https') || photoPath.startsWith('blob:')) {
      return Image.network(
        photoPath,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, _, _) => const Center(
          child: Icon(Icons.broken_image_outlined, color: AppColors.error, size: 48),
        ),
      );
    } else {
      final file = File(photoPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(Icons.broken_image_outlined, color: AppColors.error, size: 48),
          ),
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 48),
              const SizedBox(height: 8),
              Text('Local image file missing', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        );
      }
    }
  }

  Widget _buildBottomActions(BuildContext context, bool isAdmin, TaskEntity task) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 36, top: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceLight.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: isAdmin
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    label: const Text('Delete Task'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: AppTextStyles.button.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
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
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CreateTaskPage(taskToEdit: task),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: AppTextStyles.button.copyWith(fontWeight: FontWeight.bold),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : _buildAgentActions(context, task),
    );
  }

  Widget _buildAgentActions(BuildContext context, TaskEntity task) {
    if (task.status == 'Completed') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.statusCompleted.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.statusCompleted.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.statusCompleted),
            const SizedBox(width: 8),
            Text(
              'Task Completed Successfully',
              style: AppTextStyles.body.copyWith(
                color: AppColors.statusCompleted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final isPending = task.status == 'Pending';
    final actionColor = isPending ? AppColors.statusInProgress : AppColors.statusCompleted;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPending
              ? [AppColors.statusInProgress, AppColors.statusInProgress.withValues(alpha: 0.8)]
              : [AppColors.statusCompleted, AppColors.statusCompleted.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: actionColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isPending
          ? ElevatedButton.icon(
              onPressed: () => _viewModel.updateStatus(task.taskId, 'In Progress'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Progress'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: AppTextStyles.button.copyWith(fontWeight: FontWeight.bold),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )
          : ImagePickerWidget(
              onImagePicked: (path) => _viewModel.updateStatus(task.taskId, 'Completed', localPhotoPath: path),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: AppColors.white),
                    SizedBox(width: 8),
                    Text(
                      'Capture Photo & Complete',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Task?',
        content: 'Are you sure you want to permanently delete this task? This action cannot be undone.',
        confirmLabel: 'Delete',
        confirmColor: AppColors.error,
        onConfirm: () {
          _viewModel.deleteTask(widget.taskId);
          Navigator.of(context).pop(); // Back to list
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppColors.statusPending;
      case 'In Progress':
        return AppColors.statusInProgress;
      case 'Completed':
        return AppColors.statusCompleted;
      default:
        return AppColors.textMuted;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return AppColors.priorityLow;
      case 'Medium':
        return AppColors.priorityMedium;
      case 'High':
        return AppColors.priorityHigh;
      default:
        return AppColors.textMuted;
    }
  }
}
