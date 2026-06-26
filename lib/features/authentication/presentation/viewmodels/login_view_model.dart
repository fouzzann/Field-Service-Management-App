import 'package:flutter/material.dart';
import '../cubit/auth_cubit.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthCubit authCubit;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;

  LoginViewModel({required this.authCubit});

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void login(GlobalKey<FormState> formKey, BuildContext context) {
    if (formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      authCubit.login(
        emailController.text.trim(),
        passwordController.text,
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
