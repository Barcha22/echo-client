import 'dart:math';
import 'package:flutter/material.dart';

class BlueParticlesBackground extends StatefulWidget {
  final Widget child;
  const BlueParticlesBackground({super.key, required this.child});

  @override
  State<BlueParticlesBackground> createState() =>
      _BlueParticlesBackgroundState();
}

class _BlueParticlesBackgroundState extends State<BlueParticlesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final int particleCount = 60;
  late List<_Particle> particles;
  late Size _screenSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    particles = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
    if (particles.isEmpty) {
      final rnd = Random();
      for (int i = 0; i < particleCount; i++) {
        // Randomize initial position and movement
        final angle = rnd.nextDouble() * 2 * pi;
        final speed = 0.1 + rnd.nextDouble() * 0.5;
        final orbit =
            (_screenSize.width * 0.3) +
            rnd.nextDouble() * (_screenSize.width * 0.8);
        final centerX = _screenSize.width * (0.2 + rnd.nextDouble() * 0.6);
        final centerY = _screenSize.height * (0.2 + rnd.nextDouble() * 0.6);
        final direction = rnd.nextBool() ? 1.0 : -1.0;
        particles.add(
          _Particle(
            initialAngle: angle,
            speed: speed * direction,
            orbit: orbit,
            center: Offset(centerX, centerY),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlesPainter(
            particles: particles,
            time: _controller.value,
            screenSize: _screenSize,
          ),
          child: Stack(fit: StackFit.expand, children: [widget.child]),
        );
      },
    );
  }
}

class _Particle {
  final double initialAngle;
  final double speed;
  final double orbit;
  final Offset center;
  _Particle({
    required this.initialAngle,
    required this.speed,
    required this.orbit,
    required this.center,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;
  final Size screenSize;
  _ParticlesPainter({
    required this.particles,
    required this.time,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw black background first
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black,
    );

    final List<Offset> points = [];
    final Paint glowPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32);
    final Paint stickPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.35)
      ..strokeWidth = 2.5;
    final Paint ballPaint = Paint()
      ..color = Colors.blueAccent
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Draw particles
    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];
      final angle = p.initialAngle + time * 2 * pi * p.speed;
      final x = p.center.dx + cos(angle) * p.orbit;
      final y = p.center.dy + sin(angle) * p.orbit;
      final pos = Offset(x, y);
      points.add(pos);

      // Glow
      canvas.drawCircle(pos, 22, glowPaint);
      // Ball
      canvas.drawCircle(pos, 10, ballPaint);
    }

    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        final dist = (points[i] - points[j]).distance;
        if (dist < 120) {
          final opacity = (1 - dist / 120) * 0.7;
          stickPaint.color = Colors.blueAccent.withValues(alpha: opacity);
          canvas.drawLine(points[i], points[j], stickPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}
