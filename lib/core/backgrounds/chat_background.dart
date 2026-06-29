import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ─── Tile model ─────────────────────────────────────────────────────────────

enum _TileType { bubbleRight, bubbleLeft, heart, send }

class _Tile {
  final double x, y, size, opacity, pulseOffset, pulseSpeed, rotation;
  final _TileType type;
  const _Tile({
    required this.x, required this.y,
    required this.size, required this.opacity,
    required this.pulseOffset, required this.pulseSpeed,
    required this.rotation, required this.type,
  });
}

// ─── Controller ─────────────────────────────────────────────────────────────

class _ChatBgController extends ChangeNotifier {
  final TickerProvider vsync;
  late final Ticker _ticker;
  final _rng = Random();

  final List<_Tile> _tiles = [];
  double _time = 0;
  bool _initialized = false;
  Size _size = Size.zero;

  List<_Tile> get tiles => _tiles;
  double get time => _time;

  _ChatBgController({required this.vsync}) {
    _ticker = vsync.createTicker((elapsed) {
      _time = elapsed.inMilliseconds / 1000.0;
      notifyListeners();
    })..start();
  }

  void initIfNeeded(Size size) {
    if (_initialized && _size == size) return;
    _initialized = true;
    _size = size;
    _tiles.clear();

    const spacing = 62.0;
    const types = _TileType.values;
    final cols = (size.width / spacing).ceil() + 2;
    final rows = (size.height / spacing).ceil() + 2;
    var idx = 0;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final xOff = r % 2 == 0 ? 0.0 : spacing * 0.5;
        _tiles.add(_Tile(
          x: c * spacing + xOff - spacing,
          y: r * spacing - spacing,
          type: types[idx % types.length],
          size: 14 + _rng.nextDouble() * 8,
          opacity: 0.06 + _rng.nextDouble() * 0.06,
          pulseOffset: _rng.nextDouble() * pi * 2,
          pulseSpeed: 0.4 + _rng.nextDouble() * 0.4,
          rotation: (_rng.nextDouble() - 0.5) * 0.25,
        ));
        idx++;
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

// ─── Painter ────────────────────────────────────────────────────────────────

class _ChatBgPainter extends CustomPainter {
  final _ChatBgController controller;

  _ChatBgPainter({required this.controller})
      : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    for (final t in controller.tiles) {
      _drawTile(canvas, t);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D0B18), Color(0xFF0A0F1E)],
        ).createShader(rect),
    );
  }

  void _drawTile(Canvas canvas, _Tile t) {
    final pulse = sin(controller.time * t.pulseSpeed + t.pulseOffset) * 0.5 + 0.5;
    final alpha = t.opacity * (0.75 + pulse * 0.25);

    canvas.save();
    canvas.translate(t.x, t.y);
    canvas.rotate(t.rotation);

    switch (t.type) {
      case _TileType.bubbleRight:
        _drawSpeechBubble(canvas, t.size, true, alpha);
      case _TileType.bubbleLeft:
        _drawSpeechBubble(canvas, t.size, false, alpha);
      case _TileType.heart:
        _drawHeart(canvas, t.size, alpha);
      case _TileType.send:
        _drawSend(canvas, t.size, alpha);
    }

    canvas.restore();
  }

  void _drawSpeechBubble(Canvas canvas, double size, bool right, double alpha) {
    final bw = size * 2;
    final bh = size * 1.3;
    final r = bh * 0.35;
    final tailW = bh * 0.22;
    final tailH = bh * 0.28;
    final x = -bw / 2;
    final y = -bh / 2;

    final path = Path();
    path.moveTo(x + r, y);
    path.lineTo(x + bw - r, y);
    path.arcToPoint(Offset(x + bw, y + r), radius: Radius.circular(r));
    path.lineTo(x + bw, y + bh - r);
    path.arcToPoint(Offset(x + bw - r, y + bh), radius: Radius.circular(r));

    if (right) {
      final tx = x + bw - r * 0.4;
      path.lineTo(tx + tailW, y + bh);
      path.quadraticBezierTo(
        tx + tailW * 0.2, y + bh + tailH,
        tx - tailW * 0.6, y + bh,
      );
    }

    path.lineTo(x + r, y + bh);
    path.arcToPoint(Offset(x, y + bh - r), radius: Radius.circular(r));

    if (!right) {
      final ty = y + bh - r * 0.4;
      path.lineTo(x, ty);
      path.quadraticBezierTo(
        x - tailH, ty + tailW * 0.2,
        x, ty - tailW * 0.8,
      );
    }

    path.lineTo(x, y + r);
    path.arcToPoint(Offset(x + r, y), radius: Radius.circular(r));
    path.close();

    final color = right
        ? HSLColor.fromAHSL(1, 260, 0.5, 0.7).toColor()
        : HSLColor.fromAHSL(1, 180, 0.45, 0.65).toColor();

    canvas.drawPath(path, Paint()..color = color.withValues(alpha:alpha * 0.18));
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha:alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeJoin = StrokeJoin.round,
    );

    // Text lines inside
    final lineColor = color.withValues(alpha:alpha * 0.7);
    final linePaint = Paint()..color = lineColor;
    for (var i = 0; i < 2; i++) {
      final lw = i == 0 ? bw * 0.45 : bw * 0.3;
      final lx = -lw / 2;
      final ly = -bh * 0.15 + i * bh * 0.25;
      canvas.drawRRect(
        RRect.fromLTRBR(lx, ly, lx + lw, ly + 1.8, const Radius.circular(1)),
        linePaint,
      );
    }
  }

  void _drawHeart(Canvas canvas, double size, double alpha) {
    final s = size * 0.9;
    final path = Path();
    path.moveTo(0, s * 0.3);
    path.cubicTo(-s*0.0, -s*0.1, -s*0.6, -s*0.5, -s*0.5, -s*0.1);
    path.cubicTo(-s*0.5, -s*0.55, -s*0.1, -s*0.7, 0, -s*0.3);
    path.cubicTo(s*0.1, -s*0.7, s*0.5, -s*0.55, s*0.5, -s*0.1);
    path.cubicTo(s*0.6, -s*0.5, 0, -s*0.1, 0, s*0.3);
    path.close();

    const color = Color(0xFFF082A0);
    canvas.drawPath(path, Paint()..color = color.withValues(alpha:alpha * 0.2));
    canvas.drawPath(path,
        Paint()
          ..color = color.withValues(alpha:alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
  }

  void _drawSend(Canvas canvas, double size, double alpha) {
    final s = size;
    final path = Path();
    path.moveTo(-s * 0.7, -s * 0.55);
    path.lineTo(s * 0.8, 0);
    path.lineTo(-s * 0.7, s * 0.55);
    path.lineTo(-s * 0.3, 0);
    path.close();

    const color = Color(0xFF82C8F0);
    canvas.drawPath(path, Paint()..color = color.withValues(alpha:alpha * 0.2));
    canvas.drawPath(path,
        Paint()
          ..color = color.withValues(alpha:alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_ChatBgPainter old) => true;
}

// ─── Public widget ───────────────────────────────────────────────────────────

/// Chat-themed animated background.
/// Make your [Scaffold] / content background [Colors.transparent].
///
/// ```dart
/// ChatBackground(
///   child: Scaffold(
///     backgroundColor: Colors.transparent,
///     body: YourPage(),
///   ),
/// )
/// ```
class ChatBackground extends StatefulWidget {
  final Widget child;
  const ChatBackground({super.key, required this.child});

  @override
  State<ChatBackground> createState() => _ChatBackgroundState();
}

class _ChatBackgroundState extends State<ChatBackground>
    with SingleTickerProviderStateMixin {
  late final _ChatBgController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _ChatBgController(vsync: this);
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
            AnimatedBuilder(
              animation: _controller,
              builder: (_, _) => CustomPaint(
                painter: _ChatBgPainter(controller: _controller),
                size: size,
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}