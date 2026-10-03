import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Demo modundaki arkadaş "fotoğrafları": pencereden görünen çizimler.
class SceneArt extends StatelessWidget {
  const SceneArt(this.scene, {super.key});

  final int scene;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ScenePainter(scene), child: const SizedBox.expand());
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.scene);

  final int scene;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.max(size.width / 300, size.height / 360);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate((size.width - 300 * s) / 2, (size.height - 360 * s) / 2);
    canvas.scale(s);
    switch (scene % 6) {
      case 0:
        _rooftops(canvas);
        break;
      case 1:
        _rainCat(canvas);
        break;
      case 2:
        _sunsetFerry(canvas);
        break;
      case 3:
        _tea(canvas);
        break;
      case 4:
        _dishes(canvas);
        break;
      default:
        _laundry(canvas);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) => oldDelegate.scene != scene;
}

Paint _p(int c) => Paint()..color = Color(c);

void _rect(Canvas c, double x, double y, double w, double h, int col) =>
    c.drawRect(Rect.fromLTWH(x, y, w, h), _p(col));

Path _poly(List<double> pts) {
  final p = Path()..moveTo(pts[0], pts[1]);
  for (var i = 2; i < pts.length; i += 2) {
    p.lineTo(pts[i], pts[i + 1]);
  }
  p.close();
  return p;
}

Paint _stroke(int col, double w) => Paint()
  ..color = Color(col)
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round;

void _frame(Canvas c, int frame, int sill) {
  c.drawRect(const Rect.fromLTWH(7, 7, 286, 346), _stroke(frame, 14)..strokeCap = StrokeCap.butt);
  _rect(c, 146, 7, 8, 300, frame);
  _rect(c, 0, 306, 300, 54, sill);
}

void _gull(Canvas c, double x, double y, double w, int col) {
  final p = Path()
    ..moveTo(x, y)
    ..quadraticBezierTo(x + w / 2, y - w / 2, x + w, y)
    ..quadraticBezierTo(x + w * 1.5, y - w / 2, x + w * 2, y);
  c.drawPath(p, _stroke(col, 3));
}

void _rooftops(Canvas c) {
  _rect(c, 0, 0, 300, 360, 0xFFA7D3EE);
  c.drawCircle(const Offset(228, 78), 28, _p(0xFFFFE29A));
  c.drawPath(_poly([0, 222, 40, 196, 90, 210, 140, 188, 200, 206, 260, 192, 300, 202, 300, 360, 0, 360]), _p(0xFF8FAEC4));
  _rect(c, 66, 96, 12, 140, 0xFFEFE6D8);
  c.drawPath(_poly([66, 96, 72, 58, 78, 96]), _p(0xFF7C8E9C));
  _rect(c, 62, 138, 20, 6, 0xFFEFE6D8);
  _rect(c, 10, 238, 92, 122, 0xFFE8D5BE);
  c.drawPath(_poly([2, 242, 56, 208, 110, 242]), _p(0xFFC4603F));
  _rect(c, 110, 222, 82, 138, 0xFFF1E4D2);
  c.drawPath(_poly([102, 226, 151, 192, 200, 226]), _p(0xFFA94E34));
  _rect(c, 200, 248, 100, 112, 0xFFDCC4A7);
  c.drawPath(_poly([192, 252, 250, 218, 308, 252]), _p(0xFFC4603F));
  for (final w in const [
    [28.0, 258.0], [66.0, 258.0], [128.0, 246.0], [164.0, 246.0], [128.0, 282.0], [216.0, 270.0], [258.0, 270.0],
  ]) {
    _rect(c, w[0], w[1], 16, 22, 0xFF4E6475);
  }
  _frame(c, 0xFF2B2521, 0xFF3A322C);
  c.drawPath(_poly([36, 306, 42, 282, 72, 282, 78, 306]), _p(0xFFB85A3A));
  c.drawOval(const Rect.fromLTWH(32, 250, 26, 34), _p(0xFF4F7A4A));
  c.drawOval(const Rect.fromLTWH(56, 252, 30, 30), _p(0xFF5E8F57));
}

