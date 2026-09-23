import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/utils.dart';

const _dayIndexes = [1, 2, 3, 4, 5, 6]; // الاثنين → السبت

class Timetable extends StatelessWidget {
  final List<Map<String, dynamic>> schedule;
  const Timetable({super.key, required this.schedule});

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
          decoration: const BoxDecoration(color: AppColors.zinc100),
          children: [
            for (final i in _dayIndexes)
              _cell(dayLabel(i), bold: true, bg: AppColors.zinc100),
            _cell(tr('الوقت'), bold: true, bg: AppColors.accentSoft, color: AppColors.accent),
          ],
        );

    final rows = <TableRow>[header()];
    for (var r = 0; r < slots.length; r++) {
      final parts = slots[r].split('|');
      final start = parts[0];
      final end = parts[1];
      final bg = r.isOdd ? AppColors.zinc50 : Colors.white;
      rows.add(TableRow(
        decoration: BoxDecoration(color: bg),
        children: [
          for (final di in _dayIndexes)
            _cell(cellMap['$start|$end|$di'] ?? '—',
                bg: cellMap.containsKey('$start|$end|$di') ? AppColors.accentSoft : bg,
                color: cellMap.containsKey('$start|$end|$di') ? AppColors.accent : AppColors.zinc300),
          _cell('$start–$end', mono: true, bg: AppColors.accentSoft, color: AppColors.accent, bold: true),
        ],
      ));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.zinc200)),
        child: Table(
          defaultColumnWidth: const FlexColumnWidth(),
          border: TableBorder.all(color: AppColors.zinc100, width: 0.5),
          children: rows,
        ),
      ),
    );
  }

  Widget _cell(String text,
      {bool bold = false, bool mono = false, Color? bg, Color? color}) {
    final style = mono
        ? mono_(text, bold, color)
        : ar(10, bold ? FontWeight.w700 : FontWeight.w600,
            color ?? AppColors.zinc700);
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      alignment: Alignment.center,
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
  }

  TextStyle mono_(String text, bool bold, Color? color) =>
      mono(10, bold ? FontWeight.w700 : FontWeight.w600, color ?? AppColors.accent);
}
