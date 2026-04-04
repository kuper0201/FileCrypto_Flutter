import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class CryptUtil {
  static const int nonceSize = 12;
  static const int tagSize = 16;

  late Uint8List nonce;
  late ChaCha20Poly1305 _cipher;
  late KeyParameter _keyParam;

  CryptUtil.Encrypter(String password) {
    _keyParam = KeyParameter(_deriveKey(password));
    nonce = _generateNonce();
    _cipher = ChaCha20Poly1305(ChaCha7539Engine(), Poly1305());
    _cipher.init(true, AEADParameters(_keyParam, 128, nonce, Uint8List(0)));
  }

  CryptUtil.Decrypter(String password, this.nonce) {
    _keyParam = KeyParameter(_deriveKey(password));
    _cipher = ChaCha20Poly1305(ChaCha7539Engine(), Poly1305());
    _cipher.init(false, AEADParameters(_keyParam, 128, nonce, Uint8List(0)));
  }

  Uint8List getIV() => nonce;

  Uint8List _generateNonce() {
    final random = Random.secure();
    final n = Uint8List(nonceSize);
    for (int i = 0; i < nonceSize; i++) {
      n[i] = random.nextInt(256);
    }
    return n;
  }

  Uint8List _deriveKey(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return Uint8List.fromList(hash.bytes.sublist(0, 32));
  }

  Uint8List processEnc(Uint8List data) {
    final outSize = _cipher.getOutputSize(data.length);
    final output = Uint8List(outSize);
    int len = _cipher.processBytes(data, 0, data.length, output, 0);
    len += _cipher.doFinal(output, len);
    return Uint8List.sublistView(output, 0, len);
  }

  Uint8List processDec(Uint8List data) {
    final outSize = _cipher.getOutputSize(data.length);
    final output = Uint8List(outSize);
    int len = _cipher.processBytes(data, 0, data.length, output, 0);
    len += _cipher.doFinal(output, len);
    return Uint8List.sublistView(output, 0, len);
  }
}
