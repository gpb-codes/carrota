class Product {
  final String id;
  final String name;
  final String unit;
  final int price;
  final int stock;
  final String emoji;
  final String? supplier;
  final int? avgDaily;
  final String? barcode;

  const Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.stock,
    required this.emoji,
    this.supplier,
    this.avgDaily,
    this.barcode,
  });

  Product copyWith({int? stock}) => Product(
    id: id,
    name: name,
    unit: unit,
    price: price,
    stock: stock ?? this.stock,
    emoji: emoji,
    supplier: supplier,
    avgDaily: avgDaily,
    barcode: barcode,
  );
}

class MemoryEvent {
  final String id;
  final String when;
  final String group;
  final String title;
  final String? detail;
  final String kind;

  const MemoryEvent({
    required this.id,
    required this.when,
    required this.group,
    required this.title,
    this.detail,
    required this.kind,
  });
}

class TimelineEvent {
  final String id;
  final String time;
  final String title;
  final String? detail;
  final String? tag;

  const TimelineEvent({
    required this.id,
    required this.time,
    required this.title,
    this.detail,
    this.tag,
  });
}

class ShoppingItem {
  final String productId;
  final int qty;
  final String reason;

  const ShoppingItem({
    required this.productId,
    required this.qty,
    required this.reason,
  });
}

/// es-MX currency formatter, no external deps.
/// mxn(2430) → "$2,430"
String mxn(int n) {
  final neg = n < 0;
  final abs = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < abs.length; i++) {
    if (i > 0 && (abs.length - i) % 3 == 0) buf.write(',');
    buf.write(abs[i]);
  }
  return '${neg ? '-' : ''}\$$buf';
}

const initialProducts = <Product>[
  Product(
    id: 'tomate',
    name: 'Tomate saladet',
    unit: 'kg',
    price: 30,
    stock: 42,
    emoji: '🍅',
    supplier: 'Huerto Norte',
    avgDaily: 12,
    barcode: '7501055300017',
  ),
  Product(
    id: 'lechuga',
    name: 'Lechuga italiana',
    unit: 'pieza',
    price: 28,
    stock: 4,
    emoji: '🥬',
    supplier: 'Huerto Norte',
    avgDaily: 6,
    barcode: '7501055300024',
  ),
  Product(
    id: 'zanahoria',
    name: 'Zanahoria',
    unit: 'kg',
    price: 20,
    stock: 18,
    emoji: '🥕',
    supplier: 'Milpa Verde',
    avgDaily: 5,
    barcode: '7501055300031',
  ),
  Product(
    id: 'cilantro',
    name: 'Cilantro',
    unit: 'manojo',
    price: 12,
    stock: 3,
    emoji: '🌿',
    supplier: 'Milpa Verde',
    avgDaily: 8,
    barcode: '7501055300048',
  ),
  Product(
    id: 'espinaca',
    name: 'Espinaca',
    unit: 'bolsa',
    price: 28,
    stock: 14,
    emoji: '🥗',
    supplier: 'Huerto Norte',
    avgDaily: 6,
    barcode: '7501055300055',
  ),
  Product(
    id: 'aguacate',
    name: 'Aguacate',
    unit: 'kg',
    price: 55,
    stock: 22,
    emoji: '🥑',
    supplier: 'Milpa Verde',
    avgDaily: 4,
    barcode: '7501055300062',
  ),
  Product(
    id: 'limon',
    name: 'Limón',
    unit: 'kg',
    price: 32,
    stock: 30,
    emoji: '🍋',
    supplier: 'Cítricos del Bajío',
    avgDaily: 7,
    barcode: '7501055300079',
  ),
  Product(
    id: 'mermelada',
    name: 'Mermelada artesanal',
    unit: 'frasco',
    price: 95,
    stock: 12,
    emoji: '🍯',
    supplier: 'Taller La Abeja',
    avgDaily: 2,
    barcode: '7501055300086',
  ),
];

const seedMemories = <MemoryEvent>[
  MemoryEvent(
    id: 'm1',
    when: '17:15',
    group: 'Hoy',
    title: 'Registraste una entrada de 20 kg de tomate de Huerto Norte.',
    detail: 'Factura por \$1,450. Se actualizó el inventario automáticamente.',
    kind: 'Registrado',
  ),
  MemoryEvent(
    id: 'm2',
    when: 'hace 2 días',
    group: 'Hace 2 días',
    title: 'Cambiaste el precio de la lechuga de \$25 a \$28.',
    detail: 'El cambio se aplicó a todas las ventas siguientes.',
    kind: 'Registrado',
  ),
  MemoryEvent(
    id: 'm3',
    when: 'la semana pasada',
    group: 'La semana pasada',
    title: 'Las ventas de cilantro aumentaron 18 %.',
    detail: 'Comparado con la semana anterior.',
    kind: 'Calculado',
  ),
  MemoryEvent(
    id: 'm4',
    when: 'patrón',
    group: 'Patrón observado',
    title: 'Normalmente recibes mercadería los lunes y jueves.',
    detail: 'He notado este patrón en las últimas 6 semanas.',
    kind: 'Patrón observado',
  ),
];

