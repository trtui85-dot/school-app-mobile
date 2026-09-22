import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';
import 'admin_print_screens.dart';
import 'section_detail_screen.dart';

class SectionMin {
  final int id;
  final String name;
  const SectionMin({required this.id, required this.name});
}

const _defaultSubjects = ['MATHS', 'FR', 'SN', 'ANG', 'PC', 'AR', 'HG'];
const _timeSlots = [
  ['08:00', '10:00'],
  ['10:00', '12:00'],
  ['12:00', '14:00'],
  ['16:00', '18:00'],
];

class SectionsScreen extends StatefulWidget {
  const SectionsScreen({super.key});
  @override
  State<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends State<SectionsScreen> {
  List<Map<String, dynamic>>? _sections;
  bool _showForm = false;
  int? _editingId;

  final _nameCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _monthCtrl = TextEditingController();
  final _customSubjectCtrl = TextEditingController();
  final List<String> _subjects = [];
  final List<Map<String, String>> _schedule = [];

  int? _scheduleDay;
  String? _scheduleSubject;
  String? _scheduleSlot;
  String _formError = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _regCtrl.dispose();
    _monthCtrl.dispose();
    _customSubjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _sections = null);
    try {
      final d = await ApiClient.instance.get('/api/admin/sections');
      if (!mounted) return;
      setState(() => _sections = asMapList(d['sections']));
    } on ApiException catch (e) {
      if (mounted) {
        showToast(context, e.message, type: ToastType.error);
        setState(() => _sections = []);
      }
    }
  }

  void _openNew() {
    setState(() {
      _editingId = null;
      _showForm = true;
      _subjects.clear();
      _schedule.clear();
      _nameCtrl.clear();
      _regCtrl.clear();
      _monthCtrl.clear();
      _formError = '';
    });
  }

  void _openEdit(Map<String, dynamic> s) {
    setState(() {
      _editingId = asInt(s['id']);
      _showForm = true;
      _subjects
        ..clear()
        ..addAll(asStrList(s['subjects']));
      _schedule.clear();
      for (final e in asMapList(s['schedule'])) {
        _schedule.add({
          'day': asStr(e['day']),
          'subject': asStr(e['subject']),
          'start': asStr(e['start']),
          'end': asStr(e['end']),
        });
      }
      _nameCtrl.text = asStr(s['name']);
      _regCtrl.text = '${asInt(s['registrationFee'])}';
      _monthCtrl.text = '${asInt(s['monthlyFee'])}';
      _formError = '';
    });
  }

  Future<void> _save() async {
    setState(() {
      _formError = '';
      _submitting = true;
    });
    final body = {
      'name': _nameCtrl.text.trim(),
      'registrationFee': int.tryParse(_regCtrl.text.trim()) ?? 0,
      'monthlyFee': int.tryParse(_monthCtrl.text.trim()) ?? 0,
      'subjects': _subjects,
      'schedule': _schedule,
    };
    try {
      if (_editingId == null) {
        await ApiClient.instance.post('/api/admin/sections', body: body);
        if (mounted) showToast(context, 'تم إنشاء القسم بنجاح');
      } else {
        await ApiClient.instance.put('/api/admin/sections/$_editingId', body: body);
        if (mounted) showToast(context, 'تم حفظ تعديلات القسم');
      }
      setState(() => _showForm = false);
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _formError = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> s) async {
    final name = asStr(s['name']);
    final okDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text('حذف القسم "$name"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.bad)),
          ),
        ],
      ),
    );
    if (okDelete != true) return;
    try {
      await ApiClient.instance.delete('/api/admin/sections/${asInt(s['id'])}');
      if (mounted) showToast(context, 'تم حذف القسم');
      if (mounted && asInt(s['id']) == _editingId) setState(() => _showForm = false);
      await _load();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, type: ToastType.error);
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
              Expanded(child: Text('إدارة الأقسام الدراسية', style: AppText.h1)),
              AppButton(
                text: 'قسم جديد',
                onPressed: _showForm ? () => setState(() => _showForm = false) : _openNew,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_showForm) _formCard(),
          if (_showForm) const SizedBox(height: 16),
          if (_sections == null)
            const AppSpinner()
          else if (_sections!.isEmpty)
            AppCard(child: const AppEmpty(title: 'لا توجد أقسام بعد — أنشئ قسمًا جديدًا'))
          else
            ..._sections!.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _sectionRow(s),
                )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _formCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_editingId == null ? 'إضافة قسم جديد' : 'تعديل: ${_nameCtrl.text}',
                    style: AppText.h2),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.zinc400),
                onPressed: () => setState(() => _showForm = false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppInput(label: 'اسم القسم', controller: _nameCtrl),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AppInput(label: 'رسوم التسجيل', controller: _regCtrl, number: true, ltr: true)),
              const SizedBox(width: 12),
              Expanded(child: AppInput(label: 'الرسوم الشهرية', controller: _monthCtrl, number: true, ltr: true)),
            ],
          ),
          const SizedBox(height: 16),
          Text('المواد الدراسية', style: AppText.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final subj in _defaultSubjects)
                _subjectChip(subj, isCustom: false),
              for (final s in _subjects.where((s) => !_defaultSubjects.contains(s)))
                _customSubjectChip(s),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customSubjectCtrl,
                  style: ar(14, FontWeight.w400, AppColors.foreground),
                  decoration: InputDecoration(
                    hintText: 'مادة أخرى (اختياري)',
                    hintStyle: ar(14, FontWeight.w400, AppColors.zinc400),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      borderSide: const BorderSide(color: AppColors.zinc300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppButton(
                text: 'إضافة',
                variant: AppButtonVariant.outline,
                onPressed: () {
                  final v = _customSubjectCtrl.text.trim().toUpperCase();
                  if (v.isEmpty || _subjects.contains(v)) return;
                  setState(() => _subjects.add(v));
                  _customSubjectCtrl.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('الجدول الزمني الأسبوعي', style: AppText.label),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppSelectField<int>(
                  placeholder: 'اليوم',
                  value: _scheduleDay,
                  options: [
                    for (var i = 1; i <= 6; i++) AppSelectOption(i, days[i]),
                  ],
                  onChanged: (v) => setState(() => _scheduleDay = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppSelectField<String>(
                  placeholder: 'اختر المادة',
                  value: _scheduleSubject,
                  options: [
                    for (final s in _subjects) AppSelectOption(s, s),
                  ],
                  onChanged: (v) => setState(() => _scheduleSubject = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppSelectField<String>(
                  placeholder: 'الوقت',
                  value: _scheduleSlot,
                  options: [
                    for (final t in _timeSlots) AppSelectOption('${t[0]}|${t[1]}', '${t[0]}–${t[1]}'),
                  ],
                  onChanged: (v) => setState(() => _scheduleSlot = v),
                ),
              ),
              const SizedBox(width: 8),
              AppButton(
                text: 'إضافة',
                variant: AppButtonVariant.outline,
                onPressed: _scheduleSubject == null || _scheduleDay == null || _scheduleSlot == null
                    ? null
                    : () {
                        final parts = _scheduleSlot!.split('|');
                        setState(() => _schedule.add({
                              'day': '$_scheduleDay',
                              'subject': _scheduleSubject!,
                              'start': parts[0],
                              'end': parts[1],
                            }));
                      },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_schedule.isNotEmpty) ...[
            Text('معاينة الجدول — ${_schedule.length} حصة', style: ar(13, FontWeight.w600, AppColors.zinc700)),
            const SizedBox(height: 8),
            ..._schedule.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${days[asInt(r['day'])]} — ${r['subject']} (${r['start']}–${r['end']})',
                          style: mono(13, FontWeight.w400, AppColors.zinc700),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.bad),
                        onPressed: () => setState(() => _schedule.remove(r)),
                      ),
                    ],
                  ),
                )),
          ],
          if (_formError.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_formError, style: ar(13, FontWeight.w400, AppColors.bad)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: _editingId == null ? 'إنشاء القسم' : 'حفظ التعديلات',
                  expand: true,
                  loading: _submitting,
                  onPressed: _save,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  text: 'إلغاء',
                  variant: AppButtonVariant.outline,
                  expand: true,
                  onPressed: () => setState(() => _showForm = false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subjectChip(String subj, {required bool isCustom}) {
    final active = _subjects.contains(subj);
    return GestureDetector(
      onTap: () => setState(() {
        if (active) {
          _subjects.remove(subj);
        } else {
          _subjects.add(subj);
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(
            color: active ? AppColors.accent : AppColors.zinc300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active) ...[
              const Icon(Icons.check, size: 14, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(subj,
                style: ar(12, FontWeight.w600,
                    active ? Colors.white : AppColors.zinc600)),
          ],
        ),
      ),
    );
  }

  Widget _customSubjectChip(String subj) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(subj, style: ar(12, FontWeight.w600, AppColors.accent)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _subjects.remove(subj)),
            child: const Icon(Icons.close, size: 14, color: AppColors.accent),
          ),
        ],
      ),
    );
  }

  Widget _sectionRow(Map<String, dynamic> s) {
    final students = asInt(asMap(s['_count'])['students']);
    final subjects = asStrList(s['subjects']);
    final showAll = subjects.length <= 5;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SectionDetailScreen(id: asInt(s['id']))),
                    );
                    _load();
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(asStr(s['name']), style: ar(15, FontWeight.w700, AppColors.foreground)),
                      ),
                      const Icon(Icons.chevron_left, size: 18, color: AppColors.zinc400),
                    ],
                  ),
                ),
              ),
              if (students > 0)
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminClassPrintScreen(sectionId: asInt(s['id']))),
                  ),
                  child: Text('طباعة القائمة', style: ar(12, FontWeight.w600, AppColors.accent)),
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.zinc500),
                tooltip: 'تعديل',
                onPressed: () => _openEdit(s),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.bad),
                tooltip: 'حذف',
                onPressed: () => _delete(s),
              ),
            ],
          ),
          Text(
            'تسجيل ${formatMoney(asInt(s['registrationFee']))} · شهري ${formatMoney(asInt(s['monthlyFee']))} · $students تلميذ',
            style: ar(12, FontWeight.w400, AppColors.zinc500),
          ),
          const SizedBox(height: 8),
          if (subjects.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final x in showAll ? subjects : subjects.take(5))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.accentSoft, borderRadius: BorderRadius.circular(6)),
                    child: Text(x, style: ar(11, FontWeight.w500, AppColors.accent)),
                  ),
                if (!showAll) Text('+${subjects.length - 5}', style: ar(11, FontWeight.w600, AppColors.zinc500)),
              ],
            ),
        ],
      ),
    );
  }
}