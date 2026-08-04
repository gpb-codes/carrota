import 'package:flutter/material.dart';

import '../theme.dart';

enum AppTab { inicio, hoy, memoria, negocio, tienda }

class BottomNav extends StatelessWidget {
  final AppTab tab;
  final ValueChanged<AppTab> onChange;

  const BottomNav({super.key, required this.tab, required this.onChange});

  static const _items = <(AppTab, String, IconData)>[
    (AppTab.inicio, 'Inicio', Icons.home_rounded),
    (AppTab.hoy, 'Hoy', Icons.today_rounded),
    (AppTab.memoria, 'Memoria', Icons.auto_stories_rounded),
    (AppTab.negocio, 'Negocio', Icons.storefront_rounded),
    (AppTab.tienda, 'Tienda', Icons.smart_display_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: cardDeco(radius: 20),
        child: Row(
          children: [
            for (final (id, label, icon) in _items)
              Expanded(
                child: _NavItem(
                  active: tab == id,
                  label: label,
                  icon: icon,
                  onTap: () => onChange(id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final bool active;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _NavItem({
    required this.active,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.mutedForeground;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? AppColors.primarySoft : Colors.transparent,
              ),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: active ? 1 : 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
