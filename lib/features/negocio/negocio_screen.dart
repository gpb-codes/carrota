import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/data.dart';
import '../../core/store.dart';

class NegocioScreen extends StatelessWidget {
  final void Function(String id) onOpenProduct;
  final VoidCallback onOpenShopping;

  const NegocioScreen({
    super.key,
    required this.onOpenProduct,
    required this.onOpenShopping,
  });

  @override
  Widget build(BuildContext context) {
    final store = LumoScope.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'NEGOCIO',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedForeground.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Carrota',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          const Text(
            'Huerto urbano y sostenible',
            style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDeco(radius: 20),
            child: Row(
              children: [
                Expanded(
                  child: _InfoRow(label: 'Moneda', value: 'MXN'),
                ),
                Expanded(
                  child: _InfoRow(label: 'Zona horaria', value: 'CDMX'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDeco(radius: 20),
            child: Row(
              children: [
                Expanded(
                  child: _InfoRow(
                    label: 'Productos',
                    value: '${store.products.length} activos',
                  ),
                ),
                Expanded(
                  child: _InfoRow(label: 'Colaboradores', value: '2'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDeco(radius: 20),
            child: Row(
              children: [
                Expanded(
                  child: _InfoRow(
                    label: 'Pagos',
                    value: 'Efectivo · Tarjeta · Transf.',
                  ),
                ),
                Expanded(
                  child: _InfoRow(label: 'Memoria', value: 'Activa'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _MiniLabel('Productos')),
              InkWell(
                onTap: onOpenShopping,
                child: const Text(
                  'Compra sugerida →',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: cardDeco(radius: 20),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < store.products.length; i++)
                  _ProductRow(
                    product: store.products[i],
                    onTap: () => onOpenProduct(store.products[i].id),
                    showDivider: i > 0,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _MiniLabel('Proactividad'),
          const SizedBox(height: 8),
          Container(
            decoration: cardDeco(radius: 20),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < _proactiveOptions.length; i++)
                  _ToggleRow(
                    label: _proactiveOptions[i],
                    defaultOn: i != 2,
                    showDivider: i > 0,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _MiniLabel('Ajustes'),
          const SizedBox(height: 8),
          Container(
            decoration: cardDeco(radius: 20),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < _settings.length; i++)
                  _SettingsRow(label: _settings[i], showDivider: i > 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _proactiveOptions = [
    'Avísame cuando un producto pueda agotarse.',
    'Recuérdame ventas incompletas.',
    'Muéstrame cambios importantes en las ventas.',
    'Envíame un resumen al cerrar el día.',
  ];

  static const _settings = [
    'Información del negocio',
    'Métodos de pago',
    'Colaboradores',
    'Notificaciones',
    'Memoria del negocio',
    'Datos y privacidad',
  ];
}

class _MiniLabel extends StatelessWidget {
  final String text;

  const _MiniLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w500,
        color: AppColors.mutedForeground.withValues(alpha: 0.9),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1,
            color: AppColors.mutedForeground.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.foreground,
          ),
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool showDivider;

  const _ProductRow({
    required this.product,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final low = product.stock <= (product.avgDaily ?? 0);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(top: BorderSide(color: AppColors.hairline))
              : null,
        ),
        child: Row(
          children: [
            Text(product.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.foreground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${product.stock} ${product.unit}${low ? ' · atención' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              mxn(product.price),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatefulWidget {
  final String label;
  final bool defaultOn;
  final bool showDivider;

  const _ToggleRow({
    required this.label,
    required this.defaultOn,
    required this.showDivider,
  });

  @override
  State<_ToggleRow> createState() => _ToggleRowState();
}

class _ToggleRowState extends State<_ToggleRow> {
  late bool _on = widget.defaultOn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: widget.showDivider
            ? const Border(top: BorderSide(color: AppColors.hairline))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.label,
              style: const TextStyle(fontSize: 14, color: AppColors.foreground),
            ),
          ),
          Switch(
            value: _on,
            onChanged: (v) => setState(() => _on = v),
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final bool showDivider;

  const _SettingsRow({required this.label, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(top: BorderSide(color: AppColors.hairline))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.foreground),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.mutedForeground,
          ),
        ],
      ),
    );
  }
}
