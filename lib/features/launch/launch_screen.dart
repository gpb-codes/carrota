import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/brand.dart';
import '../../core/data.dart';
import '../home/message.dart';

enum _Step { splash, hello, type, options, scanning, products, ready }

class LaunchScreen extends StatefulWidget {
  final VoidCallback onDone;

  const LaunchScreen({super.key, required this.onDone});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  _Step _step = _Step.splash;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _step = _Step.hello);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _step == _Step.splash
          ? const _Splash()
          : _Onboarding(
              step: _step,
              setStep: (s) => setState(() => _step = s),
              onDone: widget.onDone,
            ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Positioned.fill(
          child: IgnorePointer(child: AiGlow(size: 420)),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LumoMark(size: 72),
            const SizedBox(height: 24),
            GradientText(
              'Lumo',
              style: AppText.serifItalic.copyWith(fontSize: 48),
            ),
            const SizedBox(height: 8),
            const Text(
              'No administres tu negocio.\nHabla con él.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.foreground,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Ventas, inventario, caja y decisiones, entendidas por una sola inteligencia.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Onboarding extends StatelessWidget {
  final _Step step;
  final ValueChanged<_Step> setStep;
  final VoidCallback onDone;

  const _Onboarding({
    required this.step,
    required this.setStep,
    required this.onDone,
  });

  bool _after(_Step s) {
    const order = [
      _Step.hello,
      _Step.type,
      _Step.options,
      _Step.scanning,
      _Step.products,
      _Step.ready,
    ];
    return order.indexOf(step) >= order.indexOf(s);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
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
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Bubble(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Hola, soy ',
                            style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.foreground),
                          ),
                          TextSpan(
                            text: 'Lumo',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                          ),
                          TextSpan(
                            text: '.\nQuiero aprender cómo funciona tu negocio para ayudarte desde hoy.',
                            style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.foreground),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (step == _Step.hello)
                    const _Bubble(
                      child: Text(
                        '¿Cómo se llama?',
                        style: TextStyle(fontSize: 15, color: AppColors.foreground),
                      ),
                    ),
                  if (step != _Step.hello) const _UserBubble(text: 'Carrota.'),
                  if (step != _Step.hello)
                    const _Bubble(
                      child: Text(
                        '¿Qué tipo de negocio es Carrota?',
                        style: TextStyle(fontSize: 15, color: AppColors.foreground),
                      ),
                    ),
                  if (_after(_Step.options))
                    const _UserBubble(text: 'Un huerto urbano y tienda de productos sostenibles.'),
                  if (_after(_Step.options))
                    const _Bubble(
                      child: Text(
                        'Perfecto. Podemos comenzar de tres formas.',
                        style: TextStyle(fontSize: 15, color: AppColors.foreground),
                      ),
                    ),
                  if (step == _Step.options) ...[
                    const SizedBox(height: 8),
                    _OptionCard(
                      emoji: '📸',
                      title: 'Fotografiar mi lista de precios',
                      onTap: () => setStep(_Step.scanning),
                    ),
                    const SizedBox(height: 8),
                    const _OptionCard(emoji: '💬', title: 'Decirle algunos productos'),
                    const SizedBox(height: 8),
                    _OptionCard(
                      emoji: '✨',
                      title: 'Explorar con datos de ejemplo',
                      onTap: () => setStep(_Step.ready),
                    ),
                  ],
                  if (step == _Step.scanning) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: cardDeco(radius: 18),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: Text('📝', style: TextStyle(fontSize: 24))),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cuaderno de precios',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.foreground,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Analizando con inteligencia visual…',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const TagChip('Escaneando', tone: TagTone.ai),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _Shimmer(height: 96),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _LinkButton(
                        label: 'Ver resultados',
                        onTap: () => setStep(_Step.products),
                      ),
                    ),
                  ],
                  if (step == _Step.products) ...[
                    const SizedBox(height: 8),
                    const _Bubble(
                      child: Text(
                        'Encontré 8 productos en tu lista.',
                        style: TextStyle(fontSize: 15, color: AppColors.foreground),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: cardDeco(radius: 20),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (var i = 0; i < _foundProducts.length; i++)
                            _FoundRow(row: _foundProducts[i], showDivider: i > 0),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _Bubble(
                      child: Text(
                        'No estoy completamente seguro del precio del cilantro. ¿Son \$12?',
                        style: TextStyle(fontSize: 15, color: AppColors.foreground),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Wrap(
                      spacing: 8,
                      children: [
                        TagChip('Sí, \$12', tone: TagTone.ok),
                        _Pill('Ajustar'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _LinkButton(label: 'Continuar', onTap: () => setStep(_Step.ready)),
                    ),
                  ],
                  if (step == _Step.ready) ...[
                    const SizedBox(height: 8),
                    const _Bubble(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Carrota',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.foreground,
                              ),
                            ),
                            TextSpan(
                              text: ' está listo.\nYa puedes registrar ventas, recibir mercadería o preguntarme cómo va el negocio.',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: AppColors.foreground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GradientChip(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onDone,
                          borderRadius: BorderRadius.circular(16),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                'Empezar a hablar con Carrota',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (step == _Step.hello)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: _QuickReply(label: 'Carrota', onTap: () => setStep(_Step.type)),
            ),
          if (step == _Step.type)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: _QuickReply(
                label: 'Un huerto urbano y tienda sostenible',
                onTap: () => setStep(_Step.options),
              ),
            ),
        ],
      ),
    );
  }

  static const _foundProducts = [
    ('🍅', 'Tomate saladet', 'kg', 30, false),
    ('🥬', 'Lechuga italiana', 'pieza', 25, false),
    ('🥕', 'Zanahoria', 'kg', 20, false),
    ('🌿', 'Cilantro', 'manojo', 12, true),
    ('🥗', 'Espinaca', 'bolsa', 28, false),
    ('🥑', 'Aguacate', 'kg', 55, false),
    ('🍋', 'Limón', 'kg', 32, false),
    ('🍯', 'Mermelada artesanal', 'frasco', 95, false),
  ];
}

class _Bubble extends StatelessWidget {
  final Widget child;

  const _Bubble({required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2, right: 8),
          child: LumoMark(size: 22),
        ),
        Flexible(child: child),
      ],
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;

  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.primaryForeground,
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final VoidCallback? onTap;

  const _OptionCard({required this.emoji, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: cardDeco(radius: 20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.foreground,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickReply extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickReply({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: cardDeco(radius: 20),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LinkButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        '$label →',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _FoundRow extends StatelessWidget {
  final (String, String, String, int, bool) row;
  final bool showDivider;

  const _FoundRow({required this.row, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final (emoji, name, unit, price, uncertain) = row;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(top: BorderSide(color: AppColors.hairline))
            : null,
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.foreground,
                  ),
                ),
                Text(
                  'por $unit',
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          Text(
            mxn(price),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          if (uncertain) ...[
            const SizedBox(width: 8),
            const TagChip('¿\$12?', tone: TagTone.warn),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill(this.label);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.foreground,
        side: const BorderSide(color: AppColors.hairline),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final double height;

  const _Shimmer({required this.height});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
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
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF2EFE8),
                const Color(0xFFFBF9F4),
                const Color(0xFFF2EFE8),
              ],
              stops: [0, 0.5, 1],
              transform: _SlideGradientTransform(t),
            ),
          ),
        );
      },
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  final double t;

  const _SlideGradientTransform(this.t);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final shift = (t * 2 - 1) * bounds.width;
    return Matrix4.translationValues(shift, 0, 0);
  }
}
