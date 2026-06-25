import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:field_service_management_app/core/utils/app_colors.dart';
import 'package:field_service_management_app/core/utils/text_styles.dart';
import 'package:field_service_management_app/core/widgets/loading_widget.dart';
import 'package:field_service_management_app/features/task/domain/entities/task_entity.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/task/task_bloc.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/task/task_event.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/task/task_state.dart';
import 'package:field_service_management_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:field_service_management_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:field_service_management_app/features/task/presentation/screens/create_task_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  Future<void> _showPhotoSourceBottomSheet(BuildContext context, TaskEntity task) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (builderContext) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Photo Proof Source',
                  style: AppTextStyles.title.copyWith(fontSize: 18),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryLight),
                title: Text('Take Photo (Camera)', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.of(builderContext).pop();
                  _pickCompletionPhoto(context, task, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryLight),
                title: Text('Choose from Gallery', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.of(builderContext).pop();
                  _pickCompletionPhoto(context, task, ImageSource.gallery);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickCompletionPhoto(BuildContext context, TaskEntity task, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70, // Compressing for efficient offline storage
      );

      if (image != null) {
        String finalPath;
        if (kIsWeb) {
          finalPath = image.path; // On web, this is a blob URL
        } else {
          // Save file to permanent documents directory for offline resilience
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = 'completion_${task.taskId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final savedFile = await File(image.path).copy('${appDir.path}/$fileName');
          finalPath = savedFile.path;
        }

        if (context.mounted) {
          context.read<TaskBloc>().add(
                UpdateStatusEvent(
                  taskId: task.taskId,
                  status: 'Completed',
                  localPhotoPath: finalPath,
                ),
              );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: Text('Not Authenticated')),
      );
    }
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TasksLoaded) {
            final taskIndex = state.allTasks.indexWhere((t) => t.taskId == taskId);
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
                    padding: const EdgeInsets.all(24.0),
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

                      // Title
                      Text(task.title, style: AppTextStyles.heading2),
                      const SizedBox(height: 16),

                      // Description
                      Text('Description', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.surfaceLight.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(task.description, style: AppTextStyles.body),
                      ),
                      const SizedBox(height: 20),

                      // Assignment Metadata
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          child: const Icon(Icons.person_outline, color: AppColors.primaryLight),
                        ),
                        title: Text('Assigned Agent', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        subtitle: Text(agentName, style: AppTextStyles.title.copyWith(fontSize: 16)),
                      ),
                      Divider(color: AppColors.surfaceLight),

                      // Dates details
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateDetail('Created At', task.createdAt),
                          ),
                          Expanded(
                            child: _buildDateDetail('Last Updated', task.updatedAt),
                          ),
                        ],
                      ),
                      Divider(color: AppColors.surfaceLight),
                      const SizedBox(height: 16),

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
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
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

  Widget _buildDateDetail(String label, DateTime date) {
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final hourStr = hour12.toString().padLeft(2, '0');
    final minuteStr = date.minute.toString().padLeft(2, '0');
    final dateString = '${date.day}/${date.month}/${date.year} $hourStr:$minuteStr $period';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(dateString, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCompletionPhotoSection(TaskEntity task) {
    if (task.status != 'Completed' && task.completionPhoto.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Completion Photo Proof', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: 220,
            color: AppColors.surface,
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
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_outlined, color: AppColors.error, size: 48),
        ),
      );
    } else {
      final file = File(photoPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
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
            color: AppColors.surfaceLight.withOpacity(0.5),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CreateTaskScreen(taskToEdit: task),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Details'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.statusCompleted.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.statusCompleted),
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

    return ElevatedButton.icon(
      onPressed: () {
        if (isPending) {
          // Transition to In Progress
          context.read<TaskBloc>().add(
                UpdateStatusEvent(
                  taskId: task.taskId,
                  status: 'In Progress',
                ),
              );
        } else {
          // In Progress -> Capturing photo first, then transitions to Completed
          _showPhotoSourceBottomSheet(context, task);
        }
      },
      icon: Icon(isPending ? Icons.play_arrow : Icons.camera_alt),
      label: Text(isPending ? 'Start Progress' : 'Capture Photo & Complete'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPending ? AppColors.statusInProgress : AppColors.statusCompleted,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('Are you sure you want to permanently delete this task? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TaskBloc>().add(DeleteTaskEvent(taskId));
              // Pop dialog and pop detail screen
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
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
