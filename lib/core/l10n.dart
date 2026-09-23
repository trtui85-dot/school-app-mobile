import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight bilingual support: 'ar' (default) and 'fr'.
/// Agents may pick French; the admin interface is always Arabic.
class LocaleManager extends ChangeNotifier {
  LocaleManager._();
  static LocaleManager instance = LocaleManager._();

  bool _isFr = false;
  bool get isFr => _isFr;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _isFr = sp.getBool('lang_fr') ?? false;
    notifyListeners();
  }

  Future<void> setFr(bool value) async {
    if (_isFr == value) return;
    _isFr = value;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('lang_fr', value);
  }
}

bool get isFr => LocaleManager.instance.isFr;

/// Returns the French translation for an Arabic UI string (used as the key),
/// falling back to the Arabic text when in Arabic mode or when no translation
/// exists. Placeholder tokens like `{name}` are replaced when provided.
String tr(String arText, [Map<String, String>? params]) {
  var s = isFr ? (_fr[arText] ?? arText) : arText;
  if (params != null) {
    params.forEach((k, v) => s = s.replaceAll('{$k}', v));
  }
  return s;
}

/// Quicksand — used for the French interface (per school branding).
TextStyle fr(double size, FontWeight weight, Color color, {double? height}) =>
    GoogleFonts.quicksand(fontSize: size, fontWeight: weight, color: color, height: height);

