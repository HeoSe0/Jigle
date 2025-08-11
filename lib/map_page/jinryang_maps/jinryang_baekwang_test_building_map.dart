import 'package:flutter/material.dart';

class JinryangBaekwangTestBuildingMap extends StatelessWidget {
  final VoidCallback onBack;
  const JinryangBaekwangTestBuildingMap({super.key, required this.onBack});

  // ===== Layout & Style constants =====
  static const double _kBtnW = 80;
  static const double _kBtnH = 160;
  static const double _kGapV = 8;   // 세로 버튼 간격
  static const double _kColGap = 70; // 좌/우 컬럼 사이 간격
  static const int _kItemsPerColumn = 12;

  static double get _rowWidth => _kBtnW * 2 + _kColGap; // 80 + 24 + 80 = 184
  static double get _rowHeight =>
      _kItemsPerColumn * _kBtnH + (_kItemsPerColumn - 1) * _kGapV;

  // ===== Dialog =====
  void _showImage(BuildContext context, String label) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: Text('$label 이미지'),
        content: Image.asset('assets/sample_box1.png', fit: BoxFit.cover),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  // ===== Widgets =====
  Widget _buildShelfColumn(List<String> labels, BuildContext context) {
    return Column(
      children: List.generate(labels.length, (i) {
        final label = labels[i];
        return Container(
          margin: EdgeInsets.only(bottom: i == labels.length - 1 ? 0 : _kGapV),
          width: _kBtnW,
          height: _kBtnH,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue.shade100,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.black),
                borderRadius: BorderRadius.zero,
              ),
              padding: EdgeInsets.zero,
            ),
            onPressed: () => _showImage(context, label),
            child: Text(label),
          ),
        );
      }),
    );
  }

  /// 한 행(좌 12개 / 우 12개) 레이아웃
  Widget _buildShelfRow({
    required List<String> rightLabels, // R1~R12
    required List<String> leftLabels,  // L1~L12
    required BuildContext context,
  }) {
    return Center(
      child: SizedBox(
        width: _rowWidth,   // 184
        height: _rowHeight, // 12*160 + 11*8
        child: Stack(
          children: [
            // 중앙 박스 (좌/우 컬럼 사이 영역)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 5),
                ),
              ),
            ),
            // 좌/우 버튼 컬럼
            Positioned(
              left: 0,
              top: 0,
              child: _buildShelfColumn(rightLabels, context),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: _buildShelfColumn(leftLabels, context),
            ),
          ],
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Column(
                children: [
                  const Column(
                    children: [
                      Text(
                        'IN',
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
                  // 1행 (R1~R12 / L1~L12)
                  _buildShelfRow(
                    rightLabels: rightLabels.sublist(0, 12),
                    leftLabels: leftLabels.sublist(0, 12),
                    context: context,
                  ),
                  const SizedBox(height: 50),
                  // 2행 (R13~R24 / L13~L24)
                  _buildShelfRow(
                    rightLabels: rightLabels.sublist(12),
                    leftLabels: leftLabels.sublist(12),
                    context: context,
                  ),
                ],
              ),
            ),

            // Back 버튼
            Positioned(
              top: 12,
              left: 12,
              child: IconButton.filledTonal(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(padding: const EdgeInsets.all(10)),
                tooltip: '뒤로',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
