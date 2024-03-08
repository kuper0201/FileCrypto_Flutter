import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'package:file_crypto/utils/CryptUtil.dart';
import 'package:desktop_drop/desktop_drop.dart';

import 'package:file_crypto/utils/DirManager.dart';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class EncryptView extends StatefulWidget {
  @override
  _EncryptViewState createState() => _EncryptViewState();
}

class _EncryptViewState extends State<EncryptView> {
  ProgressDialog? pd;
  Set<String> files = {};
  List<String> get fileList => files.toList();

  int proc = 0;
  Future<void> encryptAndSave(int idx, String password) async {
    // 암호화
    CryptUtil cryp = CryptUtil.Encrypter(password);
    Uint8List iv = cryp.getIV();
    File f = File(fileList[idx]);

    var mapper = (List<int> data) {
      return cryp.processEnc(Uint8List.fromList(data));
    };

    var directoryManager = DirManager();
    await directoryManager.createBlankFile(fileList[idx].split("/").last +".chacha", iv);

    Stream<List<int>> filtStream = await f.openRead();
    Stream tr = filtStream.map(mapper);
    await directoryManager.writeFileWithStream(tr);

    proc++;
    pd!.update(value: proc);
  }

  void performEnc(String password) async {
    if(Platform.isAndroid) {
      FlutterForegroundTask.startService(notificationTitle: "Encryption", notificationText: "Processing...");
      await DirManager().checkFirstUri();
    }

    pd!.show(max: files!.length, msg: "Encrypting...", progressType: ProgressType.valuable);
    final task = <Future>[];
    int i = 0;
    for(var file in files) {
      task.add(encryptAndSave(i, password));
      i++;
    }

    proc = 0;
    await Future.wait(task);

    if(Platform.isAndroid) {
      FilePicker.platform.clearTemporaryFiles();
      FlutterForegroundTask.stopService();
    }

    setState(() {
      files.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    pd = ProgressDialog(context: context);
    final pwEditController = TextEditingController();

    return Scaffold(
        floatingActionButton: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment(Alignment.bottomRight.x, Alignment.bottomRight.y - 0.3),
              child: FloatingActionButton(
                  child: Icon(Icons.lock_outline),
                  onPressed: () async {
                    if(files.isNotEmpty) {
                      showDialog(context: context, barrierDismissible: false, builder: (context) {
                        return AlertDialog(
                          title: Text("Input password"),
                          content: TextField(controller: pwEditController, autofocus: true, obscureText: true, decoration: InputDecoration(hintText: "Password for Encrypt"), onSubmitted: (value) {Navigator.pop(context); performEnc(pwEditController.text);},),
                          actions: [
                            TextButton(onPressed: () { Navigator.pop(context); pwEditController.text = ''; }, child: Text("Cancel")),
                            TextButton(onPressed: () { Navigator.pop(context); performEnc(pwEditController.text); }, child: Text("Encrypt!"))
                          ],
                        );
                      });
                    } else {
                      showDialog(context: context, barrierDismissible: false, builder: (context) {
                        return AlertDialog(title: Text("Failed"), content: Text("Please select some files"), actions: <Widget> [
                          TextButton(onPressed: () { Navigator.pop(context); }, child: Text("OK"))
                        ],);
                      });
                    }
                  }
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                tooltip: "Add File",
                child: Icon(Icons.add),
                onPressed: () async {
                  FilePickerResult? f = await FilePicker.platform.pickFiles(allowMultiple: true);
                  if(f != null) {
                    for (var fl in f.files!) {
                      setState(() {
                        files.add(fl!.path!);
                      });
                    }
                  }
                },
              ),
            )
          ],
        ),
        body: DropTarget(
            onDragDone: (detail) async {
              if(detail != null && detail.files.isNotEmpty) {
                String fileName = detail.files.first.path;
                setState(() {
                  files.add(fileName);
                });
                // do job
              }
            },
            child: Center(
                child: Column(
                    children: [
                      AppBar(title: Text("Encryption"),),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: files.length,
                          itemBuilder: (BuildContext context, int index){
                            var txt = fileList[index].split("/");
                            return InkWell(
                              child: Card(
                                child: ListTile(
                                  title: Text(txt.last, style: TextStyle(fontStyle: FontStyle.italic, fontSize: 20)),
                                  trailing: Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(color: Colors.red),
                                    child: Center(
                                      child: Text('X', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 20)),
                                    ),
                                  ),
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  files.remove(fileList[index]);
                                });
                              },
                            );
                          }),
                        ),
                    ]
                )
            )
        )
    );
  }
}