import 'dart:math';
import 'dart:typed_data';

import '../clock.dart';
import '../models.dart';
import 'backend.dart';

/// Sunucusuz deneme modu: sahte arkadaşlarla tek telefonda tüm akış denenir.
class DemoBackend implements Backend {
  DemoBackend() {
    _groups['demo'] = Group(
      id: 'demo',
      name: 'Demo Ekibi',
      code: 'DEMO42',
      ownerId: 'z',
      members: {
        'z': 'Zeynep',
        'e': 'Emre',
        'b': 'Burak',
        'l': 'Elif',
        'd': 'Deniz',
        'm': 'Mert',
      },
    );
  }

  static const String meId = 'me';

  final Map<String, Group> _groups = {};

  /// gün -> grup -> benim gönderim
  final Map<String, Map<String, Post>> _myPosts = {};

  /// 'grup|gün' -> benim oyum
  final Map<String, String> _myVotes = {};

  String _myName = 'Sen';
  final Random _rnd = Random();

  // (uid, isim, sahne, Şipşak anından kaç dakika sonra çekti)
  static const List<List<Object>> _friends = [
    ['z', 'Zeynep', 2, 3],
    ['e', 'Emre', 1, 11],
    ['b', 'Burak', 3, 27],
    ['l', 'Elif', 4, 44],
    ['d', 'Deniz', 5, 71],
  ];

  @override
  bool get isDemo => true;

  @override
  Future<String> signIn(String name) async {
    _myName = name;
    final demo = _groups['demo'];
    if (demo != null) demo.members[meId] = name;
    return meId;
  }

  @override
  Future<List<Group>> loadGroups(String uid) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _groups.values.where((g) => g.members.containsKey(uid)).toList();
  }

  @override
  Future<Group> createGroup(String uid, String myName, String groupName) async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code = List.generate(6, (_) => chars[_rnd.nextInt(chars.length)]).join();
    final id = 'g${DateTime.now().millisecondsSinceEpoch}';
    final g = Group(id: id, name: groupName, code: code, ownerId: uid, members: {uid: myName});
    _groups[id] = g;
    return g;
  }

  @override
  Future<Group?> joinGroup(String uid, String myName, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    for (final g in _groups.values) {
      if (g.code == code.trim().toUpperCase()) {
        g.members[uid] = myName;
        return g;
      }
    }
    return null;
  }

  @override
  Future<void> leaveGroup(String uid, Group group) async {
    _groups[group.id]?.members.remove(uid);
  }

  @override
  Future<List<Post>> loadPosts(String groupId, String dayKey) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final out = <Post>[];
    if (groupId == 'demo') {
      final s = DaySchedule.today();
      // Türkiye duvar saati -> gerçek zaman damgası
      final momentEpoch = s.moment.subtract(const Duration(hours: 3)).millisecondsSinceEpoch;
      for (final f in _friends) {
        final minutes = f[3] as int;
        out.add(Post(
          uid: f[0] as String,
          name: f[1] as String,
          createdAt: momentEpoch + minutes * 60000,
          late: minutes > 60,
          demoScene: f[2] as int,
        ));
      }
    }
    final mine = _myPosts[dayKey]?[groupId];
    if (mine != null) out.add(mine);
    out.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return out;
  }

  @override
  Future<void> submitPost({
    required String uid,
    required String name,
    required List<String> groupIds,
    required String dayKey,
    required Uint8List jpeg,
    required bool late,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Demo'da zaman simüle edildiği için senin karen Şipşak anından
    // 15 dakika (geç kaldıysan 75 dakika) sonra çekilmiş sayılır.
    final s = DaySchedule.today();
    final momentEpoch = s.moment.subtract(const Duration(hours: 3)).millisecondsSinceEpoch;
    final post = Post(
      uid: uid,
      name: name,
      createdAt: momentEpoch + (late ? 75 : 15) * 60000,
      late: late,
      bytes: jpeg,
    );
    final day = _myPosts.putIfAbsent(dayKey, () => {});
    for (final gid in groupIds) {
      day[gid] = post;
    }
  }

  /// Arkadaşların oyları. Sen çektiysen çoğu sana oy verir; demo bu yüzden eğlenceli.
  @override
  Future<Map<String, String>> loadVotes(String groupId, String dayKey) async {
    final out = <String, String>{};
    final mine = _myPosts[dayKey]?[groupId] != null;
    if (groupId == 'demo') {
      out['z'] = mine ? meId : 'e';
      out['e'] = 'z';
      out['b'] = mine ? meId : 'z';
      out['l'] = mine ? meId : 'b';
      out['d'] = mine ? meId : 'z';
    }
    final myVote = _myVotes['$groupId|$dayKey'];
    if (myVote != null) out[meId] = myVote;
    return out;
  }

  @override
  Future<void> vote(String groupId, String dayKey, String voterId, String targetId) async {
    _myVotes['$groupId|$dayKey'] = targetId;
  }

  @override
  Future<void> report(String groupId, String dayKey, String postUid, String reporterUid) async {}

  /// Demo gününü sıfırlar (yeniden çekim için).
  void resetDay(String dayKey) {
    _myPosts.remove(dayKey);
    _myVotes.removeWhere((k, _) => k.endsWith('|$dayKey'));
  }

  String get myName => _myName;
}
