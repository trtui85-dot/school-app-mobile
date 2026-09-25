import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/logo.dart';
import '../../widgets/print_sheet.dart';
import '../../widgets/ui.dart';

Widget sheetHeader(String schoolName, String title) {
  return Container(
    padding: const EdgeInsets.only(bottom: 12),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black, width: 2))),
    child: Row(
      children: [
        const Spacer(),
        Column(
          children: [
            Text(schoolName, style: ar(20, FontWeight.w700, AppColors.foreground)),
            const SizedBox(height: 4),
            Text(title, style: ar(13, FontWeight.w400, AppColors.foreground)),
          ],
        ),
        const Spacer(),
        const AppLogo(size: 48, withName: false),
      ],
    ),
  );
}

Widget sheetFooter({String? pageLabel}) {
  return Container(
    padding: const EdgeInsets.only(top: 8),
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black))),
    child: Row(
      children: [
        Text('الختم والتوقيع', style: ar(12, FontWeight.w400, AppColors.foreground)),
        const Spacer(),
        if (pageLabel != null)
          Text(pageLabel, style: ar(11, FontWeight.w400, AppColors.zinc600)),
        if (pageLabel != null) const SizedBox(width: 12),
        Text(formatArabicDate(DateTime.now()), style: ar(12, FontWeight.w400, AppColors.foreground)),
      ],
    ),
  );
}

class AdminClassPrintScreen extends StatefulWidget {
  final int sectionId;
  const AdminClassPrintScreen({super.key, required this.sectionId});
  @override
  State<AdminClassPrintScreen> createState() => _AdminClassPrintScreenState();
}

class _AdminClassPrintScreenState extends State<AdminClassPrintScreen> {
  Map<String, dynamic>? _section;
  List<Map<String, dynamic>> _students = [];
  String _schoolName = 'مدارس اقرأ الحديثة';
  String _error = '';

  static const _columns = [1.2, 2.2, 2.0, 2.2, 1.2];
  static const _pageW = 360.0;
  static const _pageH = 509.0;

