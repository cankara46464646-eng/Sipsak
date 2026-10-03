import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../clock.dart';
import '../config.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Instagram hikâyesi için 9:16 "Günün Karesi" kartı.
class WinnerCardScreen extends StatefulWidget {
  const WinnerCardScreen({
    super.key,
    required this.post,
    required this.groupName,
    required this.votes,
    required this.people,
    required this.theme,
  });

  final Post post;
  final String groupName;
  final int votes;
  final int people;
  final String theme;

  @override
  State<WinnerCardScreen> createState() => _WinnerCardScreenState();
}

class _WinnerCardScreenState extends State<WinnerCardScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary = _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1080 / boundary.size.width);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw Exception('Kart oluşturulamadı');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/sipsak_gunun_karesi.png');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'Bugün Günün Karesi benim! Sen de grubunu kur: ${AppConfig.downloadUrl}',
      );
    } catch (e) {
      if (mounted) showError(context, 'Paylaşılamadı: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  RoundIconButton(icon: Icons.close, tooltip: 'Kapat', onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Text('Hikâye kartın', style: body(18, weight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: RepaintBoundary(
                        key: _cardKey,
                        child: _StoryCard(
                          post: widget.post,
                          groupName: widget.groupName,
                          votes: widget.votes,
                          people: widget.people,
                          theme: widget.theme,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: BigButton(label: 'Paylaş', icon: Icons.ios_share, busy: _busy, onPressed: _share),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.post,
    required this.groupName,
    required this.votes,
    required this.people,
    required this.theme,
  });

  final Post post;
  final String groupName;
  final int votes;
  final int people;
  final String theme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // Kart 390 genişliğe göre tasarlandı, ekrana göre ölçeklenir.
        final k = box.maxWidth / 390;
        return Container(
          color: C.flash,
          padding: EdgeInsets.fromLTRB(28 * k, 36 * k, 28 * k, 30 * k),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CrownIcon(size: 22 * k),
                  SizedBox(width: 8 * k),
                  Text('GÜNÜN KARESİ', style: body(15 * k, color: C.ink, weight: FontWeight.w700, spacing: 3 * k)),
                ],
              ),
              SizedBox(height: 6 * k),
              Text(
                '${trShortDate(trNow())} · $groupName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body(14 * k, color: C.ink, weight: FontWeight.w600),
              ),
              SizedBox(height: 30 * k),
              Transform.rotate(
                angle: -0.07,
                child: Container(
                  width: 262 * k,
                  padding: EdgeInsets.fromLTRB(12 * k, 12 * k, 12 * k, 0),
                  decoration: BoxDecoration(
                    color: C.paper,
                    borderRadius: BorderRadius.circular(5 * k),
                    boxShadow: [BoxShadow(color: const Color(0x593C2D00), blurRadius: 40 * k, offset: Offset(0, 22 * k))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 300 * k, width: double.infinity, child: ClipRect(child: PostPhoto(post))),
                      Padding(
                        padding: EdgeInsets.fromLTRB(2 * k, 10 * k, 2 * k, 14 * k),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(theme, style: display(17 * k, color: C.paperInk, height: 1.15)),
                            SizedBox(height: 4 * k),
                            Text('$people kişi arasından $votes oyla', style: mono(12 * k, color: C.paperMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Logo(size: 32 * k, dark: true),
              SizedBox(height: 8 * k),
              Text('Sen de grubunu kur, yarın sen kazan', style: body(14 * k, color: C.ink, weight: FontWeight.w600)),
              if (app.name.isNotEmpty) ...[
                SizedBox(height: 4 * k),
                Text('@${app.name}', style: body(12 * k, color: C.flashDeep, weight: FontWeight.w600)),
              ],
            ],
          ),
        );
      },
    );
  }
}
