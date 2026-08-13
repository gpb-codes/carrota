import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/brand.dart';

/// Cabecera fija del onboarding: marca de Lumo y nombre.
class LumoHeader extends StatelessWidget {
  const LumoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          const LumoMark(size: 26),
          const SizedBox(width: 8),
          const Text(
            'Lumo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          const Spacer(),
          const Text(
            'Conociendo tu negocio',
            style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}
