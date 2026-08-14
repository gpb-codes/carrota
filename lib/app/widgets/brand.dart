import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// LumoMark: concentric gradient circle with pulsing glow.
class LumoMark extends StatefulWidget {
  final double size;

  const LumoMark({super.key, this.size = 32});

  @override
  State<LumoMark> createState() => _LumoMarkState();
}

class _LumoMarkState extends State<LumoMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value;
              final glow = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
              return Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: aiGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ai2.withValues(alpha: 0.45 * glow),
                      blurRadius: s * 0.5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              );
            },
          ),
          Container(
            width: s,
            height: s,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: aiGradient,
            ),
            child: Center(
              child: Container(
                width: s - 6,
                height: s - 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                ),
                child: Center(
                  child: Container(
                    width: s / 3,
                    height: s / 3,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: aiGradient,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft radial glow behind content (ai-gradient, aurora-like pulse).
class AiGlow extends StatefulWidget {
  final double size;

  const AiGlow({super.key, this.size = 160});

  @override
  State<AiGlow> createState() => _AiGlowState();
}

class _AiGlowState extends State<AiGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final scale = 1.0 + 0.08 * math.sin(t * 2 * math.pi);
        final opacity = 0.7 + 0.15 * math.sin(t * 2 * math.pi);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: aiGradient,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Text painted with the ai gradient.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const GradientText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => aiGradient.createShader(bounds),
      child: Text(text, style: style),
    );
  }
}

/// Rounded pill / rounded rectangle with the ai gradient.
class GradientChip extends StatelessWidget {
  final Widget child;

  const GradientChip({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: aiGradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: child,
    );
  }
}
