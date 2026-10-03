import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../services/notifications.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/scenes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  bool _adult = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _valid => _name.text.trim().length >= 2 && _adult;

  Future<void> _start() async {
    if (!_valid) return;
    setState(() => _busy = true);
    try {
      await app.onboard(_name.text);
      await Notifs.requestPermission();
      await Notifs.scheduleWeek();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(alignment: Alignment.centerLeft, child: Logo(size: 34)),
              const SizedBox(height: 16),
              const _Hero(),
              const SizedBox(height: 14),
              Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Günde bir an.\n'),
                  TextSpan(text: 'Tek kazanan.', style: display(38, color: C.flash, height: 1.02, spacing: -1)),
                ]),
                style: display(38, height: 1.02, spacing: -1),
              ),
              const SizedBox(height: 12),
              Text(
                'Şipşak gelince bir saatin var. Çek, akşam arkadaşların oylasın, günün karesi sen ol.',
                style: body(16, color: const Color(0xFFB9B5AE), height: 1.45),
              ),
              const SizedBox(height: 24),
              Text('Adın', style: body(13, color: const Color(0xFFB9B5AE), weight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _name,
                maxLength: 20,
                textCapitalization: TextCapitalization.words,
                style: body(16),
                decoration: const InputDecoration(hintText: 'Örn. Deniz', counterText: ''),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _start(),
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _adult = !_adult),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _adult,
                        onChanged: (v) => setState(() => _adult = v ?? false),
                        activeColor: C.flash,
                        checkColor: C.ink,
                        side: const BorderSide(color: C.dim, width: 1.5),
                      ),
                      Expanded(child: Text('16 yaşından büyüğüm', style: body(14, color: C.muted))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              BigButton(label: 'Başla', icon: Icons.bolt, busy: _busy, onPressed: _valid ? _start : null),
              if (kIsWeb) ...[
                const SizedBox(height: 14),
                Panel(
                  child: Row(
                    children: [
                      const Icon(Icons.ios_share, color: C.flash, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'iPhone\'da uygulama gibi kullanmak için: Safari\'de alttaki Paylaş butonu > Ana Ekrana Ekle.',
                          style: body(13, color: C.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (app.isDemo) ...[
                const SizedBox(height: 14),
                Text(
                  'Demo modundasın: sahte arkadaşlarla tüm akışı deneyebilirsin.',
                  textAlign: TextAlign.center,
                  style: body(12, color: C.dim),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 270,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 56,
                child: Polaroid(width: 136, photoHeight: 140, angle: -0.16, caption: 'Zeynep', trailing: '14:07', child: const SceneArt(2)),
              ),
              Positioned(
                right: 0,
                top: 64,
                child: Polaroid(width: 136, photoHeight: 140, angle: 0.14, caption: 'Emre', trailing: '14:15', child: const SceneArt(1)),
              ),
              Positioned(
                left: (w - 172) / 2,
                top: 4,
                child: Transform.rotate(
                  angle: -0.035,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Polaroid(width: 172, photoHeight: 180, caption: 'Sen', trailing: '14:16', child: const SceneArt(0)),
                      Positioned(
                        top: -12,
                        right: -14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: C.flash,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 6))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CrownIcon(size: 15),
                              const SizedBox(width: 4),
                              Text('Günün Karesi', style: body(11, color: C.ink, weight: FontWeight.w700, height: 1.1)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
