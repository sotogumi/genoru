import 'package:flutter/material.dart';
import 'package:genoru/app/screens/input_screen.dart';
import 'package:genoru/app/theme/app_theme.dart';

void main() {
  runApp(const GenoruApp());
}

class GenoruApp extends StatelessWidget {
  const GenoruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ゲノる',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const InputScreen(),
    );
  }
}