  List<double> get _colWidths {
    final sum = _columns.fold<double>(0, (a, b) => a + b);
    final inner = _pageW - 40;
    return _columns.map((f) => f / sum * inner).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await ApiClient.instance
          .get('/api/admin/print/class', query: {'sectionId': widget.sectionId.toString()});
      if (!mounted) return;
      setState(() {
        _section = asMap(d['section']);
        _students = asMapList(d['students']);
        _schoolName = asStr(d['schoolName'], 'مدارس اقرأ الحديثة');
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  double _lineH(String text, double w, {bool ltr = false}) {
    if (text.isEmpty) return 10;
    final style = ltr
        ? mono(10, FontWeight.w400, AppColors.foreground)
        : ar(10, FontWeight.w400, AppColors.foreground);
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
      maxLines: 3,
    )..layout(maxWidth: w);
    return tp.height.clamp(12.0, 60.0);
  }

  double _rowH(Map<String, dynamic> s, List<double> widths) {
    final cells = [
      asIntOrNull(s['attendanceNumber'])?.toString() ?? '',
      '${asStr(s['arabicFirstName'])} ${asStr(s['arabicLastName'])}',
      '${asStr(s['frenchFirstName'])} ${asStr(s['frenchLastName'])}'.trim(),
      asMap(s['agent'])['fullName']?.toString() ?? '',
      '',
    ];
    var h = 10.0;
    for (var i = 0; i < cells.length; i++) {
      final cellH = _lineH(cells[i], widths[i] - 8, ltr: i == 2) + 8;
      if (cellH > h) h = cellH;
    }
    return h;
  }

  List<List<Map<String, dynamic>>> _chunkRows() {
    final rows = _students;
    if (rows.isEmpty) return [rows];
    final widths = _colWidths;
    final headerH = _lineH('اسم', 60) + 8;
    final firstBudget = _pageH - 40 - 96 - 14 - 24 - 14 - 52;
    final nextBudget = _pageH - 40 - 96 - 14 - 20;
    final chunks = <List<Map<String, dynamic>>>[];
    var budget = firstBudget;
    var used = headerH;
    var current = <Map<String, dynamic>>[];
    for (final s in rows) {
      final h = _rowH(s, widths) + 3;
      if (used + h > budget && current.isNotEmpty) {
        chunks.add(current);
        current = <Map<String, dynamic>>[];
        budget = nextBudget;
        used = headerH;
      }
      current.add(s);
      used += h;
    }
    if (current.isNotEmpty) chunks.add(current);
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    if (_error.isNotEmpty) {
      return Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: ErrorBox(_error)));
    }
    if (_section == null) {
      return const Scaffold(body: AppSpinner());
    }
    final approved = _students.where((s) => asStr(s['status']) == 'APPROVED').length;
    final chunks = _chunkRows();
    final sectionName = asStr(_section!['name']);
    final pages = <Widget>[];
    for (var k = 0; k < chunks.length; k++) {
      final isFirst = k == 0;
      final isLast = k == chunks.length - 1;
      pages.add(
        printPage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sheetHeader(
                _schoolName,
                isFirst
                    ? 'قائمة تلاميذ قسم: $sectionName'
                    : 'متابعة قائمة تلاميذ قسم: $sectionName',
              ),
              const SizedBox(height: 10),
              Text(
                'العدد الإجمالي: ${_students.length} تلميذًا · المقبولون: $approved · بتاريخ ${formatArabicDate(DateTime.now())}',
                style: ar(11, FontWeight.w400, AppColors.zinc600),
              ),
              const SizedBox(height: 10),
              Table(
                border: const TableBorder.symmetric(
                  inside: BorderSide(color: AppColors.zinc300, width: 0.5),
                ),
                columnWidths: {
                  for (var i = 0; i < 5; i++) i: FlexColumnWidth(_columns[i]),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(
                      color: AppColors.zinc100,
                      border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
                    ),
                    children: [
                      _th('رقم النداء'),
                      _th('الاسم'),
                      _th('الاسم بالفرنسية'),
                      _th('ولي الأمر'),
                      _th('ملاحظات'),
                    ],
                  ),
                  for (final s in chunks[k])
                    TableRow(children: [
                      _td(asIntOrNull(s['attendanceNumber'])?.toString() ?? ''),
                      _td('${asStr(s['arabicFirstName'])} ${asStr(s['arabicLastName'])}'),
                      _td(
                          '${asStr(s['frenchFirstName'])} ${asStr(s['frenchLastName'])}'.trim(),
                          ltr: true),
                      _td(asMap(s['agent'])['fullName']?.toString() ?? ''),
                      _td(''),
                    ]),
                ],
              ),
              const Spacer(),
              if (isLast)
                sheetFooter(pageLabel: chunks.length > 1 ? 'صفحة ${k + 1} من ${chunks.length}' : null)
              else
                _pageNumber(k + 1, chunks.length),
            ],
          ),
        ),
      );
    }
    return PrintSheetScreen(
      title: 'طباعة قائمة القسم',
      fileName: 'class-list-${widget.sectionId}',
      pages: pages,
    );
  }

  Widget _pageNumber(int current, int total) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text('صفحة $current من $total',
          textAlign: TextAlign.center, style: ar(11, FontWeight.w400, AppColors.zinc600)),
    );
  }

  Widget _th(String text) => _td(text, bold: true);

  Widget _td(String text, {bool bold = false, bool ltr = false}) {
    final style = ltr
        ? mono(10, bold ? FontWeight.w700 : FontWeight.w400, AppColors.foreground)
        : ar(10, bold ? FontWeight.w700 : FontWeight.w400, AppColors.foreground);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
  }
}

class AdminStudentPrintScreen extends StatefulWidget {
  final int id;
  const AdminStudentPrintScreen({super.key, required this.id});
  @override
  State<AdminStudentPrintScreen> createState() => _AdminStudentPrintScreenState();
}

