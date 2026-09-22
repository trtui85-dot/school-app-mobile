import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/success_screen.dart';
import '../../widgets/ui.dart';
import '../../widgets/toast.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});
  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  List<Map<String, dynamic>>? _complaints;
  String _error = '';
  bool _loading = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await ApiClient.instance.get('/api/me/complaints');
      if (!mounted) return;
      setState(() => _complaints = asMapList(d['complaints']));
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, type: ToastType.error);
      if (mounted) setState(() => _complaints ??= []);
    }
  }

  Future<void> _submit() async {
    setState(() => _error = '');
    if (_title.text.trim().length < 3) return setState(() => _error = 'العنوان مطلوب');
    if (_content.text.trim().length < 5) return setState(() => _error = 'نص الرسالة مطلوب');
    setState(() => _loading = true);
    try {
      await ApiClient.instance.post('/api/me/complaints', body: {
        'title': _title.text.trim(),
        'content': _content.text.trim(),
      });
      setState(() => _done = true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return SuccessScreen(
        title: 'تم إرسال رسالتكم',
        description: 'تم إرسال رسالتك إلى الإدارة بنجاح، وسيتم الرد عليها في أقرب وقت.',
        doneLabel: 'متابعة',
        onDone: () {
          _title.clear();
          _content.clear();
          setState(() => _done = false);
          _load();
        },
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('التواصل مع الإدارة', style: AppText.h1),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: [
              AppInput(label: 'عنوان الشكوى/الطلب', controller: _title),
              const SizedBox(height: 12),
              AppTextarea(label: 'نص الرسالة', controller: _content),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(_error, style: ar(13, FontWeight.w400, AppColors.bad)),
                ),
              ],
              const SizedBox(height: 12),
              AppButton(text: 'إرسال إلى الإدارة', expand: true, loading: _loading, onPressed: _submit),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if ((_complaints ?? []).isNotEmpty) ...[
          Align(
            alignment: Alignment.centerRight,
            child: Text('شكواي السابقة', style: AppText.title),
          ),
          const SizedBox(height: 8),
          ..._complaints!.map((c) {
            final status = asStr(c['status'], 'NEW');
            final label = status == 'ANSWERED'
                ? 'تم الرد'
                : status == 'PROCESSING'
                    ? 'قيد المعالجة'
                    : 'جديدة';
            final tone = status == 'ANSWERED'
                ? BadgeTone.ok
                : status == 'PROCESSING'
                    ? BadgeTone.neutral
                    : BadgeTone.pending;
            final reply = asStrOrNull(c['reply']);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(asStr(c['title']), style: AppText.semibold)),
                        AppBadge(label, tone: tone),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                          text: TextSpan(
                            children: [
                              TextSpan(text: 'رد الإدارة: ', style: ar(12, FontWeight.w600, AppColors.ok)),
                              TextSpan(text: reply, style: ar(12, FontWeight.w400, AppColors.zinc700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(formatArabicDateTime(c['createdAt']), style: AppText.tiny),
                  ],
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
