import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/l10n.dart';
import '../../core/utils.dart';
import '../../widgets/ads_carousel.dart';
import '../../widgets/ios_bottom_bar.dart';
import '../../widgets/logo.dart';
import '../../widgets/ui.dart';
import '../auth/login_screen.dart';
import 'timetable_screen.dart';

class GuestShell extends StatefulWidget {
  const GuestShell({super.key});

  @override
  State<GuestShell> createState() => _GuestShellState();
}

class _GuestShellState extends State<GuestShell> {
  String? _adminPhone;

  @override
  void initState() {
    super.initState();
    ApiClient.instance.get('/api/public/register-info').then((data) {
      if (mounted) setState(() => _adminPhone = asStrOrNull(data['adminPhone']));
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: LocaleManager.instance,
        builder: (context, _) => Scaffold(
        backgroundColor: AppColors.zinc50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const AppLogo(size: 32),
          actions: [
            if (_adminPhone != null && _adminPhone!.isNotEmpty)
              IconButton(
                tooltip: tr('اتصال بالإدارة'),
                icon: const Icon(Icons.phone_outlined, color: AppColors.ok),
                onPressed: () => launchUrl(Uri.parse('tel:$_adminPhone')),
              ),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              icon: const Icon(Icons.login, size: 18),
              label: Text(tr('تسجيل الدخول')),
            ),
            const SizedBox(width: 4),
          ],
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
