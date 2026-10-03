import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backend/backend.dart';
import '../backend/demo_backend.dart';
import '../backend/firebase_backend.dart';
import '../clock.dart';
import '../config.dart';
import '../models.dart';

/// Uygulamanın tek durum kaynağı.
class AppState extends ChangeNotifier {
  late SharedPreferences prefs;
  late Backend backend;

  String? uid;
  String name = '';
  List<Group> groups = [];
  bool loadingGroups = false;
  String? groupsError;

  /// Demo modunda zamanı elle ileri sarmak için.
  Phase? demoPhase;

  bool get isDemo => backend.isDemo;

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    backend = AppConfig.isOnline ? FirebaseBackend(prefs) : DemoBackend();
    name = prefs.getString('name') ?? '';
    if (backend.isDemo) {
      demoPhase = Phase.shooting;
      // Demo fotoğrafları bellekte tutulur; uygulama yeniden açılınca gün sıfırlanır.
      final days = postedDays..remove(DaySchedule.today().key);
      await prefs.setStringList('posted_days', days.toList());
      if (name.isNotEmpty) uid = await backend.signIn(name);
    } else {
      uid = prefs.getString('fb_uid');
    }
  }

  bool get onboarded => name.isNotEmpty && uid != null;

  Future<void> onboard(String newName) async {
    final clean = newName.trim();
    uid = await backend.signIn(clean);
    name = clean;
    await prefs.setString('name', clean);
    notifyListeners();
  }

  Future<void> rename(String newName) => onboard(newName);

  // ---------- Zaman ----------

  DaySchedule get today => DaySchedule.today();

  Phase get phase => demoPhase ?? today.phaseAt(trNow());

  /// Demo modunda bir sonraki evreye geçer.
  void nextDemoPhase() {
    final next = Phase.values[(phase.index + 1) % Phase.values.length];
    demoPhase = next;
    notifyListeners();
  }

  /// Bir sonraki evreye kalan süre (demo modunda null).
  Duration? get timeLeft {
    if (demoPhase != null) return null;
    final s = today;
    final now = trNow();
    switch (phase) {
      case Phase.waiting:
        return null;
      case Phase.shooting:
        return s.shootEnd.difference(now);
      case Phase.late:
        return s.votingStart.difference(now);
      case Phase.voting:
        return s.resultsAt.difference(now);
      case Phase.results:
        return null;
    }
  }

  // ---------- Seri ve taçlar (cihazda tutulur) ----------

  Set<String> get postedDays => (prefs.getStringList('posted_days') ?? const <String>[]).toSet();

  bool get postedToday => postedDays.contains(today.key);

  bool get canPost => (phase == Phase.shooting || phase == Phase.late) && !postedToday;

  int get streak {
    final days = postedDays;
    var d = today.day;
    if (!days.contains(dayKeyOf(d))) d = d.subtract(const Duration(days: 1));
    var count = 0;
    while (days.contains(dayKeyOf(d))) {
      count++;
      d = d.subtract(const Duration(days: 1));
    }
    return count;
  }

  List<String> get _crowns => prefs.getStringList('crowns') ?? const <String>[];

  int get crownsThisMonth {
    final prefix = dayKeyOf(today.day).substring(0, 7);
    return _crowns.where((c) => c.startsWith(prefix)).length;
  }

  int get crownsTotal => _crowns.length;

  Future<void> recordCrown(String groupId, String dayKey) async {
    final entry = '$dayKey|$groupId';
    final list = _crowns.toList();
    if (list.contains(entry)) return;
    list.add(entry);
    await prefs.setStringList('crowns', list);
    notifyListeners();
  }

  // ---------- Gruplar ----------

  Future<void> refreshGroups() async {
    final id = uid;
    if (id == null) return;
    loadingGroups = true;
    groupsError = null;
    notifyListeners();
    try {
      groups = await backend.loadGroups(id);
    } catch (e) {
      groupsError = e.toString();
    } finally {
      loadingGroups = false;
      notifyListeners();
    }
  }

  Future<Group> createGroup(String groupName) async {
    final g = await backend.createGroup(uid!, name, groupName.trim());
    groups = [...groups, g];
    notifyListeners();
    return g;
  }

  Future<Group?> joinGroup(String code) async {
    final g = await backend.joinGroup(uid!, name, code);
    if (g != null && !groups.any((x) => x.id == g.id)) {
      groups = [...groups, g];
      notifyListeners();
    }
    return g;
  }

  Future<void> leaveGroup(Group g) async {
    await backend.leaveGroup(uid!, g);
    groups = groups.where((x) => x.id != g.id).toList();
    notifyListeners();
  }

  // ---------- Çekim ----------

  Future<void> submitPhoto(Uint8List jpeg) async {
    final s = today;
    final isLate = phase == Phase.late;
    await backend.submitPost(
      uid: uid!,
      name: name,
      groupIds: groups.map((g) => g.id).toList(),
      dayKey: s.key,
      jpeg: jpeg,
      late: isLate,
    );
    final days = postedDays..add(s.key);
    await prefs.setStringList('posted_days', days.toList());
    notifyListeners();
  }

  /// Sadece demo: bugünkü çekimi ve oyu siler, baştan denemek için.
  Future<void> resetDemoDay() async {
    final b = backend;
    if (b is! DemoBackend) return;
    b.resetDay(today.key);
    final days = postedDays..remove(today.key);
    await prefs.setStringList('posted_days', days.toList());
    final crowns = _crowns.where((c) => !c.startsWith(today.key)).toList();
    await prefs.setStringList('crowns', crowns);
    demoPhase = Phase.shooting;
    notifyListeners();
  }
}

final AppState app = AppState();
