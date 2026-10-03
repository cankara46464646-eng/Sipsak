import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'backend.dart';

/// Ağ hatalarını anlaşılır bir mesaja çevirir.
Future<http.Response> guardNetwork(Future<http.Response> request) async {
  try {
    return await request.timeout(const Duration(seconds: 30));
  } catch (_) {
    throw BackendException('İnternet bağlantısı yok gibi görünüyor.');
  }
}

/// Firebase anonim girişi, REST üzerinden (yerel Firebase eklentisi gerekmez).
class FirebaseAuthRest {
  FirebaseAuthRest(this.apiKey, this.prefs);

  final String apiKey;
  final SharedPreferences prefs;

  String? _idToken;
  DateTime _expiry = DateTime.fromMillisecondsSinceEpoch(0);

  String? get uid => prefs.getString('fb_uid');

  Future<String> ensureSignedIn() async {
    if (prefs.getString('fb_refresh') == null || uid == null) {
      final r = await guardNetwork(http.post(
        Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'returnSecureToken': true}),
      ));
      if (r.statusCode != 200) {
        throw BackendException('Giriş yapılamadı (${r.statusCode}).');
      }
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      await prefs.setString('fb_uid', j['localId'] as String);
      await prefs.setString('fb_refresh', j['refreshToken'] as String);
      _idToken = j['idToken'] as String;
      _expiry = DateTime.now().add(Duration(seconds: int.parse(j['expiresIn'].toString()) - 60));
    }
    return uid!;
  }

  Future<String> token() async {
    await ensureSignedIn();
    final current = _idToken;
    if (current != null && DateTime.now().isBefore(_expiry)) return current;
    final r = await guardNetwork(http.post(
      Uri.parse('https://securetoken.googleapis.com/v1/token?key=$apiKey'),
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': prefs.getString('fb_refresh') ?? '',
      },
    ));
    if (r.statusCode != 200) {
      throw BackendException('Oturum yenilenemedi (${r.statusCode}).');
    }
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final token = j['id_token'] as String;
    _idToken = token;
    await prefs.setString('fb_refresh', j['refresh_token'] as String);
    _expiry = DateTime.now().add(Duration(seconds: int.parse(j['expires_in'].toString()) - 60));
    return token;
  }
}

/// Cloud Firestore'un REST arayüzü için küçük bir istemci.
class FirestoreRest {
  FirestoreRest(this.projectId, this.auth);

  final String projectId;
  final FirebaseAuthRest auth;

  String get _base =>
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  Future<Map<String, String>> _headers() async => {
        'Authorization': 'Bearer ${await auth.token()}',
        'Content-Type': 'application/json',
      };

  Future<http.Response> _send(Future<http.Response> Function(Map<String, String> h) fn) async {
    final h = await _headers();
    return guardNetwork(fn(h));
  }

  void _check(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    if (r.statusCode == 403) {
      throw BackendException('Sunucu izin vermedi (403). Firestore kurallarını kontrol et.');
    }
    throw BackendException('Sunucu hatası (${r.statusCode}).');
  }

