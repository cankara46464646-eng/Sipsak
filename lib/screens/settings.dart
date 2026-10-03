import 'package:flutter/material.dart';

import '../clock.dart';
import '../services/app_state.dart';
import '../services/notifications.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _rename() async {
    final c = TextEditingController(text: app.name);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        title: Text('Adını değiştir', style: display(22)),
        content: TextField(controller: c, autofocus: true, maxLength: 20, style: body(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Vazgeç', style: body(15))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, c.text),
            child: Text('Kaydet', style: body(15, color: C.flash, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
    c.dispose();
    if (value == null || value.trim().length < 2) return;
    try {
      await app.rename(value);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = app.today;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Row(
              children: [
                RoundIconButton(icon: Icons.chevron_left, tooltip: 'Geri', onPressed: () => Navigator.of(context).pop()),
                const SizedBox(width: 12),
                Text('Ayarlar', style: display(24)),
              ],
            ),
            const SizedBox(height: 20),
            _Tile(
              icon: Icons.person_outline,
              title: app.name,
              subtitle: 'Adın, arkadaşların seni bu adla görür',
              onTap: _rename,
            ),
            _Tile(
              icon: Icons.notifications_active_outlined,
              title: 'Bildirim izni ver',
              subtitle: 'Şipşak anını kaçırma',
              onTap: () async {
                final ok = await Notifs.requestPermission();
                await Notifs.scheduleWeek();
                if (context.mounted) showInfo(context, ok ? 'Bildirimler açık' : 'Telefon ayarlarından bildirime izin ver');
              },
            ),
            _Tile(
              icon: Icons.bolt,
              title: 'Bildirimi dene',
              subtitle: 'Şipşak bildirimi nasıl görünüyor?',
              onTap: Notifs.showTest,
            ),
            if (app.isDemo)
              _Tile(
                icon: Icons.restart_alt,
                title: 'Demo gününü sıfırla',
                subtitle: 'Çekimi ve oyu silip baştan dene',
                onTap: () async {
                  await app.resetDemoDay();
                  if (context.mounted) showInfo(context, 'Demo günü sıfırlandı');
                },
              ),
            const SizedBox(height: 20),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nasıl oynanır?', style: display(19)),
                  const SizedBox(height: 10),
                  for (final line in const [
                    'Her gün 10:00 ile 18:00 arasında bir an Şipşak gelir. Türkiye\'de herkese aynı anda.',
                    'Bir saatin var: günün temasına uygun bir kare çek. Galeri yok, sadece canlı çekim.',
                    'Geç kalırsan da atabilirsin ama karen "geç" etiketiyle görünür.',
                    '20:00\'de oylama açılır. İsimler gizli, kendine oy veremezsin.',
                    '21:00\'de Günün Karesi belli olur. Kazanırsan taç senin!',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Icon(Icons.bolt, size: 16, color: C.flash),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(line, style: body(14, color: C.muted))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.isDemo ? 'Demo modu' : 'Çevrimiçi mod', style: body(15, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    app.isDemo
                        ? 'Sunucu bağlı değil. Sahte arkadaşlarla tüm akışı deneyebilirsin; gerçek gruplar için sunucu bağlanacak.'
                        : 'Sunucuya bağlısın. Grupların ve karelerin arkadaşlarınla paylaşılıyor.',
                    style: body(13, color: C.muted),
                  ),
                  const SizedBox(height: 10),
                  Text('Bugün: ${trDate(s.day)} · tema "${s.theme}"', style: body(12, color: C.dim)),
                  Text('Sürüm 0.1.0', style: body(12, color: C.dim)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: C.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: const Color(0xFF2A2416), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: C.flash, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: body(16, weight: FontWeight.w700)),
                      Text(subtitle, style: body(13, color: C.muted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: C.dim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
