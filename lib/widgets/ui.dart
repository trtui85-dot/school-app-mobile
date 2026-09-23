import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';

enum AppButtonVariant { primary, outline, danger, success, ghost }

class AppButton extends StatelessWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final bool expand;
  const AppButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    Border? border;
    switch (variant) {
      case AppButtonVariant.primary:
        bg = AppColors.accent;
        fg = Colors.white;
        break;
      case AppButtonVariant.outline:
        bg = Colors.white;
        fg = AppColors.foreground;
        border = Border.all(color: AppColors.zinc300);
        break;
      case AppButtonVariant.danger:
        bg = AppColors.bad;
        fg = Colors.white;
        break;
      case AppButtonVariant.success:
        bg = AppColors.ok;
        fg = Colors.white;
        break;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.accent;
        break;
    }
    final disabled = onPressed == null || loading;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          ),
          const SizedBox(width: 8),
        ],
        if (child != null) child! else Text(text ?? '', style: ar(14, FontWeight.w600, fg)),
      ],
    );
    final btn = Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: disabled ? null : onPressed,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: border,
            ),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class AppInput extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool ltr;
  final bool number;
  final int? maxLength;
  final Widget? suffix;
  final Widget? prefix;
  final String? error;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final String? initialValue;

  const AppInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.ltr = false,
    this.number = false,
    this.maxLength,
    this.suffix,
    this.prefix,
    this.error,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.maxLines = 1,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: ar(14, FontWeight.w500, AppColors.zinc700)),
          const SizedBox(height: 6),
        ],
        TextFormField(
          initialValue: initialValue,
          controller: controller,
          keyboardType: keyboardType ?? (number ? const TextInputType.numberWithOptions(decimal: false, signed: false) : TextInputType.text),
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
          textInputAction: textInputAction,
          textDirection: ltr ? TextDirection.ltr : null,
          textAlign: ltr ? TextAlign.left : TextAlign.right,
          style: ar(14, FontWeight.w400, AppColors.foreground),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: ar(14, FontWeight.w400, AppColors.zinc400),
            filled: true,
            fillColor: enabled ? Colors.white : AppColors.zinc50,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            prefixIcon: prefix,
            suffixIcon: suffix,
            errorText: error,
            errorStyle: ar(12, FontWeight.w400, AppColors.bad),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
              borderSide: const BorderSide(color: AppColors.zinc300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
              borderSide: const BorderSide(color: AppColors.zinc200),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
              borderSide: const BorderSide(color: AppColors.zinc300),
            ),
          ),
        ),
      ],
    );
  }
}

class AppTextarea extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final int minLines;
  final ValueChanged<String>? onChanged;
  const AppTextarea({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.minLines = 3,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: ar(14, FontWeight.w500, AppColors.zinc700)),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          minLines: minLines,
          maxLines: null,
          onChanged: onChanged,
          style: ar(14, FontWeight.w400, AppColors.foreground),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: ar(14, FontWeight.w400, AppColors.zinc400),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
              borderSide: const BorderSide(color: AppColors.zinc300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
              borderSide: const BorderSide(color: AppColors.zinc300),
            ),
          ),
        ),
      ],
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  const AppCard({super.key, required this.child, this.padding, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.zinc100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

enum BadgeTone { neutral, pending, ok, bad }

class AppBadge extends StatelessWidget {
  final String text;
  final BadgeTone tone;
  const AppBadge(this.text, {super.key, this.tone = BadgeTone.neutral});

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    switch (tone) {
      case BadgeTone.neutral:
        bg = AppColors.zinc100;
        fg = AppColors.zinc700;
        break;
      case BadgeTone.pending:
        bg = AppColors.pendingSoft;
        fg = AppColors.pending;
        break;
      case BadgeTone.ok:
        bg = AppColors.okSoft;
        fg = AppColors.ok;
        break;
      case BadgeTone.bad:
        bg = AppColors.badSoft;
        fg = AppColors.bad;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: ar(12, FontWeight.w600, fg)),
    );
  }
}

class AppEmpty extends StatelessWidget {
  final String title;
  final String? hint;
  const AppEmpty({super.key, required this.title, this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: ar(14, FontWeight.w600, AppColors.zinc500)),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint!, textAlign: TextAlign.center, style: ar(12, FontWeight.w400, AppColors.zinc400)),
          ],
        ],
      ),
    );
  }
}

class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key});
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.accent),
        ),
      ),
    );
  }
}

class ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorBox(this.message, {super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.badSoft,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Column(
        children: [
          Text(message, style: ar(14, FontWeight.w400, AppColors.bad)),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            AppButton(text: tr('إعادة المحاولة'), variant: AppButtonVariant.outline, onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}

/// A form field that opens a bottom-sheet list of options.
class AppSelectField<T> extends StatelessWidget {
  final String? label;
  final String placeholder;
  final T? value;
  final List<AppSelectOption<T>> options;
  final ValueChanged<T?> onChanged;
  const AppSelectField({
    super.key,
    this.label,
    required this.placeholder,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = options.where((o) => o.value == value).toList();
    final text = selected.isEmpty ? placeholder : selected.first.label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: ar(14, FontWeight.w500, AppColors.zinc700)),
          const SizedBox(height: 6),
        ],
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.control),
            onTap: () async {
              final picked = await showModalBottomSheet<_SelectResult<T>>(
                context: context,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
                ),
                builder: (_) => _SelectSheet<T>(options: options),
              );
              if (picked != null) onChanged(picked.value);
            },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(color: AppColors.zinc300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: ar(14, FontWeight.w400, selected.isEmpty ? AppColors.zinc400 : AppColors.foreground),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.zinc400),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AppSelectOption<T> {
  final T value;
  final String label;
  const AppSelectOption(this.value, this.label);
}

class _SelectResult<T> {
  final T value;
  const _SelectResult(this.value);
}

class _SelectSheet<T> extends StatelessWidget {
  final List<AppSelectOption<T>> options;
  const _SelectSheet({required this.options});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.zinc200, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(12),
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final o = options[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    onTap: () => Navigator.pop(context, _SelectResult(o.value)),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      child: Text(o.label, style: ar(14, FontWeight.w500, AppColors.foreground)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
