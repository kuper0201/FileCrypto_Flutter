import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shared_storage/shared_storage.dart';

class DirManager {
  Future<Uri> getURI() async {
    List<UriPermission>? uris = await persistedUriPermissions();
    while (uris == null || uris.isEmpty) {
      await openDocumentTree();
      uris = await persistedUriPermissions();
    }

    return uris!.first.uri;
  }

  void createDir() async {
    final Directory dirPath = await getApplicationDocumentsDirectory();
    Directory newDir = new Directory(dirPath.path + "/FileCrypto/");
    if (!await newDir.exists()) {
      newDir.create();
    }
  }

  void createFile(String fileName, Uint8List contents) async {
    if (Platform.isAndroid) {
      Uri uri = await getURI();
      await createFileAsBytes(uri, mimeType: 'raw/content', displayName: fileName, bytes: contents);
    } else {
      createDir();
      final Directory dirPath = await getApplicationDocumentsDirectory();
      Directory newDir = new Directory(dirPath.path + "/FileCrypto/");
      File newF = File(newDir.path + "/" + fileName);
      if (!await newF.exists()) {
        await newF.create();
      }
      await newF.writeAsBytes(contents);
    }
  }
}
