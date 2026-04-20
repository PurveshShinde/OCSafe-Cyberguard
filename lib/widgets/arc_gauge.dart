import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';

class ArcGauge extends StatelessWidget {
  final double score;
  const ArcGauge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final valueColor = score >= 80 ? AppColors.success : (score >= 50 ? AppColors.warning : AppColors.error);
    
    return SizedBox(
      width: 300,
      height: 250,
      child: CustomPaint(
        painter: ArcPainter(score: score, color: valueColor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              '${score.toInt()}%',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: valueColor),
            ),
            const SizedBox(height: 4),
            const Text(
              'Security Score',
              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class ArcPainter extends CustomPainter {
  final double score;
  final Color color;
  ArcPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 20); 
    final radius = size.width / 2 - 20;

    final tickPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final double startAngle = math.pi * 0.8;
    final double sweepAngle = math.pi * 1.4;

    const int tickCount = 40;
    for (int i = 0; i <= tickCount; i++) {
        final angle = startAngle + (i / tickCount) * sweepAngle;
        final isMajor = i % 10 == 0;
        final innerRadius = isMajor ? radius - 15 : radius - 5;
        final x1 = center.dx + innerRadius * math.cos(angle);
        final y1 = center.dy + innerRadius * math.sin(angle);
        final x2 = center.dx + radius * math.cos(angle);
        final y2 = center.dy + radius * math.sin(angle);
        
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);

        if (isMajor) {
          int value = (i / tickCount * 100).toInt();
          // Draw text for 10, 30, 50, 70, 80 etc if we want, but omitting helps minimalism
          // We will draw it for 10, 20, 30, 50, 70, 80, 100 as per screenshot approx.
          if (value > 0) {
            final textPainter = TextPainter(
              text: TextSpan(text: '$value', style: const TextStyle(color: Colors.grey, fontSize: 10)),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();
            final textOuter = radius + 15;
            final textCenter = Offset(
              center.dx + textOuter * math.cos(angle) - textPainter.width/2,
              center.dy + textOuter * math.sin(angle) - textPainter.height/2,
            );
            textPainter.paint(canvas, textCenter);
          }
        }
    }

    final bgArcPaint = Paint()
      ..color = const Color(0xFFF1F5F9) // Very light slate
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius - 30);
    canvas.drawArc(rect, startAngle, sweepAngle, false, bgArcPaint);

    final fgArcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
      
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawArc(rect, startAngle, sweepAngle * (score / 100), false, shadowPaint);
    canvas.drawArc(rect, startAngle, sweepAngle * (score / 100), false, fgArcPaint);
    
    final knobAngle = startAngle + sweepAngle * (score / 100);
    final knobCenter = Offset(
      center.dx + (radius - 30) * math.cos(knobAngle),
      center.dy + (radius - 30) * math.sin(knobAngle),
    );
    
    // Outer white glow/border 
    canvas.drawCircle(knobCenter, 12, Paint()..color = Colors.white.withValues(alpha: 0.5));
    canvas.drawCircle(knobCenter, 10, Paint()..color = Colors.white);
    canvas.drawCircle(knobCenter, 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
