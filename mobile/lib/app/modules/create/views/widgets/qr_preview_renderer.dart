import 'dart:math' as math;

import 'package:custom_qr_generator/custom_qr_generator.dart';
import 'package:flutter/material.dart';
import 'package:zxing_lib/qrcode.dart';

import '../../../../../core/logic/generator_logic.dart';
import '../../../../../core/models/app_models.dart';

class QrPreviewWidget extends StatefulWidget {
  const QrPreviewWidget({
    super.key,
    required this.payload,
    required this.qrStyleId,
    required this.cornerStyleId,
    required this.qrErrorLevel,
    required this.theme,
  });

  final String payload;
  final String qrStyleId;
  final String cornerStyleId;
  final String qrErrorLevel;
  final ThemeSpec theme;

  @override
  State<QrPreviewWidget> createState() => _QrPreviewWidgetState();
}

class _QrPreviewWidgetState extends State<QrPreviewWidget> {
  late ByteMatrix _matrix;
  late ErrorCorrectionLevel _ecl;

  @override
  void initState() {
    super.initState();
    _ecl = toQrErrorLevel(widget.qrErrorLevel);
    _matrix = Encoder.encode(widget.payload, _ecl).matrix!;
  }

  @override
  void didUpdateWidget(covariant QrPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.payload != widget.payload ||
        oldWidget.qrErrorLevel != widget.qrErrorLevel) {
      _ecl = toQrErrorLevel(widget.qrErrorLevel);
      _matrix = Encoder.encode(widget.payload, _ecl).matrix!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final (needsWebPainter, shapeSet) = _resolveQrRenderingStrategy(
      widget.qrStyleId,
      widget.cornerStyleId,
    );

    if (needsWebPainter) {
      return RepaintBoundary(
        child: CustomPaint(
          size: const Size.square(250),
          painter: WebLikeQrPainter(
            matrix: _matrix,
            dotStyleId: widget.qrStyleId,
            cornerStyleId: widget.cornerStyleId,
            darkColor: widget.theme.dark,
            accentColor: widget.theme.accent,
            backgroundColor: widget.theme.light,
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: CustomPaint(
        size: const Size.square(250),
        painter: QrPainter(
          data: widget.payload,
          options: QrOptions(
            padding: 0.14,
            ecl: _ecl,
            colors: QrColors(
              dark: QrColorSolid(widget.theme.dark),
              frame: QrColorSolid(widget.theme.dark),
              ball: QrColorSolid(widget.theme.accent),
              background: QrColorSolid(widget.theme.light),
            ),
            shapes: QrShapes(
              darkPixel: shapeSet.$1,
              frame: shapeSet.$2,
              ball: shapeSet.$3,
            ),
          ),
        ),
      ),
    );
  }
}

(bool, (QrPixelShape, QrFrameShape, QrBallShape)) _resolveQrRenderingStrategy(
  String dotStyleId,
  String cornerStyleId,
) {
  const unsupportedDots = <String>{
    'diamond',
    'kite',
    'plus',
    'star',
    'cross',
    'bars_v',
  };
  final needsWebPainter =
      unsupportedDots.contains(dotStyleId) || cornerStyleId == 'diamond';
  return (needsWebPainter, _qrShapeSet(dotStyleId, cornerStyleId));
}

(QrPixelShape, QrFrameShape, QrBallShape) _qrShapeSet(
  String dotStyleId,
  String cornerStyleId,
) {
  final pixel = switch (dotStyleId) {
    'square' => const QrPixelShapeDefault(),
    'rounded' => const QrPixelShapeRoundCorners(cornerFraction: 0.28),
    'dot' => const QrPixelShapeCircle(radiusFraction: 0.8),
    'diamond' => const QrPixelShapeRoundCorners(cornerFraction: 0.06),
    'squircle' => const QrPixelShapeRoundCorners(cornerFraction: 0.42),
    'kite' => const QrPixelShapeRoundCorners(cornerFraction: 0.18),
    'plus' => const QrPixelShapeRoundCorners(cornerFraction: 0.04),
    'star' => const QrPixelShapeCircle(radiusFraction: 0.62),
    'cross' => const QrPixelShapeCircle(radiusFraction: 0.74),
    'bars_v' => const QrPixelShapeRoundCorners(cornerFraction: 0.0),
    _ => const QrPixelShapeDefault(),
  };

  final (QrFrameShape frame, QrBallShape ball) = switch (cornerStyleId) {
    'square' => (const QrFrameShapeDefault(), const QrBallShapeDefault()),
    'rounded' => (
      const QrFrameShapeRoundCorners(cornerFraction: 0.2, widthFraction: 1),
      const QrBallShapeRoundCorners(cornerFraction: 0.2),
    ),
    'dot' => (
      const QrFrameShapeCircle(widthFraction: 1, radiusFraction: 1),
      const QrBallShapeCircle(radiusFraction: 1),
    ),
    'diamond' => (
      const QrFrameShapeRoundCorners(cornerFraction: 0.1, widthFraction: 1),
      const QrBallShapeRoundCorners(cornerFraction: 0.1),
    ),
    'leaf' => (
      const QrFrameShapeRoundCorners(
        cornerFraction: 0.44,
        widthFraction: 1,
        topLeft: true,
        topRight: true,
        bottomLeft: true,
        bottomRight: true,
      ),
      const QrBallShapeRoundCorners(cornerFraction: 0.42),
    ),
    _ => (const QrFrameShapeDefault(), const QrBallShapeDefault()),
  };

  return (pixel, frame, ball);
}

class WebLikeQrPainter extends CustomPainter {
  WebLikeQrPainter({
    required this.matrix,
    required this.dotStyleId,
    required this.cornerStyleId,
    required this.darkColor,
    required this.accentColor,
    required this.backgroundColor,
  });

  final ByteMatrix matrix;
  final String dotStyleId;
  final String cornerStyleId;
  final Color darkColor;
  final Color accentColor;
  final Color backgroundColor;

  bool _inFinder(int row, int col, int count) {
    final topLeft = row < 7 && col < 7;
    final topRight = row < 7 && col >= count - 7;
    final bottomLeft = row >= count - 7 && col < 7;
    return topLeft || topRight || bottomLeft;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final codeSize = math.min(size.width, size.height);
    const padRatio = 0.14;
    final padding = codeSize * padRatio;
    final count = matrix.width;
    final module = (codeSize - (padding * 2)) / count;
    final offset = Offset(
      (size.width - codeSize) / 2 + padding,
      (size.height - codeSize) / 2 + padding,
    );

    final bg = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, bg);

    final dark = Paint()..color = darkColor;
    final light = Paint()..color = backgroundColor;
    final accent = Paint()..color = accentColor;

    for (var row = 0; row < count; row += 1) {
      for (var col = 0; col < count; col += 1) {
        if (matrix.get(col, row) != 1) continue;
        if (_inFinder(row, col, count)) continue;
        final x = offset.dx + (col * module);
        final y = offset.dy + (row * module);
        _drawDot(canvas, Rect.fromLTWH(x, y, module, module), dotStyleId, dark);
      }
    }

    _drawFinder(canvas, offset, module, cornerStyleId, dark, light, accent);
    _drawFinder(
      canvas,
      Offset(offset.dx + ((count - 7) * module), offset.dy),
      module,
      cornerStyleId,
      dark,
      light,
      accent,
    );
    _drawFinder(
      canvas,
      Offset(offset.dx, offset.dy + ((count - 7) * module)),
      module,
      cornerStyleId,
      dark,
      light,
      accent,
    );
  }

  void _drawFinder(
    Canvas canvas,
    Offset topLeft,
    double module,
    String style,
    Paint dark,
    Paint light,
    Paint accent,
  ) {
    final outer = Rect.fromLTWH(topLeft.dx, topLeft.dy, module * 7, module * 7);
    final inner = Rect.fromLTWH(
      topLeft.dx + module,
      topLeft.dy + module,
      module * 5,
      module * 5,
    );
    final core = Rect.fromLTWH(
      topLeft.dx + (module * 2),
      topLeft.dy + (module * 2),
      module * 3,
      module * 3,
    );
    _drawFinderShape(canvas, outer, style, dark);
    _drawFinderShape(canvas, inner, style, light);
    _drawFinderShape(canvas, core, style, accent);
  }

  void _drawFinderShape(Canvas canvas, Rect r, String style, Paint paint) {
    switch (style) {
      case 'dot':
        canvas.drawOval(r, paint);
        return;
      case 'diamond':
        final cx = r.center.dx;
        final cy = r.center.dy;
        final path = Path()
          ..moveTo(cx, r.top)
          ..lineTo(r.right, cy)
          ..lineTo(cx, r.bottom)
          ..lineTo(r.left, cy)
          ..close();
        canvas.drawPath(path, paint);
        return;
      case 'leaf':
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            r,
            topLeft: Radius.circular(r.width * 0.44),
            topRight: Radius.circular(r.width * 0.44),
            bottomLeft: Radius.circular(r.width * 0.12),
            bottomRight: Radius.circular(r.width * 0.12),
          ),
          paint,
        );
        return;
      case 'rounded':
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.2)),
          paint,
        );
        return;
      default:
        canvas.drawRect(r, paint);
    }
  }

  void _drawDot(Canvas canvas, Rect r, String style, Paint paint) {
    final cx = r.center.dx;
    final cy = r.center.dy;
    final size = r.width;
    switch (style) {
      case 'dot':
        canvas.drawCircle(Offset(cx, cy), size * 0.4, paint);
        return;
      case 'rounded':
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, Radius.circular(size * 0.28)),
          paint,
        );
        return;
      case 'diamond':
      case 'kite':
        final h = (size / 2) * 0.92;
        final k = style == 'kite' ? 0.86 : 1.0;
        final path = Path()
          ..moveTo(cx, cy - h)
          ..lineTo(cx + (h * k), cy)
          ..lineTo(cx, cy + h)
          ..lineTo(cx - (h * k), cy)
          ..close();
        canvas.drawPath(path, paint);
        return;
      case 'squircle':
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, Radius.circular(size * 0.42)),
          paint,
        );
        return;
      case 'plus':
      case 'cross':
        final width = size * 0.24;
        final arm = size * 0.36;
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: width,
            height: arm * 2,
          ),
          paint,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: arm * 2,
            height: width,
          ),
          paint,
        );
        return;
      case 'star':
        final outer = (size / 2) * 0.94;
        final inner = outer * 0.44;
        final path = Path();
        for (var i = 0; i < 10; i += 1) {
          final radius = i.isEven ? outer : inner;
          final angle = ((math.pi / 5) * i) - (math.pi / 2);
          final px = cx + (radius * math.cos(angle));
          final py = cy + (radius * math.sin(angle));
          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        return;
      case 'bars_v':
        final bar = size * 0.34;
        canvas.drawRect(Rect.fromLTWH(cx - bar - 1, r.top, bar, size), paint);
        canvas.drawRect(Rect.fromLTWH(cx + 1, r.top, bar, size), paint);
        return;
      default:
        canvas.drawRect(r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WebLikeQrPainter old) {
    return !identical(old.matrix, matrix) ||
        old.dotStyleId != dotStyleId ||
        old.cornerStyleId != cornerStyleId ||
        old.darkColor != darkColor ||
        old.accentColor != accentColor ||
        old.backgroundColor != backgroundColor;
  }
}
