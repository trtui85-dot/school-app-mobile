import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';
import 'admin_student_detail_screen.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});
  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final _qCtrl = TextEditingController();
  List<Map<String, dynamic>>? _sections;
  int? _sectionId;
  List<Map<String, dynamic>>? _students;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _loadSections();
    _load();
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSections() async {
    try {
      final d = await ApiClient.instance.get('/api/admin/sections');
      if (!mounted) return;
      setState(() => _sections = asMapList(d['sections']));
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, type: ToastType.error);
    }
  }

  Future<void> _load() async {
    if (mounted) setState(() => _students = null);
    try {
      final d = await ApiClient.instance.get('/api/admin/students', query: {
        if (_sectionId != null) 'sectionId': _sectionId.toString(),
        if (_qCtrl.text.trim().isNotEmpty) 'q': _qCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _students = asMapList(d['students']);
        _total = asInt(d['total']);
      });
    } on ApiException catch (e) {
      if (mounted) {
        showToast(context, e.message, type: ToastType.error);
        setState(() => _students = []);
      }
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
              Text('التلاميذ', style: AppText.h1),
              const SizedBox(width: 8),
              Text('($_total)', style: mono(12, FontWeight.w400, AppColors.zinc400)),
            ],
          ),
          const SizedBox(height: 12),
          AppInput(
            hint: 'بحث بالاسم أو رقم النداء...',
            controller: _qCtrl,
            onSubmitted: _load,
          ),
          const SizedBox(height: 10),
          if (_sections != null)
            AppSelectField<int>(
              placeholder: 'كل الأقسام',
              value: _sectionId,
              options: [
                for (final s in _sections!)
                  AppSelectOption(asInt(s['id']), asStr(s['name'])),
              ],
              label: 'القسم',
              onChanged: (v) {
                setState(() => _sectionId = v);
                _load();
              },
            ),
          const SizedBox(height: 10),
          AppButton(text: 'بحث', expand: true, onPressed: _load),
          const SizedBox(height: 16),
          if (_students == null)
            const AppSpinner()
          else if (_students!.isEmpty)
            AppCard(child: const AppEmpty(title: 'لا توجد نتائج'))
          else
            ..._students!.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _studentRow(s),
                )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _studentRow(Map<String, dynamic> s) {
    final section = s['section'] == null ? null : asMap(s['section']);
    final agent = s['agent'] == null ? null : asMap(s['agent']);
    final pendingPayments = asMapList(s['payments']).length;
    final attendance = asIntOrNull(s['attendanceNumber']);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminStudentDetailScreen(id: asInt(s['id']))),
        );
        _load();
      },
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(attendance == null ? '—' : '$attendance',
                  style: mono(13, FontWeight.w600, AppColors.zinc600)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${asStr(s['arabicFirstName'])} ${asStr(s['arabicLastName'])}',
                      style: ar(14, FontWeight.w600, AppColors.accent)),
                  const SizedBox(height: 2),
                  Text(
                    '${section == null ? "بدون قسم" : asStr(section['name'])} · الوكيل: ${agent == null ? "—" : asStr(agent['fullName'])} (${agent == null ? "" : asStr(agent['phone'])})',
                    style: ar(12, FontWeight.w400, AppColors.zinc500),
                  ),
                ],
              ),
            ),
            AppBadge(pendingPayments > 0 ? '$pendingPayments بانتظار' : 'محدَّث',
                tone: pendingPayments > 0 ? BadgeTone.pending : BadgeTone.ok),
          ],
        ),
      ),
    );
  }
}