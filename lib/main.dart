import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/l10n.dart';
import 'core/session.dart';
import 'services/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await PushService.configure();
  await LocaleManager.instance.load();
  runApp(
    ChangeNotifierProvider(
      create: (_) => SessionManager(),
      child: ListenableBuilder(
        listenable: LocaleManager.instance,
        builder: (_, _) => const SchoolApp(),
      ),
    ),
  );
}
