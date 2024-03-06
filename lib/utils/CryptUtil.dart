import 'dart:ffi';

import 'package:crypto/crypto.dart';
import 'package:file_crypto/utils/DirManager.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:pointycastle/export.dart';

class CryptUtil {
  late ChaCha20Engine chacha20;
  late String password;
  late Uint8List iv;

  CryptUtil.Encrypter(this.password) {
    var key = KeyParameter(Uint8List.fromList(saltPassword(password).codeUnits));
    iv = Uint8List.fromList(getRandString(8).codeUnits);
    var params = ParametersWithIV(key, iv);
    chacha20 = ChaCha20Engine();
    chacha20.init(true, params);
  }

  CryptUtil.Decrypter(this.password, this.iv) {
    var key = KeyParameter(Uint8List.fromList(saltPassword(password).codeUnits));
    var params = ParametersWithIV(key, iv);
    chacha20 = ChaCha20Engine();
    chacha20.init(false, params);
  }

  Uint8List getIV() {
    return this.iv;
  }

  String getRandString(int len) {
    var random = Random.secure();
    var values = List<int>.generate(len, (i) =>  random.nextInt(255));
    return base64UrlEncode(values).substring(0, len);
  }

  String saltPassword(String password) {
    var passwordString = utf8.encode(password);// + uniqueKey);
    var hash = sha256.convert(passwordString);
    var key = hash.toString().substring(0, 32);

    return key;
  }

  List<int> processDec(Uint8List data) {
    return List<int>.from(chacha20.process(data));
  }

  List<int> processEnc(Uint8List data) {
    return List<int>.from(chacha20.process(data));
  }
}