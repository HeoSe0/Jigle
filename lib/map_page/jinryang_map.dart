import 'package:flutter/material.dart';

Widget buildJinryangMap(BuildContext context, void Function(String) onTap) {
  const imageOriginalWidth = 700.0;  // 원본 지도 이미지 너비
  const imageOriginalHeight = 600.0; // 원본 지도 이미지 높이

  Widget buildBox({
    required double left,
    required double top,
    required double width,
    required double height,
    required Color color, // 사용되지 않지만 구조상 남겨둠
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
        final scale = scaleX < scaleY ? scaleX : scaleY;

        double s(double val) => val * scale;

        return Stack(
          children: [
            Positioned(
              left: (constraints.maxWidth - imageOriginalWidth * scale) / 2,
              top: (constraints.maxHeight - imageOriginalHeight * scale) / 2,
              width: imageOriginalWidth * scale,
              height: imageOriginalHeight * scale,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/maps/main_map.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                  buildBox(
                    left: s(280),
                    top: s(304),
                    width: s(191),
                    height: s(177),
                    color: Colors.blue,
                    label: '진량공장 A동',
                  ),
                  buildBox(
                    left: s(281),
                    top: s(67),
                    width: s(191),
                    height: s(208),
                    color: Colors.orange,
                    label: '진량공장 B동',
                  ),
                  buildBox(
                    left: s(75),
                    top: s(215),
                    width: s(178),
                    height: s(115),
                    color: Colors.green,
                    label: '생산기술센터',
                  ),
                  buildBox(
                    left: s(60),
                    top: s(80),
                    width: s(173),
                    height: s(60),
                    color: Colors.purple,
                    label: 'ADAS',
                  ),
                  buildBox(
                    left: s(495),
                    top: s(70),
                    width: s(32),
                    height: s(152),
                    color: Colors.teal,
                    label: '중앙시험동',
                  ),
                  buildBox(
                    left: s(355),
                    top: s(510),
                    width: s(80),
                    height: s(42),
                    color: Colors.red,
                    label: '본관',
                  ),
                  buildBox(
                    left: s(255),
                    top: s(510),
                    width: s(82),
                    height: s(42),
                    color: Colors.indigo,
                    label: '후생동',
                  ),
                  buildBox(
                    left: s(212),
                    top: s(477),
                    width: s(35),
                    height: s(75),
                    color: Colors.grey,
                    label: '신관',
                  ),
                  buildBox(
                    left: s(142),
                    top: s(45),
                    width: s(100),
                    height: s(33),
                    color: Colors.brown,
                    label: '배광시험동',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
