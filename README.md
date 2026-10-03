# Şipşak

Günde bir an. Bir saat. Tek kazanan.

Her gün 10:00 ile 18:00 arasında rastgele bir anda Türkiye'deki herkese aynı anda
"Şipşak!" bildirimi gelir. Bir saat içinde günün temasına uygun bir kare çekersin
(galeri yok, sadece canlı çekim). 20:00'de grubun isimsiz oylama yapar, 21:00'de
**Günün Karesi** belli olur.

## İndir

- **iPhone (ve her tarayıcı):** https://cankara46464646-eng.github.io/Sipsak/
  Safari'de aç → alttaki **Paylaş** → **Ana Ekrana Ekle**. Uygulama gibi tam ekran açılır.
- **Android:** **[sipsak.apk](../../releases/latest/download/sipsak.apk)**
  Linke dokun, indir, aç ve kur. "Bilinmeyen kaynak" izni isterse ver.

## Modlar

- **Demo modu:** Sunucu ayarı yoksa uygulama sahte arkadaşlarla çalışır. Ana sayfadaki
  "Zamanı ileri sar" ile tüm günü (çekim, oylama, sonuç) birkaç dakikada denersin.
- **Çevrimiçi mod:** Firebase projesi bağlanınca gerçek gruplar, gerçek arkadaşlar.

## Çevrimiçi modu açmak (Firebase, ücretsiz)

1. console.firebase.google.com → **Proje ekle** → isim: `sipsak` (Analytics kapalı olabilir)
2. **Build → Authentication → Get started → Sign-in method → Anonymous → Enable**
3. **Build → Firestore Database → Create database** → konum `eur3` ya da yakın bir yer → production mode
4. Firestore → **Rules** sekmesine bu depodaki `firestore.rules` dosyasını yapıştır → **Publish**
5. ⚙️ **Project settings → General**: *Project ID* ve *Web API Key* değerlerini al
6. Bu depoda **Settings → Secrets and variables → Actions → Variables** sekmesinde iki değişken ekle:
   - `FIREBASE_API_KEY` = Web API Key
   - `FIREBASE_PROJECT_ID` = Project ID
7. **Actions → APK → Run workflow** ile yeniden derle. Yeni APK çevrimiçi modda açılır.

Fotoğraflar küçültülüp doğrudan Firestore'a yazılır; ücretsiz Spark planı yeterlidir,
Storage ya da kredi kartı gerekmez.

## Teknik

- Flutter 3.29 (Android). `android/` klasörü derlemede `flutter create` ile üretilir,
  `tool/patch_android.py` izinleri, ikonları ve imzayı ayarlar.
- Sunucu: Firebase anonim giriş + Firestore, REST üzerinden (`lib/backend/`).
- Şipşak saati ve tema tarihten hesaplanır (`lib/clock.dart`), bildirimler telefonda kurulur.
- `tool/keys/sipsak-test.jks` yalnızca test imzasıdır. Play Store'a çıkmadan önce
  gizli tutulan yeni bir anahtarla değiştirilmeli.
