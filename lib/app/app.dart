import 'dart:async';

import 'package:flutter/material.dart';

import '../core/data.dart';
import '../core/mock_ai.dart';
import '../core/store.dart';
import '../core/theme_prefs.dart';
import '../features/home/home_screen.dart';
import '../features/hoy/hoy_screen.dart';
import '../features/memoria/memoria_screen.dart';
import '../features/negocio/negocio_screen.dart';
import '../features/sheets/camera_sheet.dart';
import '../features/sheets/closing_sheet.dart';
import '../features/sheets/product_sheet.dart';
import '../features/sheets/scan_sheet.dart';
import '../features/sheets/shopping_sheet.dart';
import '../features/sheets/voice_sheet.dart';
import '../features/tienda/tienda_screen.dart';
import 'router.dart';
import 'theme.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/composer.dart';
import 'widgets/sheet.dart';

class CarrotaApp extends StatefulWidget {
  final String initialLocation;

  const CarrotaApp({super.key, required this.initialLocation});

  @override
  State<CarrotaApp> createState() => _CarrotaAppState();
}

class _CarrotaAppState extends State<CarrotaApp> {
  final _themePrefs = ThemePrefs();
  bool _dark = false;

  @override
  void initState() {
    super.initState();
    _themePrefs.isDark().then((value) {
      if (!mounted) return;
      setState(() {
        _dark = value;
        AppColors.isDark = value;
      });
    });
  }

  void _setDark(bool value) {
    AppColors.isDark = value;
    setState(() => _dark = value);
    _themePrefs.setDark(value);
  }

  @override
  Widget build(BuildContext context) {
    return LumoScope(
      store: LumoStore(),
      child: MaterialApp.router(
        title: 'Lumo · Carrota',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        darkTheme: buildAppTheme(),
        themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
        routerConfig: AppRouter.create(
          initialLocation: widget.initialLocation,
          shellBuilder: (_) => _Shell(darkMode: _dark, onToggleTheme: _setDark),
        ),
      ),
    );
  }
}

class _Shell extends StatefulWidget {
  final bool darkMode;
  final ValueChanged<bool> onToggleTheme;

