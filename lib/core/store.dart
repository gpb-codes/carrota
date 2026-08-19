import 'dart:async';

import 'package:flutter/widgets.dart';

import 'api.dart';
import 'data.dart';

enum PaymentMethod { efectivo, tarjeta, transferencia, combinado }

enum MsgKind { text, saleProposal, receipt, insight, impact }

enum Role { user, lumo }

class SaleLine {
  final String productId;
  final int qty;

  const SaleLine({required this.productId, required this.qty});

  SaleLine copyWith({int? qty}) =>
      SaleLine(productId: productId, qty: qty ?? this.qty);
}

class Sale {
  final String id;
  final List<SaleLine> lines;
  final int total;
  final PaymentMethod? payment;
  final String? authCode;
  final String at;
  final String? serverId;

  const Sale({
    required this.id,
    required this.lines,
    required this.total,
    this.payment,
    this.authCode,
    required this.at,
    this.serverId,
  });

  Sale copyWith({PaymentMethod? payment, String? authCode, String? serverId}) =>
      Sale(
        id: id,
        lines: lines,
        total: total,
        payment: payment ?? this.payment,
        authCode: authCode ?? this.authCode,
        at: at,
        serverId: serverId ?? this.serverId,
      );
}

class CartLine {
  final String productId;
  final int qty;

  const CartLine({required this.productId, required this.qty});

  CartLine copyWith({int? qty}) =>
      CartLine(productId: productId, qty: qty ?? this.qty);
}

class ChatMsg {
  final String id;
  final Role role;
  final MsgKind? kind;
  final String? text;
  final Sale? sale;
  final bool? awaitingPayment;
  final bool? awaitingAuth;
  final bool? confirmed;
  final String? supplier;
  final int? total;
  final List<SaleLine>? lines;
  final bool? approved;
  final String? productId;
  final String? reason;
  final String? recommendation;
  final List<String>? items;

  const ChatMsg({
    required this.id,
    required this.role,
    this.kind,
    this.text,
    this.sale,
    this.awaitingPayment,
    this.awaitingAuth,
    this.confirmed,
    this.supplier,
    this.total,
    this.lines,
    this.approved,
    this.productId,
    this.reason,
    this.recommendation,
    this.items,
  });

  ChatMsg copyWith({
    Sale? sale,
    bool? awaitingPayment,
    bool? awaitingAuth,
    bool? confirmed,
    bool? approved,
  }) => ChatMsg(
    id: id,
    role: role,
    kind: kind,
    text: text,
    sale: sale ?? this.sale,
    awaitingPayment: awaitingPayment ?? this.awaitingPayment,
    awaitingAuth: awaitingAuth ?? this.awaitingAuth,
    confirmed: confirmed ?? this.confirmed,
    supplier: supplier,
    total: total,
    lines: lines,
    approved: approved ?? this.approved,
    productId: productId,
    reason: reason,
    recommendation: recommendation,
    items: items,
  );

  static ChatMsg userText(String id, String text) =>
      ChatMsg(id: id, role: Role.user, kind: MsgKind.text, text: text);

  static ChatMsg lumoText(String id, String text) =>
      ChatMsg(id: id, role: Role.lumo, kind: MsgKind.text, text: text);
}

class LumoStore extends ChangeNotifier {
  List<Product> products = initialProducts;
  List<ChatMsg> chat = [];
  List<MemoryEvent> memory = seedMemories;
  List<TimelineEvent> timeline = seedTimeline;
  List<ShoppingItem> shopping = [];
  List<CartLine> cart = [];
  final Set<String> likedVideos = {};
  final Set<String> savedVideos = {};
  final Map<String, int> videoLikes = {
    for (final v in videoFeed) v.productId: v.likes,
  };
  final Map<String, List<VideoComment>> videoComments = {
    for (final v in videoFeed)
      v.productId: [...(videoCommentsSeed[v.productId] ?? const [])],
  };
  bool onboarded = false;

  ApiClient api = ApiClient();
  bool serverOnline = false;
  bool _apiLoaded = false;
  final Set<String> _commentsLoaded = {};
  BizSummary? summary;
  final List<Sale> _confirmedSales = [];

  int get cartCount => cart.fold(0, (sum, l) => sum + l.qty);

  int get cartTotal => cart.fold(
    0,
    (sum, l) => sum + (productById(l.productId)?.price ?? 0) * l.qty,
  );

