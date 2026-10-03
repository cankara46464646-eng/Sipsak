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

  /// Arkadaşlara gönderilen davet mesajındaki indirme linki.
  static const String downloadUrl = String.fromEnvironment(
    'DOWNLOAD_URL',
    defaultValue:
        'https://github.com/cankara46464646-eng/sipsak/releases/latest/download/sipsak.apk',
  );

  static bool get isOnline =>
      firebaseApiKey.isNotEmpty && firebaseProjectId.isNotEmpty;
}
