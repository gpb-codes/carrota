import 'package:flutter/material.dart';

import '../theme.dart';

class Composer extends StatefulWidget {
  final void Function(String text) onSend;
  final VoidCallback onVoice;
  final VoidCallback onCamera;
  final VoidCallback onScan;
  final String placeholder;

  const Composer({
    super.key,
    required this.onSend,
    required this.onVoice,
    required this.onCamera,
    required this.onScan,
    this.placeholder = 'Dile algo a tu negocio…',
  });

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final _controller = TextEditingController();
  bool _canSend = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    setState(() => _canSend = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.hairline),
          boxShadow: const [
            BoxShadow(
              color: Color(0x402A9CC0),
              offset: Offset(0, 8),
              blurRadius: 30,
              spreadRadius: -10,
            ),
            BoxShadow(
              color: Color(0x4033A058),
              offset: Offset(0, 2),
              blurRadius: 6,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: widget.onScan,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
              color: AppColors.mutedForeground,
            ),
            IconButton(
              onPressed: widget.onCamera,
              icon: const Icon(Icons.camera_alt_outlined, size: 22),
              color: AppColors.mutedForeground,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  color: AppColors.foreground,
                  fontSize: 15,
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  hintText: 'Dile algo a tu negocio…',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (v) {
                  final can = v.trim().isNotEmpty;
                  if (can != _canSend) setState(() => _canSend = can);
                },
                onSubmitted: (_) => _send(),
              ),
            ),
            _canSend
                ? IconButton(
                    onPressed: _send,
                    icon: const Icon(AppButtons.sendIcon, size: 20),
                    color: AppButtons.sendForeground,
                    style: AppButtons.primaryCircle,
                  )
                : IconButton(
                    onPressed: widget.onVoice,
                    icon: const Icon(Icons.mic_none, size: 22),
                    color: AppColors.mutedForeground,
                  ),
          ],
        ),
      ),
    );
  }
}