void _rainCat(Canvas c) {
  _rect(c, 0, 0, 300, 360, 0xFF56657E);
  _rect(c, 24, 44, 150, 270, 0xFF3E4A5E);
  _rect(c, 186, 96, 114, 220, 0xFF47546A);
  for (var row = 0; row < 4; row++) {
    for (var col = 0; col < 3; col++) {
      final lit = (row * 3 + col) % 3 == 0;
      _rect(c, 42.0 + col * 38, 66.0 + row * 50, 20, 26, lit ? 0xFFF2C26B : 0xFF2F394A);
    }
  }
  for (var row = 0; row < 3; row++) {
    for (var col = 0; col < 2; col++) {
      final lit = (row + col) % 2 == 1;
      _rect(c, 204.0 + col * 58, 120.0 + row * 50, 20, 26, lit ? 0xFFF2C26B : 0xFF2F394A);
    }
  }
  final rain = _stroke(0xFFB7C4D6, 2);
  for (final r in const [
    [36.0, 20.0], [96.0, 34.0], [160.0, 14.0], [220.0, 44.0], [268.0, 18.0], [120.0, 100.0], [250.0, 128.0], [60.0, 150.0], [180.0, 200.0],
  ]) {
    c.drawLine(Offset(r[0], r[1]), Offset(r[0] - 8, r[1] + 28), rain);
  }
  _frame(c, 0xFF1B1F27, 0xFF262B34);
  final cat = _p(0xFF121110);
  c.drawOval(const Rect.fromLTWH(164, 266, 80, 48), cat);
  c.drawCircle(const Offset(238, 262), 16, cat);
  c.drawPath(_poly([226, 252, 227, 234, 237, 248]), cat);
  c.drawPath(_poly([240, 248, 249, 234, 251, 254]), cat);
  final tail = Path()
    ..moveTo(166, 302)
    ..cubicTo(144, 302, 140, 282, 152, 272);
  c.drawPath(tail, _stroke(0xFF121110, 8));
}

void _sunsetFerry(Canvas c) {
  _rect(c, 0, 0, 300, 360, 0xFFF4B26A);
  _rect(c, 0, 0, 300, 64, 0xFFEC9558);
  _rect(c, 0, 64, 300, 50, 0xFFF1A462);
  c.drawCircle(const Offset(150, 186), 38, _p(0xFFFFE1A6));
  final shore = Path()
    ..moveTo(0, 204)
    ..lineTo(20, 204)
    ..lineTo(20, 188)
    ..lineTo(26, 188)
    ..lineTo(26, 204)
    ..lineTo(60, 204)
    ..quadraticBezierTo(72, 186, 84, 204)
    ..lineTo(120, 204)
    ..lineTo(120, 196)
    ..lineTo(170, 196)
    ..lineTo(170, 204)
    ..lineTo(200, 204)
    ..quadraticBezierTo(217, 180, 234, 204)
    ..lineTo(246, 204)
    ..lineTo(246, 180)
    ..lineTo(250, 170)
    ..lineTo(254, 180)
    ..lineTo(254, 204)
    ..lineTo(300, 204)
    ..lineTo(300, 214)
    ..lineTo(0, 214)
    ..close();
  c.drawPath(shore, _p(0xFF6B4E5A));
  _rect(c, 0, 212, 300, 148, 0xFF2F5D74);
  _rect(c, 122, 222, 56, 4, 0xFFFFE1A6);
  _rect(c, 132, 234, 36, 4, 0xFFFFE1A6);
  _rect(c, 140, 246, 20, 4, 0xFFFFE1A6);
  c.drawPath(_poly([70, 264, 206, 264, 194, 284, 82, 284]), _p(0xFFF3EEE6));
  _rect(c, 96, 248, 84, 16, 0xFFF3EEE6);
  _rect(c, 132, 234, 12, 14, 0xFF1E1E1E);
  _rect(c, 132, 234, 12, 4, 0xFFF2C94C);
  for (final x in const [104.0, 118.0, 150.0, 164.0]) {
    _rect(c, x, 252, 8, 6, 0xFF2F5D74);
  }
  _gull(c, 54, 110, 16, 0xFF4A3A40);
  _gull(c, 206, 134, 12, 0xFF4A3A40);
  _frame(c, 0xFF2B2521, 0xFF3A322C);
}

void _tea(Canvas c) {
  _rect(c, 0, 0, 300, 360, 0xFFCFE6EE);
  _rect(c, 196, 40, 104, 270, 0xFFF0DCC2);
  for (var row = 0; row < 3; row++) {
    _rect(c, 214, 70.0 + row * 70, 22, 30, 0xFFB79B7C);
    _rect(c, 258, 70.0 + row * 70, 22, 30, 0xFFB79B7C);
  }
  _rect(c, 84, 200, 12, 110, 0xFF6A4E3A);
  c.drawCircle(const Offset(80, 150), 64, _p(0xFF6F9E66));
  c.drawCircle(const Offset(130, 120), 48, _p(0xFF5C8A55));
  c.drawCircle(const Offset(40, 110), 40, _p(0xFF7FAE72));
  _frame(c, 0xFF2B2521, 0xFF3A322C);
  c.drawOval(const Rect.fromLTWH(110, 297, 80, 18), _p(0xFFC9423A));
  c.drawOval(const Rect.fromLTWH(119, 298, 62, 12), _p(0xFFF5F1EA));
  final glass = Path()
    ..moveTo(132, 232)
    ..cubicTo(128, 254, 142, 270, 138, 302)
    ..lineTo(162, 302)
    ..cubicTo(158, 270, 172, 254, 168, 232)
    ..close();
  c.drawPath(glass, _p(0xFFEADFD2));
  final tea = Path()
    ..moveTo(131, 246)
    ..cubicTo(131, 260, 142, 274, 139, 302)
    ..lineTo(161, 302)
    ..cubicTo(158, 274, 169, 260, 169, 246)
    ..close();
  c.drawPath(tea, _p(0xFFB4471E));
  final steam = _stroke(0xFFFFFFFF, 3);
  for (final x in const [144.0, 156.0]) {
    final p = Path()
      ..moveTo(x, 222)
      ..cubicTo(x - 6, 212, x + 6, 206, x, 196);
    c.drawPath(p, steam);
  }
}

