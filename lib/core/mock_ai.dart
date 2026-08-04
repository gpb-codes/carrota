import 'data.dart';
import 'store.dart';

/// Map of Spanish keywords → product id
const _keywords = <String, String>{
  'tomate': 'tomate', 'tomates': 'tomate',
  'lechuga': 'lechuga', 'lechugas': 'lechuga',
  'zanahoria': 'zanahoria', 'zanahorias': 'zanahoria',
  'cilantro': 'cilantro', 'manojo': 'cilantro', 'manojos': 'cilantro',
  'espinaca': 'espinaca', 'espinacas': 'espinaca',
  'aguacate': 'aguacate', 'aguacates': 'aguacate',
  'limon': 'limon', 'limón': 'limon', 'limones': 'limon',
  'mermelada': 'mermelada', 'mermeladas': 'mermelada',
};

const _numWords = <String, int>{
  'un': 1, 'una': 1, 'uno': 1, 'dos': 2, 'tres': 3, 'cuatro': 4, 'cinco': 5,
  'seis': 6, 'siete': 7, 'ocho': 8, 'nueve': 9, 'diez': 10, 'once': 11, 'doce': 12,
  'quince': 15, 'veinte': 20, 'treinta': 30,
};

List<SaleLine> parseSale(String input, List<Product> products) {
  final text = input.toLowerCase().replaceAll(RegExp(r'[.,]'), ' ');
  final tokens = text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  final lines = <SaleLine>[];
  for (var i = 0; i < tokens.length; i++) {
    final t = tokens[i];
    final pid = _keywords[t];
    if (pid == null) continue;
    // look back up to 3 tokens for a quantity
    var qty = 1;
    for (var j = i - 3; j < i; j++) {
      if (j < 0) continue;
      final w = tokens[j];
      if (RegExp(r'^\d+(\.\d+)?$').hasMatch(w)) {
        qty = int.tryParse(w) ?? 1;
      } else if (_numWords.containsKey(w)) {
        qty = _numWords[w]!;
      }
    }
    final existing = lines.where((l) => l.productId == pid).firstOrNull;
    if (existing != null) {
      lines[lines.indexOf(existing)] = SaleLine(
        productId: pid,
        qty: existing.qty + qty,
      );
    } else {
      lines.add(SaleLine(productId: pid, qty: qty));
    }
  }
  return lines;
}

int totalOf(List<SaleLine> lines, List<Product> products) {
  var acc = 0;
  for (final l in lines) {
    for (final p in products) {
      if (p.id == l.productId) {
        acc += p.price * l.qty;
        break;
      }
    }
  }
  return acc;
}

enum AppIntent { sale, receive, question, close, unknown }

AppIntent detectIntent(String input) {
  final t = input.toLowerCase();
  if (RegExp(r'(vend|cobr|venta)').hasMatch(t)) return AppIntent.sale;
  if (RegExp(r'(lleg|recib|entrega|mercader)').hasMatch(t)) return AppIntent.receive;
  if (RegExp(r'(cierr|cerrar|cierre)').hasMatch(t)) return AppIntent.close;
  if (RegExp(r'(cómo|como vamos|qué|que falt|cuánto|cuanto)').hasMatch(t)) return AppIntent.question;
  return AppIntent.unknown;
}
