import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/ads_carousel.dart';
import '../../widgets/ui.dart';
import 'student_detail_screen.dart';
import 'timetable_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onOpenRegister;
  const HomeScreen({super.key, required this.onOpenRegister});
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>>? _students;
  String _error = '';

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    if (mounted) setState(() { _students = null; _error = ''; });
    try {
      final res = await ApiClient.instance.get('/api/me/students');
      if (!mounted) return;
      setState(() => _students = asMapList(res['students']));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _students = [];
      });
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
          const AdsCarousel(),
          const SizedBox(height: 20),
          AppButton(
            variant: AppButtonVariant.success,
            text: 'الجدول الزمني الأسبوعي',
            expand: true,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TimetableScreen()),
            ),
          ),
          const SizedBox(height: 20),
          Text(tr('أبنائي'), style: AppText.h1),
          const SizedBox(height: 16),
          if (_error.isNotEmpty) ...[
            ErrorBox(_error, onRetry: reload),
            const SizedBox(height: 16),
          ],
          if (_students == null)
            const AppSpinner()
          else if (_students!.isEmpty && _error.isEmpty)
            AppCard(child: AppEmpty(title: tr('لا يوجد لديك تلاميذ مسجَّلون بعد'), hint: tr('ابدأ التسجيل لتتمكن من متابعة أطفالك')))
          else
            ..._students!.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _studentCard(s),
                )),
        ],
      ),
    );
  }

  Widget _studentCard(Map<String, dynamic> s) {
    final status = asStr(s['status'], 'PENDING');
    final section = s['section'] == null ? null : asMap(s['section']);
    final attendance = asIntOrNull(s['attendanceNumber']);
    final rejection = asStrOrNull(s['rejectionReason']);

    BadgeTone tone;
    String statusLabel;
    if (status == 'APPROVED') {
      tone = BadgeTone.ok;
      statusLabel = tr('مقبول');
    } else if (status == 'REJECTED') {
      tone = BadgeTone.bad;
      statusLabel = tr('مرفوض');
    } else {
      tone = BadgeTone.pending;
      statusLabel = tr('بانتظار التوثيق');
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StudentDetailScreen(id: asInt(s['id']))),
        );
        reload();
      },
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: const Icon(Icons.school_outlined, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName(s),
                    overflow: TextOverflow.ellipsis,
                    style: ar(14, FontWeight.w600, AppColors.foreground),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          section == null ? tr('بدون قسم') : asStr(section['name']),
                          overflow: TextOverflow.ellipsis,
                          style: ar(12, FontWeight.w400, AppColors.zinc500),
                        ),
                      ),
                      if (attendance != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.zinc100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${tr('رقم النداء: ')}$attendance', style: mono(11, FontWeight.w400, AppColors.zinc600)),
                        ),
                      ],
                    ],
                  ),
                  if (status == 'REJECTED' && rejection != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${tr('السبب: ')}$rejection', style: ar(11, FontWeight.w400, AppColors.bad)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppBadge(statusLabel, tone: tone),
          ],
        ),
      ),
    );
  }
}
