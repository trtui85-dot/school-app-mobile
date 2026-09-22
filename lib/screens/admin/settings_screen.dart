import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/image_upload.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Map<String, dynamic>>? _accounts;
  final _schoolName = TextEditingController();
  final _adminPhone = TextEditingController();
  final _schoolYear = TextEditingController();

  final _bankName = TextEditingController();
  final _bankNumber = TextEditingController();
  final _holderName = TextEditingController();
  String? _bankLogo;
  bool _savingInfo = false;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _schoolName.dispose();
    _adminPhone.dispose();
    _schoolYear.dispose();
    _bankName.dispose();
    _bankNumber.dispose();
    _holderName.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final accounts = await ApiClient.instance.get('/api/admin/bank-accounts');
      final settings = await ApiClient.instance.get('/api/admin/settings');
      final m = asMap(settings['settings']);
      if (!mounted) return;
      _schoolName.text = asStr(m['schoolName']);
      _adminPhone.text = asStr(m['adminPhone']);
      _schoolYear.text = asStr(m['schoolYear']);
      setState(() => _accounts = asMapList(accounts['accounts']));
    } on ApiException catch (e) {
      if (mounted) {
        showToast(context, e.message, type: ToastType.error);
        setState(() => _accounts = []);
      }
    }
  }

  Future<void> _saveInfo() async {
    setState(() => _savingInfo = true);
    try {
      await ApiClient.instance.put('/api/admin/settings', body: {
        'schoolName': _schoolName.text.trim(),
        'adminPhone': _adminPhone.text.trim(),
        'schoolYear': _schoolYear.text.trim(),
      });
      if (mounted) showToast(context, 'تم حفظ بيانات المدرسة');
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _savingInfo = false);
    }
  }

  Future<void> _addBank() async {
    setState(() => _adding = true);
    try {
      await ApiClient.instance.post('/api/admin/bank-accounts', body: {
        'bankName': _bankName.text.trim(),
        'number': _bankNumber.text.trim(),
        'holderName': _holderName.text.trim().isEmpty ? null : _holderName.text.trim(),
        'logo': _bankLogo,
      });
      setState(() {
        _bankName.clear();
        _bankNumber.clear();
        _holderName.clear();
        _bankLogo = null;
      });
      if (mounted) {
        showToast(context, 'تم إضافة حساب بنكي');
        await _load();
      }
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _deleteBank(Map<String, dynamic> b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text('حذف حساب ${asStr(b['bankName'])}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.bad)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.delete('/api/admin/bank-accounts',
          query: {'id': asInt(b['id']).toString()});
      if (mounted) {
        showToast(context, 'تم حذف الحساب البنكي');
        await _load();
      }
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('الإعدادات', style: AppText.h1),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('بيانات المدرسة العامة', style: AppText.title),
                const SizedBox(height: 12),
                AppInput(label: 'اسم المدرسة', controller: _schoolName),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppInput(
                        label: 'رقم هاتف الإدارة (لزر الاتصال)',
                        controller: _adminPhone,
                        ltr: true,
                        number: true,
                        maxLength: 8,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppInput(
                        label: 'السنة الدراسية',
                        controller: _schoolYear,
                        ltr: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'حفظ',
                  expand: true,
                  loading: _savingInfo,
                  onPressed: _saveInfo,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_outlined, size: 18, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('رقم/أرقام بنكية معروضة للوكلاء', style: AppText.title),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppInput(hint: 'اسم البنك', controller: _bankName),
                const SizedBox(height: 10),
                AppInput(hint: 'رقم الحساب', controller: _bankNumber, ltr: true),
                const SizedBox(height: 10),
                AppInput(hint: 'الحامل', controller: _holderName),
                const SizedBox(height: 10),
                ImageUpload(label: 'شعار البنك (اختياري)', onChange: (v) => _bankLogo = v),
                const SizedBox(height: 12),
                AppButton(text: 'إضافة', expand: true, loading: _adding, onPressed: _addBank),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_accounts != null)
            ..._accounts!.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _bankRow(b),
                )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _bankRow(Map<String, dynamic> b) {
    final logo = asStrOrNull(b['logo']);
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (logo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 56,
                height: 40,
                color: Colors.white,
                child: Image.memory(base64DecodeSafe(logo), fit: BoxFit.contain),
              ),
            )
          else
            Container(
              width: 56,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.zinc100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('لا شعار', style: ar(10, FontWeight.w400, AppColors.zinc500)),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asStr(b['bankName']), style: AppText.semibold),
                Text(
                  '${asStr(b['number'])}${asStrOrNull(b['holderName']) != null ? " — ${asStr(b['holderName'])}" : ""}',
                  style: mono(12, FontWeight.w400, AppColors.zinc600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.bad),
            tooltip: 'حذف',
            onPressed: () => _deleteBank(b),
          ),
        ],
      ),
    );
  }
}