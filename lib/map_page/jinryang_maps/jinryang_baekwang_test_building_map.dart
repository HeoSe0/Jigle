import 'package:flutter/material.dart';

class JinryangBaekwangTestBuildingMap extends StatelessWidget {
  final VoidCallback onBack;

  const JinryangBaekwangTestBuildingMap({super.key, required this.onBack});

  void _showImage(BuildContext context, String label) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$label 이미지'),
        content: Image.asset(
          'assets/sample_box1.png',
          fit: BoxFit.cover,
        ),
        actions: [
          TextButton(
            child: const Text("닫기"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  Widget _buildShelfColumn(List<String> labels, BuildContext context) {
    return Column(
      children: labels
          .map(
            (label) => Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          width: 80,
          height: 160,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue.shade100,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.black),
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: () => _showImage(context, label),
            child: Text(label),
          ),
        ),
      )
          .toList(),
    );
  }

  Widget _buildShelfRow({
    required List<String> rightLabels,
    required List<String> leftLabels,
    required BuildContext context,
  }) {
    return SizedBox(
      height: 12 * 168,
      child: Stack(
        children: [
          // 정확한 위치에 박스 고정 (화면 기준 비율 조정)
          Align(
            alignment: Alignment.center,
            child: FractionallySizedBox(
              widthFactor: 0.62, // ★ 튜닝 포인트: 너비 위치 조절
              alignment: Alignment.center,
              child: Container(
                width: 184, // 80 + 24 + 80
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
            ),
          ),

          // 하늘색 버튼 Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShelfColumn(rightLabels, context),
              const SizedBox(width: 24),
              _buildShelfColumn(leftLabels, context),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leftLabels = List.generate(24, (i) => 'L${i + 1}');
    final rightLabels = List.generate(24, (i) => 'R${i + 1}');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                child: Column(
                  children: [
                    const Column(
                      children: [
                        Text(
                          "IN",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(Icons.arrow_downward, size: 32, color: Colors.blue),
                        SizedBox(height: 20),
                      ],
                    ),

                    _buildShelfRow(
                      rightLabels: rightLabels.sublist(0, 12),
                      leftLabels: leftLabels.sublist(0, 12),
                      context: context,
                    ),

                    const SizedBox(height: 50),

                    _buildShelfRow(
                      rightLabels: rightLabels.sublist(12),
                      leftLabels: leftLabels.sublist(12),
                      context: context,
                    ),
                  ],
                ),
              ),
            ),

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
      ),
    );
  }
}