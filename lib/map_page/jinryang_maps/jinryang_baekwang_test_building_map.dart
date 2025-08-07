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
          'assets/sample_box1.png', // 공통으로 사용할 이미지 경로
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
      mainAxisAlignment: MainAxisAlignment.start,
      children: labels
          .map(
            (label) => Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          width: 160, // 2.5배
          height: 80, // 1.5배
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

  @override
  Widget build(BuildContext context) {
    final leftLabels = [
      ...List.generate(24, (i) => 'L${i + 1}'),
    ];
    final rightLabels = [
      ...List.generate(24, (i) => 'R${i + 1}'),
    ];

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
                    // 입구 + 방향 표시
                    Column(
                      children: const [
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
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildShelfColumn(rightLabels.sublist(0, 12), context),
                          _buildShelfColumn(leftLabels.sublist(0, 12), context),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShelfColumn(rightLabels.sublist(12), context),
                          _buildShelfColumn(leftLabels.sublist(12), context),
                        ],
                      ),
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