import 'package:flutter/material.dart';

class EventScreen extends StatelessWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('이벤트'),
        backgroundColor: Colors.white,),
      body: const Center(child: Text('이벤트 화면')),
    );
  }
}