import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../widgets/logo.dart';
import '../widgets/toast.dart';
import '../widgets/ui.dart';

/// Vérifie au démarrage si une nouvelle version de l'application est disponible
/// sur les stores, et affiche une invitation à mettre à jour le cas échéant.
class UpdateChecker {
  static const String _playUrl =
      'https://play.google.com/store/apps/details?id=com.iqra.schoolapp';
  static const String _appStoreUrl = 'https://apps.apple.com/app/id6818333559';

  static bool _checked = false;

  static String get _storeUrl {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return _appStoreUrl;
    }
    return _playUrl;
  }

  /// À appeler une fois après la première frame. Silencieux en cas d'échec.
  static Future<void> check(BuildContext context) async {
    if (_checked) return;
    _checked = true;
    try {
      final info = await PackageInfo.fromPlatform();
      final current = int.tryParse(info.buildNumber) ?? 0;
      final data = await ApiClient.instance.get('/api/public/register-info');
      final latest = asInt(data['latestAppVersion']);
      if (latest == 0 || latest <= current) return;
      final custom = asStr(data['appUpdateUrl']).trim();
      final target = custom.isNotEmpty ? custom : _storeUrl;
      if (!context.mounted) return;
      await _show(context, target);
    } catch (_) {
      // vérification facultative : on ignore les erreurs réseau
    }
  }

  static Future<void> _show(BuildContext context, String url) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 64, withName: false),
              const SizedBox(height: 16),
              Text(tr('تحديث جديد متوفر'),
                  textAlign: TextAlign.center,
                  style: ar(18, FontWeight.w700, AppColors.foreground)),
              const SizedBox(height: 8),
              Text(
                tr('هناك تحديث جديد للتطبيق. يرجى التحديث للاستفادة من آخر الميزات والتحسينات.'),
                textAlign: TextAlign.center,
                style: ar(14, FontWeight.w400, AppColors.zinc600, height: 1.6),
              ),
              const SizedBox(height: 22),
              AppButton(
                text: tr('تحديث الآن'),
                expand: true,
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _open(context, url);
                },
              ),
              const SizedBox(height: 8),
              AppButton(
                text: tr('لاحقًا'),
                variant: AppButtonVariant.ghost,
                expand: true,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _open(BuildContext context, String url) async {
    try {
      final ok = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        showToast(context, tr('تعذر فتح المتجر'), type: ToastType.error);
      }
    } catch (_) {
      if (context.mounted) showToast(context, tr('تعذر فتح المتجر'), type: ToastType.error);
    }
  }
}
