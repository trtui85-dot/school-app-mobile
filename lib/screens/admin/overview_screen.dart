import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/ui.dart';

class OverviewScreen extends StatefulWidget {
  final ValueChanged<String>? onNavigate;
  const OverviewScreen({super.key, this.onNavigate});
  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  Map<String, dynamic>? _stats;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _stats = null;
      _error = '';
    });
    try {
      final d = await ApiClient.instance.get('/api/admin/overview');
      if (!mounted) return;
      setState(() => _stats = asMap(d['stats']));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard_outlined, size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('نظرة عامة', style: AppText.h1),
            ],
          ),
          const SizedBox(height: 16),
          if (_error.isNotEmpty)
            ErrorBox(_error, onRetry: _load)
          else if (_stats == null)
            const AppSpinner()
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _card('عدد الأقسام', asInt(_stats!['sections']), Icons.menu_book_outlined,
                    AppColors.accent, AppColors.accentSoft, 'sections'),
                _card('التلاميذ المقبولون', asInt(_stats!['students']), Icons.people_outline,
                    AppColors.ok, AppColors.okSoft, 'students'),
                _card('طلبات بانتظار المراجعة', asInt(_stats!['pendingStudents']),
                    Icons.description_outlined, AppColors.pending, AppColors.pendingSoft, 'requests'),
                _card('دفعات بانتظار التوثيق', asInt(_stats!['pendingPayments']),
                    Icons.credit_card_outlined, AppColors.pending, AppColors.pendingSoft, 'payments'),
                _card('شكاوى جديدة', asInt(_stats!['newComplaints']), Icons.error_outline,
                    AppColors.bad, AppColors.badSoft, 'complaints'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _card(String label, int value, IconData icon, Color fg, Color bg, String key) {
    return GestureDetector(
      onTap: widget.onNavigate == null ? null : () => widget.onNavigate!(key),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.control)),
              child: Icon(icon, size: 20, color: fg),
            ),
            const Spacer(),
            Text('$value', style: ar(24, FontWeight.w700, AppColors.foreground)),
            const SizedBox(height: 2),
            Text(label, style: ar(12, FontWeight.w400, AppColors.zinc500)),
          ],
        ),
      ),
    );
  }
}
