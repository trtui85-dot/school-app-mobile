import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';

import 'l10n.dart';
/// School months (Oct → Jun) exactly like the web app.
class SchoolMonth {
  final int num;
  final String label;
  const SchoolMonth(this.num, this.label);
}

const List<SchoolMonth> schoolMonths = [
  SchoolMonth(10, 'أكتوبر'),
  SchoolMonth(11, 'نوفمبر'),
  SchoolMonth(12, 'ديسمبر'),
  SchoolMonth(1, 'يناير'),
  SchoolMonth(2, 'فبراير'),
  SchoolMonth(3, 'مارس'),
  SchoolMonth(4, 'أبريل'),
  SchoolMonth(5, 'مايو'),
  SchoolMonth(6, 'يونيو'),
];

const List<String> days = [
  'الأحد',
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
];

String monthLabel(int num) {
  final m = schoolMonths.firstWhere((m) => m.num == num, orElse: () => SchoolMonth(num, '$num'));
  return tr(m.label);
}

/// Localized weekday name for timetable headers.
String dayLabel(int index) {
  if (index < 0 || index >= days.length) return '—';
  return tr(days[index]);
}

/// e.g. "2026-2027" — year starts on October 1st.
String currentSchoolYear() {
  final now = DateTime.now();
  final start = now.month >= 9 ? now.year : now.year - 1;
  return '$start-${start + 1}';
}

String todayISO() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String formatDateISO(dynamic value) {
  final d = value is DateTime ? value : DateTime.parse(value.toString());
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final NumberFormat _money = NumberFormat.decimalPattern('fr_FR');

String formatMoney(num n) => '${_money.format(n)} MRU';

final NumberFormat _frNumber = NumberFormat.decimalPattern('fr_FR');
String formatNumber(num n) => _frNumber.format(n);

String formatArabicDate(dynamic value) {
  final d = value is DateTime ? value : DateTime.parse(value.toString());
  return DateFormat('d MMMM y', isFr ? 'fr' : 'ar').format(d);
}

String formatArabicDateTime(dynamic value) {
  final d = value is DateTime ? value : DateTime.parse(value.toString());
  return DateFormat('d MMMM y — HH:mm', isFr ? 'fr' : 'ar').format(d);
}

// ---- JSON helpers (API returns loosely-typed maps) ----

Map<String, dynamic> asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

int asInt(dynamic v, [int def = 0]) {
  if (v == null) return def;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? def;
}

int? asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double asDouble(dynamic v, [double def = 0]) {
  if (v == null) return def;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? def;
}

String asStr(dynamic v, [String def = '']) => v == null ? def : v.toString();

String? asStrOrNull(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

List<Map<String, dynamic>> asMapList(dynamic v) {
  if (v is List) return v.map((e) => asMap(e)).toList();
  return const [];
}

List<int> asIntList(dynamic v) {
  if (v is List) return v.map((e) => asInt(e)).toList();
  return const [];
}

List<String> asStrList(dynamic v) {
  if (v is List) return v.map((e) => asStr(e)).toList();
  return const [];
}

/// Decodes a base64 string, tolerating data-URI prefixes and whitespace.
Uint8List base64DecodeSafe(String value) {
  var s = value;
  final comma = s.indexOf(',');
  if (s.startsWith('data:') && comma != -1) s = s.substring(comma + 1);
  s = s.replaceAll(RegExp(r'\s'), '');
  return base64Decode(s);
}
