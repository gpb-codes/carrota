import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/brand.dart';
import '../../core/data.dart';
import '../../core/store.dart';

/* ─── Shared chips & bubbles ─── */

enum TagTone { neutral, ai, ok, warn }

class TagChip extends StatelessWidget {
  final String text;
  final TagTone tone;

  const TagChip(this.text, {super.key, this.tone = TagTone.neutral});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      TagTone.ai => (AppColors.accentSoft, AppColors.primary),
      TagTone.ok => (AppColors.primarySoft, AppColors.primary),
      TagTone.warn => (AppColors.amberSoft, AppColors.amber),
      TagTone.neutral => (AppColors.surface2, AppColors.mutedForeground),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final Widget child;
  final Role role;

  const ChatBubble({super.key, required this.child, required this.role});

  @override
  Widget build(BuildContext context) {
    if (role == Role.user) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 310),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(6),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x301C8742),
                offset: Offset(0, 3),
                blurRadius: 10,
              ),
            ],
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: AppColors.primaryForeground,
              fontSize: 15,
              height: 1.5,
            ),
            child: child,
          ),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2, right: 8),
          child: LumoMark(size: 26),
        ),
        Flexible(
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: AppColors.foreground,
              fontSize: 15,
              height: 1.5,
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}

/* ─── Message dispatcher ─── */

class Message extends StatelessWidget {
  final ChatMsg msg;
  final void Function(String id, PaymentMethod method) onPickPayment;
  final void Function(String id, String auth) onSubmitAuth;
  final void Function(String id) onApproveReceipt;
  final void Function(String productId) onOpenInsight;
  final void Function(String id) onUndo;

  const Message({
    super.key,
    required this.msg,
    required this.onPickPayment,
    required this.onSubmitAuth,
    required this.onApproveReceipt,
    required this.onOpenInsight,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final m = msg;
    if (m.role == Role.user) {
      return _Rise(
        child: ChatBubble(role: Role.user, child: Text(m.text ?? '')),
      );
    }
    switch (m.kind) {
      case MsgKind.text:
        return _Rise(
          child: ChatBubble(role: Role.lumo, child: Text(m.text ?? '')),
        );
      case MsgKind.saleProposal:
        return _Rise(
          child: _SaleProposalCard(
            m: m,
            onPickPayment: onPickPayment,
            onSubmitAuth: onSubmitAuth,
            onUndo: onUndo,
          ),
        );
      case MsgKind.receipt:
        return _Rise(
          child: _ReceiptCard(m: m, onApproveReceipt: onApproveReceipt),
        );
      case MsgKind.insight:
        return _Rise(
          child: _InsightCard(m: m, onOpenInsight: onOpenInsight),
        );
      case MsgKind.impact:
        return _Rise(child: _ImpactCard(m: m));
      case null:
        return const SizedBox.shrink();
    }
  }
}

class _Rise extends StatelessWidget {
  final Widget child;

