import 'package:flutter/material.dart';
import '/map_page/jinryang_map.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String selectedFactory = 'SL 진량 본사'; // 기본 선택
  bool showFactoryList = false;

  final List<String> factories = [
    'SL 진량 본사',
    '진량공장 A동',
    '진량공장 B동',
    '생산기술센터',
    'ADAS',
    '중앙시험동',
    '본관',
    '후생동',
    '신관',
    '배광시험동',
  ];

  void _toggleFactoryList() {
    setState(() {
      showFactoryList = !showFactoryList;
    });

    if (showFactoryList) {
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) {
          setState(() {
            showFactoryList = false;
          });
        }
      });
    }
  }

  void _goToPage(BuildContext context, String buildingName) {
    setState(() {
      selectedFactory = buildingName;
      showFactoryList = false;
    });
  }

  Widget _buildFactoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: factories.map((name) {
        final isSelected = selectedFactory == name;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? Colors.grey.shade700 : Colors.grey.shade300,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onPressed: () {
              setState(() {
                selectedFactory = name;
                showFactoryList = false;
              });
            },
            child: Text(name),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFactoryMap(String factory) {
    if (factory == 'SL 진량 본사') {
      return buildJinryangMap(context, (buildingName) => _goToPage(context, buildingName));
    }

    return Center(
      child: Text(
        '$factory 지도는 준비 중입니다.',
        style: const TextStyle(fontSize: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: selectedFactory != 'SL 진량 본사'
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              selectedFactory = 'SL 진량 본사';
              showFactoryList = false;
            });
          },
        )
            : null,
      ),
      body: Stack(
        children: [
          // 지도 영역
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              child: _buildFactoryMap(selectedFactory),
            ),
          ),

          // 공장 선택 버튼 및 리스트
          Positioned(
            top: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton(
                  onPressed: _toggleFactoryList,
                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
                  child: Text(selectedFactory),
                ),
                if (showFactoryList)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: _buildFactoryList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
