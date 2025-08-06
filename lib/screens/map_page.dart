import 'package:flutter/material.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('SL 진량 본사'),
        backgroundColor: Colors.white,),
      body: Center(
        child: InteractiveViewer(
          child: Stack(
            children: [
              Image.asset(
                'factory_map.png',
                fit: BoxFit.cover,
              ),

              // 진량공장 A동
              Positioned(
                left: 270,
                top: 290,
                width: 180,
                height: 160,
                child: GestureDetector(
                  onTap: () => _showDialog(context, '진량공장 A동'),
                  child: _buildBorderBox(Colors.blue),
                ),
              ),

              // 진량공장 B동
              Positioned(
                left: 270,
                top: 65,
                width: 180,
                height: 190,
                child: GestureDetector(
                  onTap: () => _showDialog(context, '진량공장 B동'),
                  child: _buildBorderBox(Colors.orange),
                ),
              ),

              // 생산기술센터
              Positioned(
                left: 75,
                top: 208,
                width: 165,
                height: 100,
                child: GestureDetector(
                  onTap: () => _showDialog(context, '생산기술센터'),
                  child: _buildBorderBox(Colors.green),
                ),
              ),

              // ADAS
              Positioned(
                left: 60,
                top: 74,
                width: 160,
                height: 58,
                child: GestureDetector(
                  onTap: () => _showDialog(context, 'ADAS'),
                  child: _buildBorderBox(Colors.purple),
                ),
              ),

              // 중앙시험동
              Positioned(
                left: 480,
                top: 70,
                width: 30,
                height: 140,
                child: GestureDetector(
                  onTap: () => _showDialog(context, '중앙시험동'),
                  child: _buildBorderBox(Colors.teal),
                ),
              ),

              // 본관
              Positioned(
                left: 340,
                top: 485,
                width: 80,
                height: 40,
                child: GestureDetector(
                  onTap: () => _showDialog(context, '본관'),
                  child: _buildBorderBox(Colors.red),
                ),
              ),

              // 후생동
              Positioned(
                left: 243,
                top: 485,
                width: 80,
                height: 40,
                child: GestureDetector(
                  onTap: () => _showDialog(context, '후생동'),
                  child: _buildBorderBox(Colors.indigo),
                ),
              ),

              // 신관
              Positioned(
                left: 203,
                top: 450,
                width: 35,
                height: 75,
                child: GestureDetector(
                  onTap: () => _showDialog(context, '신관'),
                  child: _buildBorderBox(Colors.grey),
                ),
              ),

              // ✅ 배광시험동 (추가됨)
              Positioned(
                left: 140,
                top: 45,
                width: 87,
                height: 30,
                child: GestureDetector(
                  onTap: () => _showDialog(context, '배광시험동'),
                  child: _buildBorderBox(Colors.brown),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 공통 스타일 함수
  Widget _buildBorderBox(Color color) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        color: Colors.transparent,
      ),
    );
  }

  void _showDialog(BuildContext context, String buildingName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(buildingName),
        content: const Text('이 영역을 클릭했습니다.'),
        actions: [
          TextButton(
            child: const Text('닫기'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
