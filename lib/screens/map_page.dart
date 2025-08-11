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

  /// 스크롤 없는 커스텀 앵커 메뉴
  Future<String?> _showAnchoredMenuNoScroll({
    required double left,
    required double top,
    required double width,
    required List<String> items,
  }) {
    const rowHeight = 44.0;
    final fullHeight = items.length * rowHeight + 8.0;

    return showGeneralDialog<String>(
      context: context,
      barrierLabel: 'dismiss',
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (_, __, ___) {
        return Stack(
          children: [
            // 바깥 터치로 닫기
            Positioned.fill(
              child: GestureDetector(onTap: () => Navigator.of(context).pop()),
            ),
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                elevation: 6,
                child: Container(
                  width: width,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 8,
                        color: Colors.black12,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(items.length, (i) {
                      final name = items[i];
                      return InkWell(
                        onTap: () => Navigator.of(context).pop(name),
                        child: Container(
                          height: rowHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                child: Text('${i + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(name)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }

  /// 공장 버튼 바로 아래에 건물 리스트 드롭다운(뒤로가기 없음, 스크롤 없음)
  Future<void> _openBuildingMenuForGroup(
      String group,
      BuildContext buttonContext,
      ) async {
    setState(() {
      selectedFactoryGroup = group;
      selectedBuilding = null;
    });

    final overlayBox =
    Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonBox = buttonContext.findRenderObject() as RenderBox;

    final overlaySize = overlayBox.size;
    final buttonTopLeft =
    buttonBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final buttonBottom = buttonTopLeft.dy + buttonBox.size.height;

    // 메뉴 폭 고정(클램프), 좌우 12px 여백 보장
    const desiredWidth = 240.0;
    final menuWidth = desiredWidth.clamp(200.0, overlaySize.width - 24);

    // 왼쪽 정렬 + 화면 넘침 방지(좌우만 클램프)
    double left = buttonTopLeft.dx;
    if (left + menuWidth > overlaySize.width - 12) {
      left = overlaySize.width - menuWidth - 12;
    }
    if (left < 12) left = 12;

    // 위/아래 중 어디로 펼칠지 결정 (스크롤 없이 전체 보이도록)
    final buildings = factoryBuildings[group] ?? const <String>[];
    const rowHeight = 44.0;
    final fullHeight = buildings.length * rowHeight + 8.0;

    // 아래로 펼친 경우의 하단 여유
    final bottomSpace =
        overlaySize.height - (buttonBottom + 6) - 12 - MediaQuery.of(context).padding.bottom;
    // 위로 펼친 경우의 상단 여유
    final topSpace =
        (buttonTopLeft.dy - 6) - 12 - MediaQuery.of(context).padding.top;

    double top;
    if (fullHeight <= bottomSpace) {
      // 아래로 펼쳐도 다 보임
      top = buttonBottom + 6;
    } else if (fullHeight <= topSpace) {
      // 위로 펼치면 다 보임
      top = buttonTopLeft.dy - 6 - fullHeight;
      if (top < 12) top = 12;
    } else {
      // 화면보다 메뉴가 더 큼: 그래도 스크롤 금지 조건 → 위로 붙여서 최대한 노출
      top = (overlaySize.height - fullHeight) / 2;
      if (top < 12) top = 12;
    }

    // 스크롤 없는 커스텀 팝업 표시
    final selected = await _showAnchoredMenuNoScroll(
      left: left,
      top: top,
      width: menuWidth,
      items: buildings,
    );

    if (selected == null) return; // 바깥 탭으로 닫힘
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        // 기본/자동 back 아이콘 숨김
        automaticallyImplyLeading: false,
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
