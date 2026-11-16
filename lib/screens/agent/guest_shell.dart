import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/logo.dart';
import '../auth/login_screen.dart';
import 'timetable_screen.dart';

class GuestShell extends StatelessWidget {
  const GuestShell({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.zinc50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const AppLogo(size: 32),
          actions: [TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())), child: Text('تسجيل الدخول', style: ar(13, FontWeight.w700, AppColors.accent)))],
        ),
        body: const TimetableScreen(showAppBar: false),
      );
}
