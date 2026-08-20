import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/data.dart';
import '../../core/store.dart';
import '../home/message.dart';

class ProductSheet extends StatefulWidget {
  final String? productId;

  const ProductSheet({super.key, this.productId});

  @override
  State<ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<ProductSheet> {
  static const _heights = [30, 45, 40, 55, 62, 70, 78, 85, 72, 60, 50, 42];

  String? _activeId;

  @override
  void initState() {
    super.initState();
    _activeId = widget.productId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _activeId == null) return;
      LumoScope.of(context).noteViewed(_activeId!);
    });
  }

  void _openRelated(String productId) {
    setState(() => _activeId = productId);
  }

  @override
  Widget build(BuildContext context) {
    final store = LumoScope.of(context);
    final p = _activeId == null ? null : store.productById(_activeId!);
    if (p == null) {
      return const Padding(padding: EdgeInsets.all(16), child: SizedBox());
    }
    final days = p.stock / (p.avgDaily ?? 1);
    final warn = days < 1.5;
    final fav = store.isFavorite(p.id);
    final rating = store.ratingFor(p.id);
    final ratingCount = store.ratingCountFor(p.id);
    final topRank = store.topSellers.indexWhere((t) => t.product.id == p.id);
    final related = store.relatedTo(p.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SingleChildScrollView(
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
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                      Text(
                        'Proveedor · ${p.supplier ?? '—'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  mxn(p.price),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => store.toggleFavorite(p.id),
                  icon: Icon(
                    fav
                        ? Icons.favorite_rounded
                        : Icons.favorite_outline_rounded,
                    color: fav ? AppColors.danger : AppColors.mutedForeground,
                  ),
                  tooltip: fav ? 'Quitar de favoritos' : 'Agregar a favoritos',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  GestureDetector(
                    onTap: () => store.rateProduct(p.id, i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Icon(
                        i <= rating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 22,
                        color: i <= rating.round()
                            ? AppColors.amber
                            : AppColors.mutedForeground,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  ratingCount == 0
                      ? 'Sin reseñas todavía'
                      : '${rating.toStringAsFixed(1)} · $ratingCount reseñas',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const Spacer(),
                if (topRank >= 0)
                  TagChip('Top ${topRank + 1} ventas', tone: TagTone.ok),
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
            SizedBox(height: 16),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
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
                  Row(
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
                  Text(
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
            if (store.reviews[p.id]?.isNotEmpty ?? false) ...[
              SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: cardDeco(radius: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RESEÑAS DE CLIENTES',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: AppColors.mutedForeground.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final r in store.reviews[p.id]!) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              r.author.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      r.author,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.foreground,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    for (var i = 1; i <= 5; i++)
                                      Icon(
                                        i <= r.stars
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        size: 13,
                                        color: i <= r.stars
                                            ? AppColors.amber
                                            : AppColors.mutedForeground,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  r.text,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppColors.foreground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
            if (related.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                'También te puede interesar',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: related.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final r = related[i];
                    return InkWell(
                      onTap: () => _openRelated(r.id),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 120,
                        padding: const EdgeInsets.all(10),
                        decoration: cardDeco(radius: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.emoji, style: const TextStyle(fontSize: 22)),
                            const Spacer(),
                            Text(
                              r.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.foreground,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              mxn(r.price),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            SizedBox(height: 12),
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
                      side: BorderSide(color: AppColors.hairline),
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

