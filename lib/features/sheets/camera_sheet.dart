import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/brand.dart';
import '../../core/data.dart';
import '../home/message.dart';

class CameraSheet extends StatefulWidget {
  final VoidCallback onImportReceipt;

  const CameraSheet({super.key, required this.onImportReceipt});

  @override
  State<CameraSheet> createState() => _CameraSheetState();
}

enum _Phase { aim, scan, done }

class _CameraSheetState extends State<CameraSheet> {
  _Phase _phase = _Phase.aim;
  Timer? _t1;
  Timer? _t2;

  @override
  void initState() {
    super.initState();
    _t1 = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _phase = _Phase.scan);
    });
    _t2 = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _phase = _Phase.done);
    });
  }

  @override
  void dispose() {
    _t1?.cancel();
    _t2?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _phase == _Phase.done;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Container(
                color: AppColors.surface2,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const Center(
                      child: Text('📝', style: TextStyle(fontSize: 56)),
                    ),
                    // camera frame
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (!done) const Positioned.fill(child: _ScanLine()),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TagChip(
                            done ? 'Analizado' : 'Analizando…',
                            tone: TagTone.ai,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (done) ...[
            const SizedBox(height: 16),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LumoMark(size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Encontré una entrega de ',
                          style: TextStyle(fontSize: 14, color: AppColors.foreground),
                        ),
                        TextSpan(
                          text: 'Huerto Norte',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                        ),
                        TextSpan(
                          text: ' por ',
                          style: TextStyle(fontSize: 14, color: AppColors.foreground),
                        ),
                        TextSpan(
                          text: '\$1,450',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                        ),
                        TextSpan(
                          text: '.',
                          style: TextStyle(fontSize: 14, color: AppColors.foreground),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: cardDeco(radius: 18),
              child: const Column(
                children: [
                  _ReceiptLine(emoji: '🍅', name: 'Tomate saladet', qty: '20 kg', total: 600),
                  Divider(height: 1, color: AppColors.hairline),
                  _ReceiptLine(emoji: '🥬', name: 'Lechuga italiana', qty: '15 piezas', total: 420),
                  Divider(height: 1, color: AppColors.hairline),
                  _ReceiptLine(emoji: '🥗', name: 'Espinaca', qty: '10 bolsas', total: 280),
                  Divider(height: 1, color: AppColors.hairline),
                  _ReceiptLine(emoji: '🌿', name: 'Cilantro', qty: '12 manojos', total: 150),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onImportReceipt();
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
                      'Agregar al inventario',
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
                  child: const Text('Revisar', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ScanLine extends StatefulWidget {
  const _ScanLine();

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
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
        final t = (_c.value * 2) % 1;
        return Align(
          alignment: Alignment(0, -1 + t * 2),
          child: Container(
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: aiGradient,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ai2.withValues(alpha: 0.6),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  final String emoji;
  final String name;
  final String qty;
  final int total;

  const _ReceiptLine({
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
