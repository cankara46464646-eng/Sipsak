/// Günün Şipşak saati, teması ve evreleri.
///
/// Her telefon aynı günün Şipşak anını tarihten aynı şekilde hesaplar.
/// Böylece sunucuya gerek kalmadan Türkiye'deki herkese aynı anda
/// bildirim gider. Tüm saatler Türkiye saatidir (UTC+3, yaz saati yok).
library;

enum Phase { waiting, shooting, late, voting, results }

/// Türkiye duvar saatini, alanları o saate eşit bir UTC DateTime olarak döner.
DateTime trNow() => DateTime.now().toUtc().add(const Duration(hours: 3));

/// Gerçek bir zaman damgasını (epoch ms) Türkiye duvar saatine çevirir.
DateTime trFromEpoch(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true)
    .add(const Duration(hours: 3));

String _two(int n) => n.toString().padLeft(2, '0');

String dayKeyOf(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

String hhmm(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

/// Geri sayım metni: 1 saatten azsa "mm:ss", fazlaysa "s:mm:ss".
String countdownText(Duration d) {
  if (d.isNegative) return '00:00';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  if (h > 0) return '$h:${_two(m)}:${_two(s)}';
  return '${_two(m)}:${_two(s)}';
}

const List<String> kMonths = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

const List<String> kWeekdays = [
  'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar',
];

String trDate(DateTime d) => '${d.day} ${kMonths[d.month - 1]} ${kWeekdays[d.weekday - 1]}';

String trShortDate(DateTime d) => '${d.day} ${kMonths[d.month - 1]}';

/// 32 bit FNV-1a: her cihazda aynı sonucu verir.
int fnv32(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

const List<String> kThemes = [
  'Pencerenden ne görünüyor?',
  'Şu an önündeki yemek',
  'En komik suratın',
  'Kırmızı bir şey bul',
  'Ayakkabıların',
  'Şu an elinde ne var?',
  'Gökyüzü',
  'En sevdiğin köşe',
  'Bir hayvan',
  'Masanın üstü',
  'Yolda gördüğün en tuhaf şey',
  'Çay ya da kahve',
  'Gölgen',
  'Bir tabela',
  'Yeşil bir şey',
  'Ellerin',
  'Buzdolabının içi',
  'Bugünkü kombinin',
  'Bir kapı',
  'Çantanın içi',
  'Yukarı bak',
  'Aşağı bak',
  'Bir çiçek',
  'Etrafındaki en eski şey',
  'Bir merdiven',
  'Yuvarlak bir şey',
  'Sokağından bir kare',
  'Bir araç',
  'Işık',
  'En dağınık yer',
  'Bir yansıma',
  'Sarı bir şey',
  'Mavi bir şey',
  'Saat kaç?',
  'Suyla ilgili bir şey',
  'Bir desen',
  'Doğadan bir parça',
  'Bugünün manzarası',
  'Bir kitap ya da defter',
  'Tatlı bir şey',
  'Bir anahtar',
  'Şu an dinlediğin şey',
  'Bir sandalye',
  'En sevdiğin eşya',
  'Bir pencere',
  'Kafanın üstündeki tavan',
  'Bir bitki',
  'Akşam yemeğin',
  'Bir harf bul',
  'Arka planı ilginç bir selfie',
];

class DaySchedule {
  DaySchedule._(this.day, this.moment, this.theme);

  /// Günün başlangıcı (Türkiye saati, UTC alanlarıyla).
  final DateTime day;

  /// Şipşak anı: 10:00 ile 17:59 arasında, tarihten hesaplanır.
  final DateTime moment;
  final String theme;

  factory DaySchedule.forDay(DateTime anyTime) {
    final day = DateTime.utc(anyTime.year, anyTime.month, anyTime.day);
    final key = dayKeyOf(day);
    final minutes = 10 * 60 + fnv32('sipsak-an-$key') % (8 * 60);
    final moment = day.add(Duration(minutes: minutes));
    final idx = day.difference(DateTime.utc(2026, 1, 1)).inDays;
    final n = kThemes.length;
    final theme = kThemes[((idx % n) + n) % n];
    return DaySchedule._(day, moment, theme);
  }

  static DaySchedule today() => DaySchedule.forDay(trNow());

  String get key => dayKeyOf(day);
  DateTime get shootEnd => moment.add(const Duration(hours: 1));
  DateTime get votingStart => day.add(const Duration(hours: 20));
  DateTime get resultsAt => day.add(const Duration(hours: 21));

  Phase phaseAt(DateTime t) {
    if (t.isBefore(moment)) return Phase.waiting;
    if (t.isBefore(shootEnd)) return Phase.shooting;
    if (t.isBefore(votingStart)) return Phase.late;
    if (t.isBefore(resultsAt)) return Phase.voting;
    return Phase.results;
  }
}

String phaseLabel(Phase p) {
  switch (p) {
    case Phase.waiting:
      return 'Bekleniyor';
    case Phase.shooting:
      return 'Şipşak anı';
    case Phase.late:
      return 'Geç çekim';
    case Phase.voting:
      return 'Oylama';
    case Phase.results:
      return 'Sonuçlar';
  }
}
