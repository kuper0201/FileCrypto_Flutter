import 'package:flutter/material.dart';
import 'package:file_crypto/HomeView.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // home: GridPage()
      home: HomeView()
    );
  }
}

// class GridPage extends StatefulWidget {
//   const GridPage({Key? key}) : super(key: key);

//   @override
//   _GridPageState createState() => _GridPageState();
// }

// class _GridPageState extends State<GridPage> {
//   @override
//   Widget build(BuildContext context) {
//     final plainText = 'encryption test';
//     final pwEditController = TextEditingController();
    
//     return  Scaffold(
//       body: GridView(
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
//         scrollDirection: Axis.vertical,
//         children: [
//           Container(
//             width: 100,
//             height: 100,
//             color: Colors.red,
//           ),
//           Container(
//             width: 100,
//             height: 100,
//             color: Colors.blue,
//           ),
//           Container(
//             width: 100,
//             height: 100,
//             color: Colors.green,
//           ),
//           Container(
//             width: 100,
//             height: 100,
//             color: Colors.amber,
//           ),
//           Container(
//             width: 100,
//             height: 100,
//             color: Colors.blueGrey,
//           ),
//           Container(
//             width: 100,
//             height: 100,
//             color: Colors.brown,
//           ),
//         ],
//       )
//     );
//   }
// }