const seedTimeline = <TimelineEvent>[
  TimelineEvent(
    id: 't1',
    time: '18:42',
    title: 'Cierre diario preparado.',
    detail: 'Ventas totales: \$8,250.',
    tag: 'Cierre',
  ),
  TimelineEvent(
    id: 't2',
    time: '17:15',
    title: 'Llegaron 20 kg de tomate de Huerto Norte.',
    tag: 'Inventario',
  ),
  TimelineEvent(
    id: 't3',
    time: '16:38',
    title: 'Venta con tarjeta por \$280.',
    detail: 'Autorización: 683194.',
    tag: 'Venta',
  ),
  TimelineEvent(
    id: 't4',
    time: '14:20',
    title: 'El precio de la lechuga cambió de \$25 a \$28.',
    tag: 'Precio',
  ),
  TimelineEvent(
    id: 't5',
    time: '11:05',
    title: 'El cilantro llegó a nivel crítico.',
    tag: 'Alerta',
  ),
];

class Briefing {
  final String greeting;
  final List<String> paragraphs;

  const Briefing({required this.greeting, required this.paragraphs});
}

/// Ventas del día reales, espejo de GET /api/summary.
class ByPaymentTotals {
  final int efectivo;
  final int tarjeta;
  final int transferencia;
  final int combinado;

  const ByPaymentTotals({
    this.efectivo = 0,
    this.tarjeta = 0,
    this.transferencia = 0,
    this.combinado = 0,
  });

  factory ByPaymentTotals.fromJson(Map<String, dynamic> json) =>
      ByPaymentTotals(
        efectivo: (json['efectivo'] as num?)?.toInt() ?? 0,
        tarjeta: (json['tarjeta'] as num?)?.toInt() ?? 0,
        transferencia: (json['transferencia'] as num?)?.toInt() ?? 0,
        combinado: (json['combinado'] as num?)?.toInt() ?? 0,
      );
}

class TopProduct {
  final String productId;
  final String name;
  final String emoji;
  final int qty;

  const TopProduct({
    required this.productId,
    required this.name,
    required this.emoji,
    required this.qty,
  });
}

class BizSummary {
  final String date;
  final int salesTotal;
  final int salesCount;
  final ByPaymentTotals byPayment;
  final List<TopProduct> topProducts;
  final int openAuth;
  final int inventoryValue;
  final int lowStockCount;

  const BizSummary({
    required this.date,
    required this.salesTotal,
    required this.salesCount,
    required this.byPayment,
    required this.topProducts,
    required this.openAuth,
    required this.inventoryValue,
    required this.lowStockCount,
  });

  factory BizSummary.fromJson(Map<String, dynamic> json) => BizSummary(
    date: json['date'] as String? ?? '',
    salesTotal: (json['salesTotal'] as num?)?.toInt() ?? 0,
    salesCount: (json['salesCount'] as num?)?.toInt() ?? 0,
    byPayment: ByPaymentTotals.fromJson(
      (json['byPayment'] as Map<String, dynamic>?) ?? const {},
    ),
    topProducts: [
      for (final t in (json['topProducts'] as List?) ?? const [])
        if (t is Map<String, dynamic>)
          TopProduct(
            productId: t['productId'] as String? ?? '',
            name: t['name'] as String? ?? '',
            emoji: t['emoji'] as String? ?? '🛒',
            qty: (t['qty'] as num?)?.toInt() ?? 0,
          ),
    ],
    openAuth: (json['openAuth'] as num?)?.toInt() ?? 0,
    inventoryValue: (json['inventoryValue'] as num?)?.toInt() ?? 0,
    lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
  );
}

const briefing = Briefing(
  greeting: 'Buenos días, Jorge.',
  paragraphs: [
    'Carrota comenzó bien el día.',
    'Llevas \$2,430 en ventas.',
    'La caja coincide con lo registrado.',
    'Tres productos tienen poco inventario.',
    'Una venta con tarjeta todavía no tiene código de autorización.',
  ],
);

/// A product video in the Tienda feed (TikTok Shop style).
/// c1/c2 are ARGB colors for the animated placeholder gradient.
class VideoProduct {
  final String productId;
  final String caption;
  final List<String> hashtags;
  final int c1;
  final int c2;
  final int likes;
  final bool mine;

  const VideoProduct({
    required this.productId,
    required this.caption,
    required this.hashtags,
    required this.c1,
    required this.c2,
    required this.likes,
    this.mine = false,
  });
}

/// A video published by the shop owner (own content in the Tienda).
class MyVideo {
  final String id;
  final String productId;
  final String caption;
  final List<String> hashtags;
  final int price;
  final int c1;
  final int c2;
  final DateTime at;

  const MyVideo({
    required this.id,
    required this.productId,
    required this.caption,
    required this.hashtags,
    required this.price,
    required this.c1,
    required this.c2,
    required this.at,
  });

  VideoProduct toVideo() => VideoProduct(
    productId: productId,
    caption: caption,
    hashtags: hashtags,
    c1: c1,
    c2: c2,
    likes: 0,
    mine: true,
  );
}

/// Gradient pairs for videos published by the shop owner.
const myVideoPalette = <({int c1, int c2})>[
  (c1: 0xFF9BC94C, c2: 0xFF2F6B2F),
  (c1: 0xFFE5533D, c2: 0xFF8F1D10),
  (c1: 0xFFF5D23C, c2: 0xFFC77D0F),
  (c1: 0xFF4CC2FF, c2: 0xFF1D4F8F),
  (c1: 0xFFE96BA8, c2: 0xFF7A2D55),
];

class VideoComment {
  final String author;
  final String initial;
  final String text;
  final String ago;

  const VideoComment({
    required this.author,
    required this.initial,
    required this.text,
    required this.ago,
  });
}

const videoFeed = <VideoProduct>[
  VideoProduct(
    productId: 'aguacate',
    caption: 'Aguacate de Milpa Verde. Cremoso y listo para hoy.',
    hashtags: ['#aguacate', '#fresco', '#milpaverde'],
    c1: 0xFF9BC94C,
    c2: 0xFF2F6B2F,
    likes: 2104,
  ),
  VideoProduct(
    productId: 'tomate',
    caption: 'Tomate saladet recién llegado de Huerto Norte.',
    hashtags: ['#tomate', '#huertonorte', '#saladet'],
    c1: 0xFFE5533D,
    c2: 0xFF8F1D10,
    likes: 1240,
  ),
  VideoProduct(
    productId: 'limon',
    caption: 'Limón amarillo, perfecto para la limonada de la tarde.',
    hashtags: ['#limon', '#citricosdelbajio'],
    c1: 0xFFF5D23C,
    c2: 0xFFC77D0F,
    likes: 678,
  ),
  VideoProduct(
    productId: 'lechuga',
    caption: 'Lechuga italiana fresca y crujiente, sin pesticidas.',
    hashtags: ['#lechuga', '#verde', '#italiana'],
    c1: 0xFF7BC26B,
    c2: 0xFF24663A,
    likes: 856,
  ),
  VideoProduct(
    productId: 'mermelada',
    caption: 'Mermelada artesanal del Taller La Abeja.',
    hashtags: ['#mermelada', '#artesanal', '#laabeja'],
    c1: 0xFFE8A64A,
    c2: 0xFF8F4E17,
    likes: 342,
  ),
  VideoProduct(
    productId: 'zanahoria',
    caption: 'Zanahoria dulce, perfecta para el caldo de la semana.',
    hashtags: ['#zanahoria', '#fresco'],
    c1: 0xFFF59E3C,
    c2: 0xFFC54813,
    likes: 512,
  ),
];

const videoCommentsSeed = <String, List<VideoComment>>{
  'aguacate': [
    VideoComment(
      author: 'Luis',
      initial: 'L',
      text: 'El mejor aguacate de la zona 🥑',
      ago: 'hace 1 h',
    ),
    VideoComment(
      author: 'Karen',
      initial: 'K',
      text: '¿Hacen envíos a la colonia Centro?',
      ago: 'hace 3 h',
    ),
  ],
  'tomate': [
    VideoComment(
      author: 'María',
      initial: 'M',
      text: '¿El kilo sigue a \$30? 🙌',
      ago: 'hace 2 h',
    ),
    VideoComment(
      author: 'Chef Ana',
      initial: 'A',
      text: 'El de la semana pasada estaba muy bueno',
      ago: 'hace 5 h',
    ),
  ],
  'lechuga': [
    VideoComment(
      author: 'Don Pepe',
      initial: 'D',
      text: 'Fresca, la llevo cada martes',
      ago: 'hace 4 h',
    ),
  ],
  'limon': [
    VideoComment(
      author: 'Sofía',
      initial: 'S',
      text: 'Perfecto para la limonada de la tarde 🍋',
      ago: 'hace 6 h',
    ),
  ],
};
