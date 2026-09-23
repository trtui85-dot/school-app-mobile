import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/l10n.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../widgets/logo.dart';
import '../../widgets/language_toggle.dart';
import '../../widgets/ui.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = '');
    if (_name.text.trim().length < 2) return setState(() => _error = tr('الاسم الكامل مطلوب'));
    if (!RegExp(r'^\d{8}$').hasMatch(_phone.text)) {
      return setState(() => _error = tr('رقم الهاتف يجب أن يتكون من 8 أرقام فقط'));
    }
    if (_password.text.length < 6) return setState(() => _error = tr('كلمة المرور لا تقل عن 6 محارف'));
    if (_password.text != _confirm.text) return setState(() => _error = tr('كلمة المرور غير متطابقة مع التأكيد'));
    setState(() => _loading = true);
    try {
      await context.read<SessionManager>().signup(_name.text.trim(), _phone.text, _password.text);
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: LanguageToggle(),
                  ),
                  const SizedBox(height: 12),
                  const AppLogo(size: 64, withName: false),
                  const SizedBox(height: 20),
                  Text(tr('إنشاء حساب'), style: ar(22, FontWeight.w700, AppColors.foreground)),
                  const SizedBox(height: 8),
                  Text(tr('لتسجيل أطفالك ومتابعتهم'), style: ar(13, FontWeight.w400, AppColors.zinc500)),
                  const SizedBox(height: 28),
                  AppInput(label: tr('الاسم الكامل'), hint: tr('الاسم واللقب'), controller: _name),
                  const SizedBox(height: 16),
                  AppInput(
                    label: tr('رقم الهاتف'),
                    hint: 'XXXXXXXX',
                    controller: _phone,
                    ltr: true,
                    number: true,
                    maxLength: 8,
                    onChanged: (v) {
                      final clean = v.replaceAll(RegExp(r'\D'), '');
                      if (clean != v && _phone.text != clean) {
                        _phone.value = TextEditingValue(
                          text: clean,
                          selection: TextSelection.collapsed(offset: clean.length),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    label: tr('كلمة المرور'),
                    hint: tr('6 محارف على الأقل'),
                    controller: _password,
                    obscureText: _obscure,
                    suffix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20, color: AppColors.zinc500),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    label: tr('تأكيد كلمة المرور'),
                    hint: tr('أعد كتابة كلمة المرور'),
                    controller: _confirm,
                    obscureText: _obscure,
                    onSubmitted: _submit,
                  ),
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ErrorBox(_error),
                  ],
                  const SizedBox(height: 20),
                  AppButton(text: tr('إنشاء حساب'), expand: true, loading: _loading, onPressed: _submit),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(tr('لديك حساب بالفعل؟ '), style: ar(13, FontWeight.w400, AppColors.zinc500)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(tr('سجّل الدخول'), style: ar(13, FontWeight.w600, AppColors.accent)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
