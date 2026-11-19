import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/l10n.dart';
import 'core/session.dart';
import 'services/push_service.dart';
import 'widgets/ads_carousel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(AdsCarousel.preload());
  await Firebase.initializeApp();
  await PushService.configure();
  await LocaleManager.instance.load();
  // Pre-warm fonts in the background so the first frame renders with the
  // final Arabic typeface instead of swapping mid-frame.
  unawaited(GoogleFonts.pendingFonts());
  runApp(
    ChangeNotifierProvider(
      create: (_) => SessionManager(),
      child: ListenableBuilder(
        listenable: LocaleManager.instance,
        builder: (_, _) => SchoolApp(),
      ),
    ),
  );
}
