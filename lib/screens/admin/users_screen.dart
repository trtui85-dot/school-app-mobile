import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>>? _agents;
  List<Map<String, dynamic>>? _admins;
  bool _agentsTab = true;
  String _msg = '';

  // agent form
  final _agentName = TextEditingController();
  final _agentPhone = TextEditingController();
  final _agentPassword = TextEditingController();
  bool _creatingAgent = false;

  // admin form
  final _adminName = TextEditingController();
  final _adminUsername = TextEditingController();
  final _adminPhone = TextEditingController();
  final _adminPassword = TextEditingController();
  final Set<String> _perms = {};
  bool _creatingAdmin = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _agentName.dispose();
    _agentPhone.dispose();
    _agentPassword.dispose();
    _adminName.dispose();
    _adminUsername.dispose();
    _adminPhone.dispose();
    _adminPassword.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final agents = await ApiClient.instance.get('/api/admin/users/agents');
      final admins = await ApiClient.instance.get('/api/admin/users/admins');
      if (!mounted) return;
      setState(() {
        _agents = asMapList(agents['agents']);
        _admins = asMapList(admins['admins']);
      });
    } on ApiException catch (e) {
      if (mounted) {
        showToast(context, e.message, type: ToastType.error);
        setState(() {
          _agents ??= [];
          _admins ??= [];
        });
      }
    }
  }

  Future<void> _createAgent() async {
    setState(() {
      _msg = '';
    });
    if (!RegExp(r'^\d{8}$').hasMatch(_agentPhone.text)) {
      return setState(() => _msg = 'رقم الهاتف يجب أن يتكون من 8 أرقام فقط');
    }
    if (_agentPassword.text.length < 6) {
      return setState(() => _msg = 'كلمة المرور 6 محارف على الأقل');
    }
    setState(() => _creatingAgent = true);
    try {
      await ApiClient.instance.post('/api/admin/users/agents', body: {
        'fullName': _agentName.text.trim(),
        'phone': _agentPhone.text.trim(),
        'password': _agentPassword.text,
      });
      if (!mounted) return;
      setState(() {
        _msg = 'تم إنشاء حساب الوكيل';
        _agentName.clear();
        _agentPhone.clear();
        _agentPassword.clear();
      });
      showToast(context, 'تم إنشاء حساب الوكيل');
      _load();
    } on ApiException catch (e) {
      setState(() => _msg = e.message);
    } finally {
      if (mounted) setState(() => _creatingAgent = false);
    }
  }

  Future<void> _createAdmin() async {
    setState(() => _msg = '');
    if (_adminPassword.text.length < 6) {
      return setState(() => _msg = 'كلمة المرور 6 محارف على الأقل');
    }
    setState(() => _creatingAdmin = true);
    try {
      await ApiClient.instance.post('/api/admin/users/admins', body: {
        'name': _adminName.text.trim(),
        'username': _adminUsername.text.trim(),
        'phone': _adminPhone.text.trim().isEmpty ? null : _adminPhone.text.trim(),
        'password': _adminPassword.text,
        'permissions': _perms.toList(),
      });
      if (!mounted) return;
      setState(() {
        _msg = 'تم إنشاء حساب المدير';
        _adminName.clear();
        _adminUsername.clear();
        _adminPhone.clear();
        _adminPassword.clear();
        _perms.clear();
      });
      showToast(context, 'تم إنشاء حساب المدير');
      _load();
    } on ApiException catch (e) {
      setState(() => _msg = e.message);
    } finally {
      if (mounted) setState(() => _creatingAdmin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(Icons.manage_accounts_outlined, size: 20, color: AppColors.accent),
            const SizedBox(width: 8),
            Text('إدارة المستخدمين', style: AppText.h1),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.zinc100,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: Row(
            children: [
              _tab('الوكلاء', true),
              _tab('المديرون', false),
            ],
          ),
        ),
        if (_msg.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _msg.contains('تم') ? AppColors.okSoft : AppColors.badSoft,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Text(
              _msg.contains('تم') ? '$_msg ✓' : _msg,
              style: ar(13, FontWeight.w500,
                  _msg.contains('تم') ? AppColors.ok : AppColors.bad),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (_agentsTab) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('إضافة مستخدم وكيل', style: AppText.title),
                const SizedBox(height: 12),
                AppInput(label: 'الاسم الكامل', controller: _agentName),
                const SizedBox(height: 10),
                AppInput(
                  label: 'رقم الهاتف',
                  controller: _agentPhone,
                  ltr: true,
                  number: true,
                  maxLength: 8,
                ),
                const SizedBox(height: 10),
                AppInput(
                  label: 'كلمة المرور',
                  controller: _agentPassword,
                  ltr: true,
                  maxLength: 100,
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'إنشاء الوكيل',
                  expand: true,
                  loading: _creatingAgent,
                  onPressed: _createAgent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_agents != null)
            ..._agents!.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(asStr(a['fullName']), style: AppText.semibold),
                              Text(asStr(a['phone']), style: mono(12, FontWeight.w400, AppColors.zinc500)),
                            ],
                          ),
                        ),
                        AppBadge('${asInt(a['studentCount'])} تلميذ', tone: BadgeTone.neutral),
                        const SizedBox(width: 8),
                        Text(formatArabicDate(a['createdAt']), style: AppText.tiny),
                      ],
                    ),
                  ),
                )),
        ] else ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('إضافة مستخدم مدير', style: AppText.title),
                const SizedBox(height: 12),
                AppInput(label: 'الاسم', controller: _adminName),
                const SizedBox(height: 10),
                AppInput(label: 'اسم المستخدم (للدخول)', controller: _adminUsername, ltr: true),
                const SizedBox(height: 10),
                AppInput(label: 'رقم الهاتف (اختياري)', controller: _adminPhone, ltr: true, number: true, maxLength: 8),
                const SizedBox(height: 10),
                AppInput(label: 'كلمة المرور', controller: _adminPassword, ltr: true, maxLength: 100),
                const SizedBox(height: 12),
                Text('الصلاحيات', style: AppText.label),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final key in allPermissions)
                      _permChip(key),
                  ],
                ),
                const SizedBox(height: 6),
                Text('بدون تحديد أي صلاحية = مدير كامل الصلاحيات (يرى كل شيء).',
                    style: AppText.tiny),
                const SizedBox(height: 12),
                AppButton(
                  text: 'إنشاء المدير',
                  expand: true,
                  loading: _creatingAdmin,
                  onPressed: _createAdmin,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_admins != null)
            ..._admins!.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(asStr(a['name']), style: AppText.semibold),
                        Text(
                          '@${asStr(a['username'])}${asStrOrNull(a['phone']) != null ? " · ${asStr(a['phone'])}" : ""}',
                          style: mono(12, FontWeight.w400, AppColors.zinc500),
                        ),
                        const SizedBox(height: 6),
                        if (a['permissions'] == null || (a['permissions'] as List).isEmpty)
                          const AppBadge('كامل الصلاحيات', tone: BadgeTone.ok)
                        else
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: (a['permissions'] as List)
                                .map((k) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: AppColors.accentSoft,
                                          borderRadius: BorderRadius.circular(6)),
                                      child: Text(
                                        permissionLabels[k.toString()] ?? k.toString(),
                                        style: ar(11, FontWeight.w500, AppColors.accent),
                                      ),
                                    ))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                )),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _tab(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _agentsTab = active;
          _msg = '';
        }),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)]
                : null,
          ),
          child: Text(label,
              style: ar(13, FontWeight.w600,
                  active ? AppColors.foreground : AppColors.zinc500)),
        ),
      ),
    );
  }

  Widget _permChip(String key) {
    final active = _perms.contains(key);
    return GestureDetector(
      onTap: () => setState(() {
        if (active) {
          _perms.remove(key);
        } else {
          _perms.add(key);
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: active ? AppColors.accent : AppColors.zinc300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active) ...[
              const Icon(Icons.check, size: 14, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(permissionLabels[key] ?? key,
                style: ar(12, FontWeight.w600,
                    active ? Colors.white : AppColors.zinc600)),
          ],
        ),
      ),
    );
  }
}