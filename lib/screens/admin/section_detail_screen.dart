import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/timetable.dart';
import '../../widgets/ui.dart';
import 'admin_print_screens.dart';
import 'admin_student_detail_screen.dart';

class SectionDetailScreen extends StatefulWidget {
  final int id;
  const SectionDetailScreen({super.key, required this.id});
  @override
  State<SectionDetailScreen> createState() => _SectionDetailScreenState();
}

class _SectionDetailScreenState extends State<SectionDetailScreen> {
  Map<String, dynamic>? _section;
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _stats;
  String _error = '';

  bool _showAdd = false;
  bool _adding = false;
  String _formError = '';
  Map<String, dynamic>? _lastAdded;

  final _first = TextEditingController();
  final _last = TextEditingController();
  final _attendance = TextEditingController();
  final _frenchFirst = TextEditingController();
  final _frenchLast = TextEditingController();
  final _rim = TextEditingController();
  final _national = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _agentName = TextEditingController();
  final _agentPhone = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _attendance.dispose();
    _frenchFirst.dispose();
    _frenchLast.dispose();
    _rim.dispose();
    _national.dispose();
    _phone.dispose();
    _address.dispose();
    _agentName.dispose();
    _agentPhone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _section = null;
      _error = '';
    });
    try {
      final d = await ApiClient.instance.get('/api/admin/sections/${widget.id}');
      if (!mounted) return;
      setState(() {
        _section = asMap(d['section']);
        _students = asMapList(d['students']);
        _stats = asMap(d['stats']);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _addStudent() async {
    setState(() {
      _formError = '';
      _adding = true;
    });
    if (!RegExp(r'^\d{8}$').hasMatch(_agentPhone.text)) {
      setState(() {
        _formError = 'رقم هاتف ولي الأمر غير صالح';
        _adding = false;
      });
      return;
    }
    try {
      final d = await ApiClient.instance.post(
        '/api/admin/sections/${widget.id}/students',
        body: {
          'arabicFirstName': _first.text.trim(),
          'arabicLastName': _last.text.trim(),
          'frenchFirstName': _frenchFirst.text.trim().isEmpty ? null : _frenchFirst.text.trim(),
          'frenchLastName': _frenchLast.text.trim().isEmpty ? null : _frenchLast.text.trim(),
          'rimNumber': _rim.text.trim().isEmpty ? null : _rim.text.trim(),
          'nationalNumber': _national.text.trim().isEmpty ? null : _national.text.trim(),
          'attendanceNumber': _attendance.text.trim().isEmpty
              ? null
              : int.tryParse(_attendance.text.trim()),
          'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
          'agentFullName': _agentName.text.trim(),
          'agentPhone': _agentPhone.text.trim(),
        },
      );
      setState(() => _lastAdded = asMap(d));
      _clearForm();
      if (mounted) {
        showToast(context,
            'تم تسجيل ${asMap(d)['student'] == null ? "" : asMap(asMap(d)['student'])['arabicFirstName']} ${asMap(asMap(d)['student'])['arabicLastName']} مباشرة وقبولًا');
      }
      await _load();
    } on ApiException catch (e) {
      setState(() => _formError = e.message);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _clearForm() {
    _first.clear();
    _last.clear();
    _attendance.clear();
    _frenchFirst.clear();
    _frenchLast.clear();
    _rim.clear();
    _national.clear();
    _phone.clear();
    _address.clear();
    _agentName.clear();
    _agentPhone.clear();
  }

  BadgeTone _tone(String s) =>
      s == 'APPROVED' ? BadgeTone.ok : s == 'REJECTED' ? BadgeTone.bad : BadgeTone.pending;
  String _label(String s) =>
      s == 'APPROVED' ? 'مقبول' : s == 'REJECTED' ? 'مرفوض' : 'بانتظار التوثيق';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.zinc50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(_section == null ? 'القسم' : asStr(_section!['name']), style: AppText.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.zinc700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _error.isNotEmpty && _section == null
          ? Padding(padding: const EdgeInsets.all(16), child: ErrorBox(_error, onRetry: _load))
          : _section == null
              ? const AppSpinner()
              : RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'تسجيل ${formatMoney(asInt(_section!['registrationFee']))} · شهري ${formatMoney(asInt(_section!['monthlyFee']))}',
                        style: ar(13, FontWeight.w400, AppColors.zinc500),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'طباعة قائمة القسم',
                              variant: AppButtonVariant.outline,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => AdminClassPrintScreen(sectionId: widget.id)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppButton(
                              text: 'إضافة تلميذ',
                              onPressed: () => setState(() => _showAdd = !_showAdd),
                            ),
                          ),
                        ],
                      ),
                      if (_lastAdded != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.okSoft,
                            borderRadius: BorderRadius.circular(AppRadius.control),
                            border: Border.all(color: AppColors.ok.withValues(alpha: 0.3)),
                          ),
                          child: RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: 'تم تسجيل جديد وقبولًا. حساب ولي الأمر: ',
                                style: ar(12, FontWeight.w400, AppColors.ok),
                              ),
                              TextSpan(
                                text:
                                    '${asStr(asMap(_lastAdded!['agent'])['fullName'])} / ${asStr(asMap(_lastAdded!['agent'])['phone'])} / كلمة المرور ${asStr(_lastAdded!['agentPassword'])}',
                                style: mono(12, FontWeight.w600, AppColors.ok),
                              ),
                            ]),
                          ),
                        ),
                      ],
                      if (_showAdd) ...[
                        const SizedBox(height: 12),
                        _addForm(),
                      ],
                      const SizedBox(height: 12),
                      if (_stats != null) _statsRow(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              variant: AppButtonVariant.outline,
                              expand: true,
                              onPressed: () => _openSubjects(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.menu_book_outlined, size: 18, color: AppColors.accent),
                                  const SizedBox(width: 8),
                                  Text('المواد الدراسية', style: ar(13, FontWeight.w600, AppColors.foreground)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              variant: AppButtonVariant.outline,
                              expand: true,
                              onPressed: () => _openSchedule(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.accent),
                                  const SizedBox(width: 8),
                                  Text('الجدول الزمني', style: ar(13, FontWeight.w600, AppColors.foreground)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('تلاميذ القسم (${asInt(_stats?['total'])})', style: AppText.h2),
                      const SizedBox(height: 12),
                      if (_students.isEmpty)
                        AppCard(child: const AppEmpty(title: 'لا يوجد تلاميذ في هذا القسم بعد'))
                      else
                        ..._students.map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _studentRow(s),
                            )),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _addForm() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إضافة تلميذ إلى ${asStr(_section!['name'])}', style: AppText.h2),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AppInput(label: 'الاسم الأول', controller: _first)),
              const SizedBox(width: 12),
              Expanded(child: AppInput(label: 'اسم العائلة', controller: _last)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AppInput(label: 'رقم النداء (اختياري)', controller: _attendance, number: true, ltr: true)),
              const SizedBox(width: 12),
              Expanded(child: AppInput(label: 'الاسم بالفرنسية', controller: _frenchFirst, ltr: true)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AppInput(label: 'اسم العائلة بالفرنسية', controller: _frenchLast, ltr: true)),
              const SizedBox(width: 12),
              Expanded(child: AppInput(label: 'رقم ريم (RIM) — اختياري', controller: _rim, ltr: true)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AppInput(label: 'الرقم الوطني — اختياري', controller: _national, ltr: true)),
              const SizedBox(width: 12),
              Expanded(child: AppInput(label: 'هاتف التلميذ — اختياري', controller: _phone, ltr: true, number: true, maxLength: 8)),
            ],
          ),
          const SizedBox(height: 12),
          AppInput(label: 'العنوان — اختياري', controller: _address),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AppInput(label: 'اسم ولي الأمر', controller: _agentName)),
              const SizedBox(width: 12),
              Expanded(child: AppInput(label: 'هاتف ولي الأمر', controller: _agentPhone, ltr: true, number: true, maxLength: 8)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'يُعتمد التلميذ فورًا في القسم. إذا لم يكن لولي الأمر حساب، يُنشأ له تلقائيًا حساب — رقم هاتفه كمعرّف وكلمة المرور 000000.',
            style: ar(12, FontWeight.w400, AppColors.zinc500),
          ),
          if (_formError.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_formError, style: ar(13, FontWeight.w400, AppColors.bad)),
          ],
          const SizedBox(height: 12),
          AppButton(
            text: 'تسجيل التلميذ',
            expand: true,
            loading: _adding,
            onPressed: _addStudent,
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    final st = _stats!;
    final tiles = [
      ['إجمالي التلاميذ', '${asInt(st['total'])}', Icons.people_outline, AppColors.accent, AppColors.accentSoft],
      ['مقبولون', '${asInt(st['approved'])}', Icons.person_add_alt_1, AppColors.ok, AppColors.okSoft],
      ['بانتظار المراجعة', '${asInt(st['pending'])}', Icons.hourglass_top, AppColors.pending, AppColors.pendingSoft],
      ['مرفوضون', '${asInt(st['rejected'])}', Icons.cancel_outlined, AppColors.bad, AppColors.badSoft],
      ['مدفوعات موثقة (${asInt(st['paymentsApproved'])})', formatMoney(asInt(st['amountCollected'])), Icons.account_balance_wallet_outlined, AppColors.ok, AppColors.okSoft],
      ['دفعات بانتظار التوثيق', '${asInt(st['paymentsPending'])}', Icons.hourglass_top, AppColors.pending, AppColors.pendingSoft],
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: tiles.map((t) {
        return AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(t[2] as IconData, size: 16, color: t[3] as Color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(t[1] as String,
                        style: ar(18, FontWeight.w700, AppColors.foreground)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(t[0] as String, style: ar(11, FontWeight.w400, AppColors.zinc500)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _openSubjects() => _sheet(
        title: 'المواد الدراسية — ${asStr(_section!['name'])}',
        body: _subjectsBody(),
      );

  Future<void> _openSchedule() => _sheet(
        title: 'الجدول الزمني الأسبوعي — ${asStr(_section!['name'])}',
        body: _scheduleBody(),
        ratio: 0.85,
      );

  Future<void> _sheet({required String title, required Widget body, double ratio = 0.75}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * ratio,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: AppText.h2, overflow: TextOverflow.ellipsis)),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 22, color: AppColors.zinc400),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Divider(color: AppColors.zinc100, height: 20),
              const SizedBox(height: 4),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subjectsBody() {
    final subjects = asStrList(_section!['subjects']);
    if (subjects.isEmpty) return const AppEmpty(title: 'لا توجد مواد مسجلة');
    return Align(
      alignment: Alignment.topRight,
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: subjects
              .map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(s, style: ar(15, FontWeight.w600, AppColors.accent)),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _scheduleBody() {
    final schedule = asMapList(_section!['schedule']);
    if (schedule.isEmpty) return const AppEmpty(title: 'لا يوجد جدول مسجل');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 560),
              child: SingleChildScrollView(child: Timetable(schedule: schedule)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text('مرّر الجدول جانبيًا لعرض كل الأيام بوضوح',
              style: AppText.tiny, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _studentRow(Map<String, dynamic> s) {
    final agent = s['agent'] == null ? null : asMap(s['agent']);
    final status = asStr(s['status'], 'PENDING');
    final attendance = asIntOrNull(s['attendanceNumber']);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminStudentDetailScreen(id: asInt(s['id']))),
      ),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${asStr(s['arabicFirstName'])} ${asStr(s['arabicLastName'])}${attendance != null ? " #$attendance" : ""}',
                    style: ar(14, FontWeight.w600, AppColors.foreground),
                  ),
                ),
                AppBadge(_label(status), tone: _tone(status)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'ولي الأمر: ${agent == null ? "—" : asStr(agent['fullName'])} · ${agent == null ? "" : asStr(agent['phone'])}',
              style: ar(12, FontWeight.w400, AppColors.zinc500),
            ),
            if (status == 'REJECTED')
              Text('سبب الرفض: ${asStrOrNull(s['rejectionReason']) ?? ""}',
                  style: ar(12, FontWeight.w400, AppColors.bad)),
          ],
        ),
      ),
    );
  }
}