  int commentCountFor(String productId) =>
      videoComments[productId]?.length ?? 0;

  final List<MyVideo> myVideos = [];

  List<VideoProduct> get feedVideos => [
    for (final m in myVideos) m.toVideo(),
    ...videoFeed,
  ];

  void publishVideo({
    required String productId,
    required String caption,
    required List<String> hashtags,
    required int price,
    String? filePath,
  }) {
    final pair =
        myVideoPalette[productId.hashCode.abs() % myVideoPalette.length];
    myVideos.insert(
      0,
      MyVideo(
        id: 'vid_${DateTime.now().microsecondsSinceEpoch}',
        productId: productId,
        caption: caption,
        hashtags: hashtags,
        price: price,
        c1: pair.c1,
        c2: pair.c2,
        at: DateTime.now(),
        filePath: filePath,
      ),
    );
    notifyListeners();
  }

  void updateMyVideo(
    String id, {
    String? caption,
    List<String>? hashtags,
    int? price,
  }) {
    final i = myVideos.indexWhere((m) => m.id == id);
    if (i < 0) return;
    final old = myVideos[i];
    myVideos[i] = MyVideo(
      id: old.id,
      productId: old.productId,
      caption: caption ?? old.caption,
      hashtags: hashtags ?? old.hashtags,
      price: price ?? old.price,
      c1: old.c1,
      c2: old.c2,
      at: old.at,
    );
    notifyListeners();
  }

