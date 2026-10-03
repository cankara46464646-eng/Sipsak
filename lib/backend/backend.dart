import 'dart:typed_data';

import '../models.dart';

class BackendException implements Exception {
  BackendException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Uygulamanın konuştuğu sunucu. Demo ve Firebase olmak üzere iki uygulaması var.
abstract class Backend {
  bool get isDemo;

  /// Kullanıcıyı açar ya da var olanı döner. Kullanıcı kimliğini (uid) döner.
  Future<String> signIn(String name);

  Future<List<Group>> loadGroups(String uid);

  Future<Group> createGroup(String uid, String myName, String groupName);

  /// Kod yanlışsa null döner.
  Future<Group?> joinGroup(String uid, String myName, String code);

  Future<void> leaveGroup(String uid, Group group);

  Future<List<Post>> loadPosts(String groupId, String dayKey);

  Future<void> submitPost({
    required String uid,
    required String name,
    required List<String> groupIds,
    required String dayKey,
    required Uint8List jpeg,
    required bool late,
  });

  /// oy veren uid -> oy verilen uid
  Future<Map<String, String>> loadVotes(String groupId, String dayKey);

  Future<void> vote(String groupId, String dayKey, String voterId, String targetId);

  Future<void> report(String groupId, String dayKey, String postUid, String reporterUid);
}
