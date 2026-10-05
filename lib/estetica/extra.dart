class CuteNet extends PositionComponent {
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = CuteTheme.net;
    
    double dashHeight = 12;
    double dashSpace = 10;
    double startY = 0;

    // Dibuja la línea punteada al centro
    while (startY < parent!.size.y) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, startY, 6, dashHeight),
          const Radius.circular(3),
        ),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }
}