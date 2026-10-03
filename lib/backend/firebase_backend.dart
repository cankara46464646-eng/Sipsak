import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models.dart';
import 'backend.dart';
import 'firestore_rest.dart';

/// Firebase (Firestore + anonim giriş) üzerinden çalışan gerçek sunucu.
///
/// Fotoğraflar küçültülmüş JPEG olarak doğrudan Firestore belgesine yazılır;
/// bu sayede ücretsiz Spark planı yeterli olur, Storage gerekmez.
class FirebaseBackend implements Backend {
  FirebaseBackend(this.prefs)
      : auth = FirebaseAuthRest(AppConfig.firebaseApiKey, prefs) {
    db = FirestoreRest(AppConfig.firebaseProjectId, auth);
  }

  final SharedPreferences prefs;
  final FirebaseAuthRest auth;
  late final FirestoreRest db;
  final Random _rnd = Random.secure();

  @override
  bool get isDemo => false;

  int get _now => DateTime.now().millisecondsSinceEpoch;

  String _randId(int len) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(len, (_) => chars[_rnd.nextInt(chars.length)]).join();
  }

  String _randCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_rnd.nextInt(chars.length)]).join();
  }

  Group _group(Map<String, dynamic> m) {
    final raw = (m['members'] as Map?) ?? const <String, dynamic>{};
    final members = <String, String>{};
    raw.forEach((k, v) => members[k.toString()] = v.toString());
    return Group(
      id: m['_id'] as String,
      name: (m['name'] as String?) ?? 'Grup',
      code: (m['code'] as String?) ?? '',
      ownerId: (m['ownerId'] as String?) ?? '',
      members: members,
    );
  }

  Future<List<String>> _userGroupIds(String uid) async {
    final u = await db.get('users/$uid');
    final raw = (u?['groups'] as List?) ?? const [];
    return [for (final x in raw) x.toString()];
  }

  Future<void> _setUserGroupIds(String uid, List<String> ids) =>
      db.set('users/$uid', {'groups': ids}, mask: ['groups']);

  @override
  Future<String> signIn(String name) async {
    final uid = await auth.ensureSignedIn();
    await db.set('users/$uid', {'name': name, 'updatedAt': _now}, mask: ['name', 'updatedAt']);
    return uid;
  }

  @override
  Future<List<Group>> loadGroups(String uid) async {
    final ids = await _userGroupIds(uid);
    final groups = await Future.wait(ids.map((id) => db.get('groups/$id')));
    final out = <Group>[];
    for (final g in groups) {
      if (g == null) continue;
      final grp = _group(g);
      if (grp.members.containsKey(uid)) out.add(grp);
    }
    return out;
  }

  @override
  Future<Group> createGroup(String uid, String myName, String groupName) async {
    final id = _randId(20);
    var code = _randCode();
    for (var i = 0; i < 5; i++) {
      final taken = await db.queryEqual('groups', 'code', code);
      if (taken.isEmpty) break;
      code = _randCode();
    }
    await db.set('groups/$id', {
      'name': groupName,
      'code': code,
      'ownerId': uid,
      'createdAt': _now,
      'members': {uid: myName},
    });
    final ids = await _userGroupIds(uid);
    if (!ids.contains(id)) ids.add(id);
    await _setUserGroupIds(uid, ids);
    return Group(id: id, name: groupName, code: code, ownerId: uid, members: {uid: myName});
  }

  @override
  Future<Group?> joinGroup(String uid, String myName, String code) async {
    final res = await db.queryEqual('groups', 'code', code.trim().toUpperCase());
    if (res.isEmpty) return null;
    final g = _group(res.first);
    await db.set(
      'groups/${g.id}',
      {
        'members': {uid: myName},
      },
      mask: ['members.${quoteField(uid)}'],
    );
    final ids = await _userGroupIds(uid);
    if (!ids.contains(g.id)) ids.add(g.id);
    await _setUserGroupIds(uid, ids);
    g.members[uid] = myName;
    return g;
  }

  @override
  Future<void> leaveGroup(String uid, Group group) async {
    await db.set('groups/${group.id}', {}, mask: ['members.${quoteField(uid)}']);
    final ids = await _userGroupIds(uid);
    ids.remove(group.id);
    await _setUserGroupIds(uid, ids);
  }

  @override
  Future<List<Post>> loadPosts(String groupId, String dayKey) async {
    final docs = await db.list('groups/$groupId/days/$dayKey/posts');
    final out = <Post>[];
    for (final m in docs) {
      Uint8List? bytes;
      final photo = m['photo'];
      if (photo is String && photo.isNotEmpty) {
        try {
          bytes = base64Decode(photo);
        } catch (_) {
          bytes = null;
        }
      }
      out.add(Post(
        uid: m['_id'] as String,
        name: (m['name'] as String?) ?? '?',
        createdAt: (m['createdAt'] as int?) ?? 0,
        late: (m['late'] as bool?) ?? false,
        bytes: bytes,
      ));
    }
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
    final data = {
      'name': name,
      'createdAt': _now,
      'late': late,
      'photo': base64Encode(jpeg),
    };
    await Future.wait(
      groupIds.map((gid) => db.set('groups/$gid/days/$dayKey/posts/$uid', data)),
    );
  }

  @override
  Future<Map<String, String>> loadVotes(String groupId, String dayKey) async {
    final docs = await db.list('groups/$groupId/days/$dayKey/votes');
    final out = <String, String>{};
    for (final m in docs) {
      final target = m['target'];
      if (target is String) out[m['_id'] as String] = target;
    }
    return out;
  }

  @override
  Future<void> vote(String groupId, String dayKey, String voterId, String targetId) =>
      db.set('groups/$groupId/days/$dayKey/votes/$voterId', {'target': targetId, 'at': _now});

  @override
  Future<void> report(String groupId, String dayKey, String postUid, String reporterUid) =>
      db.set('reports/${_randId(20)}', {
        'groupId': groupId,
        'day': dayKey,
        'postUid': postUid,
        'reporter': reporterUid,
        'at': _now,
      });
}
