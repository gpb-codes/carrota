import 'package:flutter_test/flutter_test.dart';

import 'package:carrota_flutter/core/data.dart';
import 'package:carrota_flutter/core/mock_ai.dart';
import 'package:carrota_flutter/core/store.dart';

void main() {
  test('mxn formats es-MX currency', () {
    expect(mxn(2430), r'$2,430');
    expect(mxn(1450), r'$1,450');
    expect(mxn(95), r'$95');
  });

  test('parseSale extracts products and quantities', () {
    final lines = parseSale('Vendí dos tomates, una lechuga y tres cilantro', initialProducts);
    expect(lines.length, 3);
    final tomate = lines.firstWhere((l) => l.productId == 'tomate');
    expect(tomate.qty, 2);
    final lechuga = lines.firstWhere((l) => l.productId == 'lechuga');
    expect(lechuga.qty, 1);
    final cilantro = lines.firstWhere((l) => l.productId == 'cilantro');
    expect(cilantro.qty, 3);
  });

  test('parseSale merges repeated products', () {
    final lines = parseSale('Vendí 2 tomates y 3 tomates', initialProducts);
    expect(lines.length, 1);
    expect(lines.first.qty, 5);
  });

  test('totalOf computes sale total', () {
    final lines = parseSale('Vendí dos tomates y una lechuga', initialProducts);
    expect(totalOf(lines, initialProducts), 2 * 30 + 28);
  });

  test('detectIntent classifies commands', () {
    expect(detectIntent('Vendí dos lechugas'), AppIntent.sale);
    expect(detectIntent('recibí mercadería'), AppIntent.receive);
    expect(detectIntent('preparar el cierre'), AppIntent.close);
    expect(detectIntent('¿cómo vamos?'), AppIntent.question);
    expect(detectIntent('hola'), AppIntent.unknown);
  });

  test('cart add, merge and clear', () {
    final s = LumoStore();
    s.addToCart('tomate');
    s.addToCart('tomate');
    s.addToCart('lechuga');
    expect(s.cartCount, 3);
    s.setCartQty('tomate', 5);
    expect(s.cartCount, 6);
    s.setCartQty('lechuga', 0);
    expect(s.cartCount, 5);
    expect(s.cartTotal, 5 * 30);
    s.clearCart();
    expect(s.cartCount, 0);
  });

  test('registerCartSale applies sale and clears cart', () {
    final s = LumoStore();
    s.addToCart('tomate', qty: 2);
    s.addToCart('mermelada');
    final before = s.products.firstWhere((p) => p.id == 'tomate').stock;
    final sale = s.registerCartSale();
    expect(sale, isNotNull);
    expect(sale!.total, 2 * 30 + 95);
    expect(sale.payment, PaymentMethod.efectivo);
    expect(s.cartCount, 0);
    expect(s.products.firstWhere((p) => p.id == 'tomate').stock, before - 2);
    expect(s.chat.any((m) => m.kind == MsgKind.impact), isTrue);
    expect(s.registerCartSale(), isNull);
  });

  test('video like, save and comments toggle', () {
    final s = LumoStore();
    final id = videoFeed.first.productId;
    final base = s.videoLikes[id]!;
    s.toggleVideoLike(id);
    expect(s.likedVideos.contains(id), isTrue);
    expect(s.videoLikes[id], base + 1);
    s.toggleVideoLike(id);
    expect(s.likedVideos.contains(id), isFalse);
    expect(s.videoLikes[id], base);
    s.toggleVideoSave(id);
    expect(s.savedVideos.contains(id), isTrue);
    s.addVideoComment(id, '¡Qué rico se ve!');
    expect(s.commentCountFor(id), (videoCommentsSeed[id]?.length ?? 0) + 1);
    expect(s.videoComments[id]!.first.author, 'Jorge');
  });
}
