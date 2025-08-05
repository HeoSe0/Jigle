import 'package:flutter/material.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('관심목록'),
        backgroundColor: Colors.white,),
      body: const Center(child: Text('관심목록 화면')),
    );
  }
}