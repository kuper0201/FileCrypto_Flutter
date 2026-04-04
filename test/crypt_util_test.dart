import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:file_crypto/utils/CryptUtil.dart';

void main() {
  group('CryptUtil AEAD', () {
    test('encrypt then decrypt returns original data', () {
      final password = 'test_password_123';
      final original = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

      final encrypter = CryptUtil.Encrypter(password);
      final nonce = encrypter.getIV();
      final encrypted = encrypter.processEnc(original);

      expect(encrypted.length, equals(original.length + CryptUtil.tagSize));

      final decrypter = CryptUtil.Decrypter(password, nonce);
      final decrypted = decrypter.processDec(encrypted);

      expect(decrypted, equals(original.toList()));
    });

    test('nonce is 12 bytes', () {
      final encrypter = CryptUtil.Encrypter('test');
      final nonce = encrypter.getIV();
      expect(nonce.length, equals(12));
    });

    test('encrypted output includes 16-byte tag', () {
      final encrypter = CryptUtil.Encrypter('test');
      final data = Uint8List.fromList(List.generate(64, (i) => i));
      final encrypted = encrypter.processEnc(data);
      expect(encrypted.length, equals(64 + CryptUtil.tagSize));
    });

    test('different encryption calls produce different ciphertext', () {
      final password = 'same_password';
      final data = Uint8List.fromList(List.generate(64, (i) => i));

      final enc1 = CryptUtil.Encrypter(password);
      final cipher1 = enc1.processEnc(Uint8List.fromList(data));

      final enc2 = CryptUtil.Encrypter(password);
      final cipher2 = enc2.processEnc(Uint8List.fromList(data));

      expect(cipher1, isNot(equals(cipher2)));
    });

    test('round-trip with empty data', () {
      final password = 'password';
      final original = Uint8List(0);

      final encrypter = CryptUtil.Encrypter(password);
      final nonce = encrypter.getIV();
      final encrypted = encrypter.processEnc(original);

      expect(encrypted.length, equals(CryptUtil.tagSize));

      final decrypter = CryptUtil.Decrypter(password, nonce);
      final decrypted = decrypter.processDec(encrypted);

      expect(decrypted, equals(original.toList()));
    });

    test('round-trip with single byte', () {
      final password = 'pw';
      final original = Uint8List.fromList([42]);

      final encrypter = CryptUtil.Encrypter(password);
      final nonce = encrypter.getIV();
      final encrypted = encrypter.processEnc(original);

      final decrypter = CryptUtil.Decrypter(password, nonce);
      final decrypted = decrypter.processDec(encrypted);

      expect(decrypted, equals(original.toList()));
    });

    test('round-trip with large data', () {
      final password = 'large_test_password';
      final original = Uint8List.fromList(List.generate(65536, (i) => i % 256));

      final encrypter = CryptUtil.Encrypter(password);
      final nonce = encrypter.getIV();
      final encrypted = encrypter.processEnc(original);

      final decrypter = CryptUtil.Decrypter(password, nonce);
      final decrypted = decrypter.processDec(encrypted);

      expect(decrypted, equals(original.toList()));
    });

    test('round-trip with Unicode password', () {
      final password = '암호화테스트🔐🔒';
      final original = Uint8List.fromList(List.generate(256, (i) => i));

      final encrypter = CryptUtil.Encrypter(password);
      final nonce = encrypter.getIV();
      final encrypted = encrypter.processEnc(original);

      final decrypter = CryptUtil.Decrypter(password, nonce);
      final decrypted = decrypter.processDec(encrypted);

      expect(decrypted, equals(original.toList()));
    });

    test('wrong password throws exception', () {
      final original = Uint8List.fromList([10, 20, 30, 40, 50]);

      final encrypter = CryptUtil.Encrypter('correct_password');
      final nonce = encrypter.getIV();
      final encrypted = encrypter.processEnc(original);

      final decrypter = CryptUtil.Decrypter('wrong_password', nonce);

      expect(() => decrypter.processDec(encrypted), throwsArgumentError);
    });

    test('tampered ciphertext throws exception', () {
      final original = Uint8List.fromList(List.generate(100, (i) => i));

      final encrypter = CryptUtil.Encrypter('test');
      final nonce = encrypter.getIV();
      final encrypted = encrypter.processEnc(original);

      encrypted[0] ^= 0xFF;

      final decrypter = CryptUtil.Decrypter('test', nonce);

      expect(() => decrypter.processDec(encrypted), throwsArgumentError);
    });

    test('truncated ciphertext throws exception', () {
      final original = Uint8List.fromList(List.generate(64, (i) => i));

      final encrypter = CryptUtil.Encrypter('test');
      final nonce = encrypter.getIV();
      final encrypted = encrypter.processEnc(original);

      final truncated = Uint8List.sublistView(encrypted, 0, 10);

      final decrypter = CryptUtil.Decrypter('test', nonce);

      expect(() => decrypter.processDec(truncated), throwsArgumentError);
    });
  });

  group('File encrypt/decrypt pipeline (AEAD)', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('aead_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('full file pipeline: encrypt → save → read → decrypt → verify',
        () async {
      final password = 'pipeline_test';
      final originalContent =
          Uint8List.fromList(List.generate(5000, (i) => (i * 7 + 3) % 256));

      final inputFile = File('${tempDir.path}/test.bin');
      await inputFile.writeAsBytes(originalContent);

      final encrypter = CryptUtil.Encrypter(password);
      final nonce = encrypter.getIV();
      final encrypted = encrypter.processEnc(originalContent);

      final encryptedFile = File('${tempDir.path}/test.bin.chacha');
      final sink = encryptedFile.openWrite();
      sink.add(nonce);
      sink.add(encrypted);
      await sink.close();

      final bytes = await encryptedFile.readAsBytes();
      final readNonce = Uint8List.sublistView(bytes, 0, CryptUtil.nonceSize);
      final readCipher = Uint8List.sublistView(bytes, CryptUtil.nonceSize);

      final decrypter = CryptUtil.Decrypter(password, readNonce);
      final decrypted = decrypter.processDec(readCipher);

      expect(decrypted.length, equals(originalContent.length));
      expect(decrypted, equals(originalContent.toList()));
    });

    test('large file pipeline', () async {
      final password = 'large_aead_test';
      final originalContent =
          Uint8List.fromList(List.generate(100000, (i) => (i * 31 + 17) % 256));

      final encrypter = CryptUtil.Encrypter(password);
      final nonce = encrypter.getIV();
      final encrypted = encrypter.processEnc(originalContent);

      final file = File('${tempDir.path}/large.bin.chacha');
      final sink = file.openWrite();
      sink.add(nonce);
      sink.add(encrypted);
      await sink.close();

      final bytes = await file.readAsBytes();
      final readNonce = Uint8List.sublistView(bytes, 0, CryptUtil.nonceSize);
      final readCipher = Uint8List.sublistView(bytes, CryptUtil.nonceSize);

      final decrypter = CryptUtil.Decrypter(password, readNonce);
      final decrypted = decrypter.processDec(readCipher);

      expect(decrypted.length, equals(originalContent.length));
      expect(decrypted, equals(originalContent.toList()));
    });

    test('wrong password in pipeline throws exception', () async {
      final password = 'correct';
      final original = Uint8List.fromList(List.generate(100, (i) => i));

      final encrypter = CryptUtil.Encrypter(password);
      final nonce = encrypter.getIV();
      final encrypted = encrypter.processEnc(original);

      final file = File('${tempDir.path}/test.bin.chacha');
      final sink = file.openWrite();
      sink.add(nonce);
      sink.add(encrypted);
      await sink.close();

      final bytes = await file.readAsBytes();
      final readNonce = Uint8List.sublistView(bytes, 0, CryptUtil.nonceSize);
      final readCipher = Uint8List.sublistView(bytes, CryptUtil.nonceSize);

      final decrypter = CryptUtil.Decrypter('wrong_password', readNonce);

      expect(() => decrypter.processDec(readCipher), throwsArgumentError);
    });

    test('encrypted file is different from original', () async {
      final password = 'diff_test';
      final originalContent = Uint8List.fromList(List.generate(256, (i) => i));

      final encrypter = CryptUtil.Encrypter(password);
      final encrypted = encrypter.processEnc(originalContent);

      expect(encrypted, isNot(equals(originalContent.toList())));
      expect(
          encrypted.length, equals(originalContent.length + CryptUtil.tagSize));
    });
  });
}
