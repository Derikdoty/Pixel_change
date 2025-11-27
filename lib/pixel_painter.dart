import 'package:flutter/material.dart';

class PixelPainter extends CustomPainter {
  final List<List<Color>> pixels;
  final int pixelSize;

  PixelPainter(this.pixels, {this.pixelSize = 10});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    for (int y = 0; y < pixels.length; y++) {
      for (int x = 0; x < pixels[y].length; x++) {
        paint.color = pixels[y][x];
        canvas.drawRect(
          Rect.fromLTWH(
            x * pixelSize.toDouble(),
            y * pixelSize.toDouble(),
            pixelSize.toDouble(),
            pixelSize.toDouble(),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(PixelPainter oldDelegate) => false;
}