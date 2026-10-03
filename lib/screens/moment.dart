import 'dart:async';

import 'package:flutter/material.dart';

import '../clock.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'camera.dart';
import 'sheets.dart';

/// Bildirime dokununca açılan sarı "ŞİPŞAK!" ekranı.
class MomentScreen extends StatefulWidget {
  const MomentScreen({super.key});

  @override
  State<MomentScreen> createState() => _MomentScreenState();
}

class _MomentScreenState extends State<MomentScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _openCamera() {
    if (app.groups.isEmpty) {
      showCreateSheet(context, onCreated: (_) {});
      showInfo(context, 'Kareni atmak için önce bir grup kur ya da katıl.');
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const CameraScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final s = app.today;
    final left = app.timeLeft;
    final now = trNow();
    final canPost = app.canPost;
    return Scaffold(
      backgroundColor: C.flash,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RoundIconButton(
                    icon: Icons.close,
                    tooltip: 'Kapat',
                    bg: C.ink,
                    fg: C.flash,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Text('${trDate(now)} · ${hhmm(s.moment)}', style: body(14, color: C.ink, weight: FontWeight.w600)),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(24)),
                        child: const Icon(Icons.bolt, color: C.flash, size: 46),
                      ),
                      const SizedBox(height: 18),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text('ŞİPŞAK!', style: display(68, color: C.ink, height: 0.95, spacing: -2)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        app.phase == Phase.late
                            ? 'Bir saat doldu ama hâlâ atabilirsin. Kareni "geç" etiketiyle görecekler.'
                            : 'Türkiye\'de herkes aynı anda aldı. Bir saatin var.',
                        style: body(18, color: C.ink, weight: FontWeight.w500, height: 1.4),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: C.ink, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BUGÜNÜN TEMASI', style: body(12, color: C.ink, weight: FontWeight.w700, spacing: 1.4)),
                            const SizedBox(height: 6),
                            Text(s.theme, style: display(30, color: C.ink)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (left != null)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(countdownText(left), style: mono(60, color: C.ink, spacing: -2)),
                            const SizedBox(width: 10),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text('kaldı', style: body(16, color: C.ink, weight: FontWeight.w600)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (canPost)
                BigButton(label: 'Kamerayı aç', icon: Icons.photo_camera_outlined, dark: true, height: 60, onPressed: _openCamera)
              else
                BigButton(
                  label: app.postedToday ? 'Bugünkü kareni attın' : 'Şu an çekim zamanı değil',
                  icon: app.postedToday ? Icons.check : Icons.schedule,
                  dark: true,
                  height: 60,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Arkadaşlarının karelerini görmek için önce sen çek.',
                  textAlign: TextAlign.center,
                  style: body(13, color: C.ink, weight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
