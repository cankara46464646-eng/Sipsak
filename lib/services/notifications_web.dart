/// Web sürümünde telefon içi zamanlanmış bildirim yok. Şipşak bildirimi
/// web'e sunucudan "push" ile gelecek (Firebase bağlanınca).
class Notifs {
  static const bool supported = false;

  static Future<void> init() async {}

  static Future<bool> requestPermission() async => false;

  static Future<void> showTest() async {}

  static Future<void> scheduleWeek() async {}
}
