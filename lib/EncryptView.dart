import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'package:file_crypto/utils/CryptUtil.dart';
import 'package:file_crypto/utils/DirManager.dart';
import 'package:file_crypto/views/CryptoView.dart';

class EncryptView extends StatelessWidget {
  const EncryptView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CryptoView(
      title: "Encryption",
      headerIcon: Icons.lock_outline,
      actionLabel: "Encrypt",
      passwordHint: "Password for Encrypt",
      foregroundTitle: "Encryption",
      accentColor: const Color(0xFF4CAF50),
      onCrypto: _performEncrypt,
    );
  }

  Future<void> _performEncrypt(
    List<String> fileList,
    String password,
    ProgressDialog pd,
  ) async {
    int proc = 0;
    for (int i = 0; i < fileList.length; i++) {
      await _encryptAndSave(fileList[i], password, () {
        proc++;
        pd.update(value: proc);
      });
    }
  }

  Future<void> _encryptAndSave(
    String filePath,
    String password,
    VoidCallback onDone,
  ) async {
    File f = File(filePath);
    Uint8List plainBytes = await f.readAsBytes();

    CryptUtil cryp = CryptUtil.Encrypter(password);
    Uint8List nonce = cryp.getIV();
    Uint8List encrypted = cryp.processEnc(plainBytes);

    String outputName = "${filePath.split(Platform.pathSeparator).last}.chacha";

    var dirManager = DirManager();
    await dirManager.createBlankFile(outputName, nonce);
    await dirManager.writeFileWithStream(Stream.value(encrypted.toList()));

    onDone();
  }
}
