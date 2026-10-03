"""`flutter create` ile üretilen android/ klasörünü Şipşak için ayarlar.

GitHub Actions içinde, `flutter create` sonrasında çalışır:
- uygulama adı, ikonlar ve bildirim ikonu
- izinler (internet, kamera, bildirim) ve zamanlanmış bildirim alıcıları
- core library desugaring (flutter_local_notifications için)
- sabit imza anahtarı (yeni APK eskisinin üstüne kurulabilsin diye)
- R8 kuralları
"""
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ANDROID = ROOT / "android"
APP = ANDROID / "app"
MAIN = APP / "src" / "main"


def fail(msg):
    print(f"[patch_android] HATA: {msg}")
    sys.exit(1)


def sub_once(pattern, repl, text, what, flags=0):
    new, n = re.subn(pattern, repl, text, count=1, flags=flags)
    if n == 0:
        fail(f"bulunamadı: {what}")
    return new


# ---------- ikonlar ----------
res_src = ROOT / "tool" / "res"
for d in res_src.iterdir():
    target = MAIN / "res" / d.name
    target.mkdir(parents=True, exist_ok=True)
    for f in d.iterdir():
        shutil.copy2(f, target / f.name)
raw_dir = MAIN / "res" / "raw"
raw_dir.mkdir(parents=True, exist_ok=True)
(raw_dir / "keep.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<resources xmlns:tools="http://schemas.android.com/tools" '
    'tools:keep="@drawable/ic_stat_sipsak,@mipmap/ic_launcher_round" />\n',
    encoding="utf-8",
)
print("[patch_android] ikonlar kopyalandı")

# ---------- AndroidManifest.xml ----------
manifest_path = MAIN / "AndroidManifest.xml"
m = manifest_path.read_text(encoding="utf-8")

m = sub_once(r'android:label="[^"]*"', 'android:label="Şipşak"', m, "android:label")
if "android:roundIcon" not in m:
    m = sub_once(
        r'android:icon="@mipmap/ic_launcher"',
        'android:icon="@mipmap/ic_launcher"\n        android:roundIcon="@mipmap/ic_launcher_round"',
        m,
        "android:icon",
    )

permissions = """
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-feature android:name="android.hardware.camera" android:required="false" />
"""
if "android.permission.INTERNET" not in m:
    m = sub_once(r"(<manifest[^>]*>)", lambda mo: mo.group(1) + permissions, m, "<manifest>")

receivers = """
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
"""
if "ScheduledNotificationReceiver" not in m:
    m = sub_once(r"(\s*</application>)", lambda mo: receivers + mo.group(1), m, "</application>")

manifest_path.write_text(m, encoding="utf-8")
print("[patch_android] manifest ayarlandı")

# ---------- R8 kuralları ----------
(APP / "proguard-rules.pro").write_text(
    """-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn com.google.android.play.core.**
""",
    encoding="utf-8",
)

# ---------- build.gradle(.kts) ----------
kts = APP / "build.gradle.kts"
groovy = APP / "build.gradle"

if kts.exists():
    g = kts.read_text(encoding="utf-8")
    if "isCoreLibraryDesugaringEnabled" not in g:
        g = sub_once(r"compileOptions\s*\{", "compileOptions {\n        isCoreLibraryDesugaringEnabled = true", g, "compileOptions (kts)")
    g = re.sub(r"minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 23", g)
    if "sipsakTest" not in g:
        g = sub_once(
            r"(\n\s*buildTypes\s*\{)",
            lambda mo: """
    signingConfigs {
        create("sipsakTest") {
            storeFile = file("../../tool/keys/sipsak-test.jks")
            storePassword = "sipsak123"
            keyAlias = "sipsak"
            keyPassword = "sipsak123"
        }
    }
""" + mo.group(1),
            g,
            "buildTypes (kts)",
        )
        g = sub_once(
            r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',
            'signingConfig = signingConfigs.getByName("sipsakTest")\n'
            '            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")',
            g,
            "release signingConfig (kts)",
        )
    if "desugar_jdk_libs" not in g:
        g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    kts.write_text(g, encoding="utf-8")
    print("[patch_android] build.gradle.kts ayarlandı")
elif groovy.exists():
    g = groovy.read_text(encoding="utf-8")
    if "coreLibraryDesugaringEnabled" not in g:
        g = sub_once(r"compileOptions\s*\{", "compileOptions {\n        coreLibraryDesugaringEnabled true", g, "compileOptions (groovy)")
    g = re.sub(r"minSdk(Version)?\s*=?\s*flutter\.minSdkVersion", "minSdkVersion 23", g)
    if "sipsakTest" not in g:
        g = sub_once(
            r"(\n\s*buildTypes\s*\{)",
            lambda mo: """
    signingConfigs {
        sipsakTest {
            storeFile file("../../tool/keys/sipsak-test.jks")
            storePassword "sipsak123"
            keyAlias "sipsak"
            keyPassword "sipsak123"
        }
    }
""" + mo.group(1),
            g,
            "buildTypes (groovy)",
        )
        g = sub_once(
            r"signingConfig\s*=?\s*signingConfigs\.debug",
            "signingConfig signingConfigs.sipsakTest\n"
            "            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'",
            g,
            "release signingConfig (groovy)",
        )
    if "desugar_jdk_libs" not in g:
        g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
    groovy.write_text(g, encoding="utf-8")
    print("[patch_android] build.gradle ayarlandı")
else:
    fail("android/app/build.gradle(.kts) yok")

# ---------- Kotlin sürümü ----------
settings = ANDROID / "settings.gradle.kts"
if settings.exists():
    s = settings.read_text(encoding="utf-8")
    s2 = re.sub(r'(id\("org\.jetbrains\.kotlin\.android"\)\s*version\s*")1\.[0-9.]+(")', r"\g<1>2.1.0\2", s)
    if s2 != s:
        settings.write_text(s2, encoding="utf-8")
        print("[patch_android] Kotlin 2.1.0")

print("[patch_android] tamam")
