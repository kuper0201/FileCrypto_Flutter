import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:file_picker/file_picker.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'dart:convert';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';

import 'package:file_crypto/utils/DirManager.dart' as dirMan;

class DecryptView extends StatefulWidget {
  @override
  _DecryptViewState createState() => _DecryptViewState();
}

class _DecryptViewState extends State<DecryptView> {
  Set<String> files = {};
  List<String> get fileList => files.toList();

  @override
  Widget build(BuildContext context) {
    ProgressDialog pd = ProgressDialog(context: context);;
    final pwEditController = TextEditingController();

    return Scaffold(
      floatingActionButton: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment(Alignment.bottomRight.x, Alignment.bottomRight.y - 0.3),
            child: FloatingActionButton(
              child: Icon(Icons.lock_open_outlined),
              onPressed: () async {
                const uniqueKey = "file_crypto";
                if(files.isNotEmpty) {
                  pd.show(max: files!.length, msg: "Decrypting...", progressType: ProgressType.valuable);
                  var passwordString = utf8.encode(pwEditController.text + uniqueKey);
                  var hash = sha256.convert(passwordString);
                  var key = hash.toString().substring(0, 32);

                  final iv = encrypt.IV.fromUtf8("XQnB2g7WijMpvN48");
                  final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(key), mode: encrypt.AESMode.cbc));
                  int i = 1;
                  for(String fl in files) {
                    File f = File(fl);
                    Uint8List s = await f.readAsBytes();
                    encrypt.Encrypted es = encrypt.Encrypted(s);
                    var dec = encrypter.decryptBytes(es, iv: iv);
                    var spl = fl.split("/");
                    String fileName = "dec_" + spl.last.substring(4);
                    dirMan.DirManager().createFile(fileName, Uint8List.fromList(dec));

                    pd.update(value: i);
                    i++;
                  }

                  FilePicker.platform.clearTemporaryFiles();
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
            String fileName = detail.files.first.name;
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