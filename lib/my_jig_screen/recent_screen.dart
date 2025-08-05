import 'package:flutter/material.dart';

class RecentScreen extends StatelessWidget {
  const RecentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('최근 본 글'),
        backgroundColor: Colors.white,),
      body: const Center(child: Text('최근 본 글 화면')),
    );
  }
}