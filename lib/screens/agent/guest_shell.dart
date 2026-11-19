import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/l10n.dart';
import '../../widgets/ads_carousel.dart';
import '../../widgets/ios_bottom_bar.dart';
import '../../widgets/logo.dart';
import '../../widgets/ui.dart';
import '../auth/login_screen.dart';
import 'timetable_screen.dart';

class GuestShell extends StatelessWidget {
  const GuestShell({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: LocaleManager.instance,
        builder: (context, _) => Scaffold(
        backgroundColor: AppColors.zinc50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const AppLogo(size: 32),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const AdsCarousel(),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 300,
                child: AppButton(
                  text: tr('الجدول الزمني الأسبوعي'),
                  variant: AppButtonVariant.success,
                  expand: true,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TimetableScreen()),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: IOSBottomBar(
          items: [
            IOSNavItem(id: 'home', label: tr('الرئيسية'), icon: Icons.home_outlined, activeIcon: Icons.home),
            IOSNavItem(id: 'register', label: tr('تسجيل'), icon: Icons.person_add_alt, activeIcon: Icons.person_add_alt_1),
            IOSNavItem(id: 'notifications', label: tr('الإشعارات'), icon: Icons.notifications_none, activeIcon: Icons.notifications),
            IOSNavItem(id: 'complaints', label: tr('الشكاوى'), icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble),
          ],
          selected: 'home',
          onSelect: (id) {
            if (id != 'home') _showLoginRequired(context);
          },
        ),
        ),
      );

  static Future<void> _showLoginRequired(BuildContext context) async {
    final goToLogin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('تسجيل الدخول مطلوب')),
        content: Text(tr('يجب تسجيل الدخول لاستخدام هذه الميزة.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(tr('إلغاء'))),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(tr('تسجيل الدخول'))),
        ],
      ),
    );
    if (goToLogin == true && context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }
}
