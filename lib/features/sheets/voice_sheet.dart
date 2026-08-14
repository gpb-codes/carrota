import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../app/theme.dart';
import '../../app/widgets/brand.dart';
import '../../core/data.dart';
import '../../core/mock_ai.dart';
import '../../core/store.dart';
import '../home/message.dart';

class VoiceSheet extends StatefulWidget {
  final void Function(String text) onConfirm;

  const VoiceSheet({super.key, required this.onConfirm});

  @override
  State<VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<VoiceSheet> {
  /// Fallback cuando speech_to_text no está disponible (web / sin permisos).
  static const _fallback =
      'Vendí tres bolsas de espinaca, dos lechugas y una mermelada. Pagaron en efectivo.';

  final _speech = SpeechToText();
  bool _ready = false;
  bool _listening = false;
  bool _simulating = false;
  bool _done = false;
  String _t = '';
  Timer? _typer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _ready = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            setState(() => _listening = false);
          }
        },
        onError: (_) {},
      );
    } catch (_) {
      _ready = false;
    }
    if (!mounted) return;
    if (_ready) {
      _listen();
    } else {
      _simulate();
    }
  }

  void _listen() {
    if (!_ready) return;
    setState(() {
      _listening = true;
      _done = false;
      _simulating = false;
    });
    _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: 'es-MX',
        listenFor: const Duration(seconds: 10),
        partialResults: true,
      ),
      onResult: (r) {
        setState(() => _t = r.recognizedWords.trim());
        if (r.finalResult) {
          setState(() {
            _listening = false;
            _done = true;
          });
        }
      },
    );
  }

  void _simulate() {
    _simulating = true;
    var i = 0;
    _typer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      i++;
      setState(() => _t = _fallback.substring(0, i.clamp(0, _fallback.length)));
      if (i >= _fallback.length) {
        timer.cancel();
        Timer(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _done = true);
        });
      }
    });
  }

  void _retry() {
    if (_ready) {
      _listen();
    } else if (!_simulating) {
      _simulate();
    }
  }

  @override
  void dispose() {
    _typer?.cancel();
    _speech.stop();
    super.dispose();
  }

  void _confirm() {
    widget.onConfirm(_t.isEmpty ? _fallback : _t);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = LumoScope.of(context);
    final lines = parseSale(_t.isEmpty ? _fallback : _t, store.products);
    final total = totalOf(lines, store.products);
    final showConfirm =
        lines.isNotEmpty &&
        (_simulating ? _done : _ready && !_listening && _t.isNotEmpty);

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
                    text: _t.isEmpty ? 'Escuchando…' : _t,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.foreground,
                    ),
                  ),
                  const WidgetSpan(child: _Cursor()),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (showConfirm) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const LumoMark(size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lines.length == 1
                        ? 'Entendí este producto'
                        : 'Entendí esta venta',
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
              child: Column(
                children: [
                  for (var i = 0; i < lines.length; i++)
                    _VoiceLine(line: lines[i], showDivider: i > 0),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                  ),
                ),
                Text(
                  mxn(total),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _confirm,
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _retry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.foreground,
                    side: BorderSide(color: AppColors.hairline),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Intentar de nuevo',
                    style: TextStyle(fontSize: 14),
                  ),
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

class _MicOrb extends StatelessWidget {
  const _MicOrb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: aiGradient,
        boxShadow: const [
          BoxShadow(color: Color(0x994EC983), blurRadius: 40, spreadRadius: 4),
        ],
      ),
      child: const Icon(Icons.mic_rounded, size: 36, color: Colors.white),
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
                  height:
                      (20 + math.sin(i) * 12 + (i % 5) * 4) * (0.3 + 0.7 * t),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _VoiceLine extends StatelessWidget {
  final SaleLine line;
  final bool showDivider;

  const _VoiceLine({required this.line, this.showDivider = false});

  @override
  Widget build(BuildContext context) {
    final p = LumoScope.of(context).productById(line.productId);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: showDivider
          ? BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.hairline)),
            )
          : null,
      child: Row(
        children: [
          Text(p?.emoji ?? '🛒', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p?.name ?? line.productId,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.foreground,
                  ),
                ),
                Text(
                  '${line.qty} ${p?.unit ?? ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Text(
            p == null ? '' : mxn(p.price * line.qty),
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
