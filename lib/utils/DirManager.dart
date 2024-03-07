import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shared_storage/shared_storage.dart';

class DirManager {
  DocumentFile? df;
  File? file;

  Future<void> checkFirstUri() async {
    List<UriPermission>? uris = await persistedUriPermissions();

    while (uris == null || uris.isEmpty) {
      await openDocumentTree();
      uris = await persistedUriPermissions();
    }

    bool? isDirExists = await exists(uris!.first.uri);
    if(isDirExists == null || !isDirExists!) {
      for(var uri in uris) {
        await releasePersistableUriPermission(uri.uri);
      }

      await openDocumentTree();
      uris = await persistedUriPermissions();
    }
  }

  Future<void> createBlankFile(String name, Uint8List iv) async {
    if(Platform.isAndroid) {
      Uri uri = await getURI();
      df = await createFileAsBytes(uri, mimeType: "raw/content", displayName: name, bytes: iv);
    } else {
      await createDir();
      final Directory dirPath = await getApplicationDocumentsDirectory();
      Directory newDir = new Directory(dirPath.path + "/FileCrypto/");
      file = File(newDir.path + "/" + name);
      if (!await file!.exists()) {
        await file!.create();
      }

      await file!.writeAsBytes(iv, mode: FileMode.append);
    }
  }

  Future<void> writeFileWithStream(Stream stream) async {
    if(Platform.isAndroid) {
      await for (var item in stream) {
        await writeToFileAsBytes(df!.uri, bytes: Uint8List.fromList(item), mode: FileMode.append);
      }
    } else {
      await for(var item in stream) {
        await file!.writeAsBytes(Uint8List.fromList(item), mode: FileMode.append);
      }
    }
  }

  Future<Uri> getURI() async {
    List<UriPermission>? uris = await persistedUriPermissions();

    while (uris == null || uris.isEmpty) {
      await openDocumentTree();
      uris = await persistedUriPermissions();
    }

    return uris!.first.uri;
  }

  Future<void> createDir() async {
    final Directory dirPath = await getApplicationDocumentsDirectory();
    Directory newDir = new Directory(dirPath.path + "/FileCrypto/");
    if (!await newDir.exists()) {
      await newDir.create();
    }
  }
}
