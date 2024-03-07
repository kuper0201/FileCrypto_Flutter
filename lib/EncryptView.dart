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
  late DirManager directoryManager;

  _EncryptViewState() {
    directoryManager = DirManager();
  }

  int proc = 0;
  Future<void> encryptAndSave(int idx, String password) async {
    // 암호화
    CryptUtil cryp = CryptUtil.Encrypter(password);
    Uint8List iv = cryp.getIV();
    File f = File(fileList[idx]);

    var mapper = (List<int> data) {
      return cryp.processEnc(Uint8List.fromList(data));
    };

    await directoryManager.createBlankFile(fileList[idx].split("/").last +".chacha", iv);

    Stream<List<int>> filtStream = await f.openRead();
    Stream tr = filtStream.map(mapper);
    await directoryManager.writeFileWithStream(tr);

    proc++;
    pd!.update(value: proc);
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
                    if(Platform.isAndroid) {
                      FlutterForegroundTask.startService(notificationTitle: "Encryption", notificationText: "Processing...");
                      await directoryManager.checkFirstUri();
                    }

                    if(files.isNotEmpty) {
                      pd!.show(max: files!.length, msg: "Encrypting...", progressType: ProgressType.valuable);
                      final task = <Future>[];
                      int i = 0;
                      for(var file in files) {
                        task.add(encryptAndSave(i, pwEditController.text));
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
                    } else {
                      showDialog(context: context, builder: (context) {
                        return AlertDialog(title: Text("Failed"), content: Text("Please select some files"));;
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
                      Container(
                        padding: EdgeInsets.all(5),
                        child: TextField(
                          controller: pwEditController,
                          obscureText: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Enc Password',
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: files.length,
                          itemBuilder: (BuildContext context, int index){
                            var txt = fileList[index].split("/");
                            return Center(child: Text(txt.last, style: TextStyle(fontSize: 28),));
                          }
                        ),
                      )
                    ]
                )
            )
        )
    );
  }
}