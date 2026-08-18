import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/brand.dart';
import '../../core/data.dart';
import '../../core/store.dart';
import 'message.dart';

class HomeScreen extends StatelessWidget {
  final void Function(String id, PaymentMethod method) onPickPayment;
  final void Function(String id, String auth) onSubmitAuth;
  final void Function(String id) onApproveReceipt;
  final void Function(String productId) onOpenInsight;
  final void Function(String id) onUndo;
  final void Function(String text) onStarter;
  final void Function(String id) onOpenProduct;

  const HomeScreen({
    super.key,
    required this.onPickPayment,
    required this.onSubmitAuth,
    required this.onApproveReceipt,
    required this.onOpenInsight,
    required this.onUndo,
    required this.onStarter,
    required this.onOpenProduct,
  });

  @override
  Widget build(BuildContext context) {
    final store = LumoScope.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(),
          const SizedBox(height: 16),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -24,
                left: -24,
                child: IgnorePointer(child: AiGlow(size: 160)),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: cardDeco(radius: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < briefing.paragraphs.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i == briefing.paragraphs.length - 1 ? 0 : 6,
                        ),
                        child: Text(
                          briefing.paragraphs[i],
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: i == 0
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: i == 0
                                ? AppColors.foreground
                                : AppColors.foreground.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Ventas hoy',
                  value: '\$2,430',
                  sub: '12 operaciones · +14 %',
                  tone: _Tone.ok,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Caja',
                  value: 'Todo coincide',
                  sub: 'Efectivo esperado \$940',
                  tone: _Tone.neutral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Inventario',
                  value: '3 productos',
                  sub: 'Lechuga puede agotarse',
                  tone: _Tone.warn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Pendiente',
                  value: '1 venta',
                  sub: '\$280 · sin autorización',
                  tone: _Tone.warn,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Sugerencias'),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final s in [
                  'Registrar una venta',
                  'Recibir mercadería',
                  'Ver qué falta',
                  'Preparar el cierre',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _SuggestionChip(text: s, onTap: () => onStarter(s)),
                  ),
              ],
            ),
          ),
          if (store.chat.isNotEmpty) ...[
            const SizedBox(height: 20),
            for (final m in store.chat)
              Message(
                msg: m,
                onPickPayment: onPickPayment,
                onSubmitAuth: onSubmitAuth,
                onApproveReceipt: onApproveReceipt,
                onOpenInsight: onOpenInsight,
                onUndo: onUndo,
              ),
          ],
          const SizedBox(height: 12),
          const _SectionLabel('Atención'),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onOpenProduct('lechuga'),
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                padding: const EdgeInsets.all(12),
                decoration: cardDeco(radius: 20),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.amberSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('🥬', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lechuga italiana',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.foreground,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Quedan 4 piezas · podría agotarse mañana',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.mutedForeground,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: Text(
              'Powered by Business OS',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.mutedForeground.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const LumoMark(size: 20),
            SizedBox(width: 8),
            Text(
              'Lumo · Carrota',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedForeground.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GradientText(
                  'Buenos días,',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
              TextSpan(
                text: ' Jorge.',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w500,
        color: AppColors.mutedForeground.withValues(alpha: 0.9),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: cardDeco(radius: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(fontSize: 14, color: AppColors.foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Tone { ok, warn, neutral }

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final _Tone tone;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final dot = switch (tone) {
      _Tone.ok => AppColors.primary,
      _Tone.warn => AppColors.amber,
      _Tone.neutral => AppColors.mutedForeground.withValues(alpha: 0.5),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDeco(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
              ),
              SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  color: AppColors.mutedForeground.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}
