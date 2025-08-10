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

  final Map<String, List<String>> factoryBuildings = {
    'SL 진량 본사': [
      '신관', '본관', '후생동', '진량공장 A동', '진량공장 B동',
      '생산기술센터', 'ADAS 센터', '중앙시험동', '배광시험동',
    ],
    'SL 대구공장': ['공장1', '공장2'],
    'SL 천안공장': ['공장1', '공장2'],
    'SL 안산공장': ['공장1', '공장2'],
    'SL 성산공장': ['공장1', '공장2'],
  };

  void _goBack() {
    setState(() {
      selectedBuilding = null;
    });
  }

  void _selectBuilding(String building) {
    setState(() => selectedBuilding = building);
  }

  /// 공장 버튼 바로 아래에 건물 리스트 드롭다운(뒤로가기 없음)
  Future<void> _openBuildingMenuForGroup(
      String group,
      BuildContext buttonContext,
      ) async {
    setState(() {
      selectedFactoryGroup = group;
      selectedBuilding = null;
    });

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonBox = buttonContext.findRenderObject() as RenderBox;

    final overlaySize = overlay.size;
    final buttonTopLeft = buttonBox.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonBottom = buttonTopLeft.dy + buttonBox.size.height;

    // 메뉴 폭 고정(클램프), 좌우 12px 여백 보장
    const desiredWidth = 240.0;
    final menuWidth = desiredWidth.clamp(200.0, overlaySize.width - 24);

    // 왼쪽 정렬 + 화면 넘침 방지
    double left = buttonTopLeft.dx;
    if (left + menuWidth > overlaySize.width - 12) {
      left = overlaySize.width - menuWidth - 12;
    }
    if (left < 12) left = 12;

    final right = overlaySize.width - (left + menuWidth);
    final top = buttonBottom + 6;

    // 컨텐츠만큼 높이(최대치만 제한)
    final availableHeight =
        overlaySize.height - top - 12 - MediaQuery.of(context).padding.bottom;
    final maxHeight = availableHeight.clamp(120.0, 420.0);

    final position = RelativeRect.fromLTRB(left, top, right, 0);
    final buildings = factoryBuildings[group] ?? const <String>[];

    final selected = await showMenu<String>(
      context: context,
      position: position,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white.withOpacity(0.95),
      constraints: BoxConstraints(
        minWidth: menuWidth,
        maxWidth: menuWidth,
        maxHeight: maxHeight,
      ),
      items: [
        // ✅ 뒤로가기 제거: 건물 리스트만 표시
        ...buildings.asMap().entries.map((e) {
          final idx = e.key + 1;
          final name = e.value;
          return PopupMenuItem<String>(
            value: name,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$idx', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(name)),
              ],
            ),
          );
        }),
      ],
    );

    if (selected == null) return; // 바깥 탭/ESC 등으로 닫힘
    _selectBuilding(selected);
  }

  // AppBar의 가로 공장 버튼바 (버튼 컨텍스트로 메뉴 앵커링)
  Widget _buildFactoryGroupButtonsHorizontal() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        children: factoryBuildings.keys.map((group) {
          final isSelected = group == selectedFactoryGroup;
          return Builder(
            builder: (buttonContext) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  isSelected ? Colors.grey.shade700 : Colors.grey.shade300,
                  foregroundColor: Colors.black,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _openBuildingMenuForGroup(group, buttonContext),
                child: Text(group, overflow: TextOverflow.ellipsis),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMapContent() {
    // 캠퍼스 전체: 진량 본사만 구현, 그 외는 placeholder
    if (selectedBuilding == null) {
      if (selectedFactoryGroup == 'SL 진량 본사') {
        return Container(
          margin: const EdgeInsets.all(10),
          child: buildJinryangMap(context, _selectBuilding),
        );
      } else {
        return const Center(child: Text('지도 준비 중'));
      }
    }

    // 개별 건물
    switch (selectedBuilding) {
      case '진량공장 A동':
        return JinryangADongMap(onBack: _goBack);
      case '진량공장 B동':
        return JinryangBDongMap(onBack: _goBack);
      case '본관':
        return JinryangMainBuildingMap(onBack: _goBack);
      case '후생동':
        return JinryangHusaengdongMap(onBack: _goBack);
      case '신관':
        return JinryangSingwanMap(onBack: _goBack);
      case '생산기술센터':
        return JinryangProductionTechCenterMap(onBack: _goBack);
      case 'ADAS 센터':
        return JinryangAdasCenterMap(onBack: _goBack);
      case '중앙시험동':
        return JinryangCentralTestBuildingMap(onBack: _goBack);
      case '배광시험동':
        return JinryangBaekwangTestBuildingMap(onBack: _goBack);
      default:
        return Center(child: Text('$selectedBuilding 지도는 준비 중입니다.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        // ✅ 기본/자동 back 아이콘 숨김
        automaticallyImplyLeading: false,
        // ❌ 명시적으로 넣었던 leading 아이콘 제거
        // leading: IconButton(
        //   onPressed: _goBack,
        //   icon: const Icon(Icons.arrow_back),
        //   tooltip: '뒤로가기',
        // ),
        titleSpacing: 0,
        title: _buildFactoryGroupButtonsHorizontal(),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildMapContent()),
        ],
      ),
    );
  }
}
