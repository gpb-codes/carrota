import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/brand.dart';
import '../../core/data.dart';
import '../../core/store.dart';

class ClosingSheet extends StatefulWidget {
  const ClosingSheet({super.key});

  @override
  State<ClosingSheet> createState() => _ClosingSheetState();
}

class _ClosingSheetState extends State<ClosingSheet> {
  final _controller = TextEditingController();
  bool _done = false;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    final store = LumoScope.of(context);
    setState(() => _saving = true);
    await store.closeDay(
      note: _controller.text.trim().isEmpty ? null : _controller.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = LumoScope.of(context);
    final s = store.summary;
    final expected = s?.byPayment.efectivo ?? 3150;
    final salesTotal = s?.salesTotal ?? 8250;
    final ops = s?.salesCount ?? 47;
    final card = s?.byPayment.tarjeta ?? 4400;

    final counted = int.tryParse(_controller.text) ?? 0;
    final hasCount = _controller.text.isNotEmpty;
    final diff = hasCount ? counted - expected : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: !_done
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    LumoMark(size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Preparé el cierre del día.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.foreground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ClosingMetric(
                        label: 'Ventas totales',
                        value: mxn(salesTotal),
                        tone: _MetricTone.ok,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ClosingMetric(
                        label: 'Operaciones',
                        value: '$ops',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ClosingMetric(
                        label: 'Efectivo esperado',
                        value: mxn(expected),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ClosingMetric(label: 'Tarjeta', value: mxn(card)),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (s != null && s.openAuth > 0)
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
                            color: AppColors.mutedForeground.withValues(
                              alpha: 0.9,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${s.openAuth} venta(s) con tarjeta no tienen código de autorización.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (s != null && s.openAuth > 0) const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: cardDeco(radius: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Según las ventas, deberías tener ',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.foreground,
                              ),
                            ),
                            TextSpan(
                              text: mxn(expected),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.foreground,
                              ),
                            ),
                            TextSpan(
                              text: ' en efectivo. ¿Cuánto contaste?',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.foreground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
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
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.amber,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.foreground,
                        side: BorderSide(color: AppColors.hairline),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Agregar nota',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.foreground,
                        side: BorderSide(color: AppColors.hairline),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Revisar ventas',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: hasCount && !_saving ? _close : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.primaryForeground,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          disabledBackgroundColor: AppColors.primary.withValues(
                            alpha: 0.4,
                          ),
                          disabledForegroundColor: AppColors.primaryForeground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _saving ? 'Cerrando…' : 'Cerrar el día',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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
                Text(
                  'Cierre guardado. El resumen del día y la memoria se actualizaron.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.foreground,
                  ),
                ),
                SizedBox(height: 16),
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
        color: tone == _MetricTone.ok
            ? AppColors.primarySoft
            : AppColors.surface2,
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
            style: TextStyle(
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
