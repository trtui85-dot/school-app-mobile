import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(tr('آخر تحديث: سبتمبر 2026 — مدارس اقرأ الحديثة'),
            style: ar(12, FontWeight.w400, AppColors.zinc500)),
      ),
      _section(
        tr('1. قبول الشروط'),
        tr('باستخدامك تطبيق «مدارس اقرأ الحديثة» فإنك توافق على هذه الشروط. إذا كنت لا توافق عليها يُرجى عدم استخدام التطبيق.'),
      ),
      _section(
        tr('2. الغرض من الخدمة'),
        tr('يقدم التطبيق خدمة المتابعة المدرسية لأولياء الأمور وأبنائهم المسجلين، مع إدارة التسجيلات والدفعات والحضور والتواصل المدرسي. الاستخدام مخصص للأغراض التعليمية فقط.'),
      ),
      _bullets(
        tr('3. مسؤولية المستخدم'),
        [
          tr('تقديم معلومات صحيحة وحديثة عند إنشاء الحساب وتسجيل البيانات.'),
          tr('الحفاظ على سرية كلمة المرور وعدم مشاركتها مع الآخرين.'),
          tr('استخدام التطبيق بشكل قانوني وعدم محاولة الوصول غير المصرح به للأنظمة.'),
        ],
      ),
      _section(
        tr('4. الدفعات المدرسية'),
        tr('تُعالج الدفعات يدويًا بين ولي الأمر وإدارة المدرسة، وتُوثق عبر التطبيق. التطبيق أداة مساعدة للتوثيق ولا يعتبر قناة دفع إليكترونية مستقلة.'),
      ),
      _section(
        tr('5. حقوق الملكية'),
        tr('جميع محتويات التطبيق واسمه وشعاره محمية حقوق ملكية لمدارس اقرأ الحديثة ولا يجوز استخدامها دون إذن مسبق.'),
      ),
      _section(
        tr('6. حدود المسؤولية'),
        tr('تُبذل جهود معقولة لضمان استمرارية الخدمة، لكن لا نضمن خلوّها من الانقطاع. لا نتحمل مسؤولية الأضرار الناتجة عن الاستخدام غير السليم أو انقطاع الخدمة المؤقت.'),
      ),
      _section(
        tr('7. إلغاء الحساب'),
        tr('يحق لولي الأمر طلب إلغاء حسابه، ولإدارة المدرسة تعليق أي حساب يخالف هذه الشروط أو يستخدم الخدمة بشكل مخالف.'),
      ),
      _section(
        tr('8. التواصل'),
        tr('لأي استفسار حول هذه الشروط يرجى التواصل مع إدارة مدارس اقرأ الحديثة.'),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Text(tr('شروط الاستخدام'), style: ar(16, FontWeight.w700, AppColors.foreground)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: sections,
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ar(15, FontWeight.w700, AppColors.foreground)),
          const SizedBox(height: 6),
          Text(body, style: ar(13, FontWeight.w400, AppColors.zinc700, height: 1.7)),
        ],
      ),
    );
  }

  Widget _bullets(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ar(15, FontWeight.w700, AppColors.foreground)),
          const SizedBox(height: 6),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Text('•', style: TextStyle(fontSize: 13, height: 1.7)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item, style: ar(13, FontWeight.w400, AppColors.zinc700, height: 1.7)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}