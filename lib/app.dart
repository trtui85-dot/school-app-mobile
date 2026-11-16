import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/l10n.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/agent/agent_shell.dart';
import 'screens/agent/guest_shell.dart';
import 'services/update_checker.dart';

class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: ValueKey(isFr ? 'fr' : 'ar'),
      title: 'مدارس اقرأ الحديثة',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: Locale(isFr ? 'fr' : 'ar'),
      supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: isFr ? TextDirection.ltr : TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const RootGate(),
    );
  }
}

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) UpdateChecker.check(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    if (session.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }
    final user = session.user;
    if (user == null) return const GuestShell();
    if (user.isAdmin) return const AdminShell();
    return const AgentShell();
  }
}
