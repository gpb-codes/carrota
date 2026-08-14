import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Campo de respuesta del onboarding.
///
/// No conoce el proveedor: solo recibe controlador, texto de ayuda,
/// validación y callbacks. La pantalla coordina la interacción.
class OnboardingInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool enabled;

  const OnboardingInput({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
    this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmitted(),
              onChanged: onChanged,
              style: const TextStyle(color: AppColors.foreground, fontSize: 15),
              decoration: InputDecoration(
                hintText: hintText,
                errorText: errorText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: enabled ? onSubmitted : null,
            icon: const Icon(AppButtons.sendIcon, size: 20),
            color: AppButtons.sendForeground,
            style: AppButtons.primaryCircle,
          ),
        ],
      ),
    );
  }
}
