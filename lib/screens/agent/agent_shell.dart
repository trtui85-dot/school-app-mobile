import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../services/push_service.dart';
import '../../widgets/logo.dart';
import 'complaints_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'register_screen.dart';

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
              tooltip: 'اتصال',
              icon: const Icon(Icons.phone_outlined, color: AppColors.zinc600),
              onPressed: () => launchUrl(Uri.parse('tel:$_adminPhone')),
            ),
          IconButton(
            tooltip: 'خروج',
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.zinc200)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                _tab(0, Icons.home_outlined, Icons.home, 'الرئيسية'),
                _tab(1, Icons.person_add_alt, Icons.person_add_alt_1, 'تسجيل'),
                _tab(2, Icons.notifications_none, Icons.notifications, 'الإشعارات'),
                _tab(3, Icons.chat_bubble_outline, Icons.chat_bubble, 'الشكاوى'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int i, IconData icon, IconData activeIcon, String label) {
    final active = _index == i;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _index = i);
          if (i == 0) _homeKey.currentState?.reload();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon : icon, size: 22, color: active ? AppColors.accent : AppColors.zinc400),
            const SizedBox(height: 3),
            Text(label, style: ar(11, FontWeight.w500, active ? AppColors.accent : AppColors.zinc400)),
          ],
        ),
      ),
    );
  }
}
