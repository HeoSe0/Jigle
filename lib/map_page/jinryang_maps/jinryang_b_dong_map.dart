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
                    // 배경 지도 이미지
                    Image.asset(
                      'assets/bdong_map.png',
                      width: imageWidth,
                      height: imageHeight,
                      fit: BoxFit.contain,
                    ),

                    // 선반 버튼들 (각 버튼에 실제 이미지 표시 연결)
                    _buildShelfButton(
                      context,
                      label: "L1",
                      leftPercent: 0.08,
                      topPercent: 0.25,
                      widthPercent: 0.13,
                      heightPercent: 0.63,
                      imageWidth: imageWidth,
                      imageHeight: imageHeight,
                      imagePath: 'assets/shelf_L1.png',
                    ),
                    _buildShelfButton(
                      context,
                      label: "R1",
                      leftPercent: 0.75,
                      topPercent: 0.25,
                      widthPercent: 0.13,
                      heightPercent: 0.63,
                      imageWidth: imageWidth,
                      imageHeight: imageHeight,
                      imagePath: 'assets/shelf_R1.png',
                    ),
                    _buildShelfButton(
                      context,
                      label: "C1",
                      leftPercent: 0.31,
                      topPercent: 0.10,
                      widthPercent: 0.37,
                      heightPercent: 0.14,
                      imageWidth: imageWidth,
                      imageHeight: imageHeight,
                      imagePath: 'assets/shelf_C1.png',
                    ),
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

  /// 버튼 생성 함수
  Widget _buildShelfButton(
      BuildContext context, {
        required String label,
        required double leftPercent,
        required double topPercent,
        required double widthPercent,
        required double heightPercent,
        required double imageWidth,
        required double imageHeight,
        required String imagePath,
      }) {
    return Positioned(
      left: imageWidth * leftPercent,
      top: imageHeight * topPercent,
      width: imageWidth * widthPercent,
      height: imageHeight * heightPercent,
      child: TextButton(
        onPressed: () {
          _showImageDialog(context, label, imagePath);
        },
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: EdgeInsets.zero,
        ),
        child: Container(
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  /// 이미지 팝업 다이얼로그
  void _showImageDialog(BuildContext context, String label, String imagePath) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$label 선반 이미지'),
        content: Image.asset(
          imagePath,
          fit: BoxFit.contain,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}