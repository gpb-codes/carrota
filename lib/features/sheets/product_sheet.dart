import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/data.dart';
import '../../core/store.dart';
import '../home/message.dart';

class ProductSheet extends StatelessWidget {
  final String? productId;

  const ProductSheet({super.key, this.productId});

  static const _heights = [30, 45, 40, 55, 62, 70, 78, 85, 72, 60, 50, 42];

  @override
  Widget build(BuildContext context) {
    final store = LumoScope.of(context);
    final p = productId == null ? null : store.productById(productId!);
    if (p == null) {
      return const Padding(padding: EdgeInsets.all(16), child: SizedBox());
    }
    final days = p.stock / (p.avgDaily ?? 1);
    final warn = days < 1.5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 140,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primarySoft, AppColors.accentSoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(p.emoji, style: const TextStyle(fontSize: 64)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    Text(
                      'Proveedor · ${p.supplier ?? '—'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                mxn(p.price),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ProductMetric(
                  label: 'Stock',
                  value: '${p.stock} ${p.unit}',
                  tone: warn ? _MetricTone.warn : _MetricTone.ok,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProductMetric(
                  label: 'Ventas/día',
                  value: '${p.avgDaily ?? 0}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProductMetric(
                  label: 'Alcance',
                  value: '${days.toStringAsFixed(1)} d',
                  tone: warn ? _MetricTone.warn : _MetricTone.ok,
                ),
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
                  'TENDENCIA DE STOCK',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    color: AppColors.mutedForeground.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 64,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final h in _heights)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.4 + h / 200,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              height: h / 100 * 64,
                            ),
                          ),
                        ),
                    ],
                  ),
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
                const Text(
                  'Las ventas aumentaron desde que comenzó la promoción de ensaladas. Al ritmo actual, el producto podría agotarse mañana antes de las 2 PM.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in [
                'Agregar a la lista de compra',
                'Cambiar precio',
                'Registrar llegada',
                'Preguntar sobre este producto',
              ])
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.foreground,
                    side: const BorderSide(color: AppColors.hairline),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(a, style: const TextStyle(fontSize: 14)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _MetricTone { neutral, ok, warn }

class _ProductMetric extends StatelessWidget {
  final String label;
  final String value;
  final _MetricTone tone;

  const _ProductMetric({
    required this.label,
    required this.value,
    this.tone = _MetricTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      _MetricTone.warn => (AppColors.amberSoft, AppColors.amber),
      _MetricTone.ok => (AppColors.primarySoft, AppColors.foreground),
      _MetricTone.neutral => (AppColors.surface2, AppColors.foreground),
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
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
              color: fg.withValues(alpha: tone == _MetricTone.warn ? 1 : 0.9),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
