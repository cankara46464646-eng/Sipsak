import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'scenes.dart';

/// Şimşek simgeli logo.
class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 30, this.dark = false});

  final double size;

  /// Sarı zemin üstünde kullanılacaksa true.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: dark ? C.ink : C.flash,
            borderRadius: BorderRadius.circular(size * 0.3),
          ),
          child: Icon(Icons.bolt, size: size * 0.7, color: dark ? C.flash : C.ink),
        ),
        SizedBox(width: size * 0.27),
        Text('şipşak', style: display(size * 0.78, color: dark ? C.ink : C.text)),
      ],
    );
  }
}

/// Taç simgesi.
class CrownIcon extends StatelessWidget {
  const CrownIcon({super.key, this.size = 22, this.color = C.ink});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _CrownPainter(color)));
  }
}

class _CrownPainter extends CustomPainter {
  _CrownPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path()
      ..moveTo(w * 0.12, h * 0.33)
      ..lineTo(w * 0.31, h * 0.50)
      ..lineTo(w * 0.50, h * 0.21)
      ..lineTo(w * 0.69, h * 0.50)
      ..lineTo(w * 0.88, h * 0.33)
      ..lineTo(w * 0.79, h * 0.79)
      ..lineTo(w * 0.21, h * 0.79)
      ..close();
    canvas.drawPath(
      p,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.09
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CrownPainter oldDelegate) => oldDelegate.color != color;
}

const List<Color> _avatarColors = [
  Color(0xFF9DC3E6),
  Color(0xFFE8A87C),
  Color(0xFFB8D99A),
  Color(0xFFE6B3D3),
  Color(0xFFF2D16B),
  Color(0xFFC7B6F0),
];

Color avatarColor(String seed) {
  var h = 0;
  for (final c in seed.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return _avatarColors[h % _avatarColors.length];
}

String initialOf(String name) {
  final t = name.trim();
  if (t.isEmpty) return '?';
  return t.characters.first.toUpperCase();
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.seed, this.size = 30, this.ring = C.surface, this.faded = false});

  final String name;
  final String? seed;
  final double size;
  final Color ring;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: faded ? 0.5 : 1,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: avatarColor(seed ?? name),
          shape: BoxShape.circle,
          border: Border.all(color: ring, width: 2),
        ),
        child: Text(initialOf(name), style: body(size * 0.4, color: C.ink, weight: FontWeight.w700, height: 1)),
      ),
    );
  }
}

/// Üst üste binmiş avatarlar.
class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.members, this.max = 3, this.size = 30, this.ring = C.surface});

  final Map<String, String> members;
  final int max;
  final double size;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    final entries = members.entries.toList();
    final shown = entries.take(max).toList();
    final extra = entries.length - shown.length;
    final children = <Widget>[
      for (final e in shown) Avatar(name: e.value, seed: e.key, size: size, ring: ring),
      if (extra > 0)
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: C.surface2, shape: BoxShape.circle, border: Border.all(color: ring, width: 2)),
          child: Text('+$extra', style: body(size * 0.36, weight: FontWeight.w700, height: 1)),
        ),
    ];
    final step = size * 0.72;
    return SizedBox(
      width: step * (children.length - 1) + size,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < children.length; i++) Positioned(left: step * i, child: children[i]),
        ],
      ),
    );
  }
}

/// Bir gönderinin fotoğrafı (gerçek JPEG ya da demo çizimi).
class PostPhoto extends StatelessWidget {
  const PostPhoto(this.post, {super.key});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final bytes = post.bytes;
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true, width: double.infinity, height: double.infinity);
    }
    return SceneArt(post.demoScene ?? 0);
  }
}

/// Polaroid çerçeve.
class Polaroid extends StatelessWidget {
  const Polaroid({
    super.key,
    required this.child,
    required this.photoHeight,
    this.caption,
    this.trailing,
    this.width,
    this.angle = 0,
    this.padding = 10,
  });

  final Widget child;
  final double photoHeight;
  final String? caption;
  final String? trailing;
  final double? width;
  final double angle;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
      decoration: BoxDecoration(
        color: C.paper,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 28, offset: Offset(0, 12))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(height: photoHeight, child: child),
          ),
          SizedBox(
            height: 36,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    caption ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: body(13, color: C.paperInk, weight: FontWeight.w700),
                  ),
                ),
                if (trailing != null) Text(trailing!, style: mono(12, color: C.paperMuted)),
              ],
            ),
          ),
        ],
      ),
    );
    if (angle == 0) return card;
    return Transform.rotate(angle: angle, child: card);
  }
}

/// Küçük etiket.
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.icon, this.bg = C.surface, this.fg = C.text});

  final String text;
  final IconData? icon;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(text, style: body(12, color: fg, weight: FontWeight.w700, height: 1.1)),
        ],
      ),
    );
  }
}

/// Ana buton: sarı, büyük, yuvarlak köşeli.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.dark = false,
    this.busy = false,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Sarı zemin üstündeki koyu buton.
  final bool dark;
  final bool busy;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final bg = dark ? C.ink : (enabled ? C.flash : C.surface2);
    final fg = dark ? C.flash : (enabled ? C.ink : C.muted);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onPressed : null,
        child: SizedBox(
          height: height,
          child: Center(
            child: busy
                ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.6, color: fg))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: fg),
                        const SizedBox(width: 8),
                      ],
                      Text(label, style: body(17, color: fg, weight: FontWeight.w700)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Kenarlıklı ikincil buton.
class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF4A4A54)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: C.text),
                const SizedBox(width: 8),
              ],
              Text(label, style: body(15, weight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Yuvarlak simge butonu (geri, kapat vb.).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.bg = C.surface,
    this.fg = C.text,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color bg;
  final Color fg;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(width: size, height: size, child: Icon(icon, color: fg, size: size * 0.48)),
        ),
      ),
    );
  }
}

/// Koyu kart kutusu.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 14), this.color = C.surface});

  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      child: child,
    );
  }
}

void showError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
}

void showInfo(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
