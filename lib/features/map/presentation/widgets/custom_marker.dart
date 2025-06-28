import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomMarker {
  /// Create a custom marker with user avatar
  static Future<BitmapDescriptor> createCustomMarkerFromAsset(
    String assetPath, {
    double size = 120,
    Color borderColor = Colors.white,
    double borderWidth = 8,
  }) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: size.toInt(),
      targetHeight: size.toInt(),
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Draw circle border
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    
    final circleRadius = size / 2;
    canvas.drawCircle(
      Offset(circleRadius, circleRadius),
      circleRadius - (borderWidth / 2),
      paint,
    );
    
    // Draw circle background
    final bgPaint = Paint()
      ..color = borderColor.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(circleRadius, circleRadius),
      circleRadius - borderWidth,
      bgPaint,
    );
    
    // Draw the image
    canvas.drawImage(fi.image, Offset(borderWidth, borderWidth), Paint());
    
    // Convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }
  
  /// Create a custom marker with user initials
  static Future<BitmapDescriptor> createCustomMarkerWithInitials(
    String initials, {
    double size = 120,
    Color backgroundColor = Colors.blue,
    Color textColor = Colors.white,
    double fontSize = 40,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Draw circle background
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    
    final circleRadius = size / 2;
    canvas.drawCircle(
      Offset(circleRadius, circleRadius),
      circleRadius,
      bgPaint,
    );
    
    // Draw text
    final textPainter = TextPainter(
      text: TextSpan(
        text: initials.length > 2 ? initials.substring(0, 2).toUpperCase() : initials.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );
    
    // Convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }
  
  /// Create a custom marker with heart shape for relationship
  static Future<BitmapDescriptor> createHeartMarker({
    double size = 120,
    Color color = Colors.red,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Add a white background circle for better visibility
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final center = Offset(size / 2, size / 2);
    canvas.drawCircle(center, size / 2, bgPaint);
    
    // Draw heart shape
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeWidth = 4.0;
    
    final heartSize = size * 0.7;
    
    // Create a more defined heart shape
    final path = Path();
    
    // Start at bottom point of the heart
    path.moveTo(center.dx, center.dy + heartSize * 0.3);
    
    // Left curve - first create the left bump of the heart
    path.cubicTo(
      center.dx - heartSize * 0.5, center.dy, // control point 1
      center.dx - heartSize * 0.5, center.dy - heartSize * 0.5, // control point 2
      center.dx, center.dy - heartSize * 0.3, // end point
    );
    
    // Right curve - create the right bump of the heart
    path.cubicTo(
      center.dx + heartSize * 0.5, center.dy - heartSize * 0.5, // control point 1
      center.dx + heartSize * 0.5, center.dy, // control point 2
      center.dx, center.dy + heartSize * 0.3, // end point (back to start)
    );
    
    // Fill the heart
    canvas.drawPath(path, paint);
    
    // Add a border for better definition
    final borderPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    
    canvas.drawPath(path, borderPaint);
    
    // Convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) {
      print('Error: Failed to generate heart marker image');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
    }
    
    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }
}
