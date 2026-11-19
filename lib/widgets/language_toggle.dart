import 'package:flutter/material.dart';
import '../core/l10n.dart';
import '../core/theme.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final french = isFr;
    return OutlinedButton.icon(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('اللغة', textAlign: TextAlign.center, style: ar(18, FontWeight.w700, AppColors.foreground)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _option(dialogContext, 'العربية', false, !french),
            const SizedBox(height: 8),
            _option(dialogContext, 'Français', true, french),
          ]),
        ),
      ),
      icon: const Icon(Icons.language, size: 18),
      label: Text(french ? 'Français' : 'العربية'),
    );
  }

  Widget _option(BuildContext context, String label, bool french, bool active) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: active ? AppColors.accentSoft : null,
            side: BorderSide(color: active ? AppColors.accent : AppColors.zinc300),
          ),
          onPressed: () {
            LocaleManager.instance.setFr(french);
            Navigator.pop(context);
          },
          child: Text(label, style: ar(14, FontWeight.w600, active ? AppColors.accent : AppColors.foreground)),
        ),
      );
}
