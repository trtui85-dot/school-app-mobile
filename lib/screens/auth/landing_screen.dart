import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../widgets/logo.dart';
import '../../widgets/language_toggle.dart';
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: LanguageToggle(),
                  ),
                  const SizedBox(height: 12),
                  const AppLogo(size: 88, withName: false),
                  const SizedBox(height: 24),
                  Text(tr('مدارس اقرأ الحديثة'), textAlign: TextAlign.center, style: ar(24, FontWeight.w700, AppColors.foreground)),
                  const SizedBox(height: 12),
                  Text(
                    tr('نظام متابعة التسجيل وتحصيل الرسوم والغياب والتواصل مع أولياء الأمور'),
                    textAlign: TextAlign.center,
                    style: ar(14, FontWeight.w400, AppColors.zinc500, height: 1.6),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    text: tr('تسجيل الدخول'),
                    expand: true,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: tr('إنشاء حساب ولي أمر'),
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
