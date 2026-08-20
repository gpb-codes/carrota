import 'package:flutter_test/flutter_test.dart';

import 'package:carrota_flutter/core/store.dart';

void main() {
  test('favoritos: toggle agrega y quita', () {
    final store = LumoStore();
    expect(store.isFavorite('tomate'), isFalse);
    store.toggleFavorite('tomate');
    expect(store.isFavorite('tomate'), isTrue);
    store.toggleFavorite('tomate');
    expect(store.isFavorite('tomate'), isFalse);
  });

  test('vistos recientes: dedupe, mueve al frente y limita a 12', () {
    final store = LumoStore();
    for (var i = 0; i < 15; i++) {
      store.noteViewed('p$i');
    }
    expect(store.recentlyViewed.length, 12);
    expect(store.recentlyViewed.first, 'p14');
    store.noteViewed('p10');
    expect(store.recentlyViewed.first, 'p10');
    expect(store.recentlyViewed.where((id) => id == 'p10').length, 1);
  });

  test('reseñas: rateProduct acumula promedio y conteo', () {
    final store = LumoStore();
    expect(store.ratingFor('tomate'), 5.0);
    final before = store.ratingCountFor('tomate');
    store.rateProduct('tomate', 3);
    expect(store.ratingCountFor('tomate'), before + 1);
    expect(
      store.ratingFor('tomate'),
      (store.ratingSum['tomate']!) / (before + 1),
    );
  });

  test('cupones: aplicar es insensible a mayúsculas y valida', () {
    final store = LumoStore();
    expect(store.appliedCoupon, isNull);
    expect(store.applyCoupon(' fresco10 '), isTrue);
    expect(store.appliedCoupon?.code, 'FRESCO10');
    store.clearCoupon();
    expect(store.appliedCoupon, isNull);
    expect(store.applyCoupon('NOEXISTE'), isFalse);
  });

  test('descuento: cartDiscount y cartPayable usan el cupón', () {
    final store = LumoStore();
    final p = store.productById('aguacate')!;
    store.addToCart('aguacate', qty: 2);
    expect(store.cartTotal, p.price * 2);
    store.applyCoupon('VERDE20');
    expect(store.cartDiscount, p.price * 2 * 20 ~/ 100);
    expect(store.cartPayable, store.cartTotal - store.cartDiscount);
  });

  test('venta con cupón: total con descuento y cupón limpiado', () {
    final store = LumoStore();
    store.addToCart('tomate');
    store.applyCoupon('FRESCO10');
    final before = store.cartTotal;
    final sale = store.registerCartSale();
    expect(sale, isNotNull);
    expect(sale!.total, before * 90 ~/ 100);
    expect(store.appliedCoupon, isNull);
    expect(store.cart, isEmpty);
  });

  test('más vendidos: ranking por unidades vendidas', () {
    final store = LumoStore();
    final top = store.topSellers;
    expect(top.first.product.id, 'aguacate');
    expect(top.first.units, 34);
    store.addToCart('tomate', qty: 3);
    store.registerCartSale();
    final after = store.topSellers;
    expect(after.firstWhere((t) => t.product.id == 'tomate').units, 31);
  });

  test('relacionados: mismo proveedor primero y excluye el producto', () {
    final store = LumoStore();
    final rel = store.relatedTo('tomate');
    expect(rel.any((p) => p.id == 'tomate'), isFalse);
    expect(rel.isNotEmpty, isTrue);
    final p = store.productById('tomate')!;
    if (p.supplier != null) {
      final same = rel.where((x) => x.supplier == p.supplier).toList();
      expect(same, isNotEmpty);
    }
  });
}
