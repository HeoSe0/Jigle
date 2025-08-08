import 'package:flutter/material.dart';

class JinryangBDongMap extends StatelessWidget {
  final VoidCallback onBack;

  const JinryangBDongMap({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final imageWidth = constraints.maxWidth;
              final imageHeight = constraints.maxHeight;

              return Center(
                child: Stack(
                  children: [
                    // 지도 이미지
                    Image.asset(
                      'assets/bdong_map.png',
                      width: imageWidth,
                      height: imageHeight,
                      fit: BoxFit.contain,
                    ),

                    // 선반 버튼들 (비율 기반 위치 및 크기)
                    _buildShelfButton(context, "L1", 0.08, 0.25, 0.13, 0.63, imageWidth, imageHeight),
                    _buildShelfButton(context, "R1", 0.75, 0.25, 0.13, 0.63, imageWidth, imageHeight),
                    _buildShelfButton(context, "C1", 0.31, 0.10, 0.37, 0.14, imageWidth, imageHeight),
                  ],
                ),
              );
            },
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

  /// 선반 버튼 생성 함수
  Widget _buildShelfButton(
      BuildContext context,
      String label,
      double leftPercent,
      double topPercent,
      double widthPercent,
      double heightPercent,
      double imageWidth,
      double imageHeight,
      ) {
    return Positioned(
      left: imageWidth * leftPercent,
      top: imageHeight * topPercent,
      width: imageWidth * widthPercent,
      height: imageHeight * heightPercent,
      child: TextButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label 클릭됨')),
          );
        },
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          padding: EdgeInsets.zero,
        ),
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.black54, // 글자 배경도 약간 입혀서 가독성 ↑
            ),
          ),
        ),
      ),
    );
  }
}