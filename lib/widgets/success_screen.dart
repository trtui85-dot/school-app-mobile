import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import 'ui.dart';

class SuccessScreen extends StatelessWidget {
  final String title;
  final String description;
  final String doneLabel;
  final VoidCallback onDone;
  const SuccessScreen({
    super.key,
    required this.title,
    required this.description,
    required this.onDone,
    this.doneLabel = 'حسنًا',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(color: AppColors.okSoft, shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 48, color: AppColors.ok),
                  ),
                ),
                const SizedBox(height: 24),
                Text(title, textAlign: TextAlign.center, style: ar(20, FontWeight.w700, AppColors.foreground)),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: ar(14, FontWeight.w400, AppColors.zinc500, height: 1.6),
                  ),
                ),
                const SizedBox(height: 32),
ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: AppButton(text: tr(doneLabel), expand: true, onPressed: onDone),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