  Future<Map<String, dynamic>?> get(String path) async {
    final r = await _send((h) => http.get(Uri.parse('$_base/$path'), headers: h));
    if (r.statusCode == 404) return null;
    _check(r);
    return decodeDoc(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> list(String collectionPath) async {
    final out = <Map<String, dynamic>>[];
    String? pageToken;
    do {
      final q = pageToken == null
          ? '?pageSize=100'
          : '?pageSize=100&pageToken=${Uri.encodeQueryComponent(pageToken)}';
      final r = await _send((h) => http.get(Uri.parse('$_base/$collectionPath$q'), headers: h));
      if (r.statusCode == 404) return out;
      _check(r);
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      final docs = (j['documents'] as List?) ?? const [];
      for (final d in docs) {
        out.add(decodeDoc(d as Map<String, dynamic>));
      }
      pageToken = j['nextPageToken'] as String?;
    } while (pageToken != null);
    return out;
  }

  /// Belgeyi yazar. [mask] verilirse yalnızca o alanlar değişir;
  /// maskede olup veride olmayan alanlar silinir.
  Future<void> set(String path, Map<String, dynamic> data, {List<String>? mask}) async {
    var url = '$_base/$path';
    if (mask != null && mask.isNotEmpty) {
      url += '?${mask.map((m) => 'updateMask.fieldPaths=${Uri.encodeQueryComponent(m)}').join('&')}';
    }
    final body = jsonEncode({'fields': encodeFields(data)});
    final r = await _send((h) => http.patch(Uri.parse(url), headers: h, body: body));
    _check(r);
  }

  Future<List<Map<String, dynamic>>> queryEqual(
    String collectionId,
    String field,
    Object value, {
    int limit = 1,
  }) async {
    final body = jsonEncode({
      'structuredQuery': {
        'from': [
          {'collectionId': collectionId},
        ],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': field},
            'op': 'EQUAL',
            'value': encodeValue(value),
          },
        },
        'limit': limit,
      },
    });
    final r = await _send((h) => http.post(Uri.parse('$_base:runQuery'), headers: h, body: body));
    _check(r);
    final arr = jsonDecode(r.body) as List;
    final out = <Map<String, dynamic>>[];
    for (final e in arr) {
      final m = e as Map<String, dynamic>;
      final d = m['document'];
      if (d != null) out.add(decodeDoc(d as Map<String, dynamic>));
    }
    return out;
  }
}

/// Firestore alan adlarını yol içinde güvenle kullanmak için ters tırnak.
String quoteField(String name) => '`${name.replaceAll('`', '')}`';

Map<String, dynamic> decodeDoc(Map<String, dynamic> doc) {
  final fields = (doc['fields'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  final out = <String, dynamic>{};
  fields.forEach((k, v) => out[k] = decodeValue(v as Map<String, dynamic>));
  final name = (doc['name'] as String?) ?? '';
  out['_id'] = name.split('/').last;
  return out;
}

dynamic decodeValue(Map<String, dynamic> v) {
  if (v.containsKey('stringValue')) return v['stringValue'] as String;
  if (v.containsKey('integerValue')) return int.parse(v['integerValue'].toString());
  if (v.containsKey('doubleValue')) return (v['doubleValue'] as num).toDouble();
  if (v.containsKey('booleanValue')) return v['booleanValue'] as bool;
  if (v.containsKey('mapValue')) {
    final mv = v['mapValue'] as Map<String, dynamic>;
    final f = (mv['fields'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final out = <String, dynamic>{};
    f.forEach((k, x) => out[k] = decodeValue(x as Map<String, dynamic>));
    return out;
  }
  if (v.containsKey('arrayValue')) {
    final av = v['arrayValue'] as Map<String, dynamic>;
    final vals = (av['values'] as List?) ?? const [];
    return [for (final x in vals) decodeValue(x as Map<String, dynamic>)];
  }
  if (v.containsKey('timestampValue')) return v['timestampValue'] as String;
  return null;
}

Map<String, dynamic> encodeFields(Map<String, dynamic> data) {
  final out = <String, dynamic>{};
  data.forEach((k, v) => out[k] = encodeValue(v));
  return out;
}

Map<String, dynamic> encodeValue(Object? v) {
  if (v == null) return <String, dynamic>{'nullValue': null};
  if (v is bool) return <String, dynamic>{'booleanValue': v};
  if (v is int) return <String, dynamic>{'integerValue': v.toString()};
  if (v is double) return <String, dynamic>{'doubleValue': v};
  if (v is String) return <String, dynamic>{'stringValue': v};
  if (v is Map) {
    final fields = <String, dynamic>{};
    v.forEach((k, x) => fields[k.toString()] = encodeValue(x));
    return <String, dynamic>{
      'mapValue': <String, dynamic>{'fields': fields},
    };
  }
  if (v is List) {
    return <String, dynamic>{
      'arrayValue': <String, dynamic>{
        'values': [for (final x in v) encodeValue(x)],
      },
    };
  }
  throw ArgumentError('Desteklenmeyen tip: ${v.runtimeType}');
}
