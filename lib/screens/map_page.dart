import 'dart:async';
import 'package:flutter/material.dart';

import '/map_page/jinryang_map.dart';
import '/map_page/jinryang_maps/jinryang_a_dong_map.dart';
import '/map_page/jinryang_maps/jinryang_b_dong_map.dart';
import '/map_page/jinryang_maps/jinryang_main_building_map.dart';
import '/map_page/jinryang_maps/jinryang_husaengdong_map.dart';
import '/map_page/jinryang_maps/jinryang_singwan_map.dart';
import '/map_page/jinryang_maps/jinryang_production_tech_center_map.dart';
import '/map_page/jinryang_maps/jinryang_adas_center_map.dart';
import '/map_page/jinryang_maps/jinryang_central_test_building_map.dart';
import '/map_page/jinryang_maps/jinryang_baekwang_test_building_map.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String selectedFactoryGroup = 'SL 진량 본사';
  String? selectedBuilding;
  bool isBuildingNavVisible = false;
  Timer? _hideTimer;

  final Map<String, List<String>> factoryBuildings = {
    'SL 진량 본사': [
      '신관',
      '본관',
      '후생동',
      '진량공장 A동',
      '진량공장 B동',
      '생산기술센터',
      'ADAS 센터',
      '중앙시험동',
      '배광시험동',
    ],
    'SL 대구공장': ['공장1', '공장2'],
    'SL 천안공장': ['공장1', '공장2'],
    'SL 안산공장': ['공장1', '공장2'],
    'SL 성산공장': ['공장1', '공장2'],
  };

  void _selectFactoryGroup(String group) {
    setState(() {
      selectedFactoryGroup = group;
      selectedBuilding = null;
      isBuildingNavVisible = true;
    });
    _startHideTimer();
  }

  void _selectBuilding(String building) {
    setState(() {
      selectedBuilding = building;
      isBuildingNavVisible = true;
    });
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        isBuildingNavVisible = false;
      });
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  Widget _buildFactoryGroupButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: factoryBuildings.keys.map((group) {
        final isSelected = group == selectedFactoryGroup;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? Colors.grey.shade700 : Colors.grey.shade300,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              foregroundColor: Colors.black,
            ),
            onPressed: () => _selectFactoryGroup(group),
            child: Text(group),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBuildingListVertical() {
    final buildings = factoryBuildings[selectedFactoryGroup]!;

    return ListView.builder(
      itemCount: buildings.length,
      itemBuilder: (context, index) {
        final name = buildings[index];
        final isSelected = name == selectedBuilding;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 40),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onPressed: () => _selectBuilding(name),
            child: Text('${index + 1}. $name'),
          ),
        );
      },
    );
  }

  Widget _buildMapContent() {
    void onBack() {
      setState(() {
        selectedBuilding = null;
        isBuildingNavVisible = true;
      });
      _startHideTimer();
    }

    if (selectedBuilding == null) {
      return Container(
        margin: const EdgeInsets.all(10),
        child: buildJinryangMap(context, _selectBuilding),
      );
    }

    switch (selectedBuilding) {
      case '진량공장 A동':
        return JinryangADongMap(onBack: onBack);
      case '진량공장 B동':
        return JinryangBDongMap(onBack: onBack);
      case '본관':
        return JinryangMainBuildingMap(onBack: onBack);
      case '후생동':
        return JinryangHusaengdongMap(onBack: onBack);
      case '신관':
        return JinryangSingwanMap(onBack: onBack);
      case '생산기술센터':
        return JinryangProductionTechCenterMap(onBack: onBack);
      case 'ADAS 센터':
        return JinryangAdasCenterMap(onBack: onBack);
      case '중앙시험동':
        return JinryangCentralTestBuildingMap(onBack: onBack);
      case '배광시험동':
        return JinryangBaekwangTestBuildingMap(onBack: onBack);
      default:
        return Center(child: Text('$selectedBuilding 지도는 준비 중입니다.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showMap = selectedFactoryGroup == 'SL 진량 본사';

    return Scaffold(
      appBar: AppBar(title: const Text('공장 지도')),
      body: Stack(
        children: [
          Positioned.fill(
            child: showMap ? _buildMapContent() : const Center(child: Text('지도 준비 중')),
          ),

          Positioned(
            top: 12,
            left: 12,
            child: Container(
              color: Colors.transparent,
              child: _buildFactoryGroupButtons(),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: 12,
            left: isBuildingNavVisible ? 160 : 100,
            width: isBuildingNavVisible ? 140 : 0,
            height: 340,
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: isBuildingNavVisible ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _buildBuildingListVertical(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
