import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Map<String, dynamic>>? _payments;
  List<Map<String, dynamic>>? _sections;
  int? _sectionId;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _load();
    _loadSections();
  }

  Future<void> _loadSections() async {
    try {
      final d = await ApiClient.instance.get('/api/admin/sections');
      if (!mounted) return;
      setState(() => _sections = asMapList(d['sections']));
    } on ApiException catch (_) {}
  }

  Future<void> _load() async {
    if (mounted) setState(() => _payments = null);
    try {
      final d = await ApiClient.instance.get('/api/admin/payments',
          query: {
            if (_status.isNotEmpty) 'status': _status,
            if (_sectionId != null) 'sectionId': _sectionId.toString(),
          });
      if (!mounted) return;
      setState(() => _payments = asMapList(d['payments']));
    } on ApiException catch (e) {
      if (mounted) {
        showToast(context, e.message, type: ToastType.error);
        setState(() => _payments = []);
      }
    }
  }

  BadgeTone _tone(String s) =>
      s == 'APPROVED' ? BadgeTone.ok : s == 'REJECTED' ? BadgeTone.bad : BadgeTone.pending;
  String _label(String s) =>
      s == 'APPROVED' ? 'موثقة' : s == 'REJECTED' ? 'مرفوضة' : 'بانتظار التوثيق';

  @override
  Widget build(BuildContext context) {
    const filters = [['', 'الكل'], ['PENDING', 'بانتظار التوثيق'], ['APPROVED', 'موثقة'], ['REJECTED', 'مرفوضة']];
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('الدفعات', style: AppText.h1),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.zinc100,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Row(
              children: filters.map((f) {
                final active = _status == f[0];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _status = f[0]);
                      _load();
                    },
                    child: Container(
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: active
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)]
                            : null,
                      ),
                      child: Text(f[1],
                          style: ar(12, FontWeight.w600,
                              active ? AppColors.foreground : AppColors.zinc500)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: AppSelectField<int>(
              label: 'القسم',
              placeholder: '— كل الأقسام —',
              value: _sectionId,
              options: [
                const AppSelectOption(0, 'كل الأقسام'),
                for (final s in _sections ?? []) AppSelectOption(asInt(s['id']), asStr(s['name'])),
              ],
              onChanged: (v) {
                setState(() => _sectionId = v == 0 ? null : v);
                _load();
              },
            ),
          ),
          const SizedBox(height: 16),
          if (_payments == null)
            const AppSpinner()
          else if (_payments!.isEmpty)
            AppCard(child: const AppEmpty(title: 'لا توجد دفعات'))
          else
            ..._payments!.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _paymentCard(p),
                )),
        ],
      ),
    );
  }

  Widget _paymentCard(Map<String, dynamic> p) {
    final student = asMap(p['student']);
    final section = student['section'] == null ? null : asMap(student['section']);
    final agent = student['agent'] == null ? null : asMap(student['agent']);
    final status = asStr(p['status'], 'PENDING');
    final type = asStr(p['type']);
    final month = asIntOrNull(p['month']);
    final typeLabel = type == 'REGISTRATION'
        ? 'رسوم التسجيل'
        : 'شهر ${monthLabel(month ?? 0)} (${asStr(p['schoolYear'])})';
    final attendance = asIntOrNull(student['attendanceNumber']);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${asStr(student['arabicFirstName'])} ${asStr(student['arabicLastName'])}',
                  style: ar(15, FontWeight.w700, AppColors.foreground),
                ),
              ),
              if (attendance != null)
                Text('#$attendance', style: mono(12, FontWeight.w400, AppColors.zinc500)),
              const SizedBox(width: 8),
              AppBadge(_label(status), tone: _tone(status)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$typeLabel · ${section == null ? "" : asStr(section['name'])} · ${agent == null ? "" : asStr(agent['fullName'])}',
            style: ar(12, FontWeight.w400, AppColors.zinc500),
          ),
          const SizedBox(height: 4),
          Text(formatMoney(asInt(p['amount'])), style: mono(13, FontWeight.w600, AppColors.accent)),
          const SizedBox(height: 10),
          AppButton(
            text: 'مراجعة',
            expand: true,
            onPressed: () => _openReview(p),
          ),
        ],
      ),
    );
  }

  Future<void> _openReview(Map<String, dynamic> p) async {
    Uint8List? proof =
        await ApiClient.instance.fetchBytes('/api/admin/payments/${asInt(p['id'])}/proof');
    if (!mounted) return;

    final reasonCtrl = TextEditingController();
    String error = '';
    bool loading = false;
    String status = asStr(p['status'], 'PENDING');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) {
          final student = asMap(p['student']);
          final type = asStr(p['type']);
          final month = asIntOrNull(p['month']);
          final typeLabel = type == 'REGISTRATION'
              ? 'رسوم التسجيل'
              : 'شهر ${monthLabel(month ?? 0)}';
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${asStr(student['arabicFirstName'])} ${asStr(student['arabicLastName'])}',
                    style: AppText.h2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$typeLabel · ${formatMoney(asInt(p['amount']))} · ${formatArabicDate(p['createdAt'])}',
                    style: ar(12, FontWeight.w400, AppColors.zinc500),
                  ),
                  const SizedBox(height: 12),
                  if (proof != null)
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        color: AppColors.zinc50,
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        border: Border.all(color: AppColors.zinc200),
                      ),
                      child: Image.memory(proof, fit: BoxFit.contain),
                    ),
                  const SizedBox(height: 16),
                  if (loading) ...[
                    const AppSpinner(),
                  ] else if (status == 'APPROVED') ...[
                    Center(child: AppBadge('موثقة', tone: BadgeTone.ok)),
                  ] else if (status == 'REJECTED') ...[
                    Center(child: AppBadge('مرفوضة', tone: BadgeTone.bad)),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'توثيق / قبول',
                            variant: AppButtonVariant.success,
                            onPressed: () => _decide(
                              p,
                              action: 'APPROVE',
                              reason: null,
                              sheetContext: sheetContext,
                              setSheet: setSheet,
                              setStatus: (s) => status = s,
                              onError: (e) => error = e,
                              setLoading: (l) => loading = l,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            text: 'رفض',
                            variant: AppButtonVariant.danger,
                            onPressed: () => setSheet(() => status = 'REJECTING'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (status == 'REJECTING') ...[
                    AppTextarea(
                      label: 'سبب الرفض (إجباري)',
                      controller: reasonCtrl,
                    ),
                    if (error.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(error, style: ar(13, FontWeight.w400, AppColors.bad)),
                    ],
                    const SizedBox(height: 12),
                    AppButton(
                      text: 'تأكيد الرفض',
                      variant: AppButtonVariant.danger,
                      expand: true,
                      loading: loading,
                      onPressed: () {
                        if (reasonCtrl.text.trim().isEmpty) {
                          setSheet(() => error = 'سبب الرفض إجباري');
                          return;
                        }
                        _decide(
                          p,
                          action: 'REJECT',
                          reason: reasonCtrl.text.trim(),
                          sheetContext: sheetContext,
                          setSheet: setSheet,
                          setStatus: (s) => status = s,
                          onError: (e) => error = e,
                          setLoading: (l) => loading = l,
                        );
                      },
                    ),
                  ],
                  if (status == 'PENDING' && error.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(error, style: ar(13, FontWeight.w400, AppColors.bad)),
                  ],
                  if (status == 'PENDING' && loading) const AppSpinner(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _decide(
    Map<String, dynamic> p, {
    required String action,
    required String? reason,
    required BuildContext sheetContext,
    required void Function(VoidCallback) setSheet,
    required ValueChanged<String> setStatus,
    required ValueChanged<String> onError,
    required ValueChanged<bool> setLoading,
  }) async {
    setSheet(() => setLoading(true));
    try {
      await ApiClient.instance.post(
        '/api/admin/payments/${asInt(p['id'])}/decision',
        body: {'action': action, 'rejectionReason': reason},
      );
      if (!sheetContext.mounted) return;
      Navigator.pop(sheetContext);
      if (mounted) {
        showToast(context, action == 'APPROVE' ? 'تم توثيق الدفعة بنجاح' : 'تم رفض الدفعة');
      }
      _load();
    } on ApiException catch (e) {
      setSheet(() {
        setLoading(false);
        onError(e.message);
      });
    }
  }
}
