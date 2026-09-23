import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/api_client.dart';
import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import 'logo.dart';
import 'toast.dart';
import 'ui.dart';

class ReceiptScreen extends StatefulWidget {
  final int paymentId;
  const ReceiptScreen({super.key, required this.paymentId});
  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final _sheetKey = GlobalKey();
  Map<String, dynamic>? _payment;
  String _schoolName = 'مدارس اقرأ الحديثة';
  String _error = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await ApiClient.instance.get('/api/me/receipt/${widget.paymentId}');
      if (!mounted) return;
      setState(() {
        _payment = asMap(d['payment']);
        _schoolName = asStr(d['schoolName'], 'مدارس اقرأ الحديثة');
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<Uint8List?> _capture() async {
    final boundary = _sheetKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> _download() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final bytes = await _capture();
      if (bytes == null) return;
      if (!await Gal.hasAccess()) await Gal.requestAccess();
      await Gal.putImageBytes(bytes, name: 'receipt-${widget.paymentId}');
      if (mounted) showToast(context, tr('تم حفظ الإيصال في المعرض'));
    } catch (_) {
      if (mounted) showToast(context, tr('تعذر حفظ الصورة'), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _print() async {
    try {
      final bytes = await _capture();
      if (bytes == null) return;
      final doc = pw.Document();
      final img = pw.MemoryImage(bytes);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain)),
        ),
      );
      await Printing.layoutPdf(onLayout: (_) async => doc.save());
    } catch (_) {
      if (mounted) showToast(context, tr('تعذرت الطباعة'), type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.zinc100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(tr('إيصال الدفع'), style: AppText.h2),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.zinc700),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_payment != null)
            TextButton.icon(
              onPressed: _download,
              icon: _saving
                  ? const SizedBox(
                      width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download, size: 18),
              label: Text(tr('تحميل'), style: ar(13, FontWeight.w600, AppColors.accent)),
            ),
          if (_payment != null)
            TextButton.icon(
              onPressed: _print,
              icon: const Icon(Icons.print, size: 18),
              label: Text(tr('طباعة'), style: ar(13, FontWeight.w600, AppColors.accent)),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _error.isNotEmpty
          ? Padding(padding: const EdgeInsets.all(16), child: ErrorBox(_error, onRetry: _load))
          : _payment == null
              ? const AppSpinner()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: RepaintBoundary(
                      key: _sheetKey,
                      child: Container(
                        width: 420,
                        color: Colors.white,
                        padding: const EdgeInsets.all(20),
                        child: _sheet(),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _sheet() {
    final p = _payment!;
    final student = asMap(p['student']);
    final section = student['section'] == null ? null : asMap(student['section']);
    final isMonthly = asStr(p['type']) == 'MONTHLY';
    final month = asIntOrNull(p['month']);
    final typeLabel = isMonthly
        ? '${tr('رسوم شهر ')}${monthLabel(month ?? 0)} (${asStr(p['schoolYear'])})'
        : tr('رسوم التسجيل');
    final verifiedAt = asStrOrNull(p['verifiedAt']);

    Widget row(String label, String value, {bool useMono = false, Color? color, bool last = false}) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.zinc200, width: 0.6)),
        ),
        child: Row(
          children: [
            Text(label, style: ar(13, FontWeight.w400, AppColors.zinc600)),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.left,
                style: useMono
                    ? mono(13, FontWeight.w600, color ?? AppColors.foreground)
                    : ar(13, FontWeight.w700, color ?? AppColors.foreground),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
          ),
          child: Row(
            children: [
              const Spacer(),
              Column(
                children: [
                  Text(_schoolName, style: ar(22, FontWeight.w700, AppColors.foreground)),
                  const SizedBox(height: 4),
                  Text(tr('إيصال دفع'), style: ar(14, FontWeight.w400, AppColors.foreground)),
                ],
              ),
              const Spacer(),
              const AppLogo(size: 56, withName: false),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '${tr('رقم الإيصال: ')}${asInt(p['id']).toString().padLeft(5, '0')}',
          textAlign: TextAlign.center,
          style: mono(12, FontWeight.w400, AppColors.zinc500),
        ),
        const SizedBox(height: 16),
        Container(
          width: 360,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.zinc200),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            children: [
              row(tr('التلميذ'),
                  '${asStr(student['arabicFirstName'])} ${asStr(student['arabicLastName'])}'),
              row(tr('القسم'), section == null ? '—' : asStr(section['name'])),
              row(tr('نوع الدفع'), typeLabel),
              row(tr('المبلغ'), formatMoney(asInt(p['amount'])), useMono: true),
              row(tr('حالة الدفع'), tr('موثقة'), color: AppColors.ok),
              row(tr('تاريخ التوثيق'),
                  verifiedAt == null ? '—' : formatArabicDate(verifiedAt)),
              row(tr('بيان الولي'), asStrOrNull(p['verifiedByName']) ?? tr('الإدارة'), last: true),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '${tr('شكرًا لثقتكم بـ')}$_schoolName',
          textAlign: TextAlign.center,
          style: ar(12, FontWeight.w400, AppColors.zinc600),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.only(top: 8),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.black)),
          ),
          child: Row(
            children: [
              Text(tr('الختم والتوقيع'), style: ar(12, FontWeight.w400, AppColors.foreground)),
              const Spacer(),
              Text(formatArabicDate(DateTime.now()), style: ar(12, FontWeight.w400, AppColors.foreground)),
            ],
          ),
        ),
      ],
    );
  }
}
