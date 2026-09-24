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
  final _groupCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>>? _sections;
  int? _sectionId;
  Map<String, dynamic>? _selected;
  List<Map<String, dynamic>> _notes = [];
  bool _searching = false;
  bool _loadingNotes = false;
  bool _submitting = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _contentCtrl.dispose();
    _groupCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSections() async {
    try {
      final d = await ApiClient.instance.get('/api/admin/sections');
      if (!mounted) return;
      setState(() => _sections = asMapList(d['sections']));
    } on ApiException catch (_) {}
  }

  void _onSectionChanged(int? raw) {
    _sectionId = raw == 0 ? null : raw;
    setState(() {});
    _search();
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty && _sectionId == null) {
      setState(() => _results = []);
      return;
    }
    setState(() {
      _searching = true;
      _results = [];
    });
    try {
      final d = await ApiClient.instance.get('/api/admin/students', query: {
        if (_sectionId != null) 'sectionId': _sectionId.toString(),
        if (q.isNotEmpty) 'q': q,
      });
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
    if (_selected == null) return setState(() => _error = 'اختر التلميذ أولًا');
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

  Future<void> _broadcastSheet({
    required String title,
    required Map<String, dynamic> Function(String content) bodyBuilder,
  }) async {
    _groupCtrl.clear();
    String error = '';
    bool sending = false;
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
                          child: Text(title, style: AppText.h2),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: Text('إغلاق', style: ar(13, FontWeight.w600, AppColors.zinc500)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ستصلك الرسالة مع إشعار فوري لجميع أولياء الأمور المستهدفين.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                    ),
                    const SizedBox(height: 12),
                    AppTextarea(hint: 'مثال: اجتماع أولياء الأمور هذا السبت...', controller: _groupCtrl),
                    if (error.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(error, style: ar(13, FontWeight.w400, AppColors.bad)),
                    ],
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'إرسال الرسالة',
                      expand: true,
                      loading: sending,
                      onPressed: () async {
                        if (_groupCtrl.text.trim().length < 2) {
                          setSheet(() => error = 'محتوى الرسالة مطلوب');
                          return;
                        }
                        setSheet(() {
                          error = '';
                          sending = true;
                        });
                        try {
                          final d = await ApiClient.instance.post('/api/admin/messages',
                              body: bodyBuilder(_groupCtrl.text.trim()));
                          if (!sheetContext.mounted) return;
                          Navigator.pop(sheetContext);
                          if (mounted) {
                            showToast(context,
                                'تم إرسال الرسالة إلى ${asInt(d['sent'])} ${asInt(d['sent']) == 1 ? 'تلميذ' : 'تلاميذ'}');
                          }
                        } on ApiException catch (e) {
                          setSheet(() {
                            error = e.message;
                            sending = false;
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
    final sectionOptions = <AppSelectOption<int>>[
      const AppSelectOption(0, 'كل الأقسام'),
      for (final s in _sections ?? []) AppSelectOption(asInt(s['id']), asStr(s['name'])),
    ];

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
              AppSelectField<int>(
                label: 'القسم (اختياري)',
                placeholder: '— الكل —',
                value: _sectionId,
                options: sectionOptions,
                onChanged: _onSectionChanged,
              ),
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
              else if (_results.isEmpty && (_searchCtrl.text.isNotEmpty || _sectionId != null))
                Text('لا توجد نتائج', style: AppText.small)
              else if (_error.isNotEmpty)
                Text(_error, style: ar(13, FontWeight.w400, AppColors.bad))
              else if (_results.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
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
                            border: Border.all(color: sel ? AppColors.accent : AppColors.zinc200),
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
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('رسالة جماعية', style: AppText.title),
              const SizedBox(height: 12),
              AppSelectField<int>(
                label: 'القسم المستهدف',
                placeholder: '— كل الأقسام —',
                value: _sectionId,
                options: sectionOptions,
                onChanged: _onSectionChanged,
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'إرسال رسالة إلى جميع أولياء الأمور (كل الأقسام)',
                expand: true,
                variant: AppButtonVariant.success,
                onPressed: () => _broadcastSheet(
                  title: 'رسالة إلى جميع أولياء الأمور',
                  bodyBuilder: (content) => {'scope': 'all', 'content': content},
                ),
              ),
              const SizedBox(height: 10),
              AppButton(
                text: _sectionId == null
                    ? 'اختر قسمًا أولًا لإرسال رسالة جماعية له'
                    : 'إرسال رسالة إلى كل تلاميذ القسم المحدد',
                expand: true,
                onPressed: _sectionId == null
                    ? null
                    : () => _broadcastSheet(
                          title: 'رسالة إلى تلاميذ القسم',
                          bodyBuilder: (content) =>
                              {'scope': 'section', 'sectionId': _sectionId, 'content': content},
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