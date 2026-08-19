import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/data.dart';
import '../../core/store.dart';

/// Formulario para publicar (o editar) un video de la Tienda.
/// Recibe el archivo grabado (VideoRecorderSheet) o un video ya publicado
/// (modo edición desde "Mis videos").
class PublishVideoSheet extends StatefulWidget {
  final XFile? video;
  final MyVideo? editing;

  const PublishVideoSheet({super.key, this.video, this.editing});

  @override
  State<PublishVideoSheet> createState() => _PublishVideoSheetState();
}

class _PublishVideoSheetState extends State<PublishVideoSheet> {
  late final TextEditingController _caption;
  late final TextEditingController _hashtags;
  late final TextEditingController _price;
  late final FocusNode _captionFocus = FocusNode();
  Product? _product;
  List<String> _chips = [];
  bool _priceTouched = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _caption = TextEditingController(text: editing?.caption ?? '');
    _hashtags = TextEditingController(
      text: editing?.hashtags.map((h) => '#$h').join(' ') ?? '',
    );
    _price = TextEditingController(text: editing?.price.toString() ?? '');
    _chips = [...?editing?.hashtags];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_product != null) return;
    final store = LumoScope.of(context);
    final editing = widget.editing;
    if (editing != null) {
      _product =
          store.productById(editing.productId) ?? store.products.firstOrNull;
    } else {
      _product = store.products.firstOrNull;
    }
    if (!_isEditing && _product != null && _price.text.isEmpty) {
      _price.text = _product!.price.toString();
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    _hashtags.dispose();
    _price.dispose();
    _captionFocus.dispose();
    super.dispose();
  }

  void _parseHashtags(String value) {
    final parts = value
        .split(RegExp(r'[,\s]+'))
        .map((t) => t.trim().replaceFirst(RegExp(r'^#+'), ''))
        .where((t) => t.isNotEmpty)
        .toList();
    setState(() => _chips = parts);
  }

  void _onProductChanged(Product? p) {
    setState(() => _product = p);
    if (!_priceTouched && p != null) {
      _price.text = p.price.toString();
    }
  }

  void _save() {
    final store = LumoScope.of(context);
    final product = _product;
    final caption = _caption.text.trim();
    final price = int.tryParse(_price.text.trim());
    if (product == null || caption.isEmpty || price == null || price <= 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
            content: Text('Completa producto, descripción y un precio válido'),
          ),
        );
      return;
    }
    if (_isEditing) {
      store.updateMyVideo(
        widget.editing!.id,
        caption: caption,
        hashtags: _chips,
        price: price,
      );
    } else {
      store.publishVideo(
        productId: product.id,
        caption: caption,
        hashtags: _chips,
        price: price,
        filePath: widget.video?.path,
      );
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final store = LumoScope.of(context);
    final editing = widget.editing;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cerrar',
        ),
        title: Text(
          _isEditing ? 'Editar video' : 'Publicar video',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(_isEditing ? 'Guardar' : 'Publicar'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _VideoChip(video: widget.video, editing: editing),
          const SizedBox(height: 16),
          Text('Producto', style: _labelStyle()),
          const SizedBox(height: 6),
          DropdownButtonFormField<Product>(
            key: const ValueKey('product-dropdown'),
            initialValue: _product,
            isExpanded: true,
            decoration: _fieldDecoration('Selecciona el producto'),
            items: [
              for (final p in store.products)
                DropdownMenuItem(
                  value: p,
                  child: Text(
                    '${p.emoji} ${p.name}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.foreground, fontSize: 14),
                  ),
                ),
            ],
            onChanged: _onProductChanged,
          ),
          const SizedBox(height: 16),
          Text('Descripción', style: _labelStyle()),
          const SizedBox(height: 6),
          TextField(
            key: const ValueKey('caption-field'),
            controller: _caption,
            focusNode: _captionFocus,
            maxLength: 120,
            maxLines: 3,
            style: TextStyle(color: AppColors.foreground, fontSize: 14),
            decoration: _fieldDecoration(
              'Cuéntale a tus clientes qué ofrece este video',
            ),
          ),
          const SizedBox(height: 8),
          Text('Etiquetas', style: _labelStyle()),
          const SizedBox(height: 6),
          TextField(
            key: const ValueKey('hashtags-field'),
            controller: _hashtags,
            onChanged: _parseHashtags,
            style: TextStyle(color: AppColors.foreground, fontSize: 14),
            decoration: _fieldDecoration('#fresco #oferta ...'),
          ),
          if (_chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in _chips)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text('Precio', style: _labelStyle()),
          const SizedBox(height: 6),
          TextField(
            key: const ValueKey('price-field'),
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _priceTouched = true,
            style: TextStyle(color: AppColors.foreground, fontSize: 16),
            decoration: _fieldDecoration('0').copyWith(
              prefixText: '\$ ',
              prefixStyle: TextStyle(
                color: AppColors.foreground,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _labelStyle() => TextStyle(
    color: AppColors.mutedForeground,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.8)),
    filled: true,
    fillColor: AppColors.surface2,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.hairline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.hairline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

class _VideoChip extends StatelessWidget {
  final XFile? video;
  final MyVideo? editing;

  const _VideoChip({this.video, this.editing});

  @override
  Widget build(BuildContext context) {
    final name = video?.name ?? editing?.id ?? '';
    final title = editing != null ? 'Editando tu video' : 'Video grabado';
    return Container(
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: const [Color(0xFF2F6B2F), Color(0xFF8F4E17)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          const Icon(Icons.videocam_rounded, color: Colors.white, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
