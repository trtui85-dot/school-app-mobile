import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});
  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  final _searchCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _selected;
  List<Map<String, dynamic>> _notes = [];
  bool _searching = false;
  bool _loadingNotes = false;
  bool _submitting = false;
  String _error = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_searchCtrl.text.trim().isEmpty) return;
    setState(() {
      _searching = true;
      _results = [];
    });
    try {
      final d = await ApiClient.instance.get('/api/admin/students',
          query: {'q': _searchCtrl.text.trim()});
      if (!mounted) return;
      setState(() {
        _results = asMapList(d['students']);
        _searching = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = e.message;
      });
    }
  }

  Future<void> _loadNotes() async {
    if (_selected == null) return;
    setState(() => _loadingNotes = true);
    try {
      final d = await ApiClient.instance.get('/api/admin/notes',
          query: {'studentId': asInt(_selected!['id']).toString()});
      if (!mounted) return;
      setState(() {
        _notes = asMapList(d['notes']);
        _loadingNotes = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadingNotes = false);
      showToast(context, e.message, type: ToastType.error);
    }
  }

  Future<void> _send() async {
    setState(() => _error = '');
    if (_contentCtrl.text.trim().length < 2) {
      return setState(() => _error = 'محتوى الرسالة مطلوب');
    }
    setState(() => _submitting = true);
    try {
      await ApiClient.instance.post('/api/admin/notes', body: {
        'studentId': asInt(_selected!['id']),
        'content': _contentCtrl.text.trim(),
      });
      _contentCtrl.clear();
      if (mounted) showToast(context, 'تم إرسال الملاحظة');
      _loadNotes();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('رسائل / ملاحظات للوكلاء', style: AppText.h1),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اختر التلميذ', style: AppText.title),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppInput(
                      hint: 'بحث بالاسم أو رقم النداء...',
                      controller: _searchCtrl,
                      onSubmitted: _search,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppButton(text: 'بحث', onPressed: _search),
                ],
              ),
              const SizedBox(height: 12),
              if (_searching)
                const AppSpinner()
              else if (_results.isEmpty && _searchCtrl.text.isNotEmpty && _error.isEmpty)
                Text('لا توجد نتائج', style: AppText.small)
              else if (_error.isNotEmpty)
                Text(_error, style: ar(13, FontWeight.w400, AppColors.bad))
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (_, i) {
                      final st = _results[i];
                      final section = st['section'] == null ? null : asMap(st['section']);
                      final agent = st['agent'] == null ? null : asMap(st['agent']);
                      final sel = _selected != null && asInt(st['id']) == asInt(_selected!['id']);
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selected = st);
                          _loadNotes();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.accentSoft : Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.control),
                            border: Border.all(
                                color: sel ? AppColors.accent : AppColors.zinc200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${asStr(st['arabicFirstName'])} ${asStr(st['arabicLastName'])}',
                                      style: ar(14, FontWeight.w600, AppColors.foreground),
                                    ),
                                    Text(
                                      '${section == null ? "" : asStr(section['name'])} · ${agent == null ? "" : asStr(agent['fullName'])}',
                                      style: ar(12, FontWeight.w400, AppColors.zinc500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        if (_selected != null) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملاحظة عن ${asStr(_selected!['arabicFirstName'])} ${asStr(_selected!['arabicLastName'])}',
                  style: AppText.title,
                ),
                const SizedBox(height: 12),
                AppTextarea(
                  hint: 'مثال: لم يحفظ الدرس اليوم',
                  controller: _contentCtrl,
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_error, style: ar(13, FontWeight.w400, AppColors.bad)),
                ],
                const SizedBox(height: 12),
                AppButton(
                  text: 'إرسال إلى الوكيل',
                  expand: true,
                  loading: _submitting,
                  onPressed: _send,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الرسائل السابقة', style: AppText.title),
                const SizedBox(height: 12),
                if (_loadingNotes)
                  const AppSpinner()
                else if (_notes.isEmpty)
                  const AppEmpty(title: 'لا توجد رسائل سابقة')
                else
                  ..._notes.map((n) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(asStr(n['content']), style: ar(14, FontWeight.w400, AppColors.foreground)),
                            const SizedBox(height: 2),
                            Text(formatArabicDate(n['createdAt']), style: AppText.tiny),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
