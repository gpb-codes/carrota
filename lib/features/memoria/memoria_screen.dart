import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/brand.dart';
import '../../core/data.dart';
import '../../core/store.dart';
import '../home/message.dart';

class MemoriaScreen extends StatefulWidget {
  const MemoriaScreen({super.key});

  @override
  State<MemoriaScreen> createState() => _MemoriaScreenState();
}

class _MemoriaScreenState extends State<MemoriaScreen> {
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = LumoScope.of(context);
    final filtered = store.memory.where((m) {
      if (_q.isEmpty) return true;
      return '${m.title} ${m.detail ?? ''}'.toLowerCase().contains(
        _q.toLowerCase(),
      );
    }).toList();

    final groups = <String, List<MemoryEvent>>{};
    for (final m in filtered) {
      groups.putIfAbsent(m.group, () => []).add(m);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'MEMORIA',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedForeground.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Lo que Lumo recuerda de ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GradientText(
                    'Carrota',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Container(
            decoration: cardDeco(radius: 16, color: AppColors.surface),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text('🔎'),
                ),
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _q = v),
                    decoration: const InputDecoration(
                      hintText:
                          'Pregunta algo sobre la historia de tu negocio…',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final s in [
                  '¿Cuándo cambié el precio del tomate?',
                  '¿A quién le compro lechuga?',
                  '¿Qué pasó el lunes pasado?',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: () {
                        _search.text = s;
                        setState(() => _q = s);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.mutedForeground,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(color: AppColors.hairline),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(s, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 16),
          for (final entry in groups.entries) ...[
            Text(
              entry.key.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                color: AppColors.mutedForeground.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 8),
            for (final m in entry.value) _MemoryCard(event: m),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDeco(radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MiniLabel('Actividad'),
                const SizedBox(height: 12),
                for (var i = 0; i < store.timeline.length; i++)
                  _TimelineRow(
                    t: store.timeline[i],
                    isLast: i == store.timeline.length - 1,
                  ),
              ],
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

class _MemoryCard extends StatelessWidget {
  final MemoryEvent event;

  const _MemoryCard({required this.event});

  TagTone _tone() {
    if (event.kind == 'Registrado') return TagTone.ok;
    if (event.kind == 'Patrón observado') return TagTone.ai;
    return TagTone.neutral;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: cardDeco(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TagChip(event.kind, tone: _tone()),
              const SizedBox(width: 8),
              Text(
                event.when,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.title,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.foreground,
            ),
          ),
          if (event.detail != null) ...[
            const SizedBox(height: 4),
            Text(
              event.detail!,
              style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            children: [
              for (final action in [
                'Ver evidencia',
                'Corregir',
                'Olvidar',
                'Explicar',
              ])
                InkWell(
                  onTap: () {},
                  child: Text(
                    action,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final TimelineEvent t;
  final bool isLast;

  const _TimelineRow({required this.t, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const SizedBox(height: 5),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 1, color: AppColors.hairline)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        t.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      if (t.tag != null) ...[
                        const SizedBox(width: 8),
                        TagChip(t.tag!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.title,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: AppColors.foreground,
                    ),
                  ),
                  if (t.detail != null)
                    Text(
                      t.detail!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
