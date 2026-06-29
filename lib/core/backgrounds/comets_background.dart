import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';


class _Star {
  final double x, y, radius, baseOpacity, twinkleSpeed, twinkleOffset;
  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.baseOpacity,
    required this.twinkleSpeed,
    required this.twinkleOffset,
  });
}

class _Comet {
  double x, y, vx, vy, length, opacity;
  int life, maxLife;
  _Comet({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.length,
    required this.opacity,
    required this.life,
    required this.maxLife,
  });
}

// ─── Animation controller ───────────────────────────────────────────────────

class _NightSkyController extends ChangeNotifier {
  final TickerProvider vsync;
  late final Ticker _ticker;

  final _rng = Random();
  final List<_Star> _stars = [];
  final List<_Comet> _comets = [];

  double _time = 0;
  int _cometTimer = 0;
  bool _initialized = false;
  Size _size = Size.zero;

  static const _cometBaseInterval = 180; // ~3 s at 60 fps

  List<_Star> get stars => _stars;
  List<_Comet> get comets => _comets;
  double get time => _time;

  _NightSkyController({required this.vsync}) {
    _ticker = vsync.createTicker(_onTick)..start();
  }

  /// Call this once the layout size is known.
  void initIfNeeded(Size size) {
    if (_initialized && _size == size) return;
    _initialized = true;
    _size = size;

    _stars.clear();
    final count = (size.width * size.height / 2800).floor().clamp(60, 350);
    for (var i = 0; i < count; i++) {
      _stars.add(_Star(
        x: _rng.nextDouble() * size.width,
        y: _rng.nextDouble() * size.height,
        radius: _rng.nextDouble() * 1.4 + 0.2,
        baseOpacity: _rng.nextDouble() * 0.6 + 0.3,
        twinkleSpeed: _rng.nextDouble() * 0.02 + 0.005,
        twinkleOffset: _rng.nextDouble() * pi * 2,
      ));
    }
  }

  void _onTick(Duration elapsed) {
    _time = elapsed.inMilliseconds / 1000.0;
    _cometTimer++;

    if (_initialized &&
        _cometTimer >= _cometBaseInterval + _rng.nextInt(60)) {
      _spawnComet();
      _cometTimer = 0;
    }

    _updateComets();
    notifyListeners();
  }

  void _spawnComet() {
    final fromLeft = _rng.nextBool();
    final startX = fromLeft ? -20.0 : _size.width + 20;
    final startY = _rng.nextDouble() * _size.height * 0.6;

    // Diagonal angle so comets arc downward across the screen
    final angle = fromLeft
        ? (pi / 6) + _rng.nextDouble() * (pi / 8)   // ~30–52° right-down
        : pi - (pi / 6) - _rng.nextDouble() * (pi / 8); // ~128–150° left-down

    final speed = 4.0 + _rng.nextDouble() * 3;

    _comets.add(_Comet(
      x: startX,
      y: startY,
      vx: cos(angle) * speed,
      vy: sin(angle) * speed,
      length: 80 + _rng.nextDouble() * 80,
      opacity: 0,
      life: 0,
      maxLife: 80 + _rng.nextInt(40),
    ));
  }

