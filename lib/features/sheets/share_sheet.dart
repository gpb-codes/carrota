import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/sheet.dart';
import '../../core/data.dart';
import '../../core/store.dart';

Future<void> showShareSheet(
  BuildContext context, {
  required VideoProduct video,
}) {
  return showAppSheet(
    context,
    title: 'Compartir video',
    builder: (ctx) => ShareSheet(video: video),
  );
}

class ShareSheet extends StatelessWidget {
  final VideoProduct video;

  const ShareSheet({super.key, required this.video});

  void _done(BuildContext context, String msg) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: Text(msg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = LumoScope.of(context).productById(video.productId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(p?.emoji ?? '🎬', style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p?.name ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    Text(
                      video.caption,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ShareRow(
            circleColor: const Color(0xFF25D366),
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            onTap: () => _done(context, 'Video enviado por WhatsApp'),
          ),
          _ShareRow(
            circleColor: const Color(0xFFE1306C),
            icon: Icons.photo_camera_rounded,
            label: 'Instagram',
            onTap: () => _done(context, 'Video enviado a Instagram'),
          ),
          _ShareRow(
            circleColor: const Color(0xFF1877F2),
            icon: Icons.facebook_rounded,
            label: 'Facebook',
            onTap: () => _done(context, 'Video enviado a Facebook'),
          ),
          const SizedBox(height: 8),
          Divider(color: AppColors.hairline, height: 1),
          SizedBox(height: 8),
          _ShareRow(
            circleColor: AppColors.surface2,
            iconColor: AppColors.foreground,
            icon: Icons.link_rounded,
            label: 'Copiar enlace',
            onTap: () => _done(context, 'Enlace copiado al portapapeles'),
          ),
          _ShareRow(
            circleColor: AppColors.surface2,
            iconColor: AppColors.foreground,
            icon: Icons.download_rounded,
            label: 'Descargar video',
            onTap: () => _done(context, 'Video descargado'),
          ),
          _ShareRow(
            circleColor: AppColors.surface2,
            iconColor: AppColors.foreground,
            icon: Icons.more_horiz_rounded,
            label: 'Más opciones',
            onTap: () => _done(context, 'Abriendo más opciones…'),
          ),
        ],
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  final Color circleColor;
  final Color? iconColor;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareRow({
    required this.circleColor,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: circleColor,
              child: Icon(icon, size: 17, color: iconColor ?? Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 15, color: AppColors.foreground),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
