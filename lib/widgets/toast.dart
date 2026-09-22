import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';

enum ToastType { success, error }

void showToast(BuildContext context, String message, {ToastType type = ToastType.success}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  final controller = _ToastController();
  entry = OverlayEntry(
    builder: (_) => _ToastWidget(
      message: message,
      type: type,
      controller: controller,
      onDismissed: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _ToastController {
  final _completer = Completer<void>();
  Future<void> get done => _completer.future;
  void close() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final _ToastController controller;
  final VoidCallback onDismissed;
  const _ToastWidget({
    required this.message,
    required this.type,
    required this.controller,
    required this.onDismissed,
  });
  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 300))..forward();
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), _dismiss);
  }

  void _dismiss() {
    if (_closing) return;
    _closing = true;
    _anim.reverse().whenComplete(() {
      widget.controller.close();
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isError = widget.type == ToastType.error;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero).animate(_anim),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: GestureDetector(
                onTap: _dismiss,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.zinc900.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isError ? AppColors.bad.withValues(alpha: 0.9) : AppColors.ok.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isError ? Icons.priority_high : Icons.check,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
