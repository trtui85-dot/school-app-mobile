import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/timetable_card.dart';
import '../../widgets/ui.dart';

class TimetableScreen extends StatefulWidget {
  final bool showAppBar;
  const TimetableScreen({super.key, this.showAppBar = true});
  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  static const allowedSections = {'5C', '5D', '6C', '6D', '7D', '7LO'};
  List<Map<String, dynamic>>? _sections;
  String _error = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      Map<String, dynamic> response;
      try {
        response = await ApiClient.instance.get('/api/public/sections', useCache: false);
      } catch (_) {
        response = await ApiClient.instance.get('/api/me/students', useCache: false);
      }
      final unique = <String, Map<String, dynamic>>{};
      final source = asMapList(response['sections']).isNotEmpty
          ? asMapList(response['sections'])
          : asMapList(response['students']).map((student) => student['section'] == null ? <String, dynamic>{} : asMap(student['section'])).toList();
      for (final section in source) {
        final name = asStr(section['name']).trim();
        if (allowedSections.contains(name)) unique[name] = section;
      }
      if (mounted) setState(() => _sections = unique.values.toList());
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _sections = []; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.zinc50,
        appBar: widget.showAppBar ? AppBar(backgroundColor: Colors.white, title: Text('الجدول الزمني الأسبوعي', style: AppText.h2)) : null,
        body: _sections == null
            ? const AppSpinner()
            : RefreshIndicator(
                color: AppColors.accent,
                onRefresh: _load,
                child: _error.isNotEmpty
                    ? ListView(padding: const EdgeInsets.all(16), children: [ErrorBox(_error, onRetry: _load)])
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text('اختر قسمك لعرض الجدول', style: AppText.h2),
                          const SizedBox(height: 6),
                          Text('ستظهر لك الأقسام المتاحة حسب بيانات الإدارة.', style: AppText.body),
                          const SizedBox(height: 16),
                          ..._sections!.map((section) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _sectionButton(context, section),
                              )),
                          if (_sections!.isEmpty) AppCard(child: AppEmpty(title: 'لا توجد جداول متاحة حاليًا')),
                        ],
                      ),
              ),
      );

  Widget _sectionButton(BuildContext context, Map<String, dynamic> section) => AppCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _SectionTimetableScreen(section: section))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Icon(Icons.calendar_month_outlined, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(child: Text(asStr(section['name']), style: ar(16, FontWeight.w700, AppColors.foreground))),
              const Icon(Icons.chevron_left, color: AppColors.zinc400),
            ]),
          ),
        ),
      );
}

class _SectionTimetableScreen extends StatelessWidget {
  final Map<String, dynamic> section;
  const _SectionTimetableScreen({required this.section});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.zinc50,
        appBar: AppBar(backgroundColor: Colors.white, title: Text('جدول ${asStr(section['name'])}', style: AppText.h2)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [TimetableSection(section: section, studentName: '', schoolName: 'مدارس اقرأ الحديثة')],
        ),
      );
}
