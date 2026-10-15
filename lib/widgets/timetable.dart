import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/utils.dart';

const _dayIndexes = [1, 2, 3, 4, 5, 6]; // الاثنين → السبت

/// Weekly schedule grid. Scrolls horizontally on narrow screens and uses a
/// slightly larger type scale so each cell stays readable (never cramped).
class Timetable extends StatelessWidget {
  final List<Map<String, dynamic>> schedule;
  const Timetable({super.key, required this.schedule});

  static const double _minWidth = 560;

  @override
  Widget build(BuildContext context) {
    final slots = <String>[];
    final slotMap = <String, String>{};
    final cellMap = <String, String>{};

    for (final e in schedule) {
      final day = asInt(e['day']);
      final subject = asStr(e['subject']).trim();
      if (subject.isEmpty) continue;
      final start = asStr(e['start']);
      final end = asStr(e['end']);
      cellMap.putIfAbsent('$start|$end|$day', () => subject);
      final slotKey = '$start|$end';
      if (!slotMap.containsKey(slotKey)) {
        slotMap[slotKey] = '$start|$end';
        slots.add(slotKey);
      }
    }
    slots.sort();

    if (slots.isEmpty) return const SizedBox.shrink();

    TableRow header() => TableRow(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.zinc200, width: 1)),
          ),
          children: [
            _cell(tr('الوقت'),
                bold: true, bg: AppColors.accent, color: Colors.white, isTime: true),
            for (final i in _dayIndexes)
              _cell(dayLabel(i), bold: true, bg: AppColors.zinc50, color: AppColors.zinc700),
          ],
        );

    final rows = <TableRow>[header()];
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
            _cell(
              _subjectOf('$start|$end|$di', cellMap),
              hasContent: cellMap.containsKey('$start|$end|$di'),
              bg: band,
            ),
        ],
      ));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.zinc200)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: _minWidth),
            child: Table(
              defaultColumnWidth: const FlexColumnWidth(),
              border: TableBorder.all(color: AppColors.zinc100, width: 0.5),
              children: rows,
            ),
          ),
        ),
      ),
    );
  }

  String _subjectOf(String key, Map<String, String> cellMap) {
    return cellMap[key] ?? '—';
  }

  Widget _cell(
    String text, {
    bool bold = false,
    Color? bg,
    Color? color,
    bool isTime = false,
    bool hasContent = true,
  }) {
    final Color fg;
    if (!hasContent) {
      fg = AppColors.zinc300;
    } else {
      fg = color ?? AppColors.zinc700;
    }
    final style = isTime
        ? mono(11, FontWeight.w700, fg)
        : ar(12, bold ? FontWeight.w700 : FontWeight.w600, fg, height: 1.3);
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      alignment: Alignment.center,
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
  }
}
