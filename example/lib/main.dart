import 'package:flutter/material.dart';

import 'home_page.dart';

void main() => runApp(const PulseDbApp());

class PulseDbApp extends StatelessWidget {
  const PulseDbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PulseDb Examples',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
