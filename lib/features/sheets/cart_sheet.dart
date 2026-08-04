import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/sheet.dart';
import '../../core/data.dart';
import '../../core/store.dart';

Future<void> showCartSheet(BuildContext context) {
  return showAppSheet(context, title: 'Tu venta', builder: (ctx) => const CartSheet());
}

class CartSheet extends StatefulWidget {
  const CartSheet({super.key});

  @override
  State<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<CartSheet> {
  PaymentMethod _method = PaymentMethod.efectivo;

  void _confirm() {
    final store = LumoScope.of(context);
    final sale = store.registerCartSale(payment: _method);
    if (sale == null) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: Text('Venta registrada · ${mxn(sale.total)}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = LumoScope.of(context);
    if (store.cart.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🧺', style: TextStyle(fontSize: 44)),
            SizedBox(height: 12),
            Text(
              'Tu carrito está vacío',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Agrega productos desde la pestaña Tienda.',
              style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Text(
            '${store.cartCount} productos listos para registrar',
            style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: cardDeco(radius: 18),
            child: Column(
              children: [
                for (final line in store.cart) _CartLineRow(line: line),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.hairline)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                      Text(
                        mxn(store.cartTotal),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in const [
                PaymentMethod.efectivo,
                PaymentMethod.tarjeta,
                PaymentMethod.transferencia,
              ])
                ChoiceChip(
                  label: Text(_payLabel(m)),
                  selected: _method == m,
                  onSelected: (_) => setState(() => _method = m),
                  showCheckmark: false,
                  selectedColor: AppColors.primarySoft,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _method == m ? AppColors.primary : AppColors.foreground,
                  ),
                  side: BorderSide(
                    color: _method == m ? AppColors.primary : AppColors.hairline,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _confirm,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryForeground,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Registrar venta',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'El inventario y la caja se actualizan al instante.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _CartLineRow extends StatelessWidget {
  final CartLine line;

  const _CartLineRow({required this.line});

  @override
  Widget build(BuildContext context) {
    final store = LumoScope.of(context);
    final p = store.productById(line.productId);
    if (p == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${mxn(p.price)} / ${p.unit}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                _StepBtn(
                  icon: Icons.remove_rounded,
                  onTap: () => store.setCartQty(line.productId, line.qty - 1),
                ),
                SizedBox(
                  width: 26,
                  child: Text(
                    '${line.qty}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                _StepBtn(
                  icon: Icons.add_rounded,
                  onTap: () => store.setCartQty(line.productId, line.qty + 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(
              mxn(p.price * line.qty),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}

String _payLabel(PaymentMethod m) => switch (m) {
      PaymentMethod.efectivo => 'Efectivo',
      PaymentMethod.tarjeta => 'Tarjeta',
      PaymentMethod.transferencia => 'Transferencia',
      PaymentMethod.combinado => 'Pago combinado',
    };
