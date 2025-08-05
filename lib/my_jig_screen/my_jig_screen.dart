import 'package:flutter/material.dart';

class MyJigScreen extends StatelessWidget {
  const MyJigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('나의 지그'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 뒤로가기
          },
        ),
      ),
      body: const Center(
        child: Text('나의 지그 화면'),
      ),
    );
  }
}