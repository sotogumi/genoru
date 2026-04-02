import 'dart:math';
import 'package:flutter/material.dart';
import 'package:genoru/app/theme/app_theme.dart';

/// DNA螺旋をモチーフにしたアニメーション背景
class DnaBackground extends StatefulWidget {
  const DnaBackground({super.key});

  @override
  State<DnaBackground> createState() => _DnaBackgroundState();
}

class _DnaBackgroundState extends State<DnaBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
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
          painter: _DnaBackgroundPainter(animationValue: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _DnaBackgroundPainter extends CustomPainter {
  final double animationValue;

  _DnaBackgroundPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // 背景グラデーション
    final bgPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundDark,
              const Color(0xFF0D1333),
              AppTheme.backgroundDark,
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // DNA螺旋を描画
    _drawDnaHelix(canvas, size, size.width * 0.15, 0.6);
    _drawDnaHelix(canvas, size, size.width * 0.85, 0.4);

    // 浮遊する塩基文字
    _drawFloatingBases(canvas, size);
  }

  void _drawDnaHelix(Canvas canvas, Size size, double xCenter, double opacity) {
    final strandPaint1 =
        Paint()
          ..color = AppTheme.primaryGreen.withValues(alpha: opacity * 0.15)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final strandPaint2 =
        Paint()
          ..color = AppTheme.accentCyan.withValues(alpha: opacity * 0.15)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final path1 = Path();
    final path2 = Path();
    final amplitude = 30.0;
    final offset = animationValue * 2 * pi;

    for (double y = -20; y < size.height + 20; y += 1) {
      final x1 = xCenter + amplitude * sin((y / 60) + offset);
      final x2 = xCenter + amplitude * sin((y / 60) + offset + pi);

      if (y == -20) {
        path1.moveTo(x1, y);
        path2.moveTo(x2, y);
      } else {
        path1.lineTo(x1, y);
        path2.lineTo(x2, y);
      }

      // 塩基対の横線を一定間隔で描画
      if (y.toInt() % 40 == 0) {
        final bridgePaint =
            Paint()
              ..color = AppTheme.primaryGreen.withValues(alpha: opacity * 0.08)
              ..strokeWidth = 1;
        canvas.drawLine(Offset(x1, y), Offset(x2, y), bridgePaint);
      }
    }

    canvas.drawPath(path1, strandPaint1);
    canvas.drawPath(path2, strandPaint2);
  }

  void _drawFloatingBases(Canvas canvas, Size size) {
    final bases = ['A', 'T', 'G', 'C'];
    final random = Random(42); // 固定シードで安定した位置

    for (int i = 0; i < 12; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.3 + random.nextDouble() * 0.7;
      final y = (baseY + animationValue * size.height * speed) % size.height;
      final alpha = 0.05 + random.nextDouble() * 0.08;

      final textPainter = TextPainter(
        text: TextSpan(
          text: bases[i % 4],
          style: TextStyle(
            color: (i % 2 == 0 ? AppTheme.primaryGreen : AppTheme.accentCyan)
                .withValues(alpha: alpha),
            fontSize: 14 + random.nextDouble() * 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _DnaBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
