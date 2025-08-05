import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jigle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Pretendard-M'),
      home: const SplashScreen(),
    );
  }
}