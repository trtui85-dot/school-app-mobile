import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Floating iOS-style tab bar: frosted glass capsule, pill highlight on the
/// selected item, smooth animated icon/label swaps.
class IOSNavItem {
  final Object id;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const IOSNavItem({required this.id, required this.label, required this.icon, required this.activeIcon});
}

class IOSBottomBar extends StatelessWidget {
  final List<IOSNavItem> items;
  final Object selected;
  final ValueChanged<Object> onSelect;
  const IOSBottomBar({super.key, required this.items, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(child: _item(items[i], items[i].id == selected, () => onSelect(items[i].id))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(IOSNavItem item, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            width: active ? 30 : 26,
            height: active ? 30 : 26,
            decoration: BoxDecoration(
              color: active ? AppColors.accent.withValues(alpha: 0.12) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Icon(
                  active ? item.activeIcon : item.icon,
                  key: ValueKey('${active}_${item.id}'),
                  size: active ? 20 : 19,
                  color: active ? AppColors.accent : AppColors.zinc500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: ar(10, active ? FontWeight.w700 : FontWeight.w500,
                active ? AppColors.accent : AppColors.zinc400),
            child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}