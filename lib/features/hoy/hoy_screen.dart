import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../home/message.dart';

class HoyScreen extends StatelessWidget {
  final VoidCallback onOpenClosing;

  const HoyScreen({super.key, required this.onOpenClosing});

  static const _heights = [12, 20, 15, 28, 36, 60, 78, 84, 62, 40, 30, 22];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'HOY',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedForeground.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Así va Carrota hoy',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Vendiste ',
                  style: TextStyle(fontSize: 15, color: Color(0xCC151B24)),
                ),
                TextSpan(
                  text: '\$4,850',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                TextSpan(
                  text: ' en 28 operaciones.',
                  style: TextStyle(fontSize: 15, color: Color(0xCC151B24)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDeco(radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INGRESOS',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: AppColors.mutedForeground.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '\$4,850',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    SizedBox(width: 10),
                    TagChip('+18 % vs martes pasado', tone: TagTone.ok),
                  ],
                ),
                const SizedBox(height: 16),
                const _Sparkline(heights: _heights),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: cardDeco(radius: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MiniLabel('Pagos'),
                      const SizedBox(height: 6),
                      const _PayRow('Efectivo', '\$1,950'),
                      const _PayRow('Tarjeta', '\$2,400'),
                      const _PayRow('Transferencias', '\$500'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: cardDeco(radius: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MiniLabel('Más vendido'),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Text('🍅', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tomate saladet',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.foreground,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '32 kg vendidos',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDeco(radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    TagChip('Resumen', tone: TagTone.ai),
                    SizedBox(width: 8),
                    Text(
                      'Lumo observa',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.foreground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Las ventas fueron más fuertes entre las ',
                        style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.foreground),
                      ),
                      TextSpan(
                        text: '12:00',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                      TextSpan(
                        text: ' y las ',
                        style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.foreground),
                      ),
                      TextSpan(
                        text: '14:00',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                      TextSpan(
                        text: '. El tomate representó el ',
                        style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.foreground),
                      ),
                      TextSpan(
                        text: '28 %',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                      TextSpan(
                        text: ' de los ingresos del día.',
                        style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.foreground),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'PREGUNTAS',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedForeground.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final q in ['¿Por qué vendimos más?', 'Ver ventas con tarjeta', '¿Qué se puede agotar?', 'Comparar con la semana pasada'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: cardDeco(radius: 20),
                      child: Text(
                        q,
                        style: const TextStyle(fontSize: 14, color: AppColors.foreground),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpenClosing,
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                padding: const EdgeInsets.all(16),
                decoration: cardDeco(radius: 20),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        gradient: aiGradient,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: const Center(child: Text('🌙', style: TextStyle(fontSize: 18))),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preparar el cierre del día',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.foreground,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Confirma efectivo y revisa pendientes',
                            style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.mutedForeground),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  final String text;

  const _MiniLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1,
        color: AppColors.mutedForeground.withValues(alpha: 0.9),
      ),
    );
  }
}

class _PayRow extends StatelessWidget {
  final String label;
  final String value;

  const _PayRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.foreground),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: AppColors.foreground),
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<int> heights;

  const _Sparkline({required this.heights});

  @override
  Widget build(BuildContext context) {
    final max = heights.reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 96,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final h in heights)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: h / max),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (context, t, _) => Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(
                            alpha: 0.35 + (h / max) * 0.65,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        height: 96 * t,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('8:00', style: TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
            Text('12:00', style: TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
            Text('16:00', style: TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
            Text('20:00', style: TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
          ],
        ),
      ],
    );
  }
}
