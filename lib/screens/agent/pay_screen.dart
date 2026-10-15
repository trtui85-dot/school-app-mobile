import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/image_upload.dart';
import '../../widgets/success_screen.dart';
import '../../widgets/ui.dart';

class PayScreen extends StatefulWidget {
  final int studentId;
  const PayScreen({super.key, required this.studentId});
  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _banks = [];
  final Set<int> _selected = {};
  String? _proof;
  int? _copiedBankIdx;
  String _error = '';
  bool _loading = true;
  bool _submitting = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await ApiClient.instance.get('/api/me/students/${widget.studentId}');
      final info = await ApiClient.instance.get('/api/public/register-info');
      if (!mounted) return;
      setState(() {
        _data = asMap(d['student']);
        _banks = asMapList(info['bankAccounts']);
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

  Future<void> _copyBank(int idx, String number) async {
    await Clipboard.setData(ClipboardData(text: number));
    setState(() => _copiedBankIdx = idx);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted && _copiedBankIdx == idx) setState(() => _copiedBankIdx = null);
  }

  Future<void> _submit() async {
    setState(() => _error = '');
    if (_selected.isEmpty) return setState(() => _error = tr('اختر شهرًا واحدًا على الأقل'));
    if (_proof == null) return setState(() => _error = tr('صورة إثبات الدفع مطلوبة'));
    setState(() => _submitting = true);
    try {
      for (final month in _selected) {
        await ApiClient.instance.post('/api/me/payments', body: {
          'studentId': widget.studentId,
          'type': 'MONTHLY',
          'month': month,
          'proofBase64': _proof,
          'proofMime': 'image/jpeg',
        });
      }
      setState(() => _done = true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.zinc50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(tr('دفع الرسوم الشهرية'), style: AppText.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.zinc700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _done
          ? SuccessScreen(
              title: tr('تم إرسال طلب توثيق الدفعة'),
              description: tr('تم إرسال طلب توثيق الدفعة للأشهر المحددة ({n}) بنجاح، وستوثّقه الإدارة في أقرب وقت. ستتوصل بإشعار فور التوثيق.', {
                'n': '${_selected.length}',
              }),
              doneLabel: tr('العودة إلى بطاقة التلميذ'),
              onDone: () => Navigator.pop(context),
            )
          : _loading
              ? const AppSpinner()
              : _error.isNotEmpty && _data == null
                  ? Padding(padding: const EdgeInsets.all(16), child: ErrorBox(_error, onRetry: _load))
                  : _form(),
    );
  }

  Widget _form() {
    final student = _data!;
    final section = student['section'] == null ? null : asMap(student['section']);
    final paid = asMapList(student['payments'])
        .where((p) => asStr(p['status']) == 'APPROVED')
        .map((p) => asIntOrNull(p['month']))
        .whereType<int>()
        .toSet();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${asStr(student['arabicFirstName'])} ${asStr(student['arabicLastName'])}',
          style: ar(18, FontWeight.w700, AppColors.foreground),
        ),
        if (section != null)
          Text('(${formatMoney(asInt(section['monthlyFee']))} / ${tr('شهر')})',
              style: mono(12, FontWeight.w400, AppColors.zinc500)),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${tr('اختر الشهر (السنة ')}${currentSchoolYear()})',
                  style: ar(14, FontWeight.w700, AppColors.zinc700)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.6,
                children: schoolMonths.map((m) {
                  final isPaid = paid.contains(m.num);
                  final isSelected = _selected.contains(m.num);
                  Color bg;
                  Color fg;
                  Color border;
                  if (isPaid) {
                    bg = AppColors.okSoft;
                    fg = AppColors.ok;
                    border = AppColors.ok.withValues(alpha: 0.3);
                  } else if (isSelected) {
                    bg = AppColors.accent;
                    fg = Colors.white;
                    border = AppColors.accent;
                  } else {
                    bg = Colors.white;
                    fg = AppColors.zinc600;
                    border = AppColors.zinc200;
                  }
                  return GestureDetector(
                    onTap: isPaid
                        ? null
                        : () => setState(() {
                              if (isSelected) {
                                _selected.remove(m.num);
                              } else {
                                _selected.add(m.num);
                              }
                            }),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        border: Border.all(color: border),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isPaid) ...[
                            const Icon(Icons.check, size: 14, color: AppColors.ok),
                            const SizedBox(width: 4),
                          ],
                          Text(tr(m.label), style: ar(12, FontWeight.w600, fg)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        if (_banks.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_outlined, size: 16, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(tr('حسابات المدرسة للتحويل'),
                        style: ar(14, FontWeight.w600, AppColors.zinc700)),
                  ],
                ),
                const SizedBox(height: 8),
                ..._banks.asMap().entries.map((e) => _bankRow(e.value, e.key)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        AppCard(child: ImageUpload(label: tr('صورة إثبات التحويل/الدفع'), onChange: (v) => _proof = v)),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          ErrorBox(_error),
        ],
        const SizedBox(height: 16),
        AppButton(
          text: '${tr('إرسال الدفعة (')}${_selected.length})',
          expand: true,
          loading: _submitting,
          onPressed: _submit,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _bankRow(Map<String, dynamic> b, int idx) {
    final number = asStr(b['number']);
    final logo = asStrOrNull(b['logo']);
    final copied = _copiedBankIdx == idx;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: copied ? AppColors.ok.withValues(alpha: 0.4) : AppColors.zinc100),
        ),
        child: Row(
          children: [
            if (logo != null)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 56,
                    height: 40,
                    color: Colors.white,
                    child: Image.memory(base64DecodeSafe(logo), fit: BoxFit.contain),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(asStr(b['bankName']), style: ar(12, FontWeight.w400, AppColors.zinc500)),
                  Text(number, style: mono(14, FontWeight.w600, AppColors.foreground)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _copyBank(idx, number),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: copied ? AppColors.okSoft : AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(copied ? Icons.check : Icons.copy,
                        size: 16, color: copied ? AppColors.ok : AppColors.accent),
                    if (!copied) ...[
                      const SizedBox(width: 4),
                      Text(tr('نسخ'), style: ar(12, FontWeight.w600, AppColors.accent)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
