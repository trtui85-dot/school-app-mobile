import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/l10n.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../services/push_service.dart';
import '../../widgets/ios_bottom_bar.dart';
import '../../widgets/logo.dart';
import 'complaints_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'register_screen.dart';
import 'settings_screen.dart';

class AgentShell extends StatefulWidget {
  const AgentShell({super.key});
  @override
  State<AgentShell> createState() => _AgentShellState();
}

class _AgentShellState extends State<AgentShell> {
  int _index = 0;
  final _homeKey = GlobalKey<HomeScreenState>();
  final _notifKey = GlobalKey<NotificationsScreenState>();
  String? _adminPhone;

  @override
  void initState() {
    super.initState();
    PushService.bind(role: 'agent');
    ApiClient.instance.get('/api/public/register-info').then((d) {
      if (mounted) setState(() => _adminPhone = asStrOrNull(d['adminPhone']));
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(key: _homeKey, onOpenRegister: () => setState(() => _index = 1)),
      RegisterScreen(onDone: () {
        setState(() => _index = 0);
        _homeKey.currentState?.reload();
      }),
      NotificationsScreen(key: _notifKey),
      const ComplaintsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.zinc50,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: const AppLogo(size: 32),
        actions: [
          if (_adminPhone != null && _adminPhone!.isNotEmpty)
            IconButton(
              tooltip: tr('اتصال'),
              icon: const Icon(Icons.phone_outlined, color: AppColors.zinc600),
              onPressed: () => launchUrl(Uri.parse('tel:$_adminPhone')),
            ),
          IconButton(
            tooltip: tr('الإعدادات'),
            icon: const Icon(Icons.settings_outlined, color: AppColors.zinc600),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AgentSettingsScreen()),
            ),
          ),
          IconButton(
            tooltip: tr('خروج'),
            icon: const Icon(Icons.logout, color: AppColors.zinc600),
            onPressed: () async {
              final session = context.read<SessionManager>();
              await PushService.unbind(role: 'agent');
              await session.logout();
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.zinc100),
        ),
      ),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: IOSBottomBar(
        items: [
          IOSNavItem(id: 'home', label: tr('الرئيسية'), icon: Icons.home_outlined, activeIcon: Icons.home),
          IOSNavItem(id: 'register', label: tr('تسجيل'), icon: Icons.person_add_alt, activeIcon: Icons.person_add_alt_1),
          IOSNavItem(id: 'notifications', label: tr('الإشعارات'), icon: Icons.notifications_none, activeIcon: Icons.notifications),
          IOSNavItem(id: 'complaints', label: tr('الشكاوى'), icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble),
        ],
        selected: _idFor(_index),
        onSelect: (id) {
          setState(() => _index = _tabIndex(id.toString()));
          if (id == 'home') _homeKey.currentState?.reload();
        },
      ),
    );
  }

  String _idFor(int i) {
    switch (i) {
      case 1:
        return 'register';
      case 2:
        return 'notifications';
      case 3:
        return 'complaints';
      default:
        return 'home';
    }
  }

  int _tabIndex(String id) {
    switch (id) {
      case 'register':
        return 1;
      case 'notifications':
        return 2;
      case 'complaints':
        return 3;
      default:
        return 0;
    }
  }
}
