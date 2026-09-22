import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';

class AbsencesScreen extends StatefulWidget {
  const AbsencesScreen({super.key});
  @override
  State<AbsencesScreen> createState() => _AbsencesScreenState();
}

class _AbsencesScreenState extends State<AbsencesScreen> {
  List<Map<String, dynamic>>? _sections;
  int? _sectionId;
  DateTime _date = DateTime.now();
  List<Map<String, dynamic>>? _students;
  final Set<int> _absent = {};
  final _quickCtrl = TextEditingController();
  String _msg = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  @override
  void dispose() {
    _quickCtrl.dispose();
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
    if (_sectionId == null) return;
    setState(() {
      _students = null;
      _absent.clear();
      _msg = '';
    });
    try {
      final d = await ApiClient.instance.get('/api/admin/attendance', query: {
        'sectionId': _sectionId.toString(),
        'date': formatDateISO(_date),
      });
      if (!mounted) return;
      setState(() {
        _students = asMapList(d['students']);
        for (final st in _students!) {
          final atts = asMapList(st['attendances']);
          if (atts.isNotEmpty && asStr(atts.first['status']) == 'ABSENT') {
            _absent.add(asInt(st['id']));
          }
        }
      });
    } on ApiException catch (e) {
      if (mounted) {
        showToast(context, e.message, type: ToastType.error);
        setState(() => _students = []);
      }
    }
  }

  void _applyQuick() {
    final numbers = _quickCtrl.text
        .split(RegExp(r'[,\s]+'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toSet();
    if (numbers.isEmpty) return;
    setState(() {
      for (final st in _students ?? []) {
        final num = asIntOrNull(st['attendanceNumber']);
        if (num != null && numbers.contains(num)) {
          _absent.add(asInt(st['id']));
        }
      }
    });
    _quickCtrl.clear();
  }

  Future<void> _submit() async {
    if (_sectionId == null) return;
    setState(() {
      _msg = '';
      _submitting = true;
    });
    try {
      final d = await ApiClient.instance.post('/api/admin/attendance', body: {
        'sectionId': _sectionId,
        'date': formatDateISO(_date),
        'absentStudentIds': _absent.toList(),
      });
      final count = asInt(d['count']);
      if (!mounted) return;
      setState(() =>
          _msg = 'تم تأكيد الغياب ($count) وإرسال الإشعارات للوكلاء');
      showToast(context, 'تم تأكيد الغياب ($count) وإرسال الإشعارات للوكلاء');
    } on ApiException catch (e) {
      setState(() => _msg = e.message);
      if (mounted) showToast(context, e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('تسجيل الغياب', style: AppText.h1),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: [
              AppSelectField<int>(
                label: 'القسم',
                placeholder: '— اختر —',
                value: _sectionId,
                options: [
                  for (final s in _sections ?? []) AppSelectOption(asInt(s['id']), asStr(s['name'])),
                ],
                onChanged: (v) {
                  setState(() => _sectionId = v);
                  _load();
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          locale: const Locale('ar'),
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _date = picked);
                          _load();
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('التاريخ', style: ar(14, FontWeight.w500, AppColors.zinc700)),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.control),
                              border: Border.all(color: AppColors.zinc300),
                            ),
                            child: Row(
                              children: [
                                Text(formatDateISO(_date),
                                    style: ar(14, FontWeight.w400, AppColors.foreground)),
                                const Spacer(),
                                const Icon(Icons.calendar_today_outlined,
                                    size: 16, color: AppColors.zinc400),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_students != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppInput(
                        hint: 'أرقام نداء الغائبين مفصولة بفواصل: 3,7,12',
                        controller: _quickCtrl,
                        ltr: true,
                        onSubmitted: _applyQuick,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppButton(text: 'تطبيق', variant: AppButtonVariant.outline, onPressed: _applyQuick),
                  ],
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: _students!.isEmpty
                      ? const AppEmpty(title: 'لا يوجد تلاميذ في هذا القسم')
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _students!.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 4),
                          itemBuilder: (_, i) => _studentRow(_students![i]),
                        ),
                ),
                if (_msg.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_msg, style: ar(13, FontWeight.w400, AppColors.ok)),
                ],
                const SizedBox(height: 12),
                AppButton(
                  text: 'تأكيد الغياب (${_absent.length})',
                  expand: true,
                  loading: _submitting,
                  onPressed: _submit,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _studentRow(Map<String, dynamic> s) {
    final id = asInt(s['id']);
    final absent = _absent.contains(id);
    final attendance = asIntOrNull(s['attendanceNumber']);
    return GestureDetector(
      onTap: () => setState(() {
        if (absent) {
          _absent.remove(id);
        } else {
          _absent.add(id);
        }
      }),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: absent ? AppColors.badSoft : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: absent ? AppColors.bad : AppColors.zinc100),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: absent ? AppColors.bad : Colors.transparent,
                border: Border.all(color: absent ? AppColors.bad : AppColors.zinc300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: absent
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(attendance == null ? '—' : '$attendance',
                style: mono(13, FontWeight.w600, AppColors.zinc700)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${asStr(s['arabicFirstName'])} ${asStr(s['arabicLastName'])}',
                style: ar(14, FontWeight.w500, AppColors.foreground),
              ),
            ),
            if (absent) Text('غائب', style: ar(13, FontWeight.w600, AppColors.bad)),
          ],
        ),
      ),
    );
  }
}