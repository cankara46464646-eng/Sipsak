/// Uygulama ayarları.
///
/// [firebaseApiKey] ve [firebaseProjectId] boşsa uygulama "Demo modu"nda
/// çalışır: sahte arkadaşlarla tek telefonda denenebilir. İkisi de
/// doldurulunca gerçek çevrimiçi moda geçer.
class AppConfig {
  static const String firebaseApiKey =
      String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
  static const String firebaseProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');

  /// Android APK indirme linki.
  static const String downloadUrl = String.fromEnvironment(
    'DOWNLOAD_URL',
    defaultValue:
        'https://github.com/cankara46464646-eng/Sipsak/releases/latest/download/sipsak.apk',
  );

  /// iPhone ve tarayıcı için web uygulaması linki.
  static const String webUrl = String.fromEnvironment(
    'WEB_URL',
    defaultValue: 'https://cankara46464646-eng.github.io/Sipsak/',
  );

  static bool get isOnline =>
      firebaseApiKey.isNotEmpty && firebaseProjectId.isNotEmpty;

  /// Davet mesajlarının sonuna eklenen indirme bilgisi.
  static String get getAppText =>
      'iPhone: $webUrl (Safari\'de aç, Paylaş > Ana Ekrana Ekle)\nAndroid: $downloadUrl';
}