void _dishes(Canvas c) {
  _rect(c, 0, 0, 300, 360, 0xFFBFE0F2);
  c.drawCircle(const Offset(64, 70), 24, _p(0xFFFFF1C2));
  _gull(c, 150, 60, 14, 0xFF3B4552);
  _gull(c, 196, 84, 12, 0xFF3B4552);
  _gull(c, 232, 50, 10, 0xFF3B4552);
  _rect(c, 0, 200, 300, 12, 0xFFB9A890);
  _rect(c, 0, 212, 300, 148, 0xFFD9CBB8);
  c.drawPath(_poly([98, 118, 178, 106, 174, 136, 94, 148]), _p(0xFF2E4A6B));
  final pole = _stroke(0xFF6E6C68, 4);
  c.drawLine(const Offset(104, 148), const Offset(102, 168), pole);
  c.drawLine(const Offset(170, 138), const Offset(172, 160), pole);
  final tank = RRect.fromRectAndRadius(const Rect.fromLTWH(106, 160, 62, 34), const Radius.circular(17));
  c.drawRRect(tank, _p(0xFFE9E6E0));
  c.drawRRect(tank, _stroke(0xFF8C8A86, 2));
  c.drawLine(const Offset(112, 194), const Offset(108, 202), pole);
  c.drawLine(const Offset(162, 194), const Offset(166, 202), pole);
  for (final d in const [
    [60.0, 166.0, 22.0, 26.0, -0.44],
    [214.0, 160.0, 18.0, 22.0, -0.35],
    [258.0, 178.0, 14.0, 17.0, -0.52],
  ]) {
    c.save();
    c.translate(d[0], d[1]);
    c.rotate(d[4]);
    final r = Rect.fromCenter(center: Offset.zero, width: d[2] * 2, height: d[3] * 2);
    c.drawOval(r, _p(0xFFF4F2EE));
    c.drawOval(r, _stroke(0xFF8C8A86, 2));
    c.restore();
    c.drawLine(Offset(d[0] + 6, d[1] + d[3] - 4), Offset(d[0] + 8, 202), pole);
  }
  _frame(c, 0xFF2B2521, 0xFF3A322C);
}

void _laundry(Canvas c) {
  _rect(c, 0, 0, 300, 360, 0xFFE7C9A9);
  for (final y in const [60.0, 150.0, 230.0]) {
    _rect(c, 0, y, 300, 3, 0xFFD9B793);
  }
  _rect(c, 186, 170, 74, 96, 0xFF7A5A44);
  _rect(c, 194, 178, 58, 80, 0xFF5A7E8C);
  final line = Path()
    ..moveTo(0, 92)
    ..quadraticBezierTo(150, 128, 300, 92);
  c.drawPath(line, _stroke(0xFF5B5550, 2));
  c.drawPath(_poly([34, 100, 50, 96, 56, 104, 64, 104, 70, 96, 86, 100, 84, 116, 76, 114, 76, 152, 44, 152, 44, 114, 36, 116]), _p(0xFFF2C94C));
  _rect(c, 104, 106, 34, 58, 0xFF4F7FB8);
  c.drawPath(_poly([152, 114, 160, 114, 160, 140, 170, 146, 166, 152, 152, 144]), _p(0xFFC9423A));
  c.drawPath(_poly([172, 114, 180, 114, 180, 140, 190, 146, 186, 152, 172, 144]), _p(0xFFC9423A));
  c.drawPath(_poly([214, 104, 230, 100, 236, 108, 244, 108, 250, 100, 266, 104, 264, 120, 256, 118, 256, 154, 224, 154, 224, 118, 216, 120]), _p(0xFF6FA36A));
  _frame(c, 0xFF2B2521, 0xFF3A322C);
}
