import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'chat_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // RawDatagramSocket.bind(InternetAddress.anyIPv4, 55443)
    //     .then((RawDatagramSocket socket) {
    //   print('UDP Echo ready to receive');
    //   print('${socket.address.address}:${socket.port}');
    //   socket.listen((RawSocketEvent e) {
    //     Datagram? d = socket.receive();
    //     if (d == null) return;

    //     String message = String.fromCharCodes(d.data);
    //     print(
    //         'Datagram from ${d.address.address}:${d.port}: ${message.trim()}');

    //     socket.send(message.codeUnits, d.address, d.port);
    //   });
    // });
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}
