import 'dart:ffi';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:file_crypto/utils/DirManager.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';

import 'package:pointycastle/export.dart';

class CryptUtil {
  late ChaCha20Engine chacha20;

  CryptUtil(String password, bool isEnc) {
    var key = KeyParameter(Uint8List.fromList("1111111111111111".codeUnits));
    var iv = Uint8List.fromList("11111111".codeUnits);
    var params = ParametersWithIV(key, iv);
    chacha20 = ChaCha20Engine();
    chacha20.init(isEnc, params);
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

  List<int> encrypData(Uint8List file, String password) {
    // String key = saltPassword(password);
    //
    // final encrypter = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc));
    // Encrypted e = encrypter.encryptBytes(file, iv: iv);
    // return e.bytes;

    return "t".codeUnits;
  }

  List<int> decryptData(Uint8List encryptedFile, String password) {
    // String key = saltPassword(password);
    //
    // final encrypter = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc));
    // Encrypted es = Encrypted(encryptedFile);
    // return encrypter.decryptBytes(es, iv: iv);
    return [];
  }
}