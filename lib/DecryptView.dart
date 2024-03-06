import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_crypto/utils/CryptUtil.dart';

import 'package:file_crypto/utils/DirManager.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class DecryptView extends StatefulWidget {
  @override
  _DecryptViewState createState() => _DecryptViewState();
}

class _DecryptViewState extends State<DecryptView> {
  Set<String> files = {};
  List<String> get fileList => files.toList();
  ProgressDialog? pd;

  int proc = 0;
  Future<void> decryptAndSave(int idx, String password) async {
    // 복호화
    File f = File(fileList[idx]);
    RandomAccessFile rf = await f.open(mode: FileMode.read);
    Uint8List iv;
    try {
      List<int> bytes = await rf.read(8);
      iv = Uint8List.fromList(bytes);
    } finally {
      await rf.close();
    }

    CryptUtil cryp = CryptUtil.Decrypter(password, iv);

    var mapper = (List<int> data) {
      return cryp.processEnc(Uint8List.fromList(data));
    };

    var directoryManager = DirManager();
    var decryptFileName = fileList[idx].split("/").last.replaceAll(".chacha", "");
    await directoryManager.createBlankFile(decryptFileName, Uint8List(0));

    Stream<List<int>> filtStream = await f.openRead(8);
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
              child: Icon(Icons.lock_open_outlined),
              onPressed: () async {
                if(Platform.isAndroid) {
                  FlutterForegroundTask.startService(notificationTitle: "Decryption", notificationText: "Processing...");
                }

                if(files.isNotEmpty) {
                  pd!.show(max: files!.length, msg: "Decrypting...", progressType: ProgressType.valuable);
                  final task = <Future>[];
                  int i = 0;
                  for(var file in files) {
                    task.add(decryptAndSave(i, pwEditController.text));
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
                    labelText: 'Dec Password',
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: files.length,
                  itemBuilder: (BuildContext context, int index) {
                    var txt = fileList[index].split("/");
                    return Center(child: Text(txt.last));
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