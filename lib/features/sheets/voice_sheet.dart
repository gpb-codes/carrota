import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/brand.dart';
import '../../core/data.dart';
import '../home/message.dart';

class VoiceSheet extends StatefulWidget {
  final void Function(String text) onConfirm;

  const VoiceSheet({super.key, required this.onConfirm});

  @override
  State<VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<VoiceSheet> {
  static const _target =
      'Vendí tres bolsas de espinaca, dos lechugas y una mermelada. Pagaron en efectivo.';

  bool _understood = false;
  String _t = '';
  Timer? _typer;

  @override
  void initState() {
    super.initState();
    var i = 0;
    _typer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      i++;
      setState(() => _t = _target.substring(0, i.clamp(0, _target.length)));
      if (i >= _target.length) {
        timer.cancel();
        Timer(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _understood = true);
        });
      }
    });
  }

  @override
  void dispose() {
    _typer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Center(child: _MicOrb()),
          const SizedBox(height: 16),
          const _Wave(),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: _t,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.foreground,
                    ),
                  ),
                  if (!_understood)
                    const WidgetSpan(
                      child: _Cursor(),
                    ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (_understood) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const LumoMark(size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Entendí esta venta',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                const TagChip('Preparado', tone: TagTone.ai),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: cardDeco(radius: 18),
              child: const Column(
                children: [
                  _VoiceLine(emoji: '🥗', name: 'Espinaca', qty: '3 bolsas', total: 84),
                  Divider(height: 1, color: AppColors.hairline),
                  _VoiceLine(emoji: '🥬', name: 'Lechuga italiana', qty: '2 piezas', total: 56),
                  Divider(height: 1, color: AppColors.hairline),
                  _VoiceLine(emoji: '🍯', name: 'Mermelada artesanal', qty: '1 frasco', total: 95),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total · Efectivo',
                  style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
                ),
                Text(
                  '\$235',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onConfirm(_target);
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.primaryForeground,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Confirmar',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.foreground,
                    side: const BorderSide(color: AppColors.hairline),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Corregir hablando', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Cursor extends StatefulWidget {
  const _Cursor();

  @override
  State<_Cursor> createState() => _CursorState();
}

class _CursorState extends State<_Cursor> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(
        width: 2,
        height: 16,
        margin: const EdgeInsets.only(left: 2),
        color: AppColors.foreground,
      ),
    );
  }
}

class _MicOrb extends StatefulWidget {
  const _MicOrb();

  @override
  State<_MicOrb> createState() => _MicOrbState();
}

class _MicOrbState extends State<_MicOrb> with SingleTickerProviderStateMixin {
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
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final glow = 0.55 + 0.45 * math.sin(t * 2 * math.pi);
        return Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: aiGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.ai2.withValues(alpha: 0.6 * glow),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.mic_rounded, size: 36, color: Colors.white),
        );
      },
    );
  }
}

class _Wave extends StatefulWidget {
  const _Wave();

  @override
  State<_Wave> createState() => _WaveState();
}

class _WaveState extends State<_Wave> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
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
        return SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < 24; i++)
                Container(
                  width: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    gradient: aiGradient,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  height: (20 + math.sin(i) * 12 + (i % 5) * 4) * (0.3 + 0.7 * t),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _VoiceLine extends StatelessWidget {
  final String emoji;
  final String name;
  final String qty;
  final int total;

  const _VoiceLine({
    required this.emoji,
    required this.name,
    required this.qty,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
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
                  qty,
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          Text(
            mxn(total),
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
