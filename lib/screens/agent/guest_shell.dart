import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/ads_carousel.dart';
import '../../widgets/ios_bottom_bar.dart';
import '../../widgets/logo.dart';
import '../../widgets/ui.dart';
import '../auth/login_screen.dart';
import 'timetable_screen.dart';

class GuestShell extends StatelessWidget {
  const GuestShell({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
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
            AppButton(
              text: 'الجدول الزمني الأسبوعي',
              variant: AppButtonVariant.success,
              expand: true,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TimetableScreen()),
              ),
            ),
          ],
        ),
        bottomNavigationBar: IOSBottomBar(
          items: const [
            IOSNavItem(id: 'home', label: 'الرئيسية', icon: Icons.home_outlined, activeIcon: Icons.home),
            IOSNavItem(id: 'register', label: 'تسجيل', icon: Icons.person_add_alt, activeIcon: Icons.person_add_alt_1),
            IOSNavItem(id: 'notifications', label: 'الإشعارات', icon: Icons.notifications_none, activeIcon: Icons.notifications),
            IOSNavItem(id: 'complaints', label: 'الشكاوى', icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble),
          ],
          selected: 'home',
          onSelect: (id) {
            if (id != 'home') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            }
          },
        ),
      );
}
