import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';

/// Language switcher shown at the top of the auth screens.
/// Agents may pick French; the admin interface stays Arabic.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final fr = isFr;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _pill('العربية', active: !fr, onTap: () => LocaleManager.instance.setFr(false)),
        const SizedBox(width: 8),
        _pill('Français', active: fr, onTap: () => LocaleManager.instance.setFr(true)),
      ],
    );
  }

  Widget _pill(String label, {required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? AppColors.accent : AppColors.zinc300),
        ),
        child: Text(
          label,
          style: ar(13, FontWeight.w600, active ? Colors.white : AppColors.zinc600),
        ),
      ),
    );
  }
}