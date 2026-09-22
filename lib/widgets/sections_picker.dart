import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';

class SectionOption {
  final int id;
  final String name;
  final int registrationFee;
  final int monthlyFee;
  const SectionOption({
    required this.id,
    required this.name,
    required this.registrationFee,
    required this.monthlyFee,
  });
}

class SectionsPicker extends StatelessWidget {
  final String label;
  final List<SectionOption> sections;
  final int? value;
  final ValueChanged<int> onChange;
  const SectionsPicker({
    super.key,
    this.label = 'القسم المطلوب',
    required this.sections,
    required this.value,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    SectionOption? selected;
    for (final s in sections) {
      if (s.id == value) selected = s;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ar(14, FontWeight.w500, AppColors.zinc700)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _open(context),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(color: AppColors.zinc300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: selected == null
                      ? Text('— اختر القسم —', style: ar(14, FontWeight.w400, AppColors.zinc400))
                      : Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(selected.name, style: ar(14, FontWeight.w600, AppColors.foreground)),
                            Text('تسجيل ${formatMoney(selected.registrationFee)}', style: mono(12, FontWeight.w400, AppColors.accent)),
                            Text('شهري ${formatMoney(selected.monthlyFee)}', style: mono(12, FontWeight.w400, AppColors.zinc500)),
                          ],
                        ),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.zinc400),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.school_outlined, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('اختر القسم', style: AppText.title),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.zinc500),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (sections.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Text('لا توجد أقسام بعد', textAlign: TextAlign.center))
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sections.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final s = sections[i];
                      final isSelected = s.id == value;
                      return GestureDetector(
                        onTap: () {
                          onChange(s.id);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accentSoft : Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.control),
                            border: Border.all(color: isSelected ? AppColors.accent : AppColors.zinc200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name, style: ar(14, FontWeight.w700, AppColors.foreground)),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 12,
                                      children: [
                                        Text('رسوم التسجيل: ${formatMoney(s.registrationFee)}',
                                            style: ar(12, FontWeight.w400, AppColors.accent)),
                                        Text('الرسوم الشهرية: ${formatMoney(s.monthlyFee)}',
                                            style: ar(12, FontWeight.w400, AppColors.zinc600)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.accent : AppColors.zinc100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.check, size: 16, color: isSelected ? Colors.white : Colors.transparent),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
