import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});
  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  List<Map<String, dynamic>>? _requests;
  bool _regOpen = true;
  String _regReason = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _requests = null);
    try {
      final d = await ApiClient.instance.get('/api/admin/requests');
      if (!mounted) return;
      setState(() => _requests = asMapList(d['requests']));
    } on ApiException catch (e) {
      if (mounted) {
        showToast(context, e.message, type: ToastType.error);
        setState(() => _requests = []);
      }
    }
    try {
      final d = await ApiClient.instance.get('/api/admin/registration');
      if (!mounted) return;
      final reg = asMap(d['registration']);
      setState(() {
        _regOpen = asStr(reg['open'], 'true').toLowerCase().contains('true');
        _regReason = asStrOrNull(reg['reason']) ?? '';
      });
    } on ApiException catch (_) {}
  }

  Future<void> _openRegistrationDialog({required bool stop}) async {
    final reasonCtrl = TextEditingController();
    String error = '';
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheet) {
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(stop ? 'إيقاف التسجيل حاليًا' : 'تفعيل التسجيل', style: AppText.h2),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: Text('إغلاق', style: ar(13, FontWeight.w600, AppColors.zinc500)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (stop) ...[
                      Text(
                        'سيظهر للوكيل عند محاولة تسجيل طفل جديد: «عذرًا، التسجيل متوقف حاليًا» ويظهر فوقه السبب.',
                        style: ar(13, FontWeight.w400, AppColors.zinc600),
                      ),
                      const SizedBox(height: 12),
                      AppTextarea(label: 'سبب التوقف (يظهر للوكيل)', controller: reasonCtrl),
                    ] else
                      Text(
                        'سيُسمح للتلاميذ الجدد بإرسال طلبات التسجيل من جديد.',
                        style: ar(13, FontWeight.w400, AppColors.zinc600),
                      ),
                    if (error.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(error, style: ar(13, FontWeight.w400, AppColors.bad)),
                    ],
                    const SizedBox(height: 16),
                    AppButton(
                      text: stop ? 'تأكيد إيقاف التسجيل' : 'تأكيد تفعيل التسجيل',
                      variant: stop ? AppButtonVariant.danger : AppButtonVariant.success,
                      expand: true,
                      loading: saving,
                      onPressed: () async {
                        if (stop && reasonCtrl.text.trim().isEmpty) {
                          setSheet(() => error = 'سبب توقف التسجيل مطلوب');
                          return;
                        }
                        setSheet(() {
                          error = '';
                          saving = true;
                        });
                        try {
                          await ApiClient.instance.put('/api/admin/registration', body: {
                            'open': !stop,
                            'reason': stop ? reasonCtrl.text.trim() : '',
                          });
                          if (!sheetContext.mounted) return;
                          Navigator.pop(sheetContext);
                          if (mounted) {
                            showToast(context, stop ? 'تم إيقاف التسجيل' : 'تم تفعيل التسجيل');
                          }
                          _load();
                        } on ApiException catch (e) {
                          setSheet(() {
                            error = e.message;
                            saving = false;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text('طلبات التسجيل', style: AppText.h1),
              const SizedBox(width: 8),
              Text('(${_requests?.length ?? 0})', style: mono(12, FontWeight.w400, AppColors.zinc400)),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('حالة التسجيل', style: AppText.label),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _regOpen ? AppColors.ok : AppColors.bad,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _regOpen ? 'التسجيل مفعل' : 'التسجيل موقف',
                            style: ar(13, FontWeight.w600,
                                _regOpen ? AppColors.ok : AppColors.bad),
                          ),
                        ],
                      ),
                      if (!_regOpen && _regReason.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('السبب: $_regReason',
                            style: ar(12, FontWeight.w400, AppColors.zinc600)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  text: _regOpen ? 'إيقاف التسجيل' : 'تفعيل التسجيل',
                  variant: _regOpen ? AppButtonVariant.danger : AppButtonVariant.success,
                  onPressed: () => _openRegistrationDialog(stop: _regOpen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_requests == null)
            const AppSpinner()
          else if (_requests!.isEmpty)
            AppCard(child: const AppEmpty(title: 'لا توجد طلبات بانتظار المراجعة'))
          else
            ..._requests!.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _requestCard(r),
                )),
        ],
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> r) {
    final section = r['section'] == null ? null : asMap(r['section']);
    final agent = r['agent'] == null ? null : asMap(r['agent']);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${asStr(r['arabicFirstName'])} ${asStr(r['arabicLastName'])}',
              style: ar(15, FontWeight.w700, AppColors.foreground)),
          const SizedBox(height: 4),
          Text(
            '${section == null ? "بدون قسم" : asStr(section['name'])} · الوكيل: ${agent == null ? "—" : asStr(agent['fullName'])} (${agent == null ? "" : asStr(agent['phone'])})',
            style: ar(12, FontWeight.w400, AppColors.zinc500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'قبول',
                  variant: AppButtonVariant.success,
                  onPressed: () => _openDecision(r, approve: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  text: 'رفض',
                  variant: AppButtonVariant.danger,
                  onPressed: () => _openDecision(r, approve: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openDecision(Map<String, dynamic> r, {required bool approve}) async {
    final payment = asMapList(r['payments']).isNotEmpty ? asMapList(r['payments']).first : null;
    Uint8List? proof;
    if (payment != null) {
      proof = await ApiClient.instance.fetchBytes('/api/admin/payments/${asInt(payment['id'])}/proof');
    }
    if (!mounted) return;

    final attendanceCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String error = '';
    bool loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            final section = r['section'] == null ? null : asMap(r['section']);
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
                    Row(
                      children: [
                        Expanded(
                          child: Text('${asStr(r['arabicFirstName'])} ${asStr(r['arabicLastName'])}',
                              style: AppText.h2),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: Text('إغلاق', style: ar(13, FontWeight.w600, AppColors.zinc500)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _detail('الفرنسية', '${asStr(r['frenchFirstName'])} ${asStr(r['frenchLastName'])}'.trim()),
                    _detail('رقم ريم', asStr(r['rimNumber'])),
                    _detail('الرقم الوطني', asStr(r['nationalNumber'])),
                    _detail('الهاتف', asStr(r['phone'])),
                    _detail('العنوان', asStr(r['address'])),
                    _detail('القسم',
                        '${section == null ? "—" : asStr(section['name'])}${section != null ? " (${formatMoney(asInt(section['registrationFee']))})" : ""}'),
                    if (proof != null) ...[
                      const SizedBox(height: 12),
                      Text('إثبات دفع رسوم التسجيل', style: AppText.label),
                      const SizedBox(height: 8),
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: AppColors.zinc50,
                          borderRadius: BorderRadius.circular(AppRadius.control),
                          border: Border.all(color: AppColors.zinc200),
                        ),
                        child: Image.memory(proof, fit: BoxFit.contain),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (approve)
                      AppInput(
                        label: 'رقم النداء (اختياري)',
                        hint: 'يُترك فارغًا إن لم يحدد',
                        controller: attendanceCtrl,
                        number: true,
                        ltr: true,
                      )
                    else
                      AppTextarea(
                        label: 'سبب الرفض (إجباري)',
                        controller: reasonCtrl,
                      ),
                    if (error.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(error, style: ar(13, FontWeight.w400, AppColors.bad)),
                    ],
                    const SizedBox(height: 16),
                    AppButton(
                      text: approve ? 'تأكيد القبول' : 'تأكيد الرفض',
                      variant: approve ? AppButtonVariant.success : AppButtonVariant.danger,
                      expand: true,
                      loading: loading,
                      onPressed: () async {
                        if (!approve && reasonCtrl.text.trim().isEmpty) {
                          setSheet(() => error = 'سبب الرفض إجباري');
                          return;
                        }
                        setSheet(() {
                          error = '';
                          loading = true;
                        });
                        try {
                          await ApiClient.instance.post(
                            '/api/admin/requests/${asInt(r['id'])}/decision',
                            body: {
                              'action': approve ? 'APPROVE' : 'REJECT',
                              'attendanceNumber': attendanceCtrl.text.trim().isEmpty
                                  ? null
                                  : int.tryParse(attendanceCtrl.text.trim()),
                              'rejectionReason': approve ? null : reasonCtrl.text.trim(),
                            },
                          );
                          if (!sheetContext.mounted) return;
                          Navigator.pop(sheetContext);
                          if (mounted) {
                            showToast(context, approve ? 'تم قبول طلب التسجيل' : 'تم رفض الطلب');
                          }
                          _load();
                        } on ApiException catch (e) {
                          setSheet(() {
                            error = e.message;
                            loading = false;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(label, style: ar(13, FontWeight.w500, AppColors.zinc500))),
          Expanded(child: Text(value.isEmpty ? '—' : value, style: AppText.body)),
        ],
      ),
    );
  }
}
