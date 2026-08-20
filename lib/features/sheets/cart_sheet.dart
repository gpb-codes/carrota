import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/sheet.dart';
import '../../core/data.dart';
import '../../core/store.dart';

Future<void> showCartSheet(BuildContext context) {
  return showAppSheet(
    context,
    title: 'Tu venta',
    builder: (ctx) => const CartSheet(),
  );
}

class CartSheet extends StatefulWidget {
  const CartSheet({super.key});

  @override
  State<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<CartSheet> {
  PaymentMethod _method = PaymentMethod.efectivo;
  final _couponCtrl = TextEditingController();
  String? _couponError;

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final store = LumoScope.of(context);
    final ok = store.applyCoupon(_couponCtrl.text);
    setState(() {
      _couponError = ok ? null : 'Cupón no válido. Prueba FRESCO10.';
      if (ok) _couponCtrl.clear();
    });
  }

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
      return Padding(
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
            style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: cardDeco(radius: 18),
            child: Column(
              children: [
                for (final line in store.cart) _CartLineRow(line: line),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.hairline)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Subtotal',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ),
                          Text(
                            mxn(store.cartTotal),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                          ),
                        ],
                      ),
                      if (store.appliedCoupon != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Cupón ${store.appliedCoupon!.code} (-${store.appliedCoupon!.percent}%)',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Text(
                              '-${mxn(store.cartDiscount)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ),
                          Text(
                            mxn(store.cartPayable),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14),
          _CouponBar(
            controller: _couponCtrl,
            error: _couponError,
            onApply: _applyCoupon,
          ),
          SizedBox(height: 14),
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
                    color: _method == m
                        ? AppColors.primary
                        : AppColors.foreground,
                  ),
                  side: BorderSide(
                    color: _method == m
                        ? AppColors.primary
                        : AppColors.hairline,
                  ),
                ),
            ],
          ),
          SizedBox(height: 14),
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
          Text(
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
      decoration: BoxDecoration(
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${mxn(p.price)} / ${p.unit}',
                  style: TextStyle(
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
                    style: TextStyle(
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
              style: TextStyle(
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

class _CouponBar extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final VoidCallback onApply;

  const _CouponBar({
    required this.controller,
    required this.error,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final store = LumoScope.of(context);
    final coupon = store.appliedCoupon;
    if (coupon != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: cardDeco(radius: 16),
        child: Row(
          children: [
            Icon(
              Icons.confirmation_number_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cupón ${coupon.code} aplicado',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    coupon.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: store.clearCoupon,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.mutedForeground,
              tooltip: 'Quitar cupón',
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(fontSize: 13, color: AppColors.foreground),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: '¿Tienes un cupón?',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => onApply(),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onApply,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Aplicar', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(error!, style: TextStyle(fontSize: 12, color: AppColors.danger)),
        ] else ...[
          const SizedBox(height: 6),
          Text(
            'Prueba: FRESCO10 · VERDE20 · HOGAR15',
            style: TextStyle(fontSize: 11, color: AppColors.mutedForeground),
          ),
        ],
      ],
    );
  }
}

String _payLabel(PaymentMethod m) => switch (m) {
  PaymentMethod.efectivo => 'Efectivo',
  PaymentMethod.tarjeta => 'Tarjeta',
  PaymentMethod.transferencia => 'Transferencia',
  PaymentMethod.combinado => 'Pago combinado',
};
