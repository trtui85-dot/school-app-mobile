import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/l10n.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../services/push_service.dart';
import '../../widgets/language_toggle.dart';
import '../../widgets/success_screen.dart';
import '../../widgets/toast.dart';
import '../../widgets/ui.dart';

class AgentSettingsScreen extends StatefulWidget {
  const AgentSettingsScreen({super.key});
  @override
  State<AgentSettingsScreen> createState() => _AgentSettingsScreenState();
}

class _AgentSettingsScreenState extends State<AgentSettingsScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _loadError;

  final _name = TextEditingController();
  final _oldPass = TextEditingController();
  final _newPass = TextEditingController();
  final _confirmNewPass = TextEditingController();
  bool _obscure = true;
  bool _savingName = false;
  bool _savingPass = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _oldPass.dispose();
    _newPass.dispose();
    _confirmNewPass.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final res = await ApiClient.instance.get('/api/me/profile');
      final p = asMap(res['profile']);
      if (!mounted) return;
      _name.text = asStr(p['fullName']);
      setState(() {
        _profile = p;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.message;
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveName() async {
    if (_name.text.trim().length < 2) {
      showToast(context, tr('الاسم الكامل مطلوب'), type: ToastType.error);
      return;
    }
    setState(() => _savingName = true);
    try {
      await ApiClient.instance.put('/api/me/profile', body: {'fullName': _name.text.trim()});
      if (!mounted) return;
      setState(() => _profile = {...?_profile, 'fullName': _name.text.trim()});
      showToast(context, tr('تم حفظ الاسم'));
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _savePassword() async {
    if (_newPass.text.length < 6) {
      showToast(context, tr('كلمة المرور لا تقل عن 6 محارف'), type: ToastType.error);
      return;
    }
    if (_newPass.text != _confirmNewPass.text) {
      showToast(context, tr('كلمة المرور غير متطابقة مع التأكيد'), type: ToastType.error);
      return;
    }
    setState(() => _savingPass = true);
    try {
      await ApiClient.instance.put('/api/me/password', body: {
        'oldPassword': _oldPass.text,
        'newPassword': _newPass.text,
      });
      if (!mounted) return;
      _oldPass.clear();
      _newPass.clear();
      _confirmNewPass.clear();
      showToast(context, tr('تم تغيير كلمة المرور'));
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _savingPass = false);
    }
  }

  Future<void> _confirmDelete() async {
    final deleted = await showDialog<bool>(context: context, builder: (_) => const _DeleteAccountDialog());
    if (deleted != true || !mounted) return;
    final session = context.read<SessionManager>();
    await PushService.unbind(role: 'agent');
    await session.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SuccessScreen(
          title: tr('تم حذف الحساب'),
          description: tr('تم حذف حسابك نهائيًا. نتشرف بخدمتك مستقبلًا.'),
          doneLabel: 'حسنًا',
          onDone: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ),
      (r) => r.isFirst,
    );
  }

  Future<void> _logout() async {
    final session = context.read<SessionManager>();
    await PushService.unbind(role: 'agent');
    await session.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.zinc50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(tr('الإعدادات'), style: ar(17, FontWeight.w700, AppColors.foreground)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.zinc100),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _load,
        child: _loading
            ? ListView(children: const [AppSpinner()])
            : _loadError != null
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [ErrorBox(_loadError!, onRetry: _load)],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _profileCard(),
                      const SizedBox(height: 16),
                      _sectionTitle(tr('تعديل الاسم')),
                      AppCard(
                        child: Column(
                          children: [
                            AppInput(label: tr('الاسم الكامل'), controller: _name),
                            const SizedBox(height: 12),
                            AppButton(text: tr('حفظ'), expand: true, loading: _savingName, onPressed: _saveName),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _sectionTitle(tr('اللغة')),
                      AppCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tr('اللغة'), style: AppText.semibold),
                            const LanguageToggle(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _sectionTitle(tr('تغيير كلمة المرور')),
                      AppCard(
                        child: Column(
                          children: [
                            AppInput(
                              label: tr('كلمة المرور الحالية'),
                              controller: _oldPass,
                              obscureText: _obscure,
                              suffix: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20, color: AppColors.zinc500),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AppInput(
                              label: tr('كلمة المرور الجديدة'),
                              hint: tr('6 محارف على الأقل'),
                              controller: _newPass,
                              obscureText: _obscure,
                            ),
                            const SizedBox(height: 12),
                            AppInput(
                              label: tr('تأكيد كلمة المرور'),
                              hint: tr('أعد كتابة كلمة المرور'),
                              controller: _confirmNewPass,
                              obscureText: _obscure,
                            ),
                            const SizedBox(height: 12),
                            AppButton(
                              text: tr('حفظ'),
                              expand: true,
                              loading: _savingPass,
                              onPressed: _savePassword,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _sectionTitle(tr('حذف الحساب')),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('سيتم حذف جميع بياناتك وتلاميذك نهائيًا ولا يمكن التراجع.'),
                              style: ar(13, FontWeight.w400, AppColors.zinc600, height: 1.5),
                            ),
                            const SizedBox(height: 12),
                            AppButton(
                              text: tr('حذف الحساب نهائيًا'),
                              variant: AppButtonVariant.danger,
                              expand: true,
                              onPressed: _confirmDelete,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppButton(text: tr('سجل الخروج'), variant: AppButtonVariant.outline, expand: true, onPressed: _logout),
                      const SizedBox(height: 24),
                    ],
                  ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: AppText.title),
      );

  Widget _profileCard() {
    final p = _profile;
    final name = asStr(p?['fullName']);
    final phone = asStr(p?['phone']);
    final created = asStrOrNull(p?['createdAt']);
    final count = asStr(p?['studentCount']);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              name.isEmpty ? '?' : name.substring(0, 1),
              style: ar(22, FontWeight.w700, AppColors.accent),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.title),
                const SizedBox(height: 4),
                Text(phone, style: mono(13, FontWeight.w400, AppColors.zinc600)),
                const SizedBox(height: 8),
                if (created != null)
                  Text('${tr('عضو منذ')} ${formatArabicDate(created)}', style: ar(12, FontWeight.w400, AppColors.zinc500)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 16, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text('${tr('عدد التلاميذ')}: $count', style: ar(13, FontWeight.w600, AppColors.foreground)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();
  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _error = '';
      _loading = true;
    });
    try {
      await ApiClient.instance.delete('/api/me/account', body: {'password': _password.text});
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Row(
        children: [
          const Icon(Icons.delete_forever_outlined, color: AppColors.bad),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tr('حذف الحساب نهائيًا'), style: ar(16, FontWeight.w700, AppColors.foreground)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('سيتم حذف جميع بياناتك وتلاميذك نهائيًا ولا يمكن التراجع.'),
            style: ar(13, FontWeight.w400, AppColors.zinc600, height: 1.5),
          ),
          const SizedBox(height: 14),
          AppInput(
            label: tr('أدخل كلمة المرور للتأكيد'),
            controller: _password,
            obscureText: true,
            onSubmitted: _delete,
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_error, style: ar(12, FontWeight.w500, AppColors.bad)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: Text(tr('إلغاء'), style: ar(14, FontWeight.w600, AppColors.zinc600)),
        ),
        TextButton(
          onPressed: _loading ? null : _delete,
          child: Text(tr('تأكيد الحذف'), style: ar(14, FontWeight.w700, AppColors.bad)),
        ),
      ],
    );
  }
}