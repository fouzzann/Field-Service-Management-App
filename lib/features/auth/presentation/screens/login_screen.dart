import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:field_service_management_app/features/task/presentation/bloc/theme/theme_cubit.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginSubmitted() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      context.read<AuthBloc>().add(
        LoginSubmitted(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  void _fillMockCredentials(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
    });
  }

  Widget _buildQuickLoginCard({
    required String roleName,
    required String email,
    required String password,
    required IconData icon,
    required Color iconColor,
    required String description,
  }) {
    final isDark = AppColors.isDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.surface.withValues(alpha: 0.5)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? AppColors.surfaceLight.withValues(alpha: 0.2)
              : AppColors.surfaceLight.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _fillMockCredentials(email, password),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roleName,
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeState) {
        final isDark = AppColors.isDark;
        final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;
        final secondaryColor = isDark ? AppColors.secondaryLight : AppColors.secondary;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              return Stack(
                children: [
                  // Dynamic Background Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [AppColors.background, const Color(0xFF0F172A), const Color(0xFF020617)]
                            : [AppColors.background, const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  
                  // Glowing Background Spheres
                  Positioned(
                    top: -60,
                    right: -60,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.06),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.1),
                            blurRadius: 100,
                            spreadRadius: 40,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -80,
                    left: -80,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: secondaryColor.withValues(alpha: isDark ? 0.12 : 0.06),
                        boxShadow: [
                          BoxShadow(
                            color: secondaryColor.withValues(alpha: isDark ? 0.25 : 0.1),
                            blurRadius: 100,
                            spreadRadius: 40,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Body Scroll
                  SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),
                            
                            // App Logo with glowing ring
                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.2),
                                        width: 5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                                          blurRadius: 30,
                                          spreadRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 92,
                                    height: 92,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark 
                                          ? AppColors.surface.withValues(alpha: 0.8)
                                          : AppColors.white,
                                      border: Border.all(
                                        color: primaryColor.withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Image.asset(
                                      'asset/App_icon-removebg-preview.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Title & Subtitle
                            Text(
                              'FIELD SERVICE',
                              style: AppTextStyles.heading1.copyWith(
                                letterSpacing: 3,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                fontSize: 26,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Management Solution',
                              style: AppTextStyles.subtitle.copyWith(
                                color: isDark ? AppColors.secondaryLight : AppColors.secondaryDark,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Form Box (Glassmorphic)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surface.withValues(alpha: 0.65)
                                    : AppColors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.surfaceLight.withValues(alpha: 0.3)
                                      : AppColors.surfaceLight.withValues(alpha: 0.5),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Sign In',
                                      style: AppTextStyles.title.copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Email Address
                                    TextFormField(
                                      controller: _emailController,
                                      validator: AppValidators.validateEmail,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        labelText: 'Email Address',
                                        labelStyle: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        floatingLabelStyle: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.email_outlined,
                                          color: primaryColor.withValues(alpha: 0.7),
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? AppColors.surfaceLight.withValues(alpha: 0.3)
                                            : AppColors.surfaceLight.withValues(alpha: 0.4),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: AppColors.surfaceLight.withValues(alpha: 0.15),
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(
                                            color: AppColors.error,
                                            width: 1.2,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(
                                            color: AppColors.error,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Password
                                    TextFormField(
                                      controller: _passwordController,
                                      validator: AppValidators.validatePassword,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        labelStyle: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        floatingLabelStyle: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.lock_outlined,
                                          color: primaryColor.withValues(alpha: 0.7),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: AppColors.textSecondary,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? AppColors.surfaceLight.withValues(alpha: 0.3)
                                            : AppColors.surfaceLight.withValues(alpha: 0.4),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: AppColors.surfaceLight.withValues(alpha: 0.15),
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(
                                            color: AppColors.error,
                                            width: 1.2,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(
                                            color: AppColors.error,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 24),
                                    
                                    state is AuthLoading
                                        ? const LoadingWidget()
                                        : Container(
                                            decoration: BoxDecoration(
                                              gradient: AppColors.primaryGradient,
                                              borderRadius: BorderRadius.circular(14),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primary.withValues(alpha: 0.35),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              onPressed: _onLoginSubmitted,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                              ),
                                              child: Text(
                                                'Login',
                                                style: AppTextStyles.button.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 36),
                            
                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: AppColors.textMuted.withValues(alpha: 0.25),
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    'EASY ACCESSIBILITY',
                                    style: AppTextStyles.caption.copyWith(
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: AppColors.textMuted.withValues(alpha: 0.25),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Developer Access Selection Cards
                            _buildQuickLoginCard(
                              roleName: 'System Administrator',
                              email: 'admin@field.com',
                              password: 'admin123',
                              icon: Icons.admin_panel_settings_outlined,
                              iconColor: AppColors.statusPending,
                              description: 'Full management dashboard and task creation tools',
                            ),
                            _buildQuickLoginCard(
                              roleName: 'Field Service Agent 1',
                              email: 'agent1@field.com',
                              password: 'agent123',
                              icon: Icons.engineering_outlined,
                              iconColor: AppColors.statusInProgress,
                              description: 'Assigned tasks overview, status updates & profile stats',
                            ),
                            _buildQuickLoginCard(
                              roleName: 'Field Service Agent 2',
                              email: 'agent2@field.com',
                              password: 'agent123',
                              icon: Icons.engineering_outlined,
                              iconColor: AppColors.statusCompleted,
                              description: 'Alternative agent account for sync and offline testing',
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
