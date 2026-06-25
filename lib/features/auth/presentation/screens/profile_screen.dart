import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:field_service_management_app/core/utils/app_colors.dart';
import 'package:field_service_management_app/core/utils/text_styles.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/theme/theme_cubit.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: const Text('My Profile'),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.isDark
                    ? [AppColors.background, const Color(0xFF0F172A).withOpacity(0.8)]
                    : [AppColors.background, const Color(0xFFF1F5F9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is Authenticated) {
                  final user = state.user;
                  final roleColor = user.isAdmin ? AppColors.primary : AppColors.secondary;
                  
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // Dual-Ring Glowing Avatar
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: roleColor.withOpacity(0.2),
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: roleColor.withOpacity(0.15),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: roleColor.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                              ),
                              CircleAvatar(
                                radius: 52,
                                backgroundColor: roleColor.withOpacity(0.12),
                                child: Icon(
                                  user.isAdmin
                                      ? Icons.admin_panel_settings_outlined
                                      : Icons.engineering_outlined,
                                  size: 52,
                                  color: user.isAdmin
                                      ? AppColors.primaryLight
                                      : AppColors.secondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Name
                        Text(
                          user.name,
                          style: AppTextStyles.heading2.copyWith(
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        
                        // Sleek Role Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: roleColor.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            user.isAdmin ? 'ADMINISTRATOR' : 'FIELD AGENT',
                            style: AppTextStyles.caption.copyWith(
                              color: user.isAdmin ? AppColors.primaryLight : AppColors.secondaryLight,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Glassmorphic Info Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.surfaceLight.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildDetailRow(
                                Icons.email_outlined,
                                'Email Address',
                                user.email,
                                roleColor,
                              ),
                              Divider(color: AppColors.surfaceLight.withOpacity(0.5), height: 24),
                              _buildDetailRow(
                                Icons.perm_identity_outlined,
                                'User ID Reference',
                                user.uid,
                                roleColor,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        
                        // Premium Logout Button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.read<AuthBloc>().add(LogoutRequested());
                            },
                            icon: const Icon(Icons.logout, size: 20),
                            label: const Text('Logout Session'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
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
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                }
                return const Center(child: Text('Not Authenticated'));
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color accentColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )
      ],
    );
  }
}