  void _updateComets() {
    for (var i = _comets.length - 1; i >= 0; i--) {
      final c = _comets[i];
      c.x += c.vx;
      c.y += c.vy;
      c.life++;

      // Fade in → full → fade out
      final p = c.life / c.maxLife;
      if (p < 0.15) {
        c.opacity = p / 0.15;
      } else if (p > 0.7) {
        c.opacity = 1.0 - (p - 0.7) / 0.3;
      } else {
        c.opacity = 1.0;
      }

      if (c.life > c.maxLife) _comets.removeAt(i);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

// ─── Painter ────────────────────────────────────────────────────────────────

class _NightSkyPainter extends CustomPainter {
  final _NightSkyController controller;

  _NightSkyPainter({required this.controller})
      : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawStars(canvas, size);
    _drawComets(canvas);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Deep night sky gradient
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF02010A),
            Color(0xFF050215),
            Color(0xFF080520),
            Color(0xFF060315),
          ],
          stops: [0.0, 0.4, 0.7, 1.0],
        ).createShader(rect),
    );

    // Nebula glow — left/upper
    _drawNebula(
      canvas,
      size,
      center: Offset(size.width * 0.3, size.height * 0.25),
      radius: size.width * 0.45,
      color: const Color(0xFF501EA0),
      opacity: 0.12,
    );

    // Nebula glow — right/lower
    _drawNebula(
      canvas,
      size,
      center: Offset(size.width * 0.75, size.height * 0.6),
      radius: size.width * 0.35,
      color: const Color(0xFF143C82),
      opacity: 0.10,
    );
  }

  void _drawNebula(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
    required double opacity,
  }) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha:opacity), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _drawStars(Canvas canvas, Size size) {
    final t = controller.time;

    for (final star in controller.stars) {
      final twinkle = sin(t * star.twinkleSpeed * 60 + star.twinkleOffset);
      final opacity = (star.baseOpacity + twinkle * 0.3).clamp(0.05, 1.0);
      final r = star.radius + (twinkle > 0.7 ? twinkle * 0.5 : 0.0);
      final center = Offset(star.x, star.y);

      // Solid core
      canvas.drawCircle(
        center,
        r,
        Paint()..color = Colors.white.withValues(alpha:opacity),
      );

      // Soft glow on bright twinkle
      if (twinkle > 0.5) {
        canvas.drawCircle(
          center,
          r * 4,
          Paint()
            ..shader = RadialGradient(
              colors: [
                const Color(0xFFC8D2FF).withValues(alpha:opacity * 0.4),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(center: center, radius: r * 4),
            ),
        );
      }
    }
  }

  void _drawComets(Canvas canvas) {
    for (final c in controller.comets) {
      final angle = atan2(c.vy, c.vx);
      final head = Offset(c.x, c.y);
      final tail = Offset(
        c.x - cos(angle) * c.length,
        c.y - sin(angle) * c.length,
      );

      // Glowing tail
      canvas.drawLine(
        tail,
        head,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFFB4C8FF).withValues(alpha:c.opacity * 0.35),
              Colors.white.withValues(alpha:c.opacity),
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(Rect.fromPoints(tail, head))
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );

      // Head halo
      canvas.drawCircle(
        head,
        8,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFDCE6FF).withValues(alpha:c.opacity * 0.9),
              const Color(0xFFB4C8FF).withValues(alpha:c.opacity * 0.4),
              Colors.transparent,
            ],
            stops: const [0.0, 0.4, 1.0],
          ).createShader(Rect.fromCircle(center: head, radius: 8)),
      );

      // Bright core dot
      canvas.drawCircle(
        head,
        1.5,
        Paint()..color = Colors.white.withValues(alpha:c.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_NightSkyPainter old) => true;
}

// ─── Public wrapper widget ───────────────────────────────────────────────────

/// Animated night-sky background wrapper.
///
/// Place any widget as [child] — set [child]'s scaffold/container background
/// to [Colors.transparent] so the sky shows through.
///
/// ```dart
/// NightSkyBackground(
///   child: Scaffold(
///     backgroundColor: Colors.transparent,
///     appBar: AppBar(
///       title: const Text('My Friends'),
///       backgroundColor: Colors.transparent,
///     ),
///     body: YourBody(),
///   ),
/// )
/// ```
class NightSkyBackground extends StatefulWidget {
  final Widget child;

  const NightSkyBackground({super.key, required this.child});

  @override
  State<NightSkyBackground> createState() => _NightSkyBackgroundState();
}

class _NightSkyBackgroundState extends State<NightSkyBackground>
    with SingleTickerProviderStateMixin {
  late final _NightSkyController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _NightSkyController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _controller.initIfNeeded(size);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Sky layer — repaints via ChangeNotifier, child never rebuilds
            AnimatedBuilder(
              animation: _controller,
              builder: (_, _) => CustomPaint(
                painter: _NightSkyPainter(controller: _controller),
                size: size,
              ),
            ),
            // Your content sits above the canvas
            widget.child,
          ],
        );
      },
    );
  }
}