const Map<String, String> _fr = {
  // ---- Auth ----
  'مدارس اقرأ الحديثة': 'Écoles Iqra Modernes',
  'مدارس اقرأ': 'Écoles Iqra',
  'الحديثة': 'Modernes',
  'نظام متابعة التسجيل وتحصيل الرسوم والغياب والتواصل مع أولياء الأمور':
      "Suivez les inscriptions, les paiements et les absences, et restez en contact avec l'administration",
  'تسجيل الدخول': 'Connexion',
  'إنشاء حساب ولي أمر': 'Créer un compte parent',
  'مرحبًا بك — سيُوجَّهك التطبيق تلقائيًا إلى لوحتك':
      "Bienvenue — l'application vous dirigera automatiquement vers votre espace",
  'رقم الهاتف': 'Numéro de téléphone',
  'كلمة المرور': 'Mot de passe',
  'املأ رقم الهاتف': 'Saisissez votre numéro',
  'املأ كلمة المرور': 'Saisissez votre mot de passe',
  'ليس لديك حساب (ولي أمر)؟ ': 'Pas encore de compte (parent) ? ',
  'أنشئ حسابًا جديدًا': 'Créer un compte',
  'إنشاء حساب': 'Créer un compte',
  'لتسجيل أطفالك ومتابعتهم': 'Pour inscrire vos enfants et les suivre',
  'الاسم الكامل': 'Nom complet',
  'الاسم واللقب': 'Prénom et nom',
  '6 محارف على الأقل': '6 caractères minimum',
  'تأكيد كلمة المرور': 'Confirmer le mot de passe',
  'أعد كتابة كلمة المرور': 'Répétez le mot de passe',
  'الاسم الكامل مطلوب': 'Le nom complet est requis',
  'رقم الهاتف يجب أن يتكون من 8 أرقام فقط': 'Le numéro doit contenir exactement 8 chiffres',
  'كلمة المرور لا تقل عن 6 محارف': 'Le mot de passe doit comporter au moins 6 caractères',
  'كلمة المرور غير متطابقة مع التأكيد': 'Les mots de passe ne correspondent pas',
  'لديك حساب بالفعل؟ ': 'Vous avez déjà un compte ? ',
  'سجّل الدخول': 'Connectez-vous',

  // ---- Agent shell ----
  'اتصال': 'Appeler',
  'خروج': 'Déconnexion',
  'الرئيسية': 'Accueil',
  'تسجيل': 'Inscription',
  'الإشعارات': 'Notifications',
  'الشكاوى': 'Réclamations',

  // ---- Home ----
  'أبنائي': 'Mes enfants',
  'لا يوجد لديك تلاميذ مسجَّلون بعد': 'Aucun élève inscrit pour le moment',
  'ابدأ التسجيل لتتمكن من متابعة أطفالك':
      'Commencez par une inscription pour pouvoir suivre vos enfants',
  'تسجيل طفل جديد': 'Inscrire un nouvel enfant',
  'مقبول': 'Accepté',
  'مرفوض': 'Rejeté',
  'بانتظار التوثيق': 'En attente de validation',
  'بدون قسم': 'Sans section',
  'رقم النداء: ': "N° d'appel : ",
  'السبب: ': 'Motif : ',

  // ---- Student detail ----
  'التلميذ': 'Élève',
  'الغياب': 'Absences',
  'سجل الغياب وأيام الغيبة': 'Registre des absences',
  'مواد وجدول': 'Matières & horaires',
  'المواد الدراسية والجدول الأسبوعي': 'Matières et emploi du temps',
  'نتائج': 'Résultats',
  'الدرجات والنتائج الدراسية': 'Notes et résultats scolaires',
  'رسائل الإدارة': 'Messages',
  'رسائل إدارة المدرسة': "Messages de l'administration",
  'الدفعات': 'Paiements',
  'رسوم التسجيل والاشتراكات الشهرية': 'Frais d\'inscription et abonnements mensuels',
  'عرض التفاصيل': 'Voir les détails',
  'طلب التسجيل قيد المراجعة من الإدارة.': "Votre demande d'inscription est en cours d'examen.",
  'تم رفض طلب التسجيل. السبب: ': "Demande d'inscription rejetée. Motif : ",
  'غير محدد': 'Non précisé',
  'عودة': 'Retour',
  'قريبًا': 'Bientôt',
  'وحدة النتائج والدرجات ستتوفر لاحقًا': 'Le module des résultats sera bientôt disponible',
  '⚠️ طفلك غائب اليوم': "⚠️ Votre enfant est absent aujourd'hui",
  'لا يوجد أي غياب مسجل': 'Aucune absence enregistrée',
  'غائب': 'Absent',
  'لا توجد بيانات القسم': 'Aucune donnée de section',
  'المواد الدراسية': 'Matières',
  'الجدول الزمني الأسبوعي': 'Emploi du temps hebdomadaire',
  'لا توجد رسائل': 'Aucun message',
  'رسوم التسجيل': "Frais d'inscription",
  'رسوم ': 'Frais de ',
  'إيصال': 'Reçu',
  'موثقة': 'Validé',
  'مرفوضة': 'Rejetée',
  'دفع شهر': 'Payer un mois',

  // ---- Pay screen ----
  'دفع الرسوم الشهرية': 'Paiement des frais mensuels',
  'تم إرسال طلب توثيق الدفعة': 'Demande de validation envoyée',
  'تم إرسال طلب توثيق الدفعة للأشهر المحددة ({n}) بنجاح، وستوثّقه الإدارة في أقرب وقت. ستتوصل بإشعار فور التوثيق.':
      "Votre demande de validation pour {n} mois est envoyée avec succès. L'administration la validera rapidement. Vous recevrez une notification dès la validation.",
  'العودة إلى بطاقة التلميذ': 'Retour à la fiche élève',
  'اختر الشهر (السنة ': 'Choisissez le mois (année ',
  'حسابات المدرسة للتحويل': "Comptes bancaires de l'école",
  'صورة إثبات التحويل/الدفع': 'Photo du justificatif de transfert',
  'إرسال الدفعة (': 'Envoyer le paiement (',
  'اختر شهرًا واحدًا على الأقل': 'Sélectionnez au moins un mois',
  'صورة إثبات الدفع مطلوبة': 'Une photo de preuve de paiement est requise',
  'نسخ': 'Copier',
  '/ شهر': '/ mois',

  // ---- Register ----
  'تم إرسال طلب التسجيل': "Demande d'inscription envoyée",
  'تم إرسال طلب تسجيل التلميذ بنجاح، وستوثّقه الإدارة في أقرب وقت. ستتوصل بإشعار فور البتّ فيه.':
      "Votre demande d'inscription a été envoyée avec succès. L'administration la validera rapidement. Vous recevrez une notification dès la décision.",
  'العودة إلى الرئيسية': "Retour à l'accueil",
  'بيانات التلميذ': "Informations de l'élève",
  'الاسم (عربي)': 'Prénom (arabe)',
  'اللقب (عربي)': 'Nom (arabe)',
  'رقم ريم': 'N° RIM',
  'الرقم الوطني': 'N° national',
  'رقم هاتف ولي الأمر': 'Téléphone du parent',
  'العنوان': 'Adresse',
  'صورة إثبات دفع رسوم التسجيل': "Photo du justificatif des frais d'inscription",
  'إرسال طلب التسجيل': "Envoyer la demande",
  'اختر القسم المطلوب': 'Choisissez la section souhaitée',
  'الاسم واللقب بالعربية مطلوبان': 'Le prénom et le nom en arabe sont requis',
  'صورة إثبات دفع رسوم التسجيل مطلوبة': "Une photo de preuve des frais d'inscription est requise",
  'عذرًا، التسجيل متوقف حاليًا': 'Désolé, les inscriptions sont actuellement suspendues',
  'يُستأنف التسجيل عندما تُعلن الإدارة ذلك.': "Les inscriptions reprendront dès que l'administration l'annoncera.",
  'التسجيل متوقف حاليًا': 'Les inscriptions sont actuellement suspendues',

  // ---- Sections picker ----
  'القسم المطلوب': 'Section souhaitée',
  '— اختر القسم —': '— Choisir la section —',
  'تسجيل ': 'Inscription ',
  'شهري ': 'Mensuel ',
  'اختر القسم': 'Choisir la section',
  'لا توجد أقسام بعد': 'Aucune section pour le moment',
  'رسوم التسجيل: ': "Frais d'inscription : ",
  'الرسوم الشهرية: ': 'Frais mensuels : ',

  // ---- Complaints ----
  'تم إرسال رسالتكم': 'Message envoyé',
  'تم إرسال رسالتك إلى الإدارة بنجاح، وسيتم الرد عليها في أقرب وقت.':
      "Votre message a été envoyé à l'administration avec succès. Vous recevrez une réponse rapidement.",
  'متابعة': 'Continuer',
  'التواصل مع الإدارة': "Contacter l'administration",
  'عنوان الشكوى/الطلب': 'Objet de la réclamation',
  'نص الرسالة': 'Votre message',
  'إرسال إلى الإدارة': "Envoyer à l'administration",
  'شكواي السابقة': 'Mes réclamations',
  'تم الرد': 'Répondu',
  'قيد المعالجة': 'En cours',
  'جديدة': 'Nouvelle',
  'رد الإدارة: ': 'Réponse : ',
  'العنوان مطلوب': "L'objet est requis",
  'نص الرسالة مطلوب': 'Veuillez saisir votre message',

  // ---- Image upload ----
  'صورة إثبات الدفع': 'Photo de justificatif',
  'تعذر ضغط الصورة': "Impossible de compresser l'image",
  'اختيار من المعرض': 'Choisir depuis la galerie',
  'التقاط صورة': 'Prendre une photo',
  'جارٍ الضغط...': 'Compression…',
  'اضغط لرفع الصورة': 'Appuyez pour envoyer une photo',
  'تُضغط الصورة تلقائيًا قبل الرفع': "L'image est compressée automatiquement",

  // ---- Receipt ----
  'إيصال الدفع': 'Reçu de paiement',
  'تحميل': 'Télécharger',
  'طباعة': 'Imprimer',
  'تم حفظ الإيصال في المعرض': 'Reçu enregistré dans la galerie',
  'تعذر حفظ الصورة': "Impossible d'enregistrer l'image",
  'تعذرت الطباعة': "Échec de l'impression",
  'إيصال دفع': 'Reçu de paiement',
  'رقم الإيصال: ': 'N° de reçu : ',
  'القسم': 'Section',
  'نوع الدفع': 'Type de paiement',
  'رسوم شهر ': 'Frais du mois de ',
  'المبلغ': 'Montant',
  'حالة الدفع': 'Statut',
  'تاريخ التوثيق': 'Date de validation',
  'بيان الولي': 'Validé par',
  'الإدارة': "L'administration",
  'شكرًا لثقتكم بـ': 'Merci de votre confiance envers ',
  'الختم والتوقيع': 'Cachet et signature',

  // ---- Shared UI ----
  'إعادة المحاولة': 'Réessayer',
  'حسنًا': 'OK',
  'الوقت': 'Heure',

  // ---- Months ----
  'أكتوبر': 'Octobre',
  'نوفمبر': 'Novembre',
  'ديسمبر': 'Décembre',
  'يناير': 'Janvier',
  'فبراير': 'Février',
  'مارس': 'Mars',
  'أبريل': 'Avril',
  'مايو': 'Mai',
  'يونيو': 'Juin',

  // ---- Days ----
  'الأحد': 'Dimanche',
  'الاثنين': 'Lundi',
  'الثلاثاء': 'Mardi',
  'الأربعاء': 'Mercredi',
  'الخميس': 'Jeudi',
  'الجمعة': 'Vendredi',
  'السبت': 'Samedi',

  // ---- Terms screen ----
  'شروط الاستخدام': "Conditions d'utilisation",
  'آخر تحديث: سبتمبر 2026 — مدارس اقرأ الحديثة':
      'Dernière mise à jour : septembre 2026 — Écoles Iqra Modernes',
  '1. قبول الشروط': "1. Acceptation des conditions",
  'باستخدامك تطبيق «مدارس اقرأ الحديثة» فإنك توافق على هذه الشروط. إذا كنت لا توافق عليها يُرجى عدم استخدام التطبيق.':
      "En utilisant l'application « Écoles Iqra Modernes », vous acceptez les présentes conditions. Si vous ne les acceptez pas, merci de ne pas utiliser l'application.",
  '2. الغرض من الخدمة': "2. Objet du service",
  'يقدم التطبيق خدمة المتابعة المدرسية لأولياء الأمور وأبنائهم المسجلين، مع إدارة التسجيلات والدفعات والحضور والتواصل المدرسي. الاستخدام مخصص للأغراض التعليمية فقط.':
      "L'application fournit un service de suivi scolaire aux parents et à leurs enfants inscrits, avec la gestion des inscriptions, des paiements, des présences et de la communication scolaire. L'utilisation est réservée à des fins exclusivement éducatives.",
  '3. مسؤولية المستخدم': "3. Responsabilité de l'utilisateur",
  'تقديم معلومات صحيحة وحديثة عند إنشاء الحساب وتسجيل البيانات.':
      "Fournir des informations exactes et à jour lors de la création du compte et de l'enregistrement des données.",
  'الحفاظ على سرية كلمة المرور وعدم مشاركتها مع الآخرين.':
      "Préserver la confidentialité du mot de passe et ne pas le partager avec d'autres.",
  'استخدام التطبيق بشكل قانوني وعدم محاولة الوصول غير المصرح به للأنظمة.':
      "Utiliser l'application de manière conforme à la loi et ne pas tenter d'accès non autorisé aux systèmes.",
  '4. الدفعات المدرسية': "4. Paiements scolaires",
  'تُعالج الدفعات يدويًا بين ولي الأمر وإدارة المدرسة، وتُوثق عبر التطبيق. التطبيق أداة مساعدة للتوثيق ولا يعتبر قناة دفع إليكترونية مستقلة.':
      "Les paiements sont traités manuellement entre le parent et l'administration de l'école, et sont validés via l'application. L'application est un outil d'aide à la validation et ne constitue pas un canal de paiement électronique indépendant.",
  '5. حقوق الملكية': "5. Droits de propriété",
  'جميع محتويات التطبيق واسمه وشعاره محمية حقوق ملكية لمدارس اقرأ الحديثة ولا يجوز استخدامها دون إذن مسبق.':
      "Tous les contenus de l'application, son nom et son logo sont protégés par les droits de propriété des Écoles Iqra Modernes et ne peuvent être utilisés sans autorisation préalable.",
  '6. حدود المسؤولية': "6. Limitation de responsabilité",
  'تُبذل جهود معقولة لضمان استمرارية الخدمة، لكن لا نضمن خلوّها من الانقطاع. لا نتحمل مسؤولية الأضرار الناتجة عن الاستخدام غير السليم أو انقطاع الخدمة المؤقت.':
      "Des efforts raisonnables sont déployés pour assurer la continuité du service, mais nous ne garantissons pas son absence d'interruption. Nous déclinons toute responsabilité pour les dommages résultant d'une mauvaise utilisation ou d'une interruption temporaire du service.",
  '7. إلغاء الحساب': "7. Annulation du compte",
  'يحق لولي الأمر طلب إلغاء حسابه، ولإدارة المدرسة تعليق أي حساب يخالف هذه الشروط أو يستخدم الخدمة بشكل مخالف.':
      "Le parent peut demander la suppression de son compte, et l'administration de l'école peut suspendre tout compte qui enfreint ces conditions ou utilise le service de manière abusive.",
  '8. التواصل': "8. Contact",
  'لأي استفسار حول هذه الشروط يرجى التواصل مع إدارة مدارس اقرأ الحديثة.':
      "Pour toute question concernant ces conditions, veuillez contacter l'administration des Écoles Iqra Modernes.",
};