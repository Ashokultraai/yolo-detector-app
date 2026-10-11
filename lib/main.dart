import 'package:flutter/material.dart';
import 'detection_screen.dart';

void main() => runApp(const TriModelApp());

class TriModelApp extends StatelessWidget {
  const TriModelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tri-Model Detector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6A5ACD),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const DetectionScreen(),
    );
  }
}
