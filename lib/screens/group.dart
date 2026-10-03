import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../clock.dart';
import '../config.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'moment.dart';
import 'winner_card.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key, required this.group});

  final Group group;

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  List<Post> _posts = [];
  Map<String, String> _votes = {};
  final Set<String> _hidden = {};
  bool _loading = true;
  String? _error;
  String? _selected;
  bool _voting = false;
  Phase? _lastPhase;
  bool _lastPosted = false;
  Timer? _tick;

  Group get g => widget.group;

  @override
  void initState() {
    super.initState();
    _lastPhase = app.phase;
    _lastPosted = app.postedToday;
    _load();
    app.addListener(_onApp);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (app.phase != _lastPhase) {
        _lastPhase = app.phase;
        _load();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    app.removeListener(_onApp);
    _tick?.cancel();
    super.dispose();
  }

  void _onApp() {
    if (!mounted) return;
    if (app.phase != _lastPhase || app.postedToday != _lastPosted) {
      _lastPhase = app.phase;
      _lastPosted = app.postedToday;
      _load();
    } else {
      setState(() {});
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final day = app.today.key;
    try {
      final results = await Future.wait([
        app.backend.loadPosts(g.id, day),
        app.backend.loadVotes(g.id, day),
      ]);
      if (!mounted) return;
      setState(() {
        _posts = results[0] as List<Post>;
        _votes = results[1] as Map<String, String>;
        _selected = _votes[app.uid];
        _loading = false;
      });
      _maybeRecordCrown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Post> get _visiblePosts => _posts.where((p) => !_hidden.contains(p.uid)).toList();

  void _maybeRecordCrown() {
    if (app.phase != Phase.results) return;
    final tally = tallyVotes(_visiblePosts, _votes);
    if (tally.isNotEmpty && tally.first.votes > 0 && tally.first.post.uid == app.uid) {
      app.recordCrown(g.id, app.today.key);
    }
  }

  void _invite() {
    final text = 'Şipşak\'ta grubuma katıl! Her gün bir an, bir saat, tek kazanan.\n\n'
        'Grup: ${g.name}\nKod: ${g.code}\n\nUygulamayı al:\n${AppConfig.getAppText}';
    Share.share(text);
  }

  void _nudge(String name) {
    final s = app.today;
    Share.share('Hadi $name, Şipşak\'ta bir senin karen eksik! Bugünün teması: "${s.theme}"');
  }

  Future<void> _leave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        title: Text('Gruptan çık?', style: display(22)),
        content: Text('${g.name} grubundan çıkacaksın. Kodu bilirsen tekrar katılabilirsin.', style: body(15, color: C.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Vazgeç', style: body(15, color: C.text))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Çık', style: body(15, color: C.danger, weight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await app.leaveGroup(g);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _report(Post p) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Bu kareyi bildir', style: display(22)),
              const SizedBox(height: 8),
              Text('Uygunsuz bir kareyse bildir; senin ekranından hemen kalkar.', style: body(14, color: C.muted)),
              const SizedBox(height: 16),
              BigButton(label: 'Bildir ve gizle', icon: Icons.flag_outlined, onPressed: () => Navigator.pop(ctx, true)),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    setState(() => _hidden.add(p.uid));
    try {
      await app.backend.report(g.id, app.today.key, p.uid, app.uid ?? '');
    } catch (_) {}
  }

  Future<void> _castVote() async {
    final target = _selected;
    if (target == null) return;
    setState(() => _voting = true);
    try {
      await app.backend.vote(g.id, app.today.key, app.uid!, target);
      _votes = {..._votes, app.uid!: target};
      if (mounted) showInfo(context, 'Oyun alındı. Sonuçlar 21:00\'de.');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phase = app.phase;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  RoundIconButton(icon: Icons.chevron_left, tooltip: 'Geri', onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(18, weight: FontWeight.w700)),
                        Text('${g.size} kişi · kod ${g.code}', style: body(13, color: C.muted)),
                      ],
                    ),
                  ),
                  RoundIconButton(icon: Icons.person_add_alt_1_outlined, tooltip: 'Davet et', onPressed: _invite),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: C.text),
                    color: C.surface2,
                    onSelected: (v) {
                      if (v == 'copy') {
                        Clipboard.setData(ClipboardData(text: g.code));
                        showInfo(context, 'Kod kopyalandı: ${g.code}');
                      } else if (v == 'leave') {
                        _leave();
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'copy', child: Text('Kodu kopyala', style: body(15))),
                      PopupMenuItem(value: 'leave', child: Text('Gruptan çık', style: body(15, color: C.danger))),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: C.flash,
                backgroundColor: C.surface,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  children: [
                    _themeCard(phase),
                    const SizedBox(height: 14),
                    ..._body(phase),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(phase),
    );
  }

  Widget _themeCard(Phase phase) {
    final s = app.today;
    final posted = _visiblePosts.length;
    final left = app.timeLeft;
    String hint;
    switch (phase) {
      case Phase.waiting:
        hint = 'Şipşak bekleniyor';
        break;
      case Phase.shooting:
      case Phase.late:
        hint = 'Oylama 20:00\'de';
        break;
      case Phase.voting:
        hint = left == null ? 'Oylama açık' : 'Sonuç ${countdownText(left)}';
        break;
      case Phase.results:
        hint = 'Sonuçlar açıklandı';
        break;
    }
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bugünün teması', style: body(12, color: C.muted, weight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(phase == Phase.waiting ? 'Şipşak gelince açılacak' : s.theme, style: display(21, height: 1.1)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('$posted/${g.size} çekti', style: body(13, weight: FontWeight.w600)),
              const Spacer(),
              const Icon(Icons.schedule, size: 16, color: C.flash),
              const SizedBox(width: 6),
              Text(hint, style: body(13, color: C.flash, weight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _body(Phase phase) {
    if (_loading && _posts.isEmpty) {
      return const [
        Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
      ];
    }
    if (_error != null) {
      return [
        Panel(child: Text('Yüklenemedi: $_error\nAşağı çekip yenile.', style: body(14, color: C.muted))),
      ];
    }
    switch (phase) {
      case Phase.waiting:
        return [
          Panel(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.bolt, color: C.flash, size: 34),
                const SizedBox(height: 8),
                Text('Şipşak gelince kareler burada', style: display(20), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text('Bildirim gelince bir saatin olacak.', style: body(14, color: C.muted), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _membersPanel(),
        ];
      case Phase.shooting:
      case Phase.late:
        if (!app.postedToday) return [_lockedPanel(), const SizedBox(height: 14), _missingRow()];
        return [_missingRow(), const SizedBox(height: 14), _feedGrid()];
      case Phase.voting:
        if (!app.postedToday) {
          return [
            Panel(child: Text('Bugün kare atmadığın için oy veremezsin. Yarın kaçırma!', style: body(14, color: C.muted))),
            const SizedBox(height: 14),
            _feedGrid(),
          ];
        }
        return [_votingInfo(), const SizedBox(height: 12), _voteGrid()];
      case Phase.results:
        return _results();
    }
  }

  Widget _membersPanel() {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Grup', style: body(13, color: C.muted, weight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final e in g.members.entries)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Avatar(name: e.value, seed: e.key, size: 28),
                    const SizedBox(width: 6),
                    Text(e.key == app.uid ? '${e.value} (sen)' : e.value, style: body(14)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lockedPanel() {
    final count = _visiblePosts.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.flash, width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, color: C.flash, size: 32),
          const SizedBox(height: 10),
          Text(
            count == 0 ? 'İlk çeken sen ol!' : '$count arkadaşın çekti',
            style: display(22),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text('Karelerini görmek için önce sen çek.', style: body(14, color: C.muted), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          BigButton(
            label: 'Şimdi çek',
            icon: Icons.bolt,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MomentScreen())),
          ),
        ],
      ),
    );
  }

  Widget _missingRow() {
    final postedIds = _posts.map((p) => p.uid).toSet();
    final missing = g.members.entries.where((e) => !postedIds.contains(e.key) && e.key != app.uid).toList();
    if (missing.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final e in missing) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4A4A54)),
            ),
            child: Row(
              children: [
                Avatar(name: e.value, seed: e.key, size: 30, faded: true),
                const SizedBox(width: 12),
                Expanded(child: Text('${e.value} henüz çekmedi', style: body(14))),
                TextButton(
                  onPressed: () => _nudge(e.value),
                  style: TextButton.styleFrom(
                    backgroundColor: C.surface2,
                    foregroundColor: C.flash,
                    minimumSize: const Size(64, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Dürt', style: body(14, color: C.flash, weight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _feedGrid() {
    final posts = _visiblePosts;
    if (posts.isEmpty) {
      return Panel(child: Text('Henüz kimse çekmedi.', style: body(14, color: C.muted)));
    }
    final firstUid = posts.first.uid;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.74,
      ),
      itemBuilder: (context, i) {
        final p = posts[i];
        final mine = p.uid == app.uid;
        return GestureDetector(
          onTap: () => _openPhoto(p, mine ? 'Sen' : p.name),
          onLongPress: mine ? null : () => _report(p),
          child: Stack(
            children: [
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, box) => Polaroid(
                    padding: 8,
                    photoHeight: box.maxHeight - 44,
                    caption: mine ? 'Sen' : p.name,
                    trailing: hhmm(trFromEpoch(p.createdAt)),
                    child: PostPhoto(p),
                  ),
                ),
              ),
              if (p.uid == firstUid)
                const Positioned(top: 14, left: 14, child: Pill('İlk çeken', bg: C.flash, fg: C.ink)),
              if (p.late)
                const Positioned(top: 14, right: 14, child: Pill('Geç', bg: C.ink, fg: C.text)),
            ],
          ),
        );
      },
    );
  }

  void _openPhoto(Post p, String title) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: C.text,
          title: Text(title, style: body(17, weight: FontWeight.w700)),
        ),
        body: Center(
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: InteractiveViewer(child: PostPhoto(p)),
          ),
        ),
      ),
    ));
  }

  Widget _votingInfo() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const [
        Pill('İsimler gizli', icon: Icons.visibility_off_outlined),
        Pill('1 oy hakkın var'),
        Pill('Sonuç 21:00', icon: Icons.schedule, fg: C.flash),
      ],
    );
  }

  /// Oylamada kareler isimsiz ve herkes için aynı karışık sırada.
  List<Post> get _shuffled {
    final list = _visiblePosts.toList();
    final seed = app.today.key + g.id;
    list.sort((a, b) => fnv32(seed + a.uid).compareTo(fnv32(seed + b.uid)));
    return list;
  }

  Widget _voteGrid() {
    final posts = _shuffled;
    if (posts.length < 2) {
      return Panel(child: Text('Oylama için en az 2 kare lazım. Arkadaşlarını dürt!', style: body(14, color: C.muted)));
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, i) {
        final p = posts[i];
        final mine = p.uid == app.uid;
        final selected = _selected == p.uid;
        return GestureDetector(
          onTap: mine ? null : () => setState(() => _selected = p.uid),
          onLongPress: mine ? null : () => _report(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: selected ? C.flash : (mine ? C.surface2 : Colors.transparent), width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(opacity: mine ? 0.4 : 1, child: PostPhoto(p)),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Color(0xCC0E0E10), shape: BoxShape.circle),
                      child: Text('${i + 1}', style: body(13, weight: FontWeight.w700, height: 1)),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(color: C.flash, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: C.ink, size: 20),
                      ),
                    ),
                  if (mine)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        color: const Color(0xE00E0E10),
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                        child: Text('Senin karen', textAlign: TextAlign.center, style: body(12, weight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _results() {
    final posts = _visiblePosts;
    if (posts.isEmpty) {
      return [Panel(child: Text('Bugün bu grupta kimse çekmedi.', style: body(14, color: C.muted)))];
    }
    final tally = tallyVotes(posts, _votes);
    final top = tally.first;
    final noVotes = top.votes == 0;
    final iWon = !noVotes && top.post.uid == app.uid;
    final winnerName = top.post.uid == app.uid ? 'Sen' : top.post.name;
    return [
      Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: C.flash, shape: BoxShape.circle),
              child: const CrownIcon(size: 30),
            ),
            const SizedBox(height: 10),
            Text('GÜNÜN KARESİ', style: body(13, color: C.flash, weight: FontWeight.w700, spacing: 2)),
            const SizedBox(height: 2),
            Text(noVotes ? 'Kimse oy vermedi' : (iWon ? 'Sensin!' : winnerName), style: display(44, spacing: -1.5)),
            const SizedBox(height: 16),
            Polaroid(
              width: 230,
              padding: 12,
              photoHeight: 250,
              angle: -0.03,
              caption: winnerName,
              trailing: '${top.votes}/${_votes.length} oy',
              child: PostPhoto(top.post),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      if (iWon) ...[
        BigButton(
          label: 'Hikâyende paylaş',
          icon: Icons.ios_share,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => WinnerCardScreen(
              post: top.post,
              groupName: g.name,
              votes: top.votes,
              people: g.size,
              theme: app.today.theme,
            ),
          )),
        ),
        const SizedBox(height: 16),
      ],
      Text('Sıralama', style: body(13, color: C.muted, weight: FontWeight.w600)),
      const SizedBox(height: 8),
      for (var i = 0; i < tally.length; i++) ...[
        Panel(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(width: 44, height: 44, child: PostPhoto(tally[i].post)),
              ),
              const SizedBox(width: 12),
              Text('${i + 1}.', style: display(18, color: i == 0 ? C.flash : C.text)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tally[i].post.uid == app.uid ? 'Sen' : tally[i].post.name,
                  style: body(15, weight: FontWeight.w700),
                ),
              ),
              Text('${tally[i].votes} oy', style: mono(14, color: C.muted)),
              const SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 8),
      Center(child: Text('Yarın yeni Şipşak. Bildirimleri açık tut.', style: body(13, color: C.muted))),
    ];
  }

  Widget? _bottomBar(Phase phase) {
    if (phase != Phase.voting || !app.postedToday || _loading) return null;
    final myVote = _votes[app.uid];
    final changed = _selected != null && _selected != myVote;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: const BoxDecoration(
          color: C.ink,
          border: Border(top: BorderSide(color: C.surface2)),
        ),
        child: BigButton(
          label: _selected == null
              ? 'Beğendiğin kareye dokun'
              : (myVote == null ? 'Oyumu ver' : (changed ? 'Oyumu değiştir' : 'Oyun verildi')),
          icon: myVote != null && !changed ? Icons.check : null,
          busy: _voting,
          onPressed: changed ? _castVote : null,
        ),
      ),
    );
  }
}
