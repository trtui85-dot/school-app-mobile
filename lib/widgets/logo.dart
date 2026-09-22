import 'package:flutter/material.dart';

import '../core/theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool withName;
  const AppLogo({super.key, this.size = 40, this.withName = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset('assets/logo.png', width: size, height: size, fit: BoxFit.contain),
        ),
        if (withName) ...[
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('مدارس اقرأ', style: ar(16, FontWeight.w700, AppColors.foreground)),
              Text('الحديثة', style: ar(12, FontWeight.w500, AppColors.zinc500)),
            ],
          ),
        ],
      ],
    );
  }
}
