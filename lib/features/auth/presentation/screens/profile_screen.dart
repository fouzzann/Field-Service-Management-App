import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/text_styles.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            final user = state.user;
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // User Avatar Icon
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Icon(
                        user.isAdmin ? Icons.admin_panel_settings_outlined : Icons.engineering_outlined,
                        size: 60,
                        color: user.isAdmin ? AppColors.primaryLight : AppColors.secondaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Name
                  Text(
                    user.name,
                    style: AppTextStyles.heading2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: user.isAdmin
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: user.isAdmin ? AppColors.primaryLight : AppColors.secondaryLight,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      user.isAdmin ? 'ADMINISTRATOR' : 'FIELD AGENT',
                      style: AppTextStyles.caption.copyWith(
                        color: user.isAdmin ? AppColors.primaryLight : AppColors.secondaryLight,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Details Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.surfaceLight.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.email_outlined, 'Email', user.email),
                        const Divider(color: AppColors.surfaceLight),
                        _buildDetailRow(
                          Icons.perm_identity_outlined,
                          'User ID',
                          user.uid,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Logout Button
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(LogoutRequested());
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
          return const Center(child: Text('Not Authenticated'));
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.body,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
