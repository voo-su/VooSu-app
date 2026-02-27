import 'dart:math' as math;

import 'package:flutter/material.dart';

class TypingDotsIndicator extends StatefulWidget {
  final Color color;
  final double dotSize;
  final double spacing;

  const TypingDotsIndicator({
    super.key,
    required this.color,
    this.dotSize = 4,
    this.spacing = 4,
  });

  @override
  State<TypingDotsIndicator> createState() => _TypingDotsIndicatorState();
}

class _TypingDotsIndicatorState extends State<TypingDotsIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = (i * 0.25) % 1.0;
            final t = (_controller.value + phase) % 1.0;
            final offset = math.sin(t * math.pi) * 5;
            return Transform.translate(
              offset: Offset(0, -offset),
              child: Container(
                width: widget.dotSize,
                height: widget.dotSize,
                margin: EdgeInsets.only(
                  left: i == 0 ? 0 : widget.spacing / 2,
                  right: i == 2 ? 0 : widget.spacing / 2,
                ),
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
