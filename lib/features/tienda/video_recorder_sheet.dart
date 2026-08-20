import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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

enum _Filter {
  none('Original', null),
  vintage('Vintage', <double>[
    0.393, 0.769, 0.189, 0, 0, //
    0.349, 0.686, 0.168, 0, 0, //
    0.272, 0.534, 0.131, 0, 0, //
    0, 0, 0, 1, 0,
  ]),
  mono('B/N', <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ]),
  warm('Cálido', <double>[
    1.1, 0, 0, 0, 12, //
    0, 1.05, 0, 0, 6, //
    0, 0, 0.94, 0, 0, //
    0, 0, 0, 1, 0,
  ]),
  fresh('Fresco', <double>[
    0.95, 0, 0, 0, 0, //
    0, 1.05, 0, 0, 6, //
    0, 0, 1.1, 0, 14, //
    0, 0, 0, 1, 0,
  ]);

  const _Filter(this.label, this.matrix);

  final String label;
  final List<double>? matrix;
}

class _VideoRecorderSheetState extends State<VideoRecorderSheet>
    with TickerProviderStateMixin {
  static const _speeds = [0.5, 1.0, 2.0];
  static const _timers = [0, 3, 5, 10];

  CameraController? _cam;
  bool _mock = false;
  bool _front = false;
  _Phase _phase = _Phase.idle;
  XFile? _file;
  int _seconds = 0;
  Timer? _ticker;

  double _speed = 1.0;
  int _timer = 0;
  int? _countdown;
  Timer? _countdownTimer;
  _Filter _filter = _Filter.none;
  bool _grid = false;
  double _zoom = 1.0;
  double _maxZoom = 4.0;

  VideoPlayerController? _preview;

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
    _countdownTimer?.cancel();
    _pulse.dispose();
    _preview?.dispose();
    _cam?.dispose();
    super.dispose();
  }

  Future<void> _setup() async {
    if (kIsWeb) {
      // camera_web rompe el controlador al detener la grabación
      // (Bad state: Cannot add new events after calling close), así que en
      // web el grabador corre en modo simulado.
      _enterMock();
      return;
    }
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
    var maxZoom = 4.0;
    try {
      maxZoom = await controller.getMaxZoomLevel();
    } catch (_) {
      // zoom no disponible
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _cam = controller;
      _maxZoom = maxZoom;
    });
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

  Future<void> _setZoom(double v) async {
    setState(() => _zoom = v);
    final cam = _cam;
    if (cam != null && cam.value.isInitialized) {
      try {
        await cam.setZoomLevel(v);
      } catch (_) {
        // zoom no disponible
      }
    }
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() => _countdown = seconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown = _countdown! - 1);
      if (_countdown! <= 0) {
        t.cancel();
        _countdown = null;
        _startRecording();
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    setState(() => _countdown = null);
  }

  Future<void> _toggleRecord() async {
    if (_countdown != null) {
      _cancelCountdown();
      return;
    }
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
    _ticker = Timer.periodic(Duration(milliseconds: (1000 / _speed).round()), (
      _,
    ) {
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
      final file = await cam.stopVideoRecording().timeout(
        const Duration(seconds: 4),
      );
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
    if (!_mock) _initPreview(file);
  }

  Future<void> _initPreview(XFile file) async {
    final controller = VideoPlayerController.file(File(file.path));
    _preview = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      await controller.dispose();
      _preview = null;
    }
  }

  void _reset() {
    _preview?.dispose();
    _preview = null;
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

  String _speedLabel(double s) =>
      s == s.roundToDouble() ? '${s.toInt()}x' : '${s}x';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.matrix(
              _filter.matrix ??
                  const [
                    1, 0, 0, 0, 0, //
                    0, 1, 0, 0, 0, //
                    0, 0, 1, 0, 0, //
                    0, 0, 0, 1, 0,
                  ],
            ),
            child: _buildViewport(),
          ),
          if (_grid && _phase == _Phase.idle) const _GridOverlay(),
          if (_countdown != null)
            SafeArea(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    '$_countdown',
                    key: ValueKey(_countdown),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 96,
                      fontWeight: FontWeight.w800,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 12)],
                    ),
                  ),
                ),
              ),
            ),
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
      final preview = _preview;
      if (preview != null && preview.value.isInitialized) {
        return VideoPlayer(preview);
      }
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF2F6B2F), const Color(0xFF8F4E17)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_outline_rounded,
              size: 72,
              color: Colors.white70,
            ),
            const SizedBox(height: 8),
            Text(
              'Vista previa (modo simulado)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ],
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
          if (_phase == _Phase.idle) ...[
            IconButton(
              onPressed: () => setState(() => _grid = !_grid),
              icon: Icon(
                _grid ? Icons.grid_on_rounded : Icons.grid_off_rounded,
                color: Colors.white,
              ),
              tooltip: _grid ? 'Quitar cuadrícula' : 'Cuadrícula de encuadre',
            ),
            if (!_mock) ...[
              IconButton(
                onPressed: _toggleFlash,
                icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
                tooltip: 'Linterna',
              ),
              IconButton(
                onPressed: _flip,
                icon: const Icon(
                  Icons.cameraswitch_rounded,
                  color: Colors.white,
                ),
                tooltip: 'Cambiar cámara',
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildControls() {
    if (_phase == _Phase.done) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Badge(icon: Icons.speed_rounded, text: _speedLabel(_speed)),
                if (_timer > 0) ...[
                  const SizedBox(width: 8),
                  _Badge(
                    icon: Icons.timer_outlined,
                    text: 'Temporizador $_timer s',
                  ),
                ],
                const SizedBox(width: 8),
                _Badge(icon: Icons.auto_awesome_rounded, text: _filter.label),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Volver a grabar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
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
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_mock)
            SizedBox(
              width: 240,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                ),
                child: Slider(
                  value: _zoom.clamp(1.0, _maxZoom),
                  min: 1.0,
                  max: _maxZoom,
                  onChanged: _setZoom,
                ),
              ),
            ),
          const SizedBox(height: 4),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _Filter.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final f = _Filter.values[i];
                return _FilterDot(
                  filter: f,
                  selected: _filter == f,
                  onTap: () => setState(() => _filter = f),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final s in _speeds) ...[
                _PillChip(
                  label: _speedLabel(s),
                  selected: _speed == s,
                  onTap: () => setState(() => _speed = s),
                ),
                const SizedBox(width: 8),
              ],
              const SizedBox(width: 8),
              for (final t in _timers) ...[
                _PillChip(
                  label: t == 0 ? 'Sin' : '${t}s',
                  selected: _timer == t,
                  onTap: () {
                    _cancelCountdown();
                    setState(() => _timer = t);
                    if (t > 0) _startCountdown(t);
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
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
                        color: recording
                            ? const Color(0xFFE5484D)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterDot extends StatelessWidget {
  final _Filter filter;
  final bool selected;
  final VoidCallback onTap;

  const _FilterDot({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (filter) {
      _Filter.none => Colors.white,
      _Filter.vintage => const Color(0xFFB08D57),
      _Filter.mono => const Color(0xFF8A8A8A),
      _Filter.warm => const Color(0xFFE07840),
      _Filter.fresh => const Color(0xFF57B8A0),
    };
    return Tooltip(
      message: filter.label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: selected ? 1 : 0.45),
            border: Border.all(
              color: selected ? Colors.white : Colors.white54,
              width: selected ? 2 : 1,
            ),
          ),
          child: selected
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.black)
              : null,
        ),
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PillChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? Colors.white : Colors.white54),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.foreground : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Badge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _GridPainter(), size: Size.infinite),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var i = 1; i <= 2; i++) {
      final dx = size.width * i / 3;
      final dy = size.height * i / 3;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
