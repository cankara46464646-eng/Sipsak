import 'dart:async';

import 'package:flutter/material.dart';

import '../clock.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../services/notifications.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'group.dart';
import 'moment.dart';
import 'settings.dart';
import 'sheets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    app.refreshGroups();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _openGroup(Group g) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GroupScreen(group: g)));
  }

  void _openMoment() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MomentScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              color: C.flash,
              backgroundColor: C.surface,
              onRefresh: app.refreshGroups,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Row(
                    children: [
                      const Logo(size: 30),
                      const Spacer(),
                      RoundIconButton(
                        icon: Icons.tune,
                        tooltip: 'Ayarlar',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                        ),
                      ),
                    ],
                  ),
                  if (app.isDemo) ...[
                    const SizedBox(height: 14),
                    _DemoBar(onChanged: () => setState(() {})),
                  ],
                  const SizedBox(height: 16),
                  _TodayCard(onShoot: _openMoment, onOpenGroups: () {
                    if (app.groups.isNotEmpty) _openGroup(app.groups.first);
                  }),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: const Icon(Icons.local_fire_department_outlined, color: C.flash, size: 22),
                          value: '${app.streak} gün',
                          label: 'Seri',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          icon: const CrownIcon(size: 22, color: C.flash),
                          value: '${app.crownsThisMonth} taç',
                          label: 'Bu ay',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Text('Grupların', style: display(21)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => showJoinSheet(context, onJoined: _openGroup),
                        style: TextButton.styleFrom(foregroundColor: C.flash, minimumSize: const Size(44, 44)),
                        child: Text('Kodla katıl', style: body(14, color: C.flash, weight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (app.loadingGroups && app.groups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (app.groupsError != null && app.groups.isEmpty)
                    Panel(
                      child: Text('Gruplar yüklenemedi: ${app.groupsError}\nAşağı çekip yenile.', style: body(14, color: C.muted)),
                    )
                  else if (app.groups.isEmpty)
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Henüz grubun yok', style: body(16, weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            'Bir grup kur, kodunu arkadaşlarına at. Ya da sana gelen kodla katıl.',
                            style: body(14, color: C.muted),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final g in app.groups) ...[
                      _GroupTile(group: g, onTap: () => _openGroup(g)),
                      const SizedBox(height: 10),
                    ],
                  const SizedBox(height: 8),
                  GhostButton(
                    label: 'Yeni grup kur',
                    icon: Icons.add,
                    onPressed: () => showCreateSheet(context, onCreated: _openGroup),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DemoBar extends StatelessWidget {
  const _DemoBar({required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A4A54)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DEMO MODU', style: body(11, color: C.flash, weight: FontWeight.w700, spacing: 1.2)),
                const SizedBox(height: 2),
                Text('Şu an: ${phaseLabel(app.phase)}', style: body(14, weight: FontWeight.w600)),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              app.nextDemoPhase();
              onChanged();
            },
            style: TextButton.styleFrom(foregroundColor: C.flash, minimumSize: const Size(44, 44)),
            icon: const Icon(Icons.fast_forward_rounded, size: 18),
            label: Text('Zamanı ileri sar', style: body(13, color: C.flash, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.value, required this.label});

  final Widget icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFF2A2416), borderRadius: BorderRadius.circular(12)),
            child: icon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: display(21, height: 1)),
                const SizedBox(height: 4),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(12, color: C.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.onShoot, required this.onOpenGroups});

  final VoidCallback onShoot;
  final VoidCallback onOpenGroups;

  @override
  Widget build(BuildContext context) {
    final s = app.today;
    final phase = app.phase;
    final left = app.timeLeft;
    final timer = left == null ? null : countdownText(left);

    switch (phase) {
      case Phase.waiting:
        return Panel(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Pill('BEKLENİYOR', icon: Icons.schedule, bg: C.surface2),
                  const Spacer(),
                  Text(trShortDate(s.day), style: body(13, color: C.muted, weight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 14),
              Text('Bugünün Şipşak\'ı henüz gelmedi', style: display(26)),
              const SizedBox(height: 8),
              Text(
                Notifs.supported
                    ? '10:00 ile 18:00 arasında bir an gelecek. Tema da o an açılacak. Bildirimleri açık tut.'
                    : '10:00 ile 18:00 arasında bir an gelecek. Tema da o an açılacak. Arada bir uygulamaya bak!',
                style: body(14, color: C.muted),
              ),
            ],
          ),
        );
      case Phase.shooting:
      case Phase.late:
        if (app.postedToday) {
          return _DoneCard(
            title: 'Kareni attın',
            text: 'Arkadaşlarının karelerine bak. Oylama 20:00\'de açılıyor.',
            action: 'Kareleri gör',
            onTap: onOpenGroups,
          );
        }
        final late = phase == Phase.late;
        return Material(
          color: C.flash,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onShoot,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Pill(late ? 'GEÇ KALDIN' : 'ŞİPŞAK GELDİ', icon: Icons.bolt, bg: C.ink, fg: C.flash),
                      const Spacer(),
                      if (timer != null) Text(timer, style: mono(18, color: C.ink)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Bugünün teması', style: body(13, color: C.flashDeep, weight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(s.theme, style: display(30, color: C.ink)),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          late ? 'Hâlâ atabilirsin, kareni "geç" etiketiyle görecekler.' : 'Bir saatin var. Galeri yok, sadece canlı çekim.',
                          style: body(14, color: C.ink, weight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(999)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Çek', style: body(15, color: C.flash, weight: FontWeight.w700)),
                            const SizedBox(width: 4),
                            const Icon(Icons.bolt, color: C.flash, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      case Phase.voting:
        return _DoneCard(
          title: 'Oylama açık',
          text: app.postedToday
              ? 'Gruplarına gir, günün karesini seç.${timer != null ? ' Sonuç: $timer' : ''}'
              : 'Bugün kare atmadığın için oy veremezsin ama karelere bakabilirsin.',
          action: 'Oy ver',
          onTap: onOpenGroups,
          highlight: true,
        );
      case Phase.results:
        return _DoneCard(
          title: 'Günün Karesi belli oldu',
          text: 'Bakalım bugün kim kazandı? Yarın yeni Şipşak.',
          action: 'Sonuçları gör',
          onTap: onOpenGroups,
          highlight: true,
          crown: true,
        );
    }
  }
}

class _DoneCard extends StatelessWidget {
  const _DoneCard({
    required this.title,
    required this.text,
    required this.action,
    required this.onTap,
    this.highlight = false,
    this.crown = false,
  });

  final String title;
  final String text;
  final String action;
  final VoidCallback onTap;
  final bool highlight;
  final bool crown;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: C.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: app.groups.isEmpty ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: highlight ? C.flash : Colors.transparent, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: C.flash, shape: BoxShape.circle),
                    child: crown ? const CrownIcon(size: 20) : const Icon(Icons.check, color: C.ink, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: display(22))),
                ],
              ),
              const SizedBox(height: 10),
              Text(text, style: body(14, color: C.muted)),
              if (app.groups.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(action, style: body(14, color: C.flash, weight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, color: C.flash, size: 18),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, required this.onTap});

  final Group group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: C.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              AvatarStack(members: group.members, max: 3),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(16, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${group.size} kişi · kod ${group.code}', style: body(13, color: C.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: C.dim),
            ],
          ),
        ),
      ),
    );
  }
}
