import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/session.dart';
import 'core/theme.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/agent/agent_shell.dart';
import 'screens/auth/landing_screen.dart';

class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدارس اقرأ الحديثة',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const RootGate(),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    if (session.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }
    final user = session.user;
    if (user == null) return const LandingScreen();
    if (user.isAdmin) return const AdminShell();
    return const AgentShell();
  }
}
