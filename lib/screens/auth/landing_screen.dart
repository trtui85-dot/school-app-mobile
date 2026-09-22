import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/logo.dart';
import '../../widgets/ui.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogo(size: 88, withName: false),
                  const SizedBox(height: 24),
                  Text('مدارس اقرأ الحديثة', textAlign: TextAlign.center, style: ar(24, FontWeight.w700, AppColors.foreground)),
                  const SizedBox(height: 12),
                  Text(
                    'نظام متابعة التسجيل وتحصيل الرسوم والغياب والتواصل مع أولياء الأمور',
                    textAlign: TextAlign.center,
                    style: ar(14, FontWeight.w400, AppColors.zinc500, height: 1.6),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    text: 'تسجيل الدخول',
                    expand: true,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'إنشاء حساب ولي أمر',
                    variant: AppButtonVariant.outline,
                    expand: true,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
