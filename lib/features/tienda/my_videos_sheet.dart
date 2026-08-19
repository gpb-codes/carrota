import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/sheet.dart';
import '../../core/data.dart';
import '../../core/store.dart';
import 'publish_video_sheet.dart';

Future<void> showMyVideosSheet(BuildContext context) {
  return showAppSheet(
    context,
    title: 'Mis videos',
    builder: (ctx) => const MyVideosSheet(),
  );
}

class MyVideosSheet extends StatefulWidget {
  const MyVideosSheet({super.key});

  @override
  State<MyVideosSheet> createState() => _MyVideosSheetState();
}

class _MyVideosSheetState extends State<MyVideosSheet> {
  Future<void> _edit(MyVideo video) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => PublishVideoSheet(editing: video),
      ),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
            content: Text('Cambios guardados'),
          ),
        );
    }
  }

  Future<void> _delete(MyVideo video) async {
    final store = LumoScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Eliminar video',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Se eliminará el video de "${video.caption}". Esta acción no se puede deshacer.',
          style: TextStyle(color: AppColors.foreground, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      store.removeMyVideo(video.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = LumoScope.of(context);
    final videos = store.myVideos;
    if (videos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Icon(
              Icons.video_library_rounded,
              size: 44,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: 12),
            Text(
              'Aún no has publicado videos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Usa el botón de cámara arriba para grabar tu primer video.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
            ),
          ],
        ),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 480),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: videos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final v = videos[i];
          final p = store.productById(v.productId);
          return _VideoTile(
            video: v,
            productName: p == null ? 'Producto' : p.name,
            onEdit: () => _edit(v),
            onDelete: () => _delete(v),
          );
        },
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final MyVideo video;
  final String productName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VideoTile({
    required this.video,
    required this.productName,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tags = video.hashtags.map((t) => '#$t').join(' ');
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              gradient: LinearGradient(
                colors: [Color(video.c1), Color(video.c2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$productName · $tags',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Column(
            children: [
              Text(
                mxn(video.price),
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}
