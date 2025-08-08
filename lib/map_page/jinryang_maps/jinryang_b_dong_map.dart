import 'package:flutter/material.dart';

class JinryangBDongMap extends StatelessWidget {
  final VoidCallback onBack;

  const JinryangBDongMap({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지 삽입
          Center(
            child: Image.asset(
              'assets/bdong_map.png', // 여기에 본인이 넣은 이미지 경로로 수정
              fit: BoxFit.contain,           // 필요시 cover로 변경 가능
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // 뒤로가기 버튼
          Positioned(
            top: 12,
            left: 12,
            child: ElevatedButton(
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.8),
                foregroundColor: Colors.black,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(8),
              ),
              child: const Icon(Icons.arrow_back),
            ),
          ),
        ],
      ),
    );
  }
}