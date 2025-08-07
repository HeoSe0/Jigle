import 'package:flutter/material.dart';

class JinryangProductionTechCenterMap extends StatelessWidget {
  final VoidCallback onBack;

  const JinryangProductionTechCenterMap({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Text(
            '생산기술센터 지도입니다.',
            style: TextStyle(fontSize: 24),
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
    );
  }
}