  const _Shell({required this.darkMode, required this.onToggleTheme});

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  AppTab _tab = AppTab.inicio;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LumoScope.of(context).loadRemote();
    });
  }

  String _now() {
    final d = DateTime.now();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _handleSend(String text) {
    final store = LumoScope.of(context);
    store.pushChat(ChatMsg.userText(uid(), text));
    final intent = detectIntent(text);

    switch (intent) {
      case AppIntent.sale:
        final lines = parseSale(text, store.products);
        if (lines.isEmpty) {
          store.pushChat(
            ChatMsg.lumoText(
              uid(),
              'No pude identificar los productos con claridad. ¿Puedes decirlos otra vez?',
            ),
          );
          return;
        }
        final sale = Sale(
          id: uid(),
          lines: lines,
          total: totalOf(lines, store.products),
          at: _now(),
        );
        store.pushChat(
          ChatMsg(
            id: uid(),
            role: Role.lumo,
            kind: MsgKind.saleProposal,
            sale: sale,
            awaitingPayment: true,
          ),
        );
      case AppIntent.receive:
        _openCamera();
      case AppIntent.close:
        _openClosing();
      case AppIntent.question:
        _llmReply(text);
      case AppIntent.unknown:
        store.pushChat(
          ChatMsg.lumoText(
            uid(),
            'Puedo registrar ventas ("Vendí dos lechugas"), recibir mercadería o responder cómo va el negocio.',
          ),
        );
    }
  }

  Future<void> _llmReply(String text) async {
    final store = LumoScope.of(context);
    List<Map<String, dynamic>> history() => [
      for (final m
          in store.chat.length > 8
              ? store.chat.sublist(store.chat.length - 8)
              : store.chat)
        if (m.role == Role.user && m.text != null)
          {'role': 'user', 'content': m.text!}
        else if (m.role == Role.lumo && m.text != null)
          {'role': 'assistant', 'content': m.text!},
    ];
    final res = await store.api.lumo(text, history: history());
    if (!mounted) return;
    if (res.power && res.reply != null) {
      store.pushChat(ChatMsg.lumoText(uid(), res.reply!));
      store.refreshSummary();
      return;
    }
    store.pushChat(
      ChatMsg.lumoText(
        uid(),
        'Hasta ahora llevas \$2,430 en ventas hoy. El tomate es lo más vendido y la lechuga podría agotarse mañana.',
      ),
    );
    Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      store.pushChat(
        ChatMsg(
          id: uid(),
          role: Role.lumo,
          kind: MsgKind.insight,
          productId: 'lechuga',
          reason:
              'Quedan 4 lechugas y normalmente vendes 6 por día. Basado en ventas de los últimos 14 días.',
          recommendation: 'Agregar 12 lechugas a la lista de compra de mañana.',
        ),
      );
      store.refreshSummary();
    });
  }

  void _onPickPayment(String id, PaymentMethod method) {
    final store = LumoScope.of(context);
    final msg = store.chat.where((m) => m.id == id).firstOrNull;
    if (msg == null ||
        msg.role != Role.lumo ||
        msg.kind != MsgKind.saleProposal) {
      return;
    }
    final sale = msg.sale!;
    if (method == PaymentMethod.efectivo ||
        method == PaymentMethod.transferencia) {
      final updated = sale.copyWith(payment: method);
      store.updateChat(
        id,
        (m) =>
            m.copyWith(sale: updated, awaitingPayment: false, confirmed: true),
      );
      store.applySale(updated);
      store.pushChat(
        ChatMsg(
          id: uid(),
          role: Role.lumo,
          kind: MsgKind.impact,
          text: 'La venta quedó registrada.',
          items: [
            'Venta por ${mxn(updated.total)}',
            'Inventario actualizado',
            'Pago con ${method.name}',
          ],
        ),
      );
    } else {
      store.updateChat(
        id,
        (m) => m.copyWith(
          sale: sale.copyWith(payment: method),
          awaitingPayment: false,
          awaitingAuth: method == PaymentMethod.tarjeta,
        ),
      );
      if (method != PaymentMethod.tarjeta) {
        store.pushChat(
          ChatMsg.lumoText(uid(), '¿Cuánto pagó con cada método?'),
        );
      }
    }
  }

  void _onSubmitAuth(String id, String auth) {
    final store = LumoScope.of(context);
    final msg = store.chat.where((m) => m.id == id).firstOrNull;
    if (msg == null ||
        msg.role != Role.lumo ||
        msg.kind != MsgKind.saleProposal) {
      return;
    }
    final sale = msg.sale!.copyWith(
      payment: PaymentMethod.tarjeta,
      authCode: auth,
    );
    store.updateChat(
      id,
      (m) => m.copyWith(sale: sale, awaitingAuth: false, confirmed: true),
    );
    store.applySale(sale);
    store.pushChat(
      ChatMsg(
        id: uid(),
        role: Role.lumo,
        kind: MsgKind.impact,
        text: 'La venta quedó registrada.',
        items: [
          'Venta por ${mxn(sale.total)}',
          'Inventario actualizado',
          'Pago con tarjeta',
          'Autorización $auth',
        ],
      ),
    );
  }

  void _onApproveReceipt(String id) {
    final store = LumoScope.of(context);
    final msg = store.chat.where((m) => m.id == id).firstOrNull;
    if (msg == null || msg.kind != MsgKind.receipt) return;
    store.receiveDelivery(msg.lines ?? [], supplier: msg.supplier);
    store.updateChat(id, (m) => m.copyWith(approved: true));
  }

  void _onUndo(String id) {
    final store = LumoScope.of(context);
    store.undoSale(id);
    store.pushChat(
      ChatMsg.lumoText(
        uid(),
        'Listo, deshice esa operación. El inventario y la caja volvieron al estado anterior.',
      ),
    );
    store.refreshSummary();
  }

  void _onStarter(String text) {
    final store = LumoScope.of(context);
    if (text.contains('venta')) {
      _handleSend('Vendí dos tomates, una lechuga y tres cilantro');
    } else if (text.contains('mercader')) {
      _openCamera();
    } else if (text.contains('falta')) {
      store.pushChat(
        ChatMsg(
          id: uid(),
          role: Role.lumo,
          kind: MsgKind.insight,
          productId: 'lechuga',
          reason: 'Quedan 4 lechugas y normalmente vendes 6 por día.',
          recommendation: 'Agregar 12 lechugas a la lista de compra de mañana.',
        ),
      );
    } else if (text.contains('cierre')) {
      _openClosing();
    }
  }

  void _onImportReceipt() {
    LumoScope.of(context).pushChat(
      ChatMsg(
        id: uid(),
        role: Role.lumo,
        kind: MsgKind.receipt,
        supplier: 'Huerto Norte',
        total: 1450,
        lines: const [
          SaleLine(productId: 'tomate', qty: 20),
          SaleLine(productId: 'lechuga', qty: 15),
          SaleLine(productId: 'espinaca', qty: 10),
          SaleLine(productId: 'cilantro', qty: 12),
        ],
      ),
    );
  }

  void _onVoiceConfirm(String text) {
    final store = LumoScope.of(context);
    final normalized = text.trim();
    if (normalized.isEmpty) return;
    store.pushChat(ChatMsg.userText(uid(), normalized));
    final lines = parseSale(normalized, store.products);
    if (lines.isEmpty) {
      _handleSend(normalized);
      return;
    }
    final sale = Sale(
      id: uid(),
      lines: lines,
      total: totalOf(lines, store.products),
      payment: PaymentMethod.efectivo,
      at: _now(),
      serverId: null,
    );
    store.pushChat(
      ChatMsg(
        id: uid(),
        role: Role.lumo,
        kind: MsgKind.saleProposal,
        sale: sale,
        confirmed: true,
      ),
    );
    store.applySale(sale);
    store.pushChat(
      ChatMsg(
        id: uid(),
        role: Role.lumo,
        kind: MsgKind.impact,
        text: 'Venta por voz registrada.',
        items: [
          'Venta por ${mxn(sale.total)}',
          'Inventario actualizado',
          'Pago en efectivo',
        ],
      ),
    );
    store.refreshSummary();
  }

  void _openVoice() {
    showAppSheet(
      context,
      title: 'Hablando con Lumo',
      builder: (ctx) => VoiceSheet(onConfirm: _onVoiceConfirm),
    );
  }

  void _openCamera() {
    showAppSheet(
      context,
      title: 'Documento',
      builder: (ctx) => CameraSheet(onImportReceipt: _onImportReceipt),
    );
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ScanSheet(onOpenProduct: (p) => _openProduct(p.id)),
      ),
    );
  }

  void _openClosing() {
    showAppSheet(
      context,
      title: 'Cierre del día',
      builder: (ctx) => const ClosingSheet(),
    );
  }

  void _openShopping() {
    showAppSheet(
      context,
      title: 'Compra sugerida para mañana',
      builder: (ctx) => const ShoppingSheet(),
    );
  }

  void _openProduct(String id) {
    showAppSheet(
      context,
      title: LumoScope.of(context).productById(id)?.name ?? 'Producto',
      builder: (ctx) => ProductSheet(productId: id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: switch (_tab) {
                  AppTab.inicio => HomeScreen(
                    onPickPayment: _onPickPayment,
                    onSubmitAuth: _onSubmitAuth,
                    onApproveReceipt: _onApproveReceipt,
                    onOpenInsight: _openProduct,
                    onUndo: _onUndo,
                    onStarter: _onStarter,
                    onOpenProduct: _openProduct,
                  ),
                  AppTab.hoy => HoyScreen(onOpenClosing: _openClosing),
                  AppTab.memoria => const MemoriaScreen(),
                  AppTab.negocio => NegocioScreen(
                    onOpenProduct: _openProduct,
                    onOpenShopping: _openShopping,
                    darkMode: widget.darkMode,
                    onToggleTheme: widget.onToggleTheme,
                  ),
                  AppTab.tienda => const TiendaScreen(),
                },
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.hairline)),
                ),
                child: Composer(
                  onSend: _handleSend,
                  onVoice: _openVoice,
                  onCamera: _openCamera,
                  onScan: _openScanner,
                ),
              ),
              BottomNav(
                tab: _tab,
                onChange: (t) {
                  setState(() => _tab = t);
                  if (t == AppTab.hoy) {
                    LumoScope.of(context).refreshSummary();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
