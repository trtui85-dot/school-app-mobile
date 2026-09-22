import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => NotificationsScreenState();
}

class NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>>? _items;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    if (mounted) setState(() => _items = null);
    try {
      final d = await ApiClient.instance.get('/api/me/notifications');
      if (!mounted) return;
      setState(() {
        _items = asMapList(d['notifications']);
      });
    } on ApiException {
      if (!mounted) return;
      setState(() => _items = []);
    }
  }

  Future<void> _markAll() async {
    try {
      await ApiClient.instance.patch('/api/me/notifications');
      await reload();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text('الإشعارات', style: AppText.h1),
              const Spacer(),
              if ((_items ?? []).any((n) => n['readAt'] == null))
                AppButton(
                  text: 'تعليم الكل كمقروء',
                  variant: AppButtonVariant.ghost,
                  onPressed: _markAll,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_items == null)
            const AppSpinner()
          else if (_items!.isEmpty)
            AppCard(child: const AppEmpty(title: 'لا توجد إشعارات', hint: 'ستصلك هنا نتائج الطلبات والدفعات والرسائل'))
          else
            ..._items!.map((n) {
              final unread = n['readAt'] == null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: unread ? AppColors.accent.withValues(alpha: 0.03) : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: unread ? AppColors.accent.withValues(alpha: 0.2) : AppColors.zinc100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(AppRadius.control),
                        ),
                        child: const Icon(Icons.notifications_none, size: 18, color: AppColors.accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(asStr(n['title']), style: ar(14, FontWeight.w600, AppColors.foreground)),
                            const SizedBox(height: 2),
                            Text(asStr(n['content']), style: ar(12, FontWeight.w400, AppColors.zinc600)),
                            const SizedBox(height: 4),
                            Text(formatArabicDateTime(n['createdAt']), style: ar(11, FontWeight.w400, AppColors.zinc400)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