  void removeMyVideo(String id) {
    myVideos.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  Product? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Product? productByBarcode(String code) {
    for (final p in products) {
      if (p.barcode != null && p.barcode == code) return p;
    }
    return null;
  }

  Future<void> loadRemote() async {
    if (_apiLoaded) return;
    try {
      final feed = await api.fetchFeed();
      for (final v in feed) {
        final id = v['productId'] as String?;
        if (id == null) continue;
        final p = productById(id);
        if (p != null) {
          final stock = v['stock'] as num?;
          if (stock != null) {
            products = [
              for (final x in products)
                if (x.id == id) x.copyWith(stock: stock.toInt()) else x,
            ];
          }
        }
        final likes = v['likes'] as num?;
        if (likes != null) videoLikes[id] = likes.toInt();
        if (v['liked'] == true) likedVideos.add(id);
        if (v['saved'] == true) savedVideos.add(id);
        final comments = v['comments'] as num? ?? 0;
        if (comments > 0) await refreshVideoComments(id);
      }
      final cartItems = await api.fetchCart();
      cart = [
        for (final i in cartItems)
          if (productById(i['productId'] as String) != null)
            CartLine(
              productId: i['productId'] as String,
              qty: (i['qty'] as num).toInt(),
            ),
      ];
      serverOnline = true;
    } catch (_) {
      serverOnline = false;
    }
    if (serverOnline) {
      await _hydrateCatalog();
      await _hydrateEvents();
      await _hydrateShopping();
      await refreshSummary();
    }
    _apiLoaded = true;
    notifyListeners();
  }

  /// Trae (o recalcula offline) el resumen del día.
  Future<void> refreshSummary() async {
    if (serverOnline) {
      try {
        final s = await api.fetchSummary();
        if (s != null) {
          summary = BizSummary.fromJson(s);
          notifyListeners();
        }
      } catch (_) {
        summary = _localSummary();
        notifyListeners();
      }
    } else {
      summary = _localSummary();
      notifyListeners();
    }
  }

  BizSummary _localSummary() {
    var total = 0;
    var count = 0;
    final byProd = <String, int>{};
    final byPayment = <String, int>{};
    for (final sale in _confirmedSales) {
      total += sale.total;
      count++;
      final pay = _payName(sale.payment);
      byPayment[pay] = (byPayment[pay] ?? 0) + sale.total;
      for (final l in sale.lines) {
        byProd[l.productId] = (byProd[l.productId] ?? 0) + l.qty;
      }
    }
    final top = byProd.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topProducts = [
      for (final e in top.take(5))
        TopProduct(
          productId: e.key,
          name: productById(e.key)?.name ?? e.key,
          emoji: productById(e.key)?.emoji ?? '🛒',
          qty: e.value,
        ),
    ];
    return BizSummary(
      date: DateTime.now().toIso8601String().split('T').first,
      salesTotal: total,
      salesCount: count,
      byPayment: ByPaymentTotals(
        efectivo: byPayment['efectivo'] ?? 0,
        tarjeta: byPayment['tarjeta'] ?? 0,
        transferencia: byPayment['transferencia'] ?? 0,
        combinado: byPayment['combinado'] ?? 0,
      ),
      topProducts: topProducts,
      openAuth: 0,
      inventoryValue: products.fold(0, (acc, p) => acc + p.stock * p.price),
      lowStockCount: products.where((p) {
        final avg = p.avgDaily ?? 0;
        return avg > 0 && p.stock < avg;
      }).length,
    );
  }

  Future<void> _hydrateCatalog() async {
    try {
      final list = await api.fetchProducts();
      if (list.isEmpty) return;
      products = [
        for (final p in list)
          Product(
            id: p['id'] as String,
            name: p['name'] as String? ?? p['id'] as String,
            unit: p['unit'] as String? ?? 'pieza',
            price: (p['price'] as num?)?.toInt() ?? 0,
            stock: (p['stock'] as num?)?.toInt() ?? 0,
            emoji: p['emoji'] as String? ?? '🛒',
            supplier: p['supplier'] as String?,
            avgDaily: (p['avgDaily'] as num?)?.toInt(),
            barcode: p['barcode'] as String?,
          ),
      ];
    } catch (_) {
      // sin conexión: se mantiene el catálogo local
    }
  }

  Future<void> _hydrateEvents() async {
    try {
      final tl = await api.fetchEvents(type: 'tl');
      if (tl.isNotEmpty) {
        timeline = [
          for (final e in tl)
            TimelineEvent(
              id: e['id'] as String? ?? uid(),
              time: e['time'] as String? ?? '',
              title: e['title'] as String? ?? '',
              detail: e['detail'] as String?,
              tag: e['tag'] as String?,
            ),
        ];
      }
      final mem = await api.fetchEvents(type: 'mem');
      if (mem.isNotEmpty) {
        memory = [
          for (final e in mem)
            MemoryEvent(
              id: e['id'] as String? ?? uid(),
              when: e['when'] as String? ?? '',
              group: e['group'] as String? ?? 'Hoy',
              title: e['title'] as String? ?? '',
              detail: e['detail'] as String?,
              kind: e['kind'] as String? ?? 'Registrado',
            ),
        ];
      }
    } catch (_) {
      // sin conexión: se mantienen la memoria local
    }
  }

  Future<void> _hydrateShopping() async {
    try {
      final items = await api.fetchShopping();
      if (items.isEmpty) return;
      shopping = [
        for (final i in items)
          ShoppingItem(
            productId: i['productId'] as String,
            qty: (i['qty'] as num?)?.toInt() ?? 1,
            reason: i['reason'] as String? ?? '',
          ),
      ];
    } catch (_) {
      // sin conexión: se mantiene la lista local
    }
  }

  Future<void> refreshVideoComments(String productId) async {
    if (!serverOnline || _commentsLoaded.contains(productId)) return;
    try {
      final comments = await api.fetchComments(productId);
      if (comments.isEmpty) return;
      videoComments[productId] = [
        for (final c in comments)
          VideoComment(
            author: c['author'] as String? ?? 'Cliente',
            initial: (c['author'] as String?)?.isNotEmpty == true
                ? (c['author'] as String)[0].toUpperCase()
                : 'C',
            text: c['text'] as String? ?? '',
            ago: c['ago'] as String? ?? '',
          ),
      ];
      _commentsLoaded.add(productId);
      notifyListeners();
    } catch (_) {
      // sin conexión: se mantienen los comentarios locales
    }
  }

  void setOnboarded(bool v) {
    onboarded = v;
    notifyListeners();
  }

  void pushChat(ChatMsg msg) {
    chat = [...chat, msg];
    notifyListeners();
  }

  void updateChat(String id, ChatMsg Function(ChatMsg) patch) {
    chat = [
      for (final m in chat)
        if (m.id == id && m.role == Role.lumo) patch(m) else m,
    ];
    notifyListeners();
  }

  void applySale(Sale sale) {
    _confirmedSales.add(sale);
    products = [
      for (final p in products)
        if (sale.lines.any((l) => l.productId == p.id))
          p.copyWith(stock: _max0(p.stock - _qtyOf(sale.lines, p.id)))
        else
          p,
    ];
    timeline = [
      TimelineEvent(
        id: 'tl-${sale.id}',
        time: sale.at,
        title: 'Venta por ${mxn(sale.total)} (${_payName(sale.payment)}).',
        detail: sale.authCode != null
            ? 'Autorización: ${sale.authCode}.'
            : null,
        tag: 'Venta',
      ),
      ...timeline,
    ];
    memory = [
      MemoryEvent(
        id: 'mem-${sale.id}',
        when: sale.at,
        group: 'Hoy',
        title: 'Registraste una venta de ${mxn(sale.total)}.',
        detail: sale.lines
            .map(
              (l) =>
                  '${l.qty} × ${productById(l.productId)?.name ?? l.productId}',
            )
            .join(', '),
        kind: 'Registrado',
      ),
      ...memory,
    ];
    if (serverOnline) {
      unawaited(() async {
        final serverId = await api.registerSale({
          'lines': [
            for (final l in sale.lines)
              {'product_id': l.productId, 'qty': l.qty},
          ],
          'payment': _payName(sale.payment),
          'total': sale.total,
          'authCode': sale.authCode,
        });
        if (serverId != null) {
          chat = [
            for (final m in chat)
              if (m.role == Role.lumo && m.sale?.id == sale.id)
                m.copyWith(sale: sale.copyWith(serverId: serverId))
              else
                m,
          ];
          notifyListeners();
        }
      }());
    }
    notifyListeners();
  }

  Future<bool> deleteSale(String id) async {
    try {
      return await api.deleteSale(id);
    } catch (_) {
      return false;
    }
  }

  /// Deshace una venta ya confirmada: devuelve el stock, quita los eventos
  /// y llama a DELETE /api/sales/{id} si hay servidor.
  Future<void> undoSale(String id) async {
    final msg = chat.where((m) => m.id == id).firstOrNull;
    final sale = msg?.sale;
    if (msg == null || sale == null || msg.kind != MsgKind.saleProposal) return;

    // Revierte el stock local.
    products = [
      for (final p in products)
        if (sale.lines.any((l) => l.productId == p.id))
          p.copyWith(stock: p.stock + _qtyOf(sale.lines, p.id))
        else
          p,
    ];
    timeline = [
      for (final t in timeline)
        if (t.id != 'tl-${sale.id}') t,
    ];
    memory = [
      for (final m in memory)
        if (m.id != 'mem-${sale.id}') m,
    ];
    _confirmedSales.removeWhere((s) => s.id == sale.id);

    if (serverOnline && sale.serverId != null) {
      unawaited(api.deleteSale(sale.serverId!));
    }
    notifyListeners();
  }

  /// Cierra el día: registra en el server (si puede) y refresca resumen/eventos.
  Future<bool> closeDay({String? note}) async {
    final ok = serverOnline ? await api.registerClosing(note: note) : false;
    await refreshSummary();
    await _hydrateEvents();
    timeline.insert(
      0,
      TimelineEvent(
        id: 'tl-close-${uid()}',
        time: _now(),
        title: 'Cierre del día registrado.',
        tag: 'Cierre',
      ),
    );
    notifyListeners();
    return ok;
  }

  void receiveDelivery(List<SaleLine> lines, {String? supplier}) {
    products = [
      for (final p in products)
        if (lines.any((l) => l.productId == p.id))
          p.copyWith(stock: p.stock + _qtyOf(lines, p.id))
        else
          p,
    ];
    if (serverOnline) {
      unawaited(
        api.registerDelivery({
          'lines': [
            for (final l in lines) {'product_id': l.productId, 'qty': l.qty},
          ],
          'supplier': ?supplier,
        }),
      );
    }
    notifyListeners();
  }

  void addShopping(List<ShoppingItem> items) {
    shopping = [...shopping, ...items];
    notifyListeners();
  }

  void addToCart(String productId, {int qty = 1}) {
    final i = cart.indexWhere((l) => l.productId == productId);
    final stock = productById(productId)?.stock ?? 0;
    if (i >= 0) {
      cart = [
        for (final l in cart)
          if (l.productId == productId)
            l.copyWith(qty: (l.qty + qty).clamp(0, stock))
          else
            l,
      ];
    } else {
      cart = [
        ...cart,
        CartLine(productId: productId, qty: qty.clamp(1, stock)),
      ];
    }
    notifyListeners();
    if (serverOnline) api.addCartItem(productId, qty: qty);
  }

  void setCartQty(String productId, int qty) {
    final stock = productById(productId)?.stock ?? 0;
    if (qty <= 0) {
      cart = [
        for (final l in cart)
          if (l.productId != productId) l,
      ];
    } else {
      cart = [
        for (final l in cart)
          if (l.productId == productId)
            l.copyWith(qty: qty.clamp(1, stock))
          else
            l,
      ];
    }
    notifyListeners();
    if (serverOnline) {
      if (qty <= 0) {
        api.removeCartItem(productId);
      } else {
        api.setCartQty(productId, qty.clamp(1, stock));
      }
    }
  }

  void clearCart() {
    cart = [];
    notifyListeners();
    if (serverOnline) api.clearCart();
  }

  void toggleVideoLike(String productId) {
    if (likedVideos.contains(productId)) {
      likedVideos.remove(productId);
      videoLikes[productId] = (videoLikes[productId] ?? 0) - 1;
    } else {
      likedVideos.add(productId);
      videoLikes[productId] = (videoLikes[productId] ?? 0) + 1;
    }
    notifyListeners();
    if (serverOnline) api.like(productId);
  }

  void toggleVideoSave(String productId) {
    if (savedVideos.contains(productId)) {
      savedVideos.remove(productId);
    } else {
      savedVideos.add(productId);
    }
    notifyListeners();
    if (serverOnline) api.save(productId);
  }

  void addVideoComment(String productId, String text) {
    final list = videoComments[productId] ?? [];
    videoComments[productId] = [
      VideoComment(author: 'Jorge', initial: 'J', text: text, ago: 'ahora'),
      ...list,
    ];
    notifyListeners();
    if (serverOnline) api.addComment(productId, text);
  }

  Sale? registerCartSale({PaymentMethod payment = PaymentMethod.efectivo}) {
    if (cart.isEmpty) return null;
    final sale = Sale(
      id: uid(),
      lines: [
        for (final l in cart) SaleLine(productId: l.productId, qty: l.qty),
      ],
      total: cartTotal,
      payment: payment,
      at: _now(),
    );
    applySale(sale);
    pushChat(
      ChatMsg(
        id: uid(),
        role: Role.lumo,
        kind: MsgKind.impact,
        text: 'La venta quedó registrada desde Tienda.',
        items: [
          'Venta por ${mxn(sale.total)}',
          'Inventario actualizado',
          'Pago con ${_payName(payment)}',
        ],
      ),
    );
    clearCart();
    return sale;
  }

  void reset() {
    products = initialProducts;
    chat = [];
    memory = seedMemories;
    timeline = seedTimeline;
    shopping = [];
    cart = [];
    _confirmedSales.clear();
    summary = null;
    likedVideos.clear();
    savedVideos.clear();
    videoLikes
      ..clear()
      ..addAll({for (final v in videoFeed) v.productId: v.likes});
    videoComments
      ..clear()
      ..addAll({
        for (final v in videoFeed)
          v.productId: [...(videoCommentsSeed[v.productId] ?? const [])],
      });
    onboarded = false;
    serverOnline = false;
    _apiLoaded = false;
    _commentsLoaded.clear();
    notifyListeners();
  }

  int _qtyOf(List<SaleLine> lines, String productId) {
    for (final l in lines) {
      if (l.productId == productId) return l.qty;
    }
    return 0;
  }

  int _max0(int n) => n < 0 ? 0 : n;

  String _now() {
    final d = DateTime.now();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _payName(PaymentMethod? p) {
    switch (p) {
      case PaymentMethod.efectivo:
        return 'efectivo';
      case PaymentMethod.tarjeta:
        return 'tarjeta';
      case PaymentMethod.transferencia:
        return 'transferencia';
      case PaymentMethod.combinado:
        return 'combinado';
      case null:
        return '—';
    }
  }
}

class LumoScope extends InheritedNotifier<LumoStore> {
  const LumoScope({super.key, required LumoStore store, required super.child})
    : super(notifier: store);

  static LumoStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LumoScope>();
    assert(scope != null, 'LumoScope not found in widget tree');
    return scope!.notifier!;
  }
}

String uid() {
  return DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
      DateTime.now().millisecond.toRadixString(36);
}
