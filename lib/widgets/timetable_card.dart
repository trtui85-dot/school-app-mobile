import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import 'logo.dart';
import 'toast.dart';

const _dayIndexes = [1, 2, 3, 4, 5, 6]; // الاثنين → السبت
const double _cardWidth = 680;

/// The full, fixed-width timetable card (school logo + students + subjects +
/// weekly grid). Rendered at a comfortable width and scaled down to fit the
/// screen, so nothing is ever hidden. Captured as a crisp image on download.
class TimetableCard extends StatelessWidget {
  final Map<String, dynamic> section;
  final String studentName;
  final String schoolName;
  const TimetableCard({
    super.key,
    required this.section,
    required this.studentName,
    required this.schoolName,
  });

  @override
  Widget build(BuildContext context) {
    final subjects = asStrList(section['subjects']);
    final schedule = asMapList(section['schedule']);
    return SizedBox(
      width: _cardWidth,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.zinc200),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            const SizedBox(height: 16),
            _info(subjects),
            const SizedBox(height: 18),
            _table(schedule),
            const SizedBox(height: 18),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.accent, width: 2)),
      ),
      child: Row(
        children: [
          const AppLogo(size: 52, withName: false),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schoolName.isEmpty ? tr('مدارس اقرأ الحديثة') : schoolName,
                    style: ar(20, FontWeight.w700, AppColors.foreground), maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(tr('الجدول الأسبوعي'),
                    style: ar(14, FontWeight.w600, AppColors.accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(List<String> subjects) {
    final sectionName = asStr(section['name']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _kv(tr('التلميذ'), studentName)),
            const SizedBox(width: 16),
            Expanded(child: _kv(tr('القسم'), sectionName.isEmpty ? '—' : sectionName)),
          ],
        ),
        if (subjects.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(tr('المواد الدراسية'), style: ar(13, FontWeight.w700, AppColors.zinc700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subjects
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(s, style: ar(12, FontWeight.w600, AppColors.accent)),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _kv(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ar(11, FontWeight.w400, AppColors.zinc500)),
          const SizedBox(height: 2),
          Text(value,
              style: ar(14, FontWeight.w700, AppColors.foreground),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      );

  Widget _table(List<Map<String, dynamic>> schedule) {
    final slots = <String>[];
    final cellMap = <String, String>{};
    for (final e in schedule) {
      final day = asInt(e['day']);
      final subject = asStr(e['subject']).trim();
      if (subject.isEmpty) continue;
      final start = asStr(e['start']);
      final end = asStr(e['end']);
      cellMap.putIfAbsent('$start|$end|$day', () => subject);
      final key = '$start|$end';
      if (!slots.contains(key)) slots.add(key);
    }
    slots.sort();

    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.zinc50,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: AppColors.zinc200),
        ),
        child: Text(tr('لا توجد حصص بعد'), style: ar(13, FontWeight.w400, AppColors.zinc500)),
      );
    }

    final rows = <TableRow>[
      TableRow(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.zinc200, width: 1)),
        ),
        children: [
          _cell(tr('الوقت'), bold: true, bg: AppColors.accent, color: Colors.white, isTime: true),
          for (final i in _dayIndexes)
            _cell(dayLabel(i), bold: true, bg: AppColors.zinc50, color: AppColors.zinc700),
        ],
      ),
    ];
    for (var r = 0; r < slots.length; r++) {
      final parts = slots[r].split('|');
      final start = parts[0];
      final end = parts[1];
      final band = r.isEven ? Colors.white : AppColors.zinc50;
      rows.add(TableRow(
        decoration: BoxDecoration(color: band),
        children: [
          _cell('$start\n$end',
              bold: true, bg: AppColors.accentSoft, color: AppColors.accent, isTime: true),
          for (final di in _dayIndexes)
            _cell(cellMap['$start|$end|$di'] ?? '—',
                hasContent: cellMap.containsKey('$start|$end|$di'), bg: band),
        ],
      ));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.zinc200)),
        child: Table(
          columnWidths: const {0: FixedColumnWidth(96)},
          defaultColumnWidth: const FlexColumnWidth(),
          border: TableBorder.all(color: AppColors.zinc100, width: 0.5),
          children: rows,
        ),
      ),
    );
  }

  Widget _cell(
    String text, {
    bool bold = false,
    Color? bg,
    Color? color,
    bool isTime = false,
    bool hasContent = true,
  }) {
    final fg = !hasContent ? AppColors.zinc300 : (color ?? AppColors.zinc700);
    final style = isTime
        ? mono(13, FontWeight.w700, fg)
        : ar(13, bold ? FontWeight.w700 : FontWeight.w600, fg, height: 1.35);
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
      alignment: Alignment.center,
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
  }

  Widget _footer() => Row(
        children: [
          Text(formatArabicDate(DateTime.now()), style: ar(11, FontWeight.w400, AppColors.zinc400)),
          const Spacer(),
          Text(tr('جدول أسبوعي'), style: ar(11, FontWeight.w400, AppColors.zinc400)),
        ],
      );
}

/// Displays [TimetableCard] scaled to fit the width (whole card visible, never
/// cropped) with a download button that saves the full-resolution card image.
class TimetableSection extends StatefulWidget {
  final Map<String, dynamic> section;
  final String studentName;
  final String schoolName;
  const TimetableSection({
    super.key,
    required this.section,
    required this.studentName,
    required this.schoolName,
  });

  @override
  State<TimetableSection> createState() => _TimetableSectionState();
}

class _TimetableSectionState extends State<TimetableSection> {
  final _key = GlobalKey();
  bool _saving = false;

  Future<void> _download() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final boundary = _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      final bytes = data.buffer.asUint8List();
      if (!await Gal.hasAccess()) await Gal.requestAccess();
      await Gal.putImageBytes(bytes,
          name: 'timetable-${DateTime.now().millisecondsSinceEpoch}');
      if (mounted) showToast(context, tr('تم حفظ الجدول في المعرض'));
    } catch (_) {
      if (mounted) showToast(context, tr('تعذر حفظ الصورة'), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(tr('الجدول الأسبوعي'), style: ar(14, FontWeight.w700, AppColors.zinc700)),
            const Spacer(),
            GestureDetector(
              onTap: _download,
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _saving
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.download, size: 16, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(tr('تحميل الجدول'), style: ar(12, FontWeight.w600, AppColors.accent)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: RepaintBoundary(
            key: _key,
            child: TimetableCard(
              section: widget.section,
              studentName: widget.studentName,
              schoolName: widget.schoolName,
            ),
          ),
        ),
      ],
    );
  }
}
