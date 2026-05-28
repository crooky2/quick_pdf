import 'package:flutter/material.dart';

import "screens/screen_convert.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick PDF',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: .fromSeed(seedColor: const Color.fromARGB(255, 20, 26, 73)),
      ),
      home: const ScreenConvert(),
    );
  }
}