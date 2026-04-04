import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:file_crypto/utils/CryptUtil.dart';

void main() {
  group('Encrypt/Decrypt pipeline simulation', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pipeline_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('single chunk encrypt then decrypt (matches app flow)', () async {
      final password = 'test_password';
      final originalContent =
          Uint8List.fromList(List.generate(1024, (i) => i % 256));

      final encrypter = CryptUtil.Encrypter(password);
      final iv = encrypter.getIV();

      final encrypted = encrypter.processEnc(originalContent);

      final decrypter = CryptUtil.Decrypter(password, iv);
      final decrypted = decrypter.processDec(Uint8List.fromList(encrypted));

      expect(decrypted, equals(originalContent.toList()));
    });

    test('multi-chunk encrypt then single-call decrypt (matches app flow)',
        () async {
      final password = 'test_password';
      final originalContent =
          Uint8List.fromList(List.generate(10000, (i) => i % 256));

      final encrypter = CryptUtil.Encrypter(password);
      final iv = encrypter.getIV();

      // Encrypt in chunks (simulates file stream)
      final chunkSize = 1024;
      final encryptedChunks = <List<int>>[];
      for (int offset = 0;
          offset < originalContent.length;
          offset += chunkSize) {
        final end = (offset + chunkSize).clamp(0, originalContent.length);
        final chunk = Uint8List.sublistView(originalContent, offset, end);
        encryptedChunks.add(encrypter.processEnc(chunk));
      }

      // Concatenate encrypted chunks
      final allEncrypted = <int>[];
      for (var chunk in encryptedChunks) {
        allEncrypted.addAll(chunk);
      }

      // Decrypt all at once (simulates DecryptView)
      final decrypter = CryptUtil.Decrypter(password, iv);
      final decrypted = decrypter.processDec(Uint8List.fromList(allEncrypted));

      expect(decrypted.length, equals(originalContent.length));
      expect(decrypted, equals(originalContent.toList()));
    });

    test('full file pipeline: write -> read back -> verify', () async {
      final password = 'pipeline_test';
      final originalContent =
          Uint8List.fromList(List.generate(5000, (i) => (i * 7 + 3) % 256));

      // --- ENCRYPT phase (simulates EncryptView._encryptAndSave) ---
      final encrypter = CryptUtil.Encrypter(password);
      final iv = encrypter.getIV();

      // Simulate stream encryption
      List<int> mapperEnc(List<int> data) {
        return encrypter.processEnc(Uint8List.fromList(data));
      }

      final inputFile = File('${tempDir.path}/original.bin');
      await inputFile.writeAsBytes(originalContent);

      final inputStream = inputFile.openRead();
      final encryptedStream = inputStream.map(mapperEnc);

      final encryptedFile = File('${tempDir.path}/original.bin.chacha');
      final sink = encryptedFile.openWrite();
      // Write IV first
      sink.add(iv);
      // Write encrypted chunks
      await for (var chunk in encryptedStream) {
        sink.add(chunk);
      }
      await sink.close();

      // --- DECRYPT phase (simulates DecryptView._decryptAndSave) ---
      final bytes = await encryptedFile.readAsBytes();
      final readIv = Uint8List.sublistView(bytes, 0, 8);
      final encryptedData = Uint8List.sublistView(bytes, 8);

      final decrypter = CryptUtil.Decrypter(password, readIv);

      List<int> mapperDec(List<int> data) {
        return decrypter.processDec(Uint8List.fromList(data));
      }

      final decryptedStream = Stream.value(encryptedData).map(mapperDec);
      final decryptedFile = File('${tempDir.path}/original_decrypted.bin');
      final decSink = decryptedFile.openWrite();
      await for (var chunk in decryptedStream) {
        decSink.add(chunk);
      }
      await decSink.close();

      // --- VERIFY ---
      final decryptedContent = await decryptedFile.readAsBytes();
      expect(decryptedContent.length, equals(originalContent.length));

      bool identical = true;
      int firstDiff = -1;
      for (int i = 0; i < originalContent.length; i++) {
        if (decryptedContent[i] != originalContent[i]) {
          identical = false;
          firstDiff = i;
          break;
        }
      }

      if (!identical) {
        print('MISMATCH at byte $firstDiff:');
        print(
            '  original: ${originalContent[firstDiff]}  decrypted: ${decryptedContent[firstDiff]}');
        print(
            '  original bytes [$firstDiff..${firstDiff + 10}]: ${originalContent.sublist(firstDiff, (firstDiff + 10).clamp(0, originalContent.length))}');
        print(
            '  decrypted bytes[$firstDiff..${firstDiff + 10}]: ${decryptedContent.sublist(firstDiff, (firstDiff + 10).clamp(0, decryptedContent.length))}');
      }

      expect(identical, isTrue,
          reason:
              'Decrypted content does not match original (first diff at byte $firstDiff)');
    });

    test('large file pipeline with real binary data', () async {
      final password = 'large_test_pw';
      final originalContent =
          Uint8List.fromList(List.generate(100000, (i) => (i * 31 + 17) % 256));

      final encrypter = CryptUtil.Encrypter(password);
      final iv = encrypter.getIV();

      final inputFile = File('${tempDir.path}/large.bin');
      await inputFile.writeAsBytes(originalContent);

      final inputStream = inputFile.openRead();
      final encryptedStream =
          inputStream.map((d) => encrypter.processEnc(Uint8List.fromList(d)));

      final encryptedFile = File('${tempDir.path}/large.bin.chacha');
      final sink = encryptedFile.openWrite();
      sink.add(iv);
      await for (var chunk in encryptedStream) {
        sink.add(chunk);
      }
      await sink.close();

      final bytes = await encryptedFile.readAsBytes();
      final readIv = Uint8List.sublistView(bytes, 0, 8);
      final encryptedData = Uint8List.sublistView(bytes, 8);

      final decrypter = CryptUtil.Decrypter(password, readIv);
      final decrypted = decrypter.processDec(encryptedData);

      expect(decrypted.length, equals(originalContent.length));

      int mismatches = 0;
      int firstMismatch = -1;
      for (int i = 0; i < originalContent.length; i++) {
        if (decrypted[i] != originalContent[i]) {
          mismatches++;
          if (firstMismatch == -1) firstMismatch = i;
        }
      }

      if (mismatches > 0) {
        print(
            'MISMATCH: $mismatches of ${originalContent.length} bytes differ');
        print('First mismatch at byte $firstMismatch');
        print(
            '  original: ${originalContent[firstMismatch]}  decrypted: ${decrypted[firstMismatch]}');
      }

      expect(mismatches, equals(0),
          reason: '$mismatches bytes differ, first at $firstMismatch');
    });
  });
}
