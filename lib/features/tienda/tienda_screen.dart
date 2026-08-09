import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/data.dart';
import '../../core/store.dart';
import '../sheets/cart_sheet.dart';
import '../sheets/comments_sheet.dart';
import '../sheets/share_sheet.dart';

class TiendaScreen extends StatelessWidget {
  const TiendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: videoFeed.length,
      itemBuilder: (context, index) => _VideoPage(video: videoFeed[index], index: index),
    );
  }
}

class _VideoPage extends StatefulWidget {
  final VideoProduct video;
  final int index;

  const _VideoPage({required this.video, required this.index});

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  @override
  void dispose() {
    _pulse.dispose();
    _burst.dispose();
    _pop.dispose();
    super.dispose();
  }

  void _like() {
    final store = LumoScope.of(context);
    store.toggleVideoLike(widget.video.productId);
    if (store.likedVideos.contains(widget.video.productId)) {
      _pop.forward(from: 0);
    }
  }

  void _onDoubleTap() {
    final store = LumoScope.of(context);
    if (!store.likedVideos.contains(widget.video.productId)) _like();
    _burst.forward(from: 0);
  }

  void _addToCart() {
    final store = LumoScope.of(context);
    store.addToCart(widget.video.productId);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Agregado a tu venta · ${store.cartCount} productos'),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final store = LumoScope.of(context);
    final video = widget.video;
    final p = store.productById(video.productId);
    if (p == null) return const SizedBox.shrink();

    final liked = store.likedVideos.contains(video.productId);
    final saved = store.savedVideos.contains(video.productId);
    final likes = store.videoLikes[video.productId] ?? 0;
    final comments = store.commentCountFor(video.productId);
    final lowStock = p.stock <= 5;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = _pulse.value;
        final c1 = Color(video.c1);
        final c2 = Color(video.c2);
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c1, Color.lerp(c1, c2, t)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.2,
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                    stops: const [0.15, 0.6],
                  ),
                ),
              ),
            ),
            Center(
              child: Transform.translate(
                offset: Offset(0, -34 - 16 * t),
                child: Transform.scale(
                  scale: 1 + 0.05 * t,
                  child: Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 50,
                          spreadRadius: 6,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        p.emoji,
                        style: const TextStyle(fontSize: 96, height: 1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(child: GestureDetector(onDoubleTap: _onDoubleTap)),
            IgnorePointer(
              child: Center(
                child: FadeTransition(
                  opacity: Tween(begin: 1.0, end: 0.0).animate(
                    CurvedAnimation(
                      parent: _burst,
                      curve: const Interval(0.55, 1),
                    ),
                  ),
                  child: ScaleTransition(
                    scale: Tween(begin: 0.6, end: 1.25).animate(
                      CurvedAnimation(parent: _burst, curve: Curves.easeOutBack),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 96,
                      color: Colors.white.withValues(alpha: 0.92),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 300,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Tienda',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${widget.index + 1} / ${videoFeed.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Badge(
                      isLabelVisible: store.cartCount > 0,
                      label: Text('${store.cartCount}'),
                      child: IconButton(
                        onPressed: () => showCartSheet(context),
                        icon: const Icon(
                          Icons.shopping_cart_rounded,
                          color: Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 12, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    p.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: lowStock
                                        ? AppColors.amberSoft
                                        : Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    lowStock
                                        ? '¡Pocas unidades!'
                                        : 'Quedan ${p.stock} ${p.unit}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: lowStock
                                          ? AppColors.amber
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  mxn(p.price),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '/ ${p.unit}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  p.supplier ?? '',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              video.caption,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                for (final tag in video.hashtags)
                                  Text(
                                    tag,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 46,
                              child: FilledButton.icon(
                                onPressed: _addToCart,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.foreground,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.add_shopping_cart_rounded,
                                  size: 19,
                                ),
                                label: const Text(
                                  'Agregar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _RailAction(
                            icon: liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_outline_rounded,
                            color: liked ? AppColors.danger : Colors.white,
                            label: _k(likes),
                            onTap: _like,
                            pop: _pop,
                            liked: liked,
                          ),
                          const SizedBox(height: 18),
                          _RailAction(
                            icon: Icons.chat_bubble_rounded,
                            color: Colors.white,
                            label: _k(comments),
                            onTap: () => showCommentsSheet(context, video: video),
                          ),
                          const SizedBox(height: 18),
                          _RailAction(
                            icon: saved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_outline_rounded,
                            color: saved ? AppColors.accent : Colors.white,
                            label: saved ? 'Guardado' : 'Guardar',
                            onTap: () => store.toggleVideoSave(video.productId),
                          ),
                          const SizedBox(height: 18),
                          _RailAction(
                            icon: Icons.send_rounded,
                            color: Colors.white,
                            label: 'Compartir',
                            onTap: () => showShareSheet(context, video: video),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RailAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final Animation<double>? pop;
  final bool liked;

  const _RailAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.pop,
    this.liked = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 27, color: color);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkResponse(
          onTap: onTap,
          radius: 28,
          child: pop == null
              ? iconWidget
              : ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.3).animate(
                    CurvedAnimation(parent: pop!, curve: Curves.easeOutBack),
                  ),
                  child: iconWidget,
                ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6),
            ],
          ),
        ),
      ],
    );
  }
}

String _k(int n) {
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)} k';
  return '$n';
}
