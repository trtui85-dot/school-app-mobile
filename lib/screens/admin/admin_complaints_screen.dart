import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});
  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  List<Map<String, dynamic>>? _complaints;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _complaints = null);
    try {
      final d = await ApiClient.instance.get('/api/admin/complaints');
      if (!mounted) return;
      setState(() => _complaints = asMapList(d['complaints']));
    } on ApiException catch (e) {
      if (mounted) {
        showToast(context, e.message, type: ToastType.error);
        setState(() => _complaints = []);
      }
    }
  }

  BadgeTone _tone(String s) =>
      s == 'ANSWERED' ? BadgeTone.ok : s == 'PROCESSING' ? BadgeTone.neutral : BadgeTone.pending;
  String _label(String s) =>
      s == 'ANSWERED' ? 'تم الرد' : s == 'PROCESSING' ? 'قيد المعالجة' : 'جديدة';

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('الشكاوى والطلبات', style: AppText.h1),
          const SizedBox(height: 16),
          if (_complaints == null)
            const AppSpinner()
          else if (_complaints!.isEmpty)
            AppCard(child: const AppEmpty(title: 'لا توجد شكاوى'))
          else
            ..._complaints!.map((c) {
              final status = asStr(c['status'], 'NEW');
              final agent = c['agent'] == null ? null : asMap(c['agent']);
              final reply = asStrOrNull(c['reply']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(asStr(c['title']), style: AppText.h2)),
                          AppBadge(_label(status), tone: _tone(status)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${agent == null ? "—" : asStr(agent['fullName'])} · ${agent == null ? "" : asStr(agent['phone'])} · ${formatArabicDate(c['createdAt'])}',
                        style: ar(12, FontWeight.w400, AppColors.zinc500),
                      ),
                      const SizedBox(height: 8),
                      Text(asStr(c['content']), style: ar(14, FontWeight.w400, AppColors.zinc600)),
                      if (reply != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.okSoft,
                            borderRadius: BorderRadius.circular(AppRadius.control),
                          ),
                          child: RichText(
                            text: TextSpan(children: [
                              TextSpan(text: 'الرد: ', style: ar(12, FontWeight.w600, AppColors.ok)),
                              TextSpan(text: reply, style: ar(12, FontWeight.w400, AppColors.zinc700)),
                            ]),
                          ),
                        ),
                      ],
                      if (status != 'ANSWERED') ...[
                        const SizedBox(height: 10),
                        AppButton(
                          text: 'الرد',
                          expand: true,
                          onPressed: () => _reply(c, reply),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _reply(Map<String, dynamic> c, String? initial) async {
    final ctrl = TextEditingController(text: initial ?? '');
    String error = '';
    bool loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
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
                Text(asStr(c['title']), style: AppText.h2),
                const SizedBox(height: 8),
                Text(asStr(c['content']), style: ar(14, FontWeight.w400, AppColors.zinc600)),
                const SizedBox(height: 16),
                AppTextarea(label: 'الرد', controller: ctrl),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(error, style: ar(13, FontWeight.w400, AppColors.bad)),
                ],
                const SizedBox(height: 12),
                AppButton(
                  text: 'إرسال الرد',
                  expand: true,
                  loading: loading,
                  onPressed: () async {
                    if (ctrl.text.trim().isEmpty) {
                      setSheet(() => error = 'الرد مطلوب');
                      return;
                    }
                    setSheet(() {
                      error = '';
                      loading = true;
                    });
                    try {
                      await ApiClient.instance.post(
                        '/api/admin/complaints/${asInt(c['id'])}',
                        body: {'reply': ctrl.text.trim()},
                      );
                      if (!sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                      if (mounted) showToast(context, 'تم إرسال الرد إلى الوكيل');
                      _load();
                    } on ApiException catch (e) {
                      setSheet(() {
                        error = e.message;
                        loading = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                AppButton(
                  text: 'إلغاء',
                  variant: AppButtonVariant.ghost,
                  expand: true,
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
