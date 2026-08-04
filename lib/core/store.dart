import 'package:flutter/widgets.dart';

import 'data.dart';

enum PaymentMethod { efectivo, tarjeta, transferencia, combinado }

enum MsgKind { text, saleProposal, receipt, insight, impact }

enum Role { user, lumo }

class SaleLine {
  final String productId;
  final int qty;

  const SaleLine({required this.productId, required this.qty});

  SaleLine copyWith({int? qty}) => SaleLine(productId: productId, qty: qty ?? this.qty);
}

class Sale {
  final String id;
  final List<SaleLine> lines;
  final int total;
  final PaymentMethod? payment;
  final String? authCode;
  final String at;

  const Sale({
    required this.id,
    required this.lines,
    required this.total,
    this.payment,
    this.authCode,
    required this.at,
  });

  Sale copyWith({PaymentMethod? payment, String? authCode}) => Sale(
        id: id,
        lines: lines,
        total: total,
        payment: payment ?? this.payment,
        authCode: authCode ?? this.authCode,
        at: at,
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
  }) =>
      ChatMsg(
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

  int get cartCount => cart.fold(0, (sum, l) => sum + l.qty);

  int get cartTotal => cart.fold(
      0, (sum, l) => sum + (productById(l.productId)?.price ?? 0) * l.qty);

  int commentCountFor(String productId) =>
      videoComments[productId]?.length ?? 0;

  Product? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
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
    products = [
      for (final p in products)
        if (sale.lines.any((l) => l.productId == p.id))
          p.copyWith(
            stock: _max0(p.stock - _qtyOf(sale.lines, p.id)),
          )
        else
          p,
    ];
    timeline = [
      TimelineEvent(
        id: 'tl-${sale.id}',
        time: sale.at,
        title: 'Venta por ${mxn(sale.total)} (${_payName(sale.payment)}).',
        detail: sale.authCode != null ? 'Autorización: ${sale.authCode}.' : null,
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
            .map((l) => '${l.qty} × ${productById(l.productId)?.name ?? l.productId}')
            .join(', '),
        kind: 'Registrado',
      ),
      ...memory,
    ];
    notifyListeners();
  }

  void receiveDelivery(List<SaleLine> lines) {
    products = [
      for (final p in products)
        if (lines.any((l) => l.productId == p.id))
          p.copyWith(stock: p.stock + _qtyOf(lines, p.id))
        else
          p,
    ];
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
      cart = [...cart, CartLine(productId: productId, qty: qty.clamp(1, stock))];
    }
    notifyListeners();
  }

  void setCartQty(String productId, int qty) {
    final stock = productById(productId)?.stock ?? 0;
    if (qty <= 0) {
      cart = [for (final l in cart) if (l.productId != productId) l];
    } else {
      cart = [
        for (final l in cart)
          if (l.productId == productId) l.copyWith(qty: qty.clamp(1, stock)) else l,
      ];
    }
    notifyListeners();
  }

  void clearCart() {
    cart = [];
    notifyListeners();
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
  }

  void toggleVideoSave(String productId) {
    if (savedVideos.contains(productId)) {
      savedVideos.remove(productId);
    } else {
      savedVideos.add(productId);
    }
    notifyListeners();
  }

  void addVideoComment(String productId, String text) {
    final list = videoComments[productId] ?? [];
    videoComments[productId] = [
      VideoComment(author: 'Jorge', initial: 'J', text: text, ago: 'ahora'),
      ...list,
    ];
    notifyListeners();
  }

  Sale? registerCartSale({PaymentMethod payment = PaymentMethod.efectivo}) {
    if (cart.isEmpty) return null;
    final sale = Sale(
      id: uid(),
      lines: [for (final l in cart) SaleLine(productId: l.productId, qty: l.qty)],
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
