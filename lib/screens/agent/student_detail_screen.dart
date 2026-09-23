import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/receipt_screen.dart';
import '../../widgets/timetable.dart';
import '../../widgets/ui.dart';
import 'pay_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final int id;
  const StudentDetailScreen({super.key, required this.id});
  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  Map<String, dynamic>? _data;
  String _error = '';
  String? _screen;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await ApiClient.instance.get('/api/me/students/${widget.id}');
      if (!mounted) return;
      setState(() {
        _data = asMap(d['student']);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = _data;
    final title = student == null
        ? tr('التلميذ')
        : '${asStr(student['arabicFirstName'])} ${asStr(student['arabicLastName'])}';

    return Scaffold(
      backgroundColor: AppColors.zinc50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(title, style: AppText.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.zinc700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const AppSpinner()
          : _error.isNotEmpty
              ? Padding(padding: const EdgeInsets.all(16), child: ErrorBox(_error, onRetry: _load))
              : RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: _load,
                  child: _screen == null ? _home(student!) : _subScreen(student!),
                ),
    );
  }

  BadgeTone _statusTone(String s) =>
      s == 'APPROVED' ? BadgeTone.ok : s == 'REJECTED' ? BadgeTone.bad : BadgeTone.pending;

  String _statusLabel(String s) =>
      s == 'APPROVED' ? tr('مقبول') : s == 'REJECTED' ? tr('مرفوض') : tr('بانتظار التوثيق');

  Widget _home(Map<String, dynamic> student) {
    final status = asStr(student['status'], 'PENDING');
    final attendance = asIntOrNull(student['attendanceNumber']);
    final section = student['section'] == null ? null : asMap(student['section']);

    final cards = [
      ['الغياب', tr('سجل الغياب وأيام الغيبة'), Icons.event_busy, const Color(0xFFF43F5E)],
      ['مواد وجدول', tr('المواد الدراسية والجدول الأسبوعي'), Icons.menu_book_outlined, const Color(0xFF8B5CF6)],
      ['نتائج', tr('الدرجات والنتائج الدراسية'), Icons.emoji_events_outlined, const Color(0xFF10B981)],
      ['رسائل الإدارة', tr('رسائل إدارة المدرسة'), Icons.message_outlined, const Color(0xFFF59E0B)],
      ['الدفعات', tr('رسوم التسجيل والاشتراكات الشهرية'), Icons.credit_card, const Color(0xFF0EA5E9)],
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titleOf(student), style: ar(18, FontWeight.w700, AppColors.foreground)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(section == null ? tr('بدون قسم') : asStr(section['name']),
                            overflow: TextOverflow.ellipsis, style: ar(13, FontWeight.w400, AppColors.zinc500)),
                      ),
                      if (attendance != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.zinc100, borderRadius: BorderRadius.circular(6)),
                          child: Text('${tr('رقم النداء: ')}$attendance',
                              style: mono(11, FontWeight.w400, AppColors.zinc600)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            AppBadge(_statusLabel(status), tone: _statusTone(status)),
          ],
        ),
        const SizedBox(height: 16),
        if (status == 'PENDING')
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.pendingSoft, borderRadius: BorderRadius.circular(AppRadius.control)),
            child: Text(tr('طلب التسجيل قيد المراجعة من الإدارة.'),
                style: ar(14, FontWeight.w400, AppColors.pending)),
          ),
        if (status == 'REJECTED')
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.badSoft, borderRadius: BorderRadius.circular(AppRadius.control)),
            child: Text(
              '${tr('تم رفض طلب التسجيل. السبب: ')}${asStrOrNull(student['rejectionReason']) ?? tr('غير محدد')}',
              style: ar(14, FontWeight.w400, AppColors.bad),
            ),
          ),
        if (status == 'APPROVED') ...[
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: cards.map((c) {
              final id = c[0] as String;
              return GestureDetector(
                onTap: () => setState(() => _screen = id),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.zinc100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: c[3] as Color,
                          borderRadius: BorderRadius.circular(AppRadius.control),
                        ),
                        child: Icon(c[2] as IconData, color: Colors.white, size: 20),
                      ),
                      const SizedBox(height: 12),
                      Text(tr(id), style: ar(14, FontWeight.w700, AppColors.zinc800)),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(c[1] as String,
                            style: ar(12, FontWeight.w400, AppColors.zinc500)),
                      ),
                      Row(
                        children: [
                          Text(tr('عرض التفاصيل'), style: ar(12, FontWeight.w600, AppColors.accent)),
                          const Icon(Icons.chevron_left, size: 14, color: AppColors.accent),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _subScreen(Map<String, dynamic> student) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            AppButton(
              text: tr('عودة'),
              variant: AppButtonVariant.outline,
              onPressed: () => setState(() => _screen = null),
            ),
            const Spacer(),
            Text(_screen!, style: ar(14, FontWeight.w700, AppColors.zinc700)),
          ],
        ),
        const SizedBox(height: 16),
        if (_screen == 'الغياب') _absence(student),
        if (_screen == 'مواد وجدول') _subjectsAndSchedule(student),
        if (_screen == 'نتائج')
          AppCard(child: AppEmpty(title: tr('قريبًا'), hint: tr('وحدة النتائج والدرجات ستتوفر لاحقًا'))),
        if (_screen == 'رسائل الإدارة') _messages(student),
        if (_screen == 'الدفعات') _payments(student),
      ],
    );
  }

  Widget _absence(Map<String, dynamic> student) {
    final absences =
        asMapList(student['attendances']).where((a) => asStr(a['status']) == 'ABSENT').toList();
    final absentToday = absences.any((a) => formatDateISO(a['date']) == todayISO());
    return Column(
      children: [
        if (absentToday)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.badSoft, borderRadius: BorderRadius.circular(AppRadius.control)),
            child: Text(tr('⚠️ طفلك غائب اليوم'),
                style: ar(14, FontWeight.w600, AppColors.bad)),
          ),
        if (absences.isEmpty)
          AppCard(child: AppEmpty(title: tr('لا يوجد أي غياب مسجل')))
        else
          AppCard(
            child: Column(
              children: absences.map((a) {
                final d = DateTime.parse(asStr(a['date']));
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Text('${monthLabel(d.month)} ${d.day}', style: AppText.body),
                      const Spacer(),
                      AppBadge(tr('غائب'), tone: BadgeTone.bad),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _subjectsAndSchedule(Map<String, dynamic> student) {
    final section = student['section'] == null ? null : asMap(student['section']);
    if (section == null) return AppCard(child: AppEmpty(title: tr('لا توجد بيانات القسم')));
    final subjects = asStrList(section['subjects']);
    final schedule = asMapList(section['schedule']);
    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('المواد الدراسية'), style: ar(14, FontWeight.w700, AppColors.zinc700)),
              const SizedBox(height: 8),
              if (subjects.isEmpty)
                Text('—', style: AppText.small)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subjects
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                                color: AppColors.accentSoft, borderRadius: BorderRadius.circular(8)),
                            child: Text(s, style: ar(12, FontWeight.w500, AppColors.accent)),
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('الجدول الزمني الأسبوعي'), style: ar(14, FontWeight.w700, AppColors.zinc700)),
              const SizedBox(height: 12),
              Timetable(schedule: schedule),
            ],
          ),
        ),
      ],
    );
  }

  Widget _messages(Map<String, dynamic> student) {
    final notes = asMapList(student['notes']);
    if (notes.isEmpty) return AppCard(child: AppEmpty(title: tr('لا توجد رسائل')));
    return Column(
      children: notes
          .map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(asStr(n['content']), style: AppText.body),
                      const SizedBox(height: 6),
                      Text(formatArabicDate(n['createdAt']), style: AppText.tiny),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _payments(Map<String, dynamic> student) {
    final payments = asMapList(student['payments']);
    final paidMonthly = payments
        .where((p) => asStr(p['status']) == 'APPROVED' && asStr(p['type']) == 'MONTHLY')
        .map((p) => asIntOrNull(p['month']))
        .whereType<int>()
        .toSet();

    return Column(
      children: [
        AppCard(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: schoolMonths.map((m) {
              final isPaid = paidMonthly.contains(m.num);
              final isCurrent = m.num == DateTime.now().month;
              final bg = isPaid
                  ? AppColors.okSoft
                  : isCurrent
                      ? AppColors.accentSoft
                      : AppColors.zinc100;
              final fg = isPaid
                  ? AppColors.ok
                  : isCurrent
                      ? AppColors.accent
                      : AppColors.zinc500;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                child: Text(tr(m.label), style: ar(12, FontWeight.w500, fg)),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        ...payments.map((p) {
          final status = asStr(p['status'], 'PENDING');
          final isReg = asStr(p['type']) == 'REGISTRATION';
          final month = asIntOrNull(p['month']);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isReg
                              ? tr('رسوم التسجيل')
                              : '${tr('رسوم ')}${monthLabel(month ?? 0)}${month != null ? " — ${asStr(p['schoolYear'])}" : ""}',
                          style: ar(14, FontWeight.w600, AppColors.foreground),
                        ),
                        const SizedBox(height: 2),
                        Text(formatMoney(asInt(p['amount'])),
                            style: mono(12, FontWeight.w400, AppColors.zinc500)),
                      ],
                    ),
                  ),
                  if (status == 'APPROVED')
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: AppButton(
                        text: tr('إيصال'),
                        variant: AppButtonVariant.ghost,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ReceiptScreen(paymentId: asInt(p['id']))),
                        ),
                      ),
                    ),
                  AppBadge(
                    status == 'APPROVED'
                        ? tr('موثقة')
                        : status == 'REJECTED'
                            ? tr('مرفوضة')
                            : tr('بانتظار التوثيق'),
                    tone: _statusTone(status),
                  ),
                ],
              ),
            ),
          );
        }),
        if (asStr(student['status']) == 'APPROVED')
          AppButton(
            text: tr('دفع شهر'),
            expand: true,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PayScreen(studentId: widget.id)),
              );
              _load();
            },
          ),
      ],
    );
  }

  String titleOf(Map<String, dynamic> s) =>
      '${asStr(s['arabicFirstName'])} ${asStr(s['arabicLastName'])}';
}
