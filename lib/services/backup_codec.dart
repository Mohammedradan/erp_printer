import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// ترميز وفك ترميز النسخ الاحتياطية المشفّرة.
///
/// تنسيق قديم مبني على مواد أولية من حزمة `crypto` الموجودة. اسم التنسيق
/// التاريخي يذكر AES خطأً؛ التنفيذ الفعلي تيار HMAC-SHA256 مخصص وليس AES.
/// يُبقى الاسم لتوافق النسخ السابقة، ويجب استبدال هذا التنسيق بمكتبة تشفير
/// مدققة عند ترقية الإصدار. اشتقاق المفاتيح PBKDF2-HMAC-SHA256.
///
/// صيغة الملف (JSON واحد):
/// ```json
/// { "v": 1, "format": "pbkdf2-hmac-sha256/aes-ctr-hmac-sha256",
///   "kdf": "pbkdf2-hmac-sha256", "iterations": 60000,
///   "salt": "<base64>", "iv": "<base64>",
///   "ct": "<base64>", "mac": "<base64>" }
/// ```
class BackupCodec {
  BackupCodec._();

  static const String formatName =
      'pbkdf2-hmac-sha256/aes-ctr-hmac-sha256';
  static const int kdfIterations = 60000;
  static const int _saltBytes = 16;
  static const int _ivBytes = 16;
  static const int _blockBytes = 32; // طول خرج HMAC-SHA256
  static const int _maxPayloadBytes = 50 * 1024 * 1024;
  static const int _maxPlaintextBytes = 32 * 1024 * 1024;

  static final Random _random = Random.secure();

  /// هل النص نسخة احتياطية مشفّرة (وليس JSON عادي)؟
  static bool isEncrypted(String text) {
    try {
      final decoded = jsonDecode(text);
      return decoded is Map && decoded['format'] == formatName;
    } catch (_) {
      return false;
    }
  }

  /// يشفّر نص النسخة الاحتياطية بكلمة مرور المستخدم.
  static String encrypt(String plaintext, String password) {
    if (password.isEmpty) {
      throw ArgumentError('كلمة مرور النسخة الاحتياطية مطلوبة');
    }
    final data = Uint8List.fromList(utf8.encode(plaintext));
    if (data.length > _maxPlaintextBytes) {
      throw ArgumentError('حجم النسخة الاحتياطية يتجاوز الحد المسموح');
    }
    final salt = _randomBytes(_saltBytes);
    final iv = _randomBytes(_ivBytes);
    final keys = _deriveKeys(password, salt);

    final ct = _xorKeystream(data, keys.encKey, iv);
    final header = utf8.encode('MATBAAERP1');

    final macBody = BytesBuilder(copy: false)
      ..add(header)
      ..add(salt)
      ..add(iv)
      ..add(ct);
    final mac = _hmac(keys.macKey, macBody.takeBytes());

    return jsonEncode(<String, dynamic>{
      'v': 1,
      'format': formatName,
      'kdf': 'pbkdf2-hmac-sha256',
      'iterations': kdfIterations,
      'salt': base64Encode(salt),
      'iv': base64Encode(iv),
      'ct': base64Encode(ct),
      'mac': base64Encode(mac),
    });
  }

  /// يفك تشفير نسخة محمية. يرمي [BackupCryptoException] عند أي فشل.
  static String decrypt(String payload, String password) {
    if (payload.length > _maxPayloadBytes) {
      throw const BackupCryptoException('حجم النسخة المشفّرة يتجاوز الحد المسموح');
    }
    late final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) {
        throw const FormatException('الملف ليس JSON صالحاً');
      }
      json = Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw const BackupCryptoException('الملف ليس نسخة احتياطية صالحة');
    }

    if (json['format'] != formatName || json['v'] != 1 ||
        json['kdf'] != 'pbkdf2-hmac-sha256') {
      throw const BackupCryptoException('صيغة تشفير غير مدعومة');
    }

    final iterations = json['iterations'] is int
        ? json['iterations'] as int
        : int.tryParse('${json['iterations']}') ?? 0;
    if (iterations != kdfIterations) {
      throw const BackupCryptoException('عدد دورات اشتقاق المفتاح غير مدعوم');
    }

    final Uint8List salt;
    final Uint8List iv;
    final Uint8List ct;
    final Uint8List mac;
    try {
      salt = base64Decode('${json['salt']}');
      iv = base64Decode('${json['iv']}');
      ct = base64Decode('${json['ct']}');
      mac = base64Decode('${json['mac']}');
    } catch (_) {
      throw const BackupCryptoException('حقول النسخة المشفّرة تالفة');
    }

    if (salt.length != _saltBytes || iv.length != _ivBytes || mac.length != 32) {
      throw const BackupCryptoException('أطوال حقول النسخة المشفّرة غير صالحة');
    }
    if (ct.length > _maxPlaintextBytes) {
      throw const BackupCryptoException('حجم محتوى النسخة المشفّرة يتجاوز الحد المسموح');
    }

    final keys = _deriveKeys(password, salt, iterations: iterations);
    final header = utf8.encode('MATBAAERP1');
    final macBody = BytesBuilder(copy: false)
      ..add(header)
      ..add(salt)
      ..add(iv)
      ..add(ct);
    final expected = _hmac(keys.macKey, macBody.takeBytes());

    if (!_constantTimeEquals(expected, mac)) {
      throw const BackupCryptoException('كلمة المرور غير صحيحة أو الملف معدَّل');
    }

    final plain = _xorKeystream(ct, keys.encKey, iv);
    try {
      return utf8.decode(plain);
    } catch (_) {
      throw const BackupCryptoException('تعذر قراءة محتوى النسخة بعد فك التشفير');
    }
  }

  // ─────────────────────────────────────────────────────────
  // المواد الأولية
  // ─────────────────────────────────────────────────────────

  static _Keys _deriveKeys(String password, Uint8List salt, {int? iterations}) {
    final master = _pbkdf2(
      utf8.encode(password),
      salt,
      iterations ?? kdfIterations,
      64,
    );
    return _Keys(
      Uint8List.fromList(master.sublist(0, 32)),
      Uint8List.fromList(master.sublist(32, 64)),
    );
  }

  /// PBKDF2-HMAC-SHA256 (RFC 2898) مبني على `Hmac` من حزمة crypto.
  static Uint8List _pbkdf2(
    List<int> password,
    Uint8List salt,
    int iterations,
    int dkLen,
  ) {
    final hmac = Hmac(sha256, password);
    final out = BytesBuilder();
    final blocks = (dkLen + 31) ~/ 32;
    final block = Uint8List(salt.length + 4);
    block.setRange(0, salt.length, salt);

    for (var i = 1; i <= blocks; i++) {
      block[salt.length + 0] = (i >> 24) & 0xFF;
      block[salt.length + 1] = (i >> 16) & 0xFF;
      block[salt.length + 2] = (i >> 8) & 0xFF;
      block[salt.length + 3] = i & 0xFF;

      var u = Uint8List.fromList(hmac.convert(block).bytes);
      final t = Uint8List.fromList(u);
      for (var c = 1; c < iterations; c++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var b = 0; b < t.length; b++) {
          t[b] ^= u[b];
        }
      }
      out.add(t);
    }
    return Uint8List.fromList(out.takeBytes().sublist(0, dkLen));
  }

  /// مولِّد تدفق بنمط العدّاد: `block_i = HMAC(encKey, iv ‖ counter_be32(i))`.
  static Uint8List _xorKeystream(
    Uint8List data,
    Uint8List key,
    Uint8List iv,
  ) {
    final hmac = Hmac(sha256, key);
    final out = Uint8List(data.length);
    final input = Uint8List(iv.length + 4)..setRange(0, iv.length, iv);
    final blocks = (data.length + _blockBytes - 1) ~/ _blockBytes;

    for (var i = 0; i < blocks; i++) {
      final counter = i + 1;
      input[iv.length + 0] = (counter >> 24) & 0xFF;
      input[iv.length + 1] = (counter >> 16) & 0xFF;
      input[iv.length + 2] = (counter >> 8) & 0xFF;
      input[iv.length + 3] = counter & 0xFF;
      final ks = hmac.convert(input).bytes;
      final start = i * _blockBytes;
      final end = min(start + _blockBytes, data.length);
      for (var j = start; j < end; j++) {
        out[j] = data[j] ^ ks[j - start];
      }
    }
    return out;
  }

  static Uint8List _hmac(Uint8List key, Uint8List body) =>
      Uint8List.fromList(Hmac(sha256, key).convert(body).bytes);

  static Uint8List _randomBytes(int n) =>
      Uint8List.fromList(List<int>.generate(n, (_) => _random.nextInt(256)));

  /// مقارنة بزمن ثابت حتى لا يتسرب طول التطابق عبر التوقيت.
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

class _Keys {
  final Uint8List encKey;
  final Uint8List macKey;
  const _Keys(this.encKey, this.macKey);
}

/// فشل تشفيري لا يجب أن يمر كخطأ عام حتى تُعرض رسالة مفهومة للمستخدم.
class BackupCryptoException implements Exception {
  final String message;
  const BackupCryptoException(this.message);

  @override
  String toString() => message;
}
