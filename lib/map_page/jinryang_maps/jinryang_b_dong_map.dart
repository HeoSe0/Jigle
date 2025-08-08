import 'package:flutter/material.dart';

class JinryangBDongMap extends StatelessWidget {
  final VoidCallback onBack;

  const JinryangBDongMap({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // LayoutBuilder로 이미지 크기 기반 버튼 위치 지정
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

                    // 버튼들 - 비율 기반 위치 지정
                    _buildShelfButton("L1", 0.13, 0.373, imageWidth, imageHeight),
                    _buildShelfButton("L2", 0.13, 0.63, imageWidth, imageHeight),
                    _buildShelfButton("L3", 0.13, 0.8, imageWidth, imageHeight),

                    _buildShelfButton("R1", 0.81, 0.373, imageWidth, imageHeight),
                    _buildShelfButton("R2", 0.81, 0.63, imageWidth, imageHeight),
                    _buildShelfButton("R3", 0.81, 0.8, imageWidth, imageHeight),

                    _buildShelfButton("C1", 0.42, 0.135, imageWidth, imageHeight),
                    _buildShelfButton("C2", 0.60, 0.135, imageWidth, imageHeight),
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

  /// 버튼 생성 함수 (위치 비율 기반)
  Widget _buildShelfButton(
      String label,
      double leftPercent,
      double topPercent,
      double imageWidth,
      double imageHeight,
      ) {
    return Positioned(
      left: imageWidth * leftPercent,
      top: imageHeight * topPercent,
      child: ElevatedButton(
        onPressed: () {
          debugPrint('$label 클릭됨');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black.withOpacity(0.6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(6),
          minimumSize: const Size(40, 30),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: FittedBox(child: Text(label)),
      ),
    );
  }
}