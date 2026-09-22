import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:schoolapp/app.dart';
import 'package:schoolapp/core/session.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renders landing screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SessionManager(),
        child: const SchoolApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مدارس اقرأ الحديثة'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('إنشاء حساب ولي أمر'), findsOneWidget);
  });
}