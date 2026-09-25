import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../services/push_service.dart';
import '../../widgets/ios_bottom_bar.dart';
import '../../widgets/logo.dart';
import 'absences_screen.dart';
import 'admin_complaints_screen.dart';
import 'admin_messages_screen.dart';
import 'ads_screen.dart';
import 'overview_screen.dart';
import 'payments_screen.dart';
import 'requests_screen.dart';
import 'sections_screen.dart';
import 'settings_screen.dart';
import 'students_screen.dart';
import 'users_screen.dart';

class AdminNavItem {
  final String key;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const AdminNavItem(this.key, this.label, this.icon, this.activeIcon);
}

const List<AdminNavItem> adminNavItems = [
  AdminNavItem('overview', 'الرئيسية', Icons.dashboard_outlined, Icons.dashboard),
  AdminNavItem('sections', 'الأقسام', Icons.menu_book_outlined, Icons.menu_book),
  AdminNavItem('requests', 'طلبات التسجيل', Icons.description_outlined, Icons.description),
  AdminNavItem('students', 'التلاميذ', Icons.people_outline, Icons.people),
  AdminNavItem('absences', 'الغياب', Icons.event_busy_outlined, Icons.event_busy),
  AdminNavItem('payments', 'الدفعات', Icons.credit_card_outlined, Icons.credit_card),
  AdminNavItem('messages', 'الرسائل', Icons.message_outlined, Icons.message),
  AdminNavItem('complaints', 'الشكاوى', Icons.support_agent_outlined, Icons.support_agent),
  AdminNavItem('ads', 'الإعلانات', Icons.campaign_outlined, Icons.campaign),
  AdminNavItem('settings', 'الإعدادات', Icons.settings_outlined, Icons.settings),
  AdminNavItem('users', 'المستخدمون', Icons.manage_accounts_outlined, Icons.manage_accounts),
];

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _key = 'overview';
  final Set<String> _visited = {'overview'};

  @override
  void initState() {
    super.initState();
    PushService.bind(role: 'admin');
  }

  List<AdminNavItem> _allowed(List<String> perms) =>
      adminNavItems.where((i) => hasPermission(perms, i.key)).toList();

  void _go(String key) {
    if (!_visited.contains(key)) _visited.add(key);
    setState(() => _key = key);
  }

  Widget _screen(String key) {
    switch (key) {
      case 'overview':
        return OverviewScreen(onNavigate: _go);
      case 'sections':
        return const SectionsScreen();
      case 'requests':
        return const RequestsScreen();
      case 'students':
        return const AdminStudentsScreen();
      case 'absences':
        return const AbsencesScreen();
      case 'payments':
        return const PaymentsScreen();
      case 'messages':
        return const AdminMessagesScreen();
      case 'complaints':
        return const AdminComplaintsScreen();
      case 'ads':
        return const AdsScreen();
      case 'settings':
        return const SettingsScreen();
      case 'users':
        return const UsersScreen();
      default:
        return const OverviewScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final perms = context.watch<SessionManager>().user?.permissions ?? const [];
    final allowed = _allowed(perms);
    final current = allowed.any((i) => i.key == _key)
        ? _key
        : (allowed.isEmpty ? '' : allowed.first.key);

    final mainKeys = ['overview', 'sections', 'requests', 'students', 'payments'];
    final mainItems = allowed.where((i) => mainKeys.contains(i.key)).toList();
    final moreItems = allowed.where((i) => !mainKeys.contains(i.key)).toList();

    final orderedKeys = allowed.map((i) => i.key).toList();
    final children = [
      for (final k in orderedKeys)
        if (_visited.contains(k)) _screen(k),
    ];
    final index = orderedKeys.indexOf(current).clamp(0, children.length - 1);

    final barItems = <IOSNavItem>[
      for (final it in mainItems)
        IOSNavItem(
          id: it.key,
          label: it.key == 'requests' ? 'الطلبات' : it.label,
          icon: it.icon,
          activeIcon: it.activeIcon,
        ),
      if (moreItems.isNotEmpty)
        const IOSNavItem(
          id: 'more',
          label: 'المزيد',
          icon: Icons.more_horiz,
          activeIcon: Icons.more_horiz,
        ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.zinc50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.zinc700),
          tooltip: 'القائمة',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const AppLogo(size: 32),
      ),
      drawer: _drawer(allowed, current),
      body: allowed.isEmpty
          ? const Center(child: Text('لا تملك أي صلاحيات'))
          : IndexedStack(index: index, children: children),
      bottomNavigationBar: barItems.isEmpty
          ? null
          : IOSBottomBar(
              items: barItems,
              selected: moreItems.any((i) => i.key == current) ? 'more' : current,
              onSelect: (id) {
                if (id == 'more') {
                  _openMoreSheet(moreItems, current);
                } else {
                  _go(id.toString());
                }
              },
            ),
    );
  }

  Widget _drawer(List<AdminNavItem> allowed, String current) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(alignment: Alignment.centerRight, child: AppLogo(size: 36)),
            ),
            const Divider(height: 1, color: AppColors.zinc100),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: allowed
                    .map((i) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _drawerItem(i, current == i.key, () {
                            _go(i.key);
                            Navigator.pop(context);
                          }),
                        ))
                    .toList(),
              ),
            ),
            const Divider(height: 1, color: AppColors.zinc100),
            Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: () {
                PushService.unbind(role: 'admin');
                context.read<SessionManager>().logout();
              },
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 20, color: AppColors.bad),
                      const SizedBox(width: 10),
                      Text('تسجيل الخروج', style: ar(14, FontWeight.w600, AppColors.bad)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(AdminNavItem item, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(
          children: [
            Icon(active ? item.activeIcon : item.icon,
                size: 20, color: active ? Colors.white : AppColors.zinc600),
            const SizedBox(width: 10),
            Text(item.label,
                style: ar(14, FontWeight.w600, active ? Colors.white : AppColors.zinc600)),
          ],
        ),
      ),
    );
  }

  void _openMoreSheet(List<AdminNavItem> moreItems, String current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.zinc200, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              Text('المزيد', style: AppText.title, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3.4,
                children: moreItems
                    .map((i) => GestureDetector(
                          onTap: () {
                            _go(i.key);
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: current == i.key ? AppColors.accentSoft : Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.control),
                              border: Border.all(
                                  color: current == i.key
                                      ? AppColors.accent.withValues(alpha: 0.3)
                                      : AppColors.zinc200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(i.icon,
                                    size: 18,
                                    color: current == i.key ? AppColors.accent : AppColors.zinc600),
                                const SizedBox(width: 8),
                                Text(i.label,
                                    style: ar(13, FontWeight.w600,
                                        current == i.key ? AppColors.accent : AppColors.zinc600)),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              AppLogoutTile(),
            ],
          ),
        ),
      ),
    );
  }
}

class AppLogoutTile extends StatelessWidget {
  const AppLogoutTile({super.key});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        context.read<SessionManager>().logout();
      },
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: AppColors.zinc200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, size: 18, color: AppColors.bad),
            const SizedBox(width: 8),
            Text('تسجيل الخروج', style: ar(14, FontWeight.w600, AppColors.bad)),
          ],
        ),
      ),
    );
  }
}
