import 'package:flutter/material.dart';

class JinryangBDongPage extends StatelessWidget {
  const JinryangBDongPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('진량공장 B동'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '진량공장 B동 지도입니다.',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('← 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}