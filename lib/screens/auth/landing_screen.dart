import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../widgets/logo.dart';
import '../../widgets/language_toggle.dart';
import '../../widgets/ui.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'terms_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleManager.instance,
      builder: (context, _) => Scaffold(
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
                      alignment: isFr ? Alignment.centerLeft : Alignment.centerRight,
                      child: const LanguageToggle(),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.accentSoft, Colors.white],
                        ),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
                      ),
                      child: const Center(child: AppLogo(size: 68, withName: false)),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      tr('مجمع مدارس اقرأ'),
                      textAlign: TextAlign.center,
                      style: isFr
                          ? fr(26, FontWeight.w700, AppColors.foreground)
                          : GoogleFonts.fustat(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.foreground,
                              height: 1.3,
                            ),
                    ),
                    const SizedBox(height: 14),
                    const _Ornament(),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsScreen()),
                      ),
                      child: Text(
                        tr('شروط الاستخدام'),
                        style: ar(13, FontWeight.w600, AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Ornament extends StatelessWidget {
  const _Ornament();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 44, height: 1.5, color: AppColors.zinc200),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.diamond_outlined, size: 14, color: AppColors.accent),
        ),
        Container(width: 44, height: 1.5, color: AppColors.zinc200),
      ],
    );
  }
}
