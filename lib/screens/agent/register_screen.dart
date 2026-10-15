import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/image_upload.dart';
import '../../widgets/sections_picker.dart';
import '../../widgets/success_screen.dart';
import '../../widgets/ui.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onDone;
  const RegisterScreen({super.key, required this.onDone});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  List<SectionOption> _sections = [];
  List<Map<String, dynamic>> _banks = [];
  int? _sectionId;
  bool _loadingInfo = true;
  bool _submitting = false;
  bool _done = false;
  bool _regOpen = true;
  String _regReason = '';
  String _error = '';
  String? _proof;
  int? _copiedBankIdx;

  final _arabicFirst = TextEditingController();
  final _arabicLast = TextEditingController();
  final _frenchFirst = TextEditingController();
  final _frenchLast = TextEditingController();
  final _rim = TextEditingController();
  final _national = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _arabicFirst.dispose();
    _arabicLast.dispose();
    _frenchFirst.dispose();
    _frenchLast.dispose();
    _rim.dispose();
    _national.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await ApiClient.instance.get('/api/public/register-info');
      final reg = asMap(d['registration']);
      setState(() {
        _regOpen = asStr(reg['open'], 'true').toLowerCase().contains('true');
        _regReason = asStrOrNull(reg['reason']) ?? '';
        _sections = asMapList(d['sections'])
            .map((s) => SectionOption(
                  id: asInt(s['id']),
                  name: asStr(s['name']),
                  registrationFee: asInt(s['registrationFee']),
                  monthlyFee: asInt(s['monthlyFee']),
                ))
            .toList();
        _banks = asMapList(d['bankAccounts']);
        _loadingInfo = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loadingInfo = false;
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
    if (!_regOpen) return setState(() => _error = tr('التسجيل متوقف حاليًا'));
    if (_sectionId == null) return setState(() => _error = tr('اختر القسم المطلوب'));
    if (_arabicFirst.text.trim().length < 2 || _arabicLast.text.trim().length < 2) {
      return setState(() => _error = tr('الاسم واللقب بالعربية مطلوبان'));
    }
    if (_proof == null) return setState(() => _error = tr('صورة إثبات دفع رسوم التسجيل مطلوبة'));
    setState(() => _submitting = true);
    try {
      await ApiClient.instance.post('/api/me/students', body: {
        'sectionId': _sectionId,
        'proofBase64': _proof,
        'proofMime': 'image/jpeg',
        'arabicFirstName': _arabicFirst.text.trim(),
        'arabicLastName': _arabicLast.text.trim(),
        'frenchFirstName': _frenchFirst.text.trim().isEmpty ? null : _frenchFirst.text.trim(),
        'frenchLastName': _frenchLast.text.trim().isEmpty ? null : _frenchLast.text.trim(),
        'rimNumber': _rim.text.trim().isEmpty ? null : _rim.text.trim(),
        'nationalNumber': _national.text.trim().isEmpty ? null : _national.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
      });
      setState(() => _done = true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return SuccessScreen(
        title: tr('تم إرسال طلب التسجيل'),
        description: tr('تم إرسال طلب تسجيل التلميذ بنجاح، وستوثّقه الإدارة في أقرب وقت. ستتوصل بإشعار فور البتّ فيه.'),
        doneLabel: tr('العودة إلى الرئيسية'),
        onDone: () {
          _reset();
          widget.onDone();
        },
      );
    }

    if (_loadingInfo) return const AppSpinner();

    if (!_regOpen) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tr('تسجيل طفل جديد'), style: AppText.h1),
          const SizedBox(height: 16),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              child: Column(
                children: [
                  const Icon(Icons.pause_circle_outline, size: 56, color: AppColors.bad),
                  const SizedBox(height: 12),
                  Text(
                    tr('عذرًا، التسجيل متوقف حاليًا'),
                    textAlign: TextAlign.center,
                    style: ar(16, FontWeight.w700, AppColors.foreground),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _regReason.isNotEmpty
                        ? _regReason
                        : tr('يُستأنف التسجيل عندما تُعلن الإدارة ذلك.'),
                    textAlign: TextAlign.center,
                    style: ar(13, FontWeight.w400, AppColors.zinc600),
                  ),
                  const SizedBox(height: 16),
                  AppButton(text: tr('إعادة المحاولة'), expand: true, onPressed: _load),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(tr('تسجيل طفل جديد'), style: AppText.h1),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionsPicker(sections: _sections, value: _sectionId, onChange: (id) => setState(() => _sectionId = id)),
              if (_banks.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.account_balance_outlined, size: 16, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(tr('حسابات المدرسة للتحويل'), style: ar(14, FontWeight.w600, AppColors.zinc700)),
                  ],
                ),
                const SizedBox(height: 8),
                ..._banks.asMap().entries.map((e) => _bankRow(e.value, e.key)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('بيانات التلميذ'), style: ar(14, FontWeight.w700, AppColors.zinc700)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: AppInput(label: tr('الاسم بالعربية'), controller: _arabicFirst, rtl: true)),
                const SizedBox(width: 12),
                Expanded(child: AppInput(label: tr('اللقب بالعربية'), controller: _arabicLast, rtl: true)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: AppInput(label: 'Prenom (français)', controller: _frenchFirst, ltr: true)),
                const SizedBox(width: 12),
                Expanded(child: AppInput(label: 'Nom (français)', controller: _frenchLast, ltr: true)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: AppInput(label: tr('رقم ريم'), controller: _rim, ltr: true)),
                const SizedBox(width: 12),
                Expanded(child: AppInput(label: tr('الرقم الوطني'), controller: _national, ltr: true)),
              ]),
              const SizedBox(height: 12),
              AppInput(
                label: tr('رقم هاتف ولي الأمر'),
                hint: 'XXXXXXXX',
                controller: _phone,
                ltr: true,
                number: true,
                maxLength: 8,
              ),
              const SizedBox(height: 12),
              AppInput(label: tr('العنوان'), controller: _address),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(child: ImageUpload(label: tr('صورة إثبات دفع رسوم التسجيل'), onChange: (v) => _proof = v)),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          ErrorBox(_error),
        ],
        const SizedBox(height: 16),
        AppButton(text: tr('إرسال طلب التسجيل'), expand: true, loading: _submitting, onPressed: _submit),
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
                    Icon(copied ? Icons.check : Icons.copy, size: 16, color: copied ? AppColors.ok : AppColors.accent),
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

  void _reset() {
    _arabicFirst.clear();
    _arabicLast.clear();
    _frenchFirst.clear();
    _frenchLast.clear();
    _rim.clear();
    _national.clear();
    _phone.clear();
    _address.clear();
    setState(() {
      _done = false;
      _sectionId = null;
      _proof = null;
      _error = '';
    });
  }
}
