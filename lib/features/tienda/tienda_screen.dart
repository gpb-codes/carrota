import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../app/theme.dart';
import '../../app/widgets/sheet.dart';
import '../../core/data.dart';
import '../../core/store.dart';
import '../sheets/cart_sheet.dart';
import '../sheets/comments_sheet.dart';
import '../sheets/product_sheet.dart';
import '../sheets/share_sheet.dart';
import 'my_videos_sheet.dart';
import 'publish_video_sheet.dart';
import 'video_recorder_sheet.dart';

class TiendaScreen extends StatefulWidget {
  const TiendaScreen({super.key});

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

enum _FeedSection { todo, favoritos, recientes, top }

class _TiendaScreenState extends State<TiendaScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  int _page = 0;
  _FeedSection _section = _FeedSection.todo;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VideoProduct> _filtered(LumoStore store) {
    final q = _query.trim().toLowerCase();
    final byQuery = q.isEmpty
        ? store.feedVideos
        : [
            for (final v in store.feedVideos)
              if (_matches(v, store, q)) v,
          ];
    return switch (_section) {
      _FeedSection.todo => byQuery,
      _FeedSection.favoritos => [
        for (final v in byQuery)
          if (store.isFavorite(v.productId)) v,
      ],
      _FeedSection.recientes => [
        for (final v in byQuery)
          if (store.recentlyViewed.contains(v.productId)) v,
      ],
      _FeedSection.top => [
        for (final v in byQuery)
          if (store.topSellers.any((t) => t.product.id == v.productId)) v,
      ],
    };
  }

  String get _emptyMessage => switch (_section) {
    _FeedSection.todo => 'Sin resultados para "$_query"',
    _FeedSection.favoritos =>
      'Aún no tienes favoritos. Toca el corazón en un producto para guardarlo aquí.',
    _FeedSection.recientes =>
      'Todavía no has visto productos. Ábrelos desde el catálogo y aparecerán aquí.',
    _FeedSection.top =>
      'Aún no hay ventas para armar el ranking. Registra tu primera venta.',
  };

  bool _matches(VideoProduct v, LumoStore store, String q) {
    if (v.caption.toLowerCase().contains(q)) return true;
    if (v.hashtags.any((t) => t.toLowerCase().contains(q))) return true;
    final name = store.productById(v.productId)?.name.toLowerCase() ?? '';
    return name.contains(q);
  }

  void _openRecorder() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => VideoRecorderSheet(
          onRecorded: (video) async {
            final published = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                fullscreenDialog: true,
                builder: (_) => PublishVideoSheet(video: video),
              ),
            );
            if (published == true && mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                    content: Text('Video publicado en tu tienda'),
                  ),
                );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = LumoScope.of(context);
    final items = _filtered(store);
    return Column(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: _SearchField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: const ValueKey('record-btn'),
                  onPressed: _openRecorder,
                  icon: const Icon(Icons.videocam_rounded, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.25),
                  ),
                  tooltip: 'Grabar un video',
                ),
                const SizedBox(width: 8),
                Badge(
                  isLabelVisible: store.myVideos.isNotEmpty,
                  label: Text('${store.myVideos.length}'),
                  child: IconButton(
                    key: const ValueKey('my-videos-btn'),
                    onPressed: () => showMyVideosSheet(context),
                    icon: const Icon(
                      Icons.video_library_rounded,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.25),
                    ),
                    tooltip: 'Mis videos',
                  ),
                ),
                if (items.isNotEmpty) ...[
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
                      '${_page + 1} / ${items.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
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
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final s in _FeedSection.values) ...[
                ChoiceChip(
                  label: Text(_sectionLabel(s)),
                  selected: _section == s,
                  onSelected: (_) => setState(() => _section = s),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  selectedColor: Colors.white,
                  backgroundColor: Colors.black.withValues(alpha: 0.25),
                  side: BorderSide(
                    color: _section == s
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.35),
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _section == s ? AppColors.foreground : Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? _EmptySearch(message: _emptyMessage)
              : PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: items.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, index) =>
                      _VideoPage(video: items[index], index: index),
                ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: Colors.white,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar en la tienda…',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: Colors.white70,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  final String message;

  const _EmptySearch({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 44,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Prueba con otro nombre, etiqueta o descripción.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
            ),
          ],
        ),
      ),
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

class _VideoPageState extends State<_VideoPage> with TickerProviderStateMixin {
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
  VideoPlayerController? _player;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    final path = widget.video.filePath;
    if (path != null && path.isNotEmpty) {
      _initPlayer(path);
    }
  }

  Future<void> _initPlayer(String path) async {
    final controller = VideoPlayerController.file(File(path));
    _player = controller;
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() => _videoFailed = true);
      } else {
        await controller.dispose();
      }
    }
  }

  void _togglePlay() {
    final player = _player;
    if (player == null || !player.value.isInitialized) return;
    if (player.value.isPlaying) {
      player.pause();
    } else {
      player.play();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _burst.dispose();
    _pop.dispose();
    _player?.dispose();
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
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppColors.accent,
              ),
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
    final related = store.relatedTo(video.productId);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = _pulse.value;
        final c1 = Color(video.c1);
        final c2 = Color(video.c2);
        final player = _player;
        final playing =
            player != null && player.value.isInitialized && !_videoFailed;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (playing)
              Positioned.fill(child: VideoPlayer(player))
            else ...[
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
            ],
            Positioned.fill(
              child: GestureDetector(
                onDoubleTap: _onDoubleTap,
                onTap: _togglePlay,
              ),
            ),
            if (video.mine)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Tuyo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
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
                      CurvedAnimation(
                        parent: _burst,
                        curve: Curves.easeOutBack,
                      ),
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
                            if (related.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 36,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: related.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 6),
                                  itemBuilder: (context, i) {
                                    final r = related[i];
                                    return InkWell(
                                      onTap: () => showAppSheet(
                                        context,
                                        title: r.name,
                                        builder: (_) =>
                                            ProductSheet(productId: r.id),
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.18,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              r.emoji,
                                              style: const TextStyle(
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              r.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              mxn(r.price),
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                            SizedBox(height: 12),
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
                            onTap: () =>
                                showCommentsSheet(context, video: video),
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

String _sectionLabel(_FeedSection s) => switch (s) {
  _FeedSection.todo => 'Todo',
  _FeedSection.favoritos => 'Favoritos',
  _FeedSection.recientes => 'Recientes',
  _FeedSection.top => 'Más vendidos',
};

