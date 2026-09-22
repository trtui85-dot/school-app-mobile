import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';
import 'admin_print_screens.dart';
import 'sections_screen.dart' show SectionMin;

class AdminStudentDetailScreen extends StatefulWidget {
  final int id;
  const AdminStudentDetailScreen({super.key, required this.id});
  @override
  State<AdminStudentDetailScreen> createState() => _AdminStudentDetailScreenState();
}

class _AdminStudentDetailScreenState extends State<AdminStudentDetailScreen> {
  Map<String, dynamic>? _student;
  List<SectionMin> _sections = [];
  String _error = '';

  // edit state
  final _attendanceCtrl = TextEditingController();
  int? _newSectionId;
  bool _editing = false;
  bool _saving = false;
  String _editError = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _attendanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _student = null;
      _error = '';
    });
    try {
      final d = await ApiClient.instance.get('/api/admin/students/${widget.id}');
      final sec = await ApiClient.instance.get('/api/admin/sections');
      if (!mounted) return;
      _attendanceCtrl.text =
          asIntOrNull(asMap(d['student'])['attendanceNumber'])?.toString() ?? '';
      setState(() {
        _student = asMap(d['student']);
        _sections = asMapList(sec['sections'])
            .map((s) => SectionMin(id: asInt(s['id']), name: asStr(s['name'])))
            .toList();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _save() async {
    setState(() {
      _editError = '';
      _saving = true;
    });
    try {
      await ApiClient.instance.put('/api/admin/students/${widget.id}', body: {
        'attendanceNumber': _attendanceCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_attendanceCtrl.text.trim()),
        'sectionId': _newSectionId,
      });
      if (mounted) {
        showToast(context, 'تم حفظ تعديلات التلميذ');
      }
      setState(() => _editing = false);
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _editError = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.zinc50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(_student == null
            ? 'ملف التلميذ'
            : '${asStr(_student!['arabicFirstName'])} ${asStr(_student!['arabicLastName'])}',
            style: AppText.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.zinc700),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_student != null)
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminStudentPrintScreen(id: widget.id),
                ),
              ),
              icon: const Icon(Icons.print, size: 18),
              label: Text('طباعة', style: ar(13, FontWeight.w600, AppColors.accent)),
            ),
        ],
      ),
      body: _error.isNotEmpty && _student == null
          ? Padding(padding: const EdgeInsets.all(16), child: ErrorBox(_error, onRetry: _load))
          : _student == null
              ? const AppSpinner()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _header(),
                    const SizedBox(height: 12),
                    _personalCard(),
                    const SizedBox(height: 12),
                    _absences(),
                    const SizedBox(height: 12),
                    _subjects(),
                    const SizedBox(height: 12),
                    _payments(),
                    const SizedBox(height: 12),
                    _notes(),
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }

  Widget _header() {
    final s = _student!;
    final section = s['section'] == null ? null : asMap(s['section']);
    final agent = s['agent'] == null ? null : asMap(s['agent']);
    final attendance = asIntOrNull(s['attendanceNumber']);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${asStr(s['arabicFirstName'])} ${asStr(s['arabicLastName'])}',
                      style: ar(18, FontWeight.w700, AppColors.foreground)),
                  if (attendance != null) ...[
                    const SizedBox(width: 8),
                    Text('#$attendance', style: mono(13, FontWeight.w400, AppColors.zinc500)),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${section == null ? "بدون قسم" : asStr(section['name'])} · الوكيل: ${agent == null ? "—" : asStr(agent['fullName'])} (${agent == null ? "" : asStr(agent['phone'])})',
                style: ar(12, FontWeight.w400, AppColors.zinc500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _personalCard() {
    final s = _student!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('البيانات الشخصية', style: AppText.title),
          const SizedBox(height: 12),
          _kv('الاسم بالفرنسية',
              '${asStr(s['frenchFirstName'])} ${asStr(s['frenchLastName'])}'.trim()),
          _kv('رقم ريم', asStr(s['rimNumber'])),
          _kv('الرقم الوطني', asStr(s['nationalNumber'])),
          _kv('الهاتف', asStr(s['phone'])),
          _kv('العنوان', asStr(s['address'])),
          const Divider(height: 24),
          if (!_editing)
            AppButton(text: 'تعديل البيانات', variant: AppButtonVariant.outline, onPressed: () {
              final section = s['section'] == null ? null : asMap(s['section']);
              _newSectionId = section == null ? null : asInt(section['id']);
              _attendanceCtrl.text =
                  asIntOrNull(s['attendanceNumber'])?.toString() ?? '';
              setState(() => _editing = true);
            })
          else
            Column(
              children: [
                AppInput(
                  label: 'رقم النداء',
                  controller: _attendanceCtrl,
                  number: true,
                  ltr: true,
                ),
                const SizedBox(height: 12),
                AppSelectField<int>(
                  label: 'نقل إلى قسم',
                  placeholder: 'بدون',
                  value: _newSectionId,
                  options: [
                    for (final sec in _sections) AppSelectOption(sec.id, sec.name),
                  ],
                  onChanged: (v) => setState(() => _newSectionId = v),
                ),
                if (_editError.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_editError, style: ar(13, FontWeight.w400, AppColors.bad)),
                ],
                const SizedBox(height: 12),
                AppButton(
                  text: 'حفظ التعديلات',
                  expand: true,
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: AppText.small)),
          Expanded(child: Text(value.isEmpty ? '—' : value, style: AppText.body)),
        ],
      ),
    );
  }

  Widget _absences() {
    final s = _student!;
    final absences =
        asMapList(s['attendances']).where((a) => asStr(a['status']) == 'ABSENT').toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('سجل الغياب (${absences.length})', style: AppText.title),
          const SizedBox(height: 8),
          if (absences.isEmpty)
            const AppEmpty(title: 'لا يوجد غياب مسجل')
          else
            ...absences
                .take(20)
                .map((a) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Text(formatArabicDate(a['date']), style: AppText.body),
                          const Spacer(),
                          const AppBadge('غائب', tone: BadgeTone.bad),
                        ],
                      ),
                    )),
        ],
      ),
    );
  }

  Widget _subjects() {
    final s = _student!;
    final section = s['section'] == null ? null : asMap(s['section']);
    if (section == null) return const SizedBox.shrink();
    final subjects = asStrList(section['subjects']);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المواد والجدول', style: AppText.title),
          const SizedBox(height: 8),
          if (subjects.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: subjects
                  .map((x) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(x, style: ar(12, FontWeight.w500, AppColors.accent)),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _payments() {
    final s = _student!;
    final payments = asMapList(s['payments']);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('سجل الدفعات', style: AppText.title),
          const SizedBox(height: 8),
          if (payments.isEmpty)
            const AppEmpty(title: 'لا توجد دفعات')
          else
            ...payments.map((p) {
              final status = asStr(p['status'], 'PENDING');
              final type = asStr(p['type']);
              final month = asIntOrNull(p['month']);
              final label = type == 'REGISTRATION'
                  ? 'رسوم التسجيل'
                  : 'شهر ${monthLabel(month ?? 0)}';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: AppText.body),
                          Text(asStr(p['schoolYear']), style: AppText.tiny),
                        ],
                      ),
                    ),
                    Text(formatMoney(asInt(p['amount'])), style: mono(13, FontWeight.w600, AppColors.zinc700)),
                    const SizedBox(width: 8),
                    AppBadge(
                      status == 'APPROVED'
                          ? 'موثقة'
                          : status == 'REJECTED'
                              ? 'مرفوضة'
                              : 'بانتظار التوثيق',
                      tone: status == 'APPROVED'
                          ? BadgeTone.ok
                          : status == 'REJECTED'
                              ? BadgeTone.bad
                              : BadgeTone.pending,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _notes() {
    final s = _student!;
    final notes = asMapList(s['notes']);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الرسائل المرسلة', style: AppText.title),
          const SizedBox(height: 8),
          if (notes.isEmpty)
            const AppEmpty(title: 'لا توجد رسائل بعد')
          else
            ...notes.map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(asStr(n['content']), style: AppText.body),
                      Text(formatArabicDate(n['createdAt']), style: AppText.tiny),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}