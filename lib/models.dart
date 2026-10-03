import 'dart:typed_data';

class Group {
  Group({
    required this.id,
    required this.name,
    required this.code,
    required this.ownerId,
    required this.members,
  });

  final String id;
  final String name;
  final String code;
  final String ownerId;

  /// uid -> görünen ad
  final Map<String, String> members;

  int get size => members.length;
}

class Post {
  Post({
    required this.uid,
    required this.name,
    required this.createdAt,
    required this.late,
    this.bytes,
    this.demoScene,
  });

  final String uid;
  final String name;

  /// Gerçek zaman damgası (epoch ms).
  final int createdAt;
  final bool late;

  /// JPEG fotoğraf.
  final Uint8List? bytes;

  /// Demo modundaki çizim sahnesi.
  final int? demoScene;
}

class Tally {
  Tally(this.post, this.votes);
  final Post post;
  final int votes;
}

/// Oyları sayar. Kendine verilen oylar sayılmaz. Eşitlikte önce çeken kazanır.
List<Tally> tallyVotes(List<Post> posts, Map<String, String> votes) {
  final counts = <String, int>{};
  votes.forEach((voter, target) {
    if (voter == target) return;
    counts[target] = (counts[target] ?? 0) + 1;
  });
  final list = [for (final p in posts) Tally(p, counts[p.uid] ?? 0)];
  list.sort((a, b) {
    final byVotes = b.votes.compareTo(a.votes);
    if (byVotes != 0) return byVotes;
    return a.post.createdAt.compareTo(b.post.createdAt);
  });
  return list;
}
