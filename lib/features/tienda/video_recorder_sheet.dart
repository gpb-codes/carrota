import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Pantalla de grabación de video para la Tienda (estilo TikTok Shop).
/// Usa la cámara y el micrófono del dispositivo. Si no hay cámara
/// disponible (Windows/Chrome/tests) entra en modo simulado.
class VideoRecorderSheet extends StatefulWidget {
  final void Function(XFile video) onRecorded;

  const VideoRecorderSheet({super.key, required this.onRecorded});

  @override
  State<VideoRecorderSheet> createState() => _VideoRecorderSheetState();
}

enum _Phase { idle, recording, done }

class _VideoRecorderSheetState extends State<VideoRecorderSheet>
    with TickerProviderStateMixin {
  CameraController? _cam;
  bool _mock = false;
  bool _front = false;
  _Phase _phase = _Phase.idle;
  XFile? _file;
  int _seconds = 0;
  Timer? _ticker;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    _cam?.dispose();
    super.dispose();
  }

  Future<void> _setup() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        _enterMock();
        return;
      }
      await _initCamera(cams, front: _front);
    } catch (_) {
      _enterMock();
    }
  }

  Future<void> _initCamera(
    List<CameraDescription> cams, {
    required bool front,
  }) async {
    final prev = _cam;
    _cam = null;
    await prev?.dispose();
    final matching = cams
        .where(
          (c) =>
              c.lensDirection ==
              (front ? CameraLensDirection.front : CameraLensDirection.back),
        )
        .toList();
    final desc = matching.isNotEmpty ? matching.first : cams.first;
    final controller = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: true,
    );
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _cam = controller);
  }

  void _enterMock() {
    if (!mounted) return;
    setState(() => _mock = true);
  }

  void _flip() {
    if (_mock || _phase != _Phase.idle) return;
    setState(() => _front = !_front);
    _setup();
  }

  Future<void> _toggleFlash() async {
    final cam = _cam;
    if (cam == null || !cam.value.isInitialized) return;
    try {
      await cam.setFlashMode(
        cam.value.flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off,
      );
    } catch (_) {
      // flash no disponible
    }
  }

  Future<void> _toggleRecord() async {
    if (_phase == _Phase.recording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (_phase != _Phase.idle) return;
    final cam = _cam;
    if (cam != null && cam.value.isInitialized) {
      try {
        await cam.startVideoRecording();
        if (!mounted) return;
        _beginRecording();
        return;
      } catch (_) {
        // cámara sin soporte de video → modo simulado
      }
    }
    _beginRecording(mock: true);
  }

  void _beginRecording({bool mock = false}) {
    _ticker?.cancel();
    setState(() {
      _mock = mock || _mock;
      _phase = _Phase.recording;
      _seconds = 0;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    _pulse.repeat(reverse: true);
  }

  Future<void> _stopRecording() async {
    _ticker?.cancel();
    _pulse
      ..stop()
      ..value = 0;
    if (_mock) {
      _finish(
        XFile.fromData(
          Uint8List.fromList(const [0, 0, 0, 0]),
          name: 'video_mock.mp4',
          mimeType: 'video/mp4',
        ),
      );
      return;
    }
    final cam = _cam;
    if (cam == null || !cam.value.isRecordingVideo) return;
    try {
      final file = await cam.stopVideoRecording();
      if (!mounted) return;
      _finish(file);
    } catch (_) {
      if (mounted) setState(() => _phase = _Phase.idle);
    }
  }

  void _finish(XFile file) {
    if (!mounted) return;
    setState(() {
      _file = file;
      _phase = _Phase.done;
    });
  }

  void _reset() {
    setState(() {
      _phase = _Phase.idle;
      _file = null;
      _seconds = 0;
    });
  }

  void _publish() {
    final file = _file;
    if (file == null) return;
    widget.onRecorded(file);
    Navigator.of(context).pop();
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildViewport(),
          SafeArea(child: _buildTopBar()),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _buildControls(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewport() {
    final cam = _cam;
    if (_phase == _Phase.done && _file != null) {
      return Container(
        color: AppColors.surface2,
        child: const Center(
          child: Icon(
            Icons.play_circle_outline_rounded,
            size: 72,
            color: Colors.white70,
          ),
        ),
      );
    }
    if (cam != null && cam.value.isInitialized) {
      return CameraPreview(cam);
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2F6B2F), const Color(0xFF8F4E17)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.videocam_rounded, size: 72, color: Colors.white54),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 28,
            ),
            tooltip: 'Cerrar',
          ),
          const Spacer(),
          if (_phase == _Phase.recording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE5484D),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _fmt(_seconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (_phase == _Phase.idle && !_mock) ...[
            IconButton(
              onPressed: _toggleFlash,
              icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
              tooltip: 'Linterna',
            ),
            IconButton(
              onPressed: _flip,
              icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
              tooltip: 'Cambiar cámara',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControls() {
    if (_phase == _Phase.done) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Volver a grabar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _publish,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Publicar'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final recording = _phase == _Phase.recording;
          final scale = recording ? 1 + 0.12 * _pulse.value : 1.0;
          return GestureDetector(
            key: const ValueKey('record-btn'),
            onTap: _toggleRecord,
            child: Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Transform.scale(
                scale: scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: recording ? const Color(0xFFE5484D) : Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
