import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/category_skin_theme.dart';

/// HEX 컬러 문자열 변환 도우미
Color _hexToColor(String hex, {Color fallback = const Color(0xFFFFF0F5)}) {
  try {
    var clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      clean = 'FF$clean';
    }
    return Color(int.parse('0x$clean'));
  } catch (_) {
    return fallback;
  }
}

/// Y2K 스킨 테마 패턴 페인터 (가독성을 위한 안전 마진 투명도 적용)
class SkinThemeBackgroundPainter extends CustomPainter {
  const SkinThemeBackgroundPainter({
    required this.patternType,
    required this.patternColor,
    required this.opacity,
  });

  final SkinPatternType patternType;
  final Color patternColor;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (patternType == SkinPatternType.none) return;

    final paintColor = patternColor.withValues(alpha: opacity.clamp(0.05, 0.65));

    switch (patternType) {
      case SkinPatternType.dot:
        _drawDotPattern(canvas, size, paintColor);
        break;
      case SkinPatternType.grid:
        _drawGridPattern(canvas, size, paintColor);
        break;
      case SkinPatternType.pixelHeart:
        _drawPixelHeartPattern(canvas, size, paintColor);
        break;
      case SkinPatternType.diagonalStripes:
        _drawDiagonalStripes(canvas, size, paintColor);
        break;
      case SkinPatternType.none:
        break;
    }
  }

  void _drawDotPattern(Canvas canvas, Size size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const spacing = 16.0;
    const dotRadius = 1.8;

    for (double y = 8.0; y < size.height; y += spacing) {
      for (double x = 8.0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  void _drawGridPattern(Canvas canvas, Size size, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 18.0;

    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawPixelHeartPattern(Canvas canvas, Size size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const spacingX = 40.0;
    const spacingY = 36.0;
    const pixel = 2.0;

    // 8-bit Pixel Heart (7x6 matrix)
    const heartRows = [
      ' 11 11 ',
      '1111111',
      '1111111',
      ' 11111 ',
      '  111  ',
      '   1   ',
    ];

    for (double startY = 14.0; startY < size.height; startY += spacingY) {
      final offsetX = ((startY / spacingY).floor() % 2 == 1) ? spacingX / 2 : 0.0;
      for (double startX = 14.0 + offsetX; startX < size.width; startX += spacingX) {
        for (int r = 0; r < heartRows.length; r++) {
          final row = heartRows[r];
          for (int c = 0; c < row.length; c++) {
            if (row[c] == '1') {
              final rect = Rect.fromLTWH(
                startX + (c * pixel),
                startY + (r * pixel),
                pixel,
                pixel,
              );
              canvas.drawRect(rect, paint);
            }
          }
        }
      }
    }
  }

  void _drawDiagonalStripes(Canvas canvas, Size size, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const step = 20.0;
    final total = size.width + size.height;

    for (double offset = -size.height; offset < total; offset += step) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SkinThemeBackgroundPainter oldDelegate) {
    return oldDelegate.patternType != patternType ||
        oldDelegate.patternColor != patternColor ||
        oldDelegate.opacity != opacity;
  }
}

/// Y2K 테두리 페인터 (도트, 대시 점선, 레트로 이중선, 윈도우98 베벨 음영 완벽 지원)
class SkinThemeBorderPainter extends CustomPainter {
  const SkinThemeBorderPainter({
    required this.borderStyle,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
  });

  final SkinBorderStyle borderStyle;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (borderStyle == SkinBorderStyle.none || borderWidth <= 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    switch (borderStyle) {
      case SkinBorderStyle.window98Bevel:
        _drawWindow98Bevel(canvas, size, borderWidth);
        break;
      case SkinBorderStyle.retroDouble:
        _drawRetroDouble(canvas, rect, borderWidth, borderRadius, borderColor);
        break;
      case SkinBorderStyle.dotted:
        _drawDottedOrDashed(canvas, rect, borderWidth, borderRadius, borderColor, isDotted: true);
        break;
      case SkinBorderStyle.dashed:
        _drawDottedOrDashed(canvas, rect, borderWidth, borderRadius, borderColor, isDotted: false);
        break;
      case SkinBorderStyle.solid:
        _drawSolid(canvas, rect, borderWidth, borderRadius, borderColor);
        break;
      case SkinBorderStyle.none:
        break;
    }
  }

  void _drawSolid(Canvas canvas, Rect rect, double width, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    final inset = width / 2;
    final innerRect = rect.deflate(inset);

    if (radius <= 0) {
      canvas.drawRect(innerRect, paint);
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(innerRect, Radius.circular(math.max(0, radius - inset))), paint);
    }
  }

  void _drawRetroDouble(Canvas canvas, Rect rect, double width, double radius, Color color) {
    final outerPaint = Paint()
      ..color = color
      ..strokeWidth = math.max(1.0, width * 0.45)
      ..style = PaintingStyle.stroke;

    final innerPaint = Paint()
      ..color = color
      ..strokeWidth = math.max(1.0, width * 0.45)
      ..style = PaintingStyle.stroke;

    // Outer line
    final outerInset = outerPaint.strokeWidth / 2;
    final outerRRect = RRect.fromRectAndRadius(
      rect.deflate(outerInset),
      Radius.circular(math.max(0, radius - outerInset)),
    );
    canvas.drawRRect(outerRRect, outerPaint);

    // Inner line with 3px gap
    final innerInset = outerInset + 3.0 + (innerPaint.strokeWidth / 2);
    if (rect.width > innerInset * 2 && rect.height > innerInset * 2) {
      final innerRRect = RRect.fromRectAndRadius(
        rect.deflate(innerInset),
        Radius.circular(math.max(0, radius - innerInset)),
      );
      canvas.drawRRect(innerRRect, innerPaint);
    }
  }

  void _drawWindow98Bevel(Canvas canvas, Size size, double thickness) {
    final t = math.max(2.0, thickness);

    // Classic Windows 95/98 3D Bevel effect:
    // Top & Left: #FFFFFF (bright light), Inner Top & Left: #DFDFDF
    // Bottom & Right: #404040 (dark shadow), Inner Bottom & Right: #808080 (medium shadow)
    final highlightOuter = Paint()..color = const Color(0xFFFFFFFF);
    final highlightInner = Paint()..color = const Color(0xFFDFDFDF);
    final shadowOuter = Paint()..color = const Color(0xFF333333);
    final shadowInner = Paint()..color = const Color(0xFF808080);

    final halfT = t / 2;

    // Outer Top
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, halfT), highlightOuter);
    // Outer Left
    canvas.drawRect(Rect.fromLTWH(0, 0, halfT, size.height), highlightOuter);

    // Inner Top
    canvas.drawRect(Rect.fromLTWH(halfT, halfT, size.width - (t * 2), halfT), highlightInner);
    // Inner Left
    canvas.drawRect(Rect.fromLTWH(halfT, halfT, halfT, size.height - (t * 2)), highlightInner);

    // Outer Bottom
    canvas.drawRect(Rect.fromLTWH(0, size.height - halfT, size.width, halfT), shadowOuter);
    // Outer Right
    canvas.drawRect(Rect.fromLTWH(size.width - halfT, 0, halfT, size.height), shadowOuter);

    // Inner Bottom
    canvas.drawRect(Rect.fromLTWH(halfT, size.height - t, size.width - t, halfT), shadowInner);
    // Inner Right
    canvas.drawRect(Rect.fromLTWH(size.width - t, halfT, halfT, size.height - t), shadowInner);
  }

  void _drawDottedOrDashed(
    Canvas canvas,
    Rect rect,
    double width,
    double radius,
    Color color, {
    required bool isDotted,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    final inset = width / 2;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(inset),
      Radius.circular(math.max(0, radius - inset)),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    final dashLength = isDotted ? width : 6.0;
    final spaceLength = isDotted ? width * 1.6 : 4.0;

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = math.min(dashLength, metric.length - distance);
        final extractPath = metric.extractPath(distance, distance + length);
        canvas.drawPath(extractPath, paint);
        distance += length + spaceLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant SkinThemeBorderPainter oldDelegate) {
    return oldDelegate.borderStyle != borderStyle ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}

/// Y2K 스킨 테마가 적용된 통합 카드 컨테이너 위젯
class SkinThemeCardContainer extends StatelessWidget {
  const SkinThemeCardContainer({
    super.key,
    required this.theme,
    required this.child,
    this.width,
    this.height,
    this.padding = EdgeInsets.zero,
    this.margin,
    this.onTap,
    this.showShadow = true,
  });

  final CategorySkinTheme theme;
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final bgColor = _hexToColor(theme.backgroundColor);
    final patternColor = _hexToColor(theme.patternColor, fallback: Colors.white);
    final borderColor = _hexToColor(theme.borderColor);
    final radius = Radius.circular(theme.borderRadius);

    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.all(radius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: theme.borderStyleEnum == SkinBorderStyle.window98Bevel ? 0.08 : 0.04),
                  blurRadius: theme.borderStyleEnum == SkinBorderStyle.window98Bevel ? 6 : 10,
                  offset: theme.borderStyleEnum == SkinBorderStyle.window98Bevel ? const Offset(2, 2) : const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.all(radius),
        child: Stack(
          children: [
            // Background Pattern
            if (theme.patternTypeEnum != SkinPatternType.none)
              Positioned.fill(
                child: CustomPaint(
                  painter: SkinThemeBackgroundPainter(
                    patternType: theme.patternTypeEnum,
                    patternColor: patternColor,
                    opacity: theme.patternOpacity,
                  ),
                ),
              ),

            // Foreground Content
            Padding(
              padding: padding,
              child: child,
            ),

            // Top Border Layer
            if (theme.borderStyleEnum != SkinBorderStyle.none && theme.borderWidth > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: SkinThemeBorderPainter(
                      borderStyle: theme.borderStyleEnum,
                      borderColor: borderColor,
                      borderWidth: theme.borderWidth,
                      borderRadius: theme.borderRadius,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }

    return container;
  }
}
