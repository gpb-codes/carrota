import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/data.dart';
import '../../core/store.dart';

class ScanSheet extends StatefulWidget {
  final void Function(Product product) onOpenProduct;

  const ScanSheet({super.key, required this.onOpenProduct});

  @override
  State<ScanSheet> createState() => _ScanSheetState();
}

class _ScanSheetState extends State<ScanSheet> {
  late final MobileScannerController _controller;
  Product? _found;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.qrCode,
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_found != null || _notFound) return;
    final raw = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (raw == null || raw.isEmpty) return;
    final store = LumoScope.of(context);
    final product = store.productByBarcode(raw);
    HapticFeedback.mediumImpact();
    if (mounted) {
      setState(() {
        if (product != null) {
          _found = product;
        } else {
          _notFound = true;
        }
      });
    }
  }

  void _reset() {
    setState(() {
      _found = null;
      _notFound = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Escanear código',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => const _ScanError(error: null),
          ),
          _ScanOverlay(found: _found != null),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: _found != null
                ? _FoundCard(
                    product: _found!,
                    onOpenProduct: () {
                      final p = _found!;
                      Navigator.of(context).pop();
                      widget.onOpenProduct(p);
                    },
                    onAgain: _reset,
                  )
                : _notFound
                    ? _NotFoundCard(onAgain: _reset)
                    : const _HintBar(),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  final bool found;

  const _ScanOverlay({required this.found});

  @override
  Widget build(BuildContext context) {
    if (found) return const SizedBox.shrink();
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFFC107), width: 3),
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }
}

class _HintBar extends StatelessWidget {
  const _HintBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xE6252525),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Apunta la cámara al código de barras del producto',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}

class _FoundCard extends StatelessWidget {
  final Product product;
  final VoidCallback onOpenProduct;
  final VoidCallback onAgain;

  const _FoundCard({
    required this.product,
    required this.onOpenProduct,
    required this.onAgain,
  });

  @override
  Widget build(BuildContext context) {
    final store = LumoScope.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(product.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${product.price} MXN / ${product.unit} · '
                      '${product.stock} en inventario',
                      style: const TextStyle(
                        color: Color(0xFF9A9A9E),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onAgain,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                color: Colors.white70,
                tooltip: 'Escanear otro',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    store.addToCart(product.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.emoji} ${product.name} al carrito'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('Agregar al carrito'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF34C759),
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => store.receiveDelivery([SaleLine(productId: product.id, qty: 1)]),
                  icon: const Icon(Icons.add_box_rounded, size: 18),
                  label: const Text('Recibir 1'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF3A3A3C)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onOpenProduct,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF3A3A3C)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotFoundCard extends StatelessWidget {
  final VoidCallback onAgain;

  const _NotFoundCard({required this.onAgain});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xE6252525),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No encontré ese producto en tu inventario',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onAgain,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Escanear otro'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFFC107),
              side: const BorderSide(color: Color(0xFF3A3A3C)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanError extends StatelessWidget {
  final Object? error;

  const _ScanError({this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_outlined,
              size: 48, color: Colors.white38),
          const SizedBox(height: 12),
          const Text(
            'No pude abrir la cámara.\nRevisa el permiso en los ajustes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
