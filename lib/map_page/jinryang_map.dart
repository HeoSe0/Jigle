import 'package:flutter/material.dart';

Widget buildJinryangMap(BuildContext context, void Function(String) onTap) {
  const imageOriginalWidth = 700.0;  // 원본 지도 이미지 너비
  const imageOriginalHeight = 600.0; // 원본 지도 이미지 높이

  Widget buildBox({
    required double left,
    required double top,
    required double width,
    required double height,
    required Color color, // <- 현재는 무시되지만 남겨둠
    required String label,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () => onTap(label),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent, width: 3),
          ),
        ),
      ),
    );
  }

  return InteractiveViewer(
    minScale: 0.5,
    maxScale: 4.0,
    boundaryMargin: const EdgeInsets.all(double.infinity),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final scaleX = constraints.maxWidth / imageOriginalWidth;
        final scaleY = constraints.maxHeight / imageOriginalHeight;

        double sx(double val) => val * scaleX;
        double sy(double val) => val * scaleY;

        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/maps/main_map.png',
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
            // 박스들 (테두리는 모두 투명)
            buildBox(
              left: sx(300),
              top: sy(304),
              width: sx(136),
              height: sy(175),
              color: Colors.blue,
              label: '진량공장 A동',
            ),
            buildBox(
              left: sx(302),
              top: sy(67),
              width: sx(133),
              height: sy(208),
              color: Colors.orange,
              label: '진량공장 B동',
            ),
            buildBox(
              left: sx(157),
              top: sy(215),
              width: sx(123),
              height: sy(115),
              color: Colors.green,
              label: '생산기술센터',
            ),
            buildBox(
              left: sx(147),
              top: sy(80),
              width: sx(120),
              height: sy(60),
              color: Colors.purple,
              label: 'ADAS',
            ),
            buildBox(
              left: sx(452),
              top: sy(70),
              width: sx(24),
              height: sy(152),
              color: Colors.teal,
              label: '중앙시험동',
            ),
            buildBox(
              left: sx(353),
              top: sy(510),
              width: sx(58),
              height: sy(42),
              color: Colors.red,
              label: '본관',
            ),
            buildBox(
              left: sx(283),
              top: sy(510),
              width: sx(58),
              height: sy(42),
              color: Colors.indigo,
              label: '후생동',
            ),
            buildBox(
              left: sx(253),
              top: sy(477),
              width: sx(25),
              height: sy(75),
              color: Colors.grey,
              label: '신관',
            ),
            buildBox(
              left: sx(140),
              top: sy(45),
              width: sx(87),
              height: sy(30),
              color: Colors.brown,
              label: '배광시험동',
            ),
          ],
        );
      },
    ),
  );
}
