import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/brand.dart';
import '../models/chat_message_model.dart';

/// Burbuja del chat de onboarding.
///
/// Decide su alineación y estilo según [MessageType]: Lumo a la
/// izquierda con su marca, el usuario a la derecha en primario.
/// El ancho máximo nunca ocupa la pantalla completa.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == MessageType.user;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.76;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: isUser
            ? _UserBubble(text: message.text)
            : _LumoBubble(text: message.text),
      ),
    );
  }
}

class _LumoBubble extends StatelessWidget {
  final String text;

  const _LumoBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2, right: 8),
          child: LumoMark(size: 22),
        ),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.foreground,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;

  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(6),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
          color: AppColors.primaryForeground,
        ),
      ),
    );
  }
}
