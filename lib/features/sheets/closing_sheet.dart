import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/brand.dart';
import '../../core/data.dart';

class ClosingSheet extends StatefulWidget {
  const ClosingSheet({super.key});

  @override
  State<ClosingSheet> createState() => _ClosingSheetState();
}

class _ClosingSheetState extends State<ClosingSheet> {
  static const _expected = 3150;

  final _controller = TextEditingController();
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final counted = int.tryParse(_controller.text) ?? 0;
    final hasCount = _controller.text.isNotEmpty;
    final diff = hasCount ? counted - _expected : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: !_done
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Row(
                  children: [
                    LumoMark(size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Preparé el cierre del martes.',
                      style: TextStyle(fontSize: 15, color: AppColors.foreground),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ClosingMetric(
                        label: 'Ventas totales',
                        value: mxn(8250),
                        tone: _MetricTone.ok,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ClosingMetric(label: 'Operaciones', value: '47'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ClosingMetric(
                        label: 'Efectivo esperado',
                        value: mxn(3150),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ClosingMetric(label: 'Tarjeta', value: mxn(4400)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: cardDeco(radius: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ATENCIÓN',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1,
                          color: AppColors.mutedForeground.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Una venta con tarjeta no tiene código de autorización.',
                        style: TextStyle(fontSize: 14, color: AppColors.foreground),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: cardDeco(radius: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Según las ventas, deberías tener ',
                              style: TextStyle(fontSize: 14, color: AppColors.foreground),
                            ),
                            TextSpan(
                              text: '\$3,150',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.foreground,
                              ),
                            ),
                            TextSpan(
                              text: ' en efectivo. ¿Cuánto contaste?',
                              style: TextStyle(fontSize: 14, color: AppColors.foreground),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                      if (diff != null && diff != 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Hay una diferencia de ${mxn(diff.abs())}. ¿Quieres agregar una nota o revisar las ventas en efectivo?',
                          style: const TextStyle(fontSize: 14, color: AppColors.amber),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.foreground,
                        side: const BorderSide(color: AppColors.hairline),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Agregar nota', style: TextStyle(fontSize: 14)),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.foreground,
                        side: const BorderSide(color: AppColors.hairline),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Revisar ventas', style: TextStyle(fontSize: 14)),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: hasCount
                            ? () => setState(() => _done = true)
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.primaryForeground,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.4),
                          disabledForegroundColor: AppColors.primaryForeground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cerrar el día',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primarySoft,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hoy vendiste 18 % más que el martes pasado. El tomate fue el producto más vendido y será necesario reponer lechuga mañana.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.foreground),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.foreground,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Listo', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
    );
  }
}

enum _MetricTone { neutral, ok }

class _ClosingMetric extends StatelessWidget {
  final String label;
  final String value;
  final _MetricTone tone;

  const _ClosingMetric({
    required this.label,
    required this.value,
    this.tone = _MetricTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tone == _MetricTone.ok ? AppColors.primarySoft : AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              color: AppColors.mutedForeground.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
