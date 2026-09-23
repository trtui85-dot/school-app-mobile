import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/l10n.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../widgets/logo.dart';
import '../../widgets/language_toggle.dart';
import '../../widgets/ui.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = '');
    if (_identifier.text.trim().isEmpty) return setState(() => _error = tr('املأ رقم الهاتف'));
    if (_password.text.isEmpty) return setState(() => _error = tr('املأ كلمة المرور'));
    setState(() => _loading = true);
    try {
      await context.read<SessionManager>().login(_identifier.text.trim(), _password.text);
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
    return ListenableBuilder(
      listenable: LocaleManager.instance,
      builder: (context, _) => Scaffold(
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
                      alignment: isFr ? Alignment.centerLeft : Alignment.centerRight,
                      child: const LanguageToggle(),
                    ),
                    const SizedBox(height: 12),
                    const AppLogo(size: 72, withName: false),
                    const SizedBox(height: 20),
                    Text(tr('تسجيل الدخول'), style: ar(22, FontWeight.w700, AppColors.foreground)),
                    const SizedBox(height: 8),
                    Text(
                      tr('مرحبًا بك — سيُوجَّهك التطبيق تلقائيًا إلى لوحتك'),
                      textAlign: TextAlign.center,
                      style: ar(13, FontWeight.w400, AppColors.zinc500),
                    ),
                    const SizedBox(height: 28),
                    AppInput(
                      label: tr('رقم الهاتف'),
                      hint: 'XXXXXXXX',
                      controller: _identifier,
                      ltr: true,
                      number: true,
                      maxLength: 8,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    AppInput(
                      label: tr('كلمة المرور'),
                      hint: '••••••',
                      controller: _password,
                      obscureText: _obscure,
                      suffix: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20, color: AppColors.zinc500),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      onSubmitted: _submit,
                    ),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ErrorBox(_error),
                    ],
                    const SizedBox(height: 20),
                    AppButton(text: tr('تسجيل الدخول'), expand: true, loading: _loading, onPressed: _submit),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(tr('ليس لديك حساب (ولي أمر)؟ '), style: ar(13, FontWeight.w400, AppColors.zinc500)),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const SignupScreen()),
                          ),
                          child: Text(tr('أنشئ حسابًا جديدًا'), style: ar(13, FontWeight.w600, AppColors.accent)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