  const _Rise({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

Widget _card({required Widget child}) => Container(
  padding: const EdgeInsets.all(16),
  margin: const EdgeInsets.only(bottom: 12),
  decoration: cardDeco(radius: 20),
  child: child,
);

Widget _headerRow({required TagChip chip, required String title}) => Row(
  children: [
    chip,
    const SizedBox(width: 8),
    Expanded(
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.foreground,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
);

class _SaleProposalCard extends StatelessWidget {
  final ChatMsg m;
  final void Function(String id, PaymentMethod method) onPickPayment;
  final void Function(String id, String auth) onSubmitAuth;
  final void Function(String id) onUndo;

  const _SaleProposalCard({
    required this.m,
    required this.onPickPayment,
    required this.onSubmitAuth,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final sale = m.sale!;
    final confirmed = m.confirmed ?? false;
    return ChatBubble(
      role: Role.lumo,
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _headerRow(
              chip: TagChip(
                confirmed ? 'Registrado' : 'Preparado',
                tone: confirmed ? TagTone.ok : TagTone.ai,
              ),
              title: 'Venta ${confirmed ? 'registrada' : 'preparada'}',
            ),
            const SizedBox(height: 12),
            for (final l in sale.lines) _SaleLineRow(line: l),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  mxn(sale.total),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ),
            if (sale.payment != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const TagChip('Pago', tone: TagTone.ok),
                  const SizedBox(width: 8),
                  Text(
                    _payLabel(sale.payment!),
                    style: TextStyle(fontSize: 14, color: AppColors.foreground),
                  ),
                  if (sale.authCode != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '· Autorización ${sale.authCode}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (m.awaitingPayment ?? false) ...[
              const SizedBox(height: 12),
              Text(
                '¿Cómo pagó?',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final method in const [
                    PaymentMethod.efectivo,
                    PaymentMethod.tarjeta,
                    PaymentMethod.transferencia,
                    PaymentMethod.combinado,
                  ])
                    _pillButton(
                      label: _payLabel(method),
                      onTap: () => onPickPayment(m.id, method),
                    ),
                ],
              ),
            ],
            if (m.awaitingAuth ?? false) ...[
              const SizedBox(height: 12),
              _AuthInput(onSubmit: (v) => onSubmitAuth(m.id, v)),
            ],
            if (confirmed) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Ver detalle'),
                  ),
                  SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () => onUndo(m.id),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.mutedForeground,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.undo_rounded, size: 15),
                    label: const Text('Deshacer'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SaleLineRow extends StatelessWidget {
  final SaleLine line;

  const _SaleLineRow({required this.line});

  @override
  Widget build(BuildContext context) {
    final store = LumoScope.of(context);
    final p = store.productById(line.productId);
    if (p == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(p.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${line.qty} × ${p.unit} · ${mxn(p.price)} c/u',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Text(
            mxn(p.price * line.qty),
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

class _ReceiptCard extends StatelessWidget {
  final ChatMsg m;
  final void Function(String id) onApproveReceipt;

  const _ReceiptCard({required this.m, required this.onApproveReceipt});

  @override
  Widget build(BuildContext context) {
    final store = LumoScope.of(context);
    return ChatBubble(
      role: Role.lumo,
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _headerRow(
              chip: const TagChip('Documento', tone: TagTone.ai),
              title: 'Entrega de ${m.supplier}',
            ),
            const SizedBox(height: 4),
            for (final l in m.lines ?? <SaleLine>[])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      store.productById(l.productId)?.emoji ?? '📦',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.productById(l.productId)?.name ?? l.productId,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.foreground,
                            ),
                          ),
                          Text(
                            '${l.qty} ${store.productById(l.productId)?.unit ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  mxn(m.total ?? 0),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ),
            if (!(m.approved ?? false)) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _primaryButton(
                      label: 'Agregar al inventario',
                      onTap: () => onApproveReceipt(m.id),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _pillButton(label: 'Revisar', onTap: () {}),
                ],
              ),
            ] else ...[
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Mercadería registrada. El tomate ahora alcanza aproximadamente para 4 días.',
                      style: TextStyle(fontSize: 14, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final ChatMsg m;
  final void Function(String productId) onOpenInsight;

  const _InsightCard({required this.m, required this.onOpenInsight});

  @override
  Widget build(BuildContext context) {
    final store = LumoScope.of(context);
    final p = store.productById(m.productId ?? '');
    return ChatBubble(
      role: Role.lumo,
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _headerRow(
              chip: const TagChip('Sugerencia', tone: TagTone.warn),
              title: 'Podrías quedarte sin ${p?.name.toLowerCase()}',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InsightMetric(
                    label: 'Qué detecté',
                    value: 'Quedan ${p?.stock} ${p?.unit}s',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InsightMetric(
                    label: 'Por qué importa',
                    value: 'Vendes ${p?.avgDaily ?? 0}/día',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              m.reason ?? '',
              style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recomendación',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.recommendation ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
                GradientChip(
                  child: InkWell(
                    onTap: () => onOpenInsight(m.productId ?? ''),
                    borderRadius: BorderRadius.circular(999),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        'Ver por qué',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                _pillButton(label: 'Agregar a la lista', onTap: () {}),
                _pillButton(label: 'Recordar después', onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightMetric extends StatelessWidget {
  final String label;
  final String value;

  const _InsightMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final ChatMsg m;

  const _ImpactCard({required this.m});

  @override
  Widget build(BuildContext context) {
    return ChatBubble(
      role: Role.lumo,
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const TagChip('Actualicé', tone: TagTone.ok),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    m.text ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final item in m.items ?? <String>[])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primarySoft,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AuthInput extends StatefulWidget {
  final void Function(String v) onSubmit;

  const _AuthInput({required this.onSubmit});

  @override
  State<_AuthInput> createState() => _AuthInputState();
}

class _AuthInputState extends State<_AuthInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Código de autorización',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 42,
          child: FilledButton(
            onPressed: () {
              final v = _controller.text.trim();
              if (v.isEmpty) return;
              widget.onSubmit(v);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryForeground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirmar'),
          ),
        ),
      ],
    );
  }
}

Widget _primaryButton({required String label, required VoidCallback onTap}) {
  return FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.primaryForeground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
  );
}

Widget _pillButton({required String label, required VoidCallback onTap}) {
  return OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.foreground,
      side: BorderSide(color: AppColors.hairline),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    child: Text(label, style: const TextStyle(fontSize: 14)),
  );
}

String _payLabel(PaymentMethod m) => switch (m) {
  PaymentMethod.efectivo => 'Efectivo',
  PaymentMethod.tarjeta => 'Tarjeta',
  PaymentMethod.transferencia => 'Transferencia',
  PaymentMethod.combinado => 'Pago combinado',
};
