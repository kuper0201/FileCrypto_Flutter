import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'package:file_crypto/utils/CryptUtil.dart';
import 'package:file_crypto/utils/DirManager.dart';
import 'package:file_crypto/views/CryptoView.dart';

class DecryptView extends StatelessWidget {
  const DecryptView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CryptoView(
      title: "Decryption",
      headerIcon: Icons.lock_open_outlined,
      actionLabel: "Decrypt",
      passwordHint: "Password for Decrypt",
      foregroundTitle: "Decryption",
      accentColor: const Color(0xFF42A5F5),
      onCrypto: _performDecrypt,
    );
  }

  Future<void> _performDecrypt(
    List<String> fileList,
    String password,
    ProgressDialog pd,
  ) async {
    int proc = 0;
    for (int i = 0; i < fileList.length; i++) {
      await _decryptAndSave(fileList[i], password, () {
        proc++;
        pd.update(value: proc);
      });
    }
  }

  Future<void> _decryptAndSave(
    String filePath,
    String password,
    VoidCallback onDone,
  ) async {
    File f = File(filePath);
    Uint8List bytes = await f.readAsBytes();

    if (bytes.length < CryptUtil.nonceSize + CryptUtil.tagSize) {
      throw ArgumentError('File too short to be a valid encrypted file');
    }

    Uint8List nonce = Uint8List.sublistView(bytes, 0, CryptUtil.nonceSize);
    Uint8List cipherWithTag = Uint8List.sublistView(bytes, CryptUtil.nonceSize);

    CryptUtil cryp = CryptUtil.Decrypter(password, nonce);
    Uint8List decrypted = cryp.processDec(cipherWithTag);

    String originalName = filePath.split(Platform.pathSeparator).last;
    if (originalName.endsWith('.chacha')) {
      originalName = originalName.substring(0, originalName.length - 7);
    }

    var dirManager = DirManager();
    await dirManager.createBlankFile(originalName, Uint8List(0));
    await dirManager.writeFileWithStream(Stream.value(decrypted.toList()));

    onDone();
  }
}
