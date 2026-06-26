import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../settings/presentation/cubit/theme_cubit.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../viewmodels/login_view_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late LoginViewModel _viewModel;
  bool _rememberMeLocal = false;

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel(authCubit: context.read<AuthCubit>());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
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
          body: BlocConsumer<AuthCubit, AuthState>(
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
              final isLoading = state is AuthLoading;

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
                        child: ListenableBuilder(
                          listenable: _viewModel,
                          builder: (context, _) {
                            return Column(
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
                                        CustomTextField(
                                          controller: _viewModel.emailController,
                                          label: 'Email Address',
                                          validator: AppValidators.validateEmail,
                                          keyboardType: TextInputType.emailAddress,
                                          prefixIcon: Icon(
                                            Icons.email_outlined,
                                            color: primaryColor.withValues(alpha: 0.7),
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        
                                        // Password
                                        CustomTextField(
                                          controller: _viewModel.passwordController,
                                          label: 'Password',
                                          validator: AppValidators.validatePassword,
                                          obscureText: _viewModel.obscurePassword,
                                          prefixIcon: Icon(
                                            Icons.lock_outlined,
                                            color: primaryColor.withValues(alpha: 0.7),
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _viewModel.obscurePassword
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: AppColors.textSecondary,
                                            ),
                                            onPressed: _viewModel.togglePasswordVisibility,
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        
                                        // Remember Me & Forgot Password Row
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: Checkbox(
                                                    value: _rememberMeLocal,
                                                    activeColor: primaryColor,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _rememberMeLocal = value ?? false;
                                                      });
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _rememberMeLocal = !_rememberMeLocal;
                                                    });
                                                  },
                                                  child: Text(
                                                    'Remember me',
                                                    style: AppTextStyles.bodySecondary.copyWith(
                                                      fontSize: 13.5,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: const Text(
                                                      'Password reset link has been sent to your email.',
                                                    ),
                                                    backgroundColor: AppColors.primary,
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              },
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: Text(
                                                'Forgot Password?',
                                                style: TextStyle(
                                                  color: primaryColor,
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 24),
                                        
                                        isLoading
                                            ? const LoadingWidget()
                                            : PrimaryButton(
                                                text: 'Login',
                                                onPressed: () => _viewModel.login(_formKey, context),
                                                isLoading: isLoading,
                                              ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 48),
                                
                                // Modern Secure Footer
                                Center(
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.lock_outline_rounded,
                                            size: 14,
                                            color: AppColors.textMuted.withValues(alpha: 0.6),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Secured with SSL 256-bit Encryption',
                                            style: AppTextStyles.caption.copyWith(
                                              color: AppColors.textMuted.withValues(alpha: 0.8),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '© 2026 Field Service Management. All rights reserved.',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textMuted.withValues(alpha: 0.5),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          },
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
