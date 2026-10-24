import 'package:flutter/material.dart';

class DecorCircle extends StatelessWidget {
  const DecorCircle({super.key, required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}