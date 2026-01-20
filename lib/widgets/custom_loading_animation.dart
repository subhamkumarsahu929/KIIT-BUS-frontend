import 'package:flutter/material.dart';

class CustomLoadingAnimation extends StatefulWidget {
  final Color? color;
  final double size;

  const CustomLoadingAnimation({super.key, this.color, this.size = 200.0});

  @override
  State<CustomLoadingAnimation> createState() => _CustomLoadingAnimationState();
}

class _CustomLoadingAnimationState extends State<CustomLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return RepaintBoundary(
      child: CustomPaint(
        size: Size(widget.size, widget.size * 0.6),
        painter: _LoadingPainter(animationValue: _controller, color: color),
      ),
    );
  }
}

class _LoadingPainter extends CustomPainter {
  final Animation<double> animationValue;
  final Color color;

  _LoadingPainter({required this.animationValue, required this.color})
    : super(repaint: animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animationValue.value;
    final w = size.width;
    final h = size.height / 2;
    
    // Background Track (Faint White)
    final Paint trackPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Progress Bar (Flat White)
    final Paint progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Draw Track
    canvas.drawLine(Offset(0, h), Offset(w, h), trackPaint);

    // Draw Filling Progress
    canvas.drawLine(Offset(0, h), Offset(w * progress, h), progressPaint);
  }

  @override
  bool shouldRepaint(covariant _LoadingPainter oldDelegate) => true;
}