class _AdminStudentPrintScreenState extends State<AdminStudentPrintScreen> {
  Map<String, dynamic>? _student;
  String _schoolName = 'مدارس اقرأ الحديثة';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await ApiClient.instance.get('/api/admin/students/${widget.id}');
      if (!mounted) return;
      setState(() {
        _student = asMap(d['student']);
        _schoolName = asStr(d['schoolName'], 'مدارس اقرأ الحديثة');
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error.isNotEmpty) {
      return Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: ErrorBox(_error)));
    }
    if (_student == null) {
      return const Scaffold(body: AppSpinner());
    }
    final s = _student!;
    final section = s['section'] == null ? null : asMap(s['section']);
    final agent = s['agent'] == null ? null : asMap(s['agent']);
    final payments = asMapList(s['payments']);
    final approvedMonthly =
        payments.where((p) => asStr(p['status']) == 'APPROVED' && asStr(p['type']) == 'MONTHLY');
    final paidMonths = approvedMonthly.map((p) => asIntOrNull(p['month'])).whereType<int>().toSet();
    final totalVerified =
        payments.where((p) => asStr(p['status']) == 'APPROVED').fold<int>(0, (sum, p) => sum + asInt(p['amount']));
    final absences =
        asMapList(s['attendances']).where((a) => asStr(a['status']) == 'ABSENT').length;

    Widget kv(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 92, child: Text(label, style: ar(10, FontWeight.w500, AppColors.zinc600))),
              Expanded(child: Text(value, style: ar(10, FontWeight.w400, AppColors.foreground))),
            ],
          ),
        );

    return PrintSheetScreen(
      title: 'طباعة ملف التلميذ',
      fileName: 'student-file-${widget.id}',
      pages: [
        printPage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sheetHeader(_schoolName, 'ملف التلميذ الفردي'),
              const SizedBox(height: 12),
              kv('الاسم بالعربية:', '${asStr(s['arabicFirstName'])} ${asStr(s['arabicLastName'])}'),
              kv('رقم النداء:', asIntOrNull(s['attendanceNumber'])?.toString() ?? ''),
              kv('الاسم بالفرنسية:',
                  '${asStr(s['frenchFirstName'])} ${asStr(s['frenchLastName'])}'.trim()),
              kv('القسم:', section == null ? '—' : asStr(section['name'])),
              kv('رقم ريم:', asStr(s['rimNumber'])),
              kv('الرقم الوطني:', asStr(s['nationalNumber'])),
              kv('ولي الأمر:',
                  '${agent == null ? "—" : asStr(agent['fullName'])} (${agent == null ? "" : asStr(agent['phone'])})'),
              kv('الهاتف:', asStr(s['phone'])),
              const SizedBox(height: 12),
              Text('وضع الدفعات', style: ar(12, FontWeight.w700, AppColors.foreground)),
              const SizedBox(height: 4),
              Table(
                border: TableBorder.all(color: AppColors.zinc300, width: 0.5),
                columnWidths: {
                  for (var i = 0; i < schoolMonths.length; i++) i: const FlexColumnWidth(),
                },
                children: [
                  TableRow(children: [
                    for (final m in schoolMonths)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(m.label, textAlign: TextAlign.center, style: ar(9, FontWeight.w600, AppColors.zinc700)),
                      ),
                  ]),
                  TableRow(children: [
                    for (final m in schoolMonths)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          paidMonths.contains(m.num) ? '✓' : '—',
                          textAlign: TextAlign.center,
                          style: ar(12, FontWeight.w600, paidMonths.contains(m.num) ? AppColors.ok : AppColors.zinc300),
                        ),
                      ),
                  ]),
                ],
              ),
              const SizedBox(height: 6),
              Text('إجمالي المبالغ الموثقة: ${formatMoney(totalVerified)}', style: ar(11, FontWeight.w600, AppColors.foreground)),
              const SizedBox(height: 10),
              Text('الغياب المسجل ($absences) — السجل الكامل في ملف القسم.',
                  style: ar(11, FontWeight.w400, AppColors.zinc600)),
              const Spacer(),
              sheetFooter(),
            ],
          ),
        ),
      ],
    );
  }
}