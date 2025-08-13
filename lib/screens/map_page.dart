// lib/screens/map_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../map_page/jinryang_map.dart';
import '../map_page/jinryang_maps/jinryang_a_dong_map.dart';
import '../map_page/jinryang_maps/jinryang_adas_center_map.dart';
import '../map_page/jinryang_maps/jinryang_b_dong_map.dart';
import '../map_page/jinryang_maps/jinryang_baekwang_test_building_map.dart';
import '../map_page/jinryang_maps/jinryang_central_test_building_map.dart';
import '../map_page/jinryang_maps/jinryang_husaengdong_map.dart';
import '../map_page/jinryang_maps/jinryang_main_building_map.dart';
import '../map_page/jinryang_maps/jinryang_production_tech_center_map.dart';
import '../map_page/jinryang_maps/jinryang_singwan_map.dart';
import '../widgets/jig_item_data.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.jigsNotifier});

  /// 전체 지그 리스트(지도와 포화도/카드 연동에 사용)
  final ValueListenable<List<JigItemData>> jigsNotifier;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String selectedFactoryGroup = 'SL 진량 본사';
  String? selectedBuilding;

  final Map<String, List<String>> factoryBuildings = const {
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

  void _goBack() => setState(() => selectedBuilding = null);
  void _selectBuilding(String building) => setState(() => selectedBuilding = building);

  // ───────────────── 커스텀 앵커 메뉴(스크롤 없음) ─────────────────
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
                  height: fullHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(blurRadius: 8, color: Colors.black12, offset: Offset(0, 2)),
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
                                child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
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
      transitionBuilder: (context, anim, __, child) => FadeTransition(opacity: anim, child: child),
    );
  }

  Future<void> _openBuildingMenuForGroup(String group, BuildContext buttonContext) async {
    setState(() {
      selectedFactoryGroup = group;
      selectedBuilding = null;
    });

    final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonBox = buttonContext.findRenderObject() as RenderBox;

    final overlaySize = overlayBox.size;
    final buttonTopLeft = buttonBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final buttonBottom = buttonTopLeft.dy + buttonBox.size.height;

    const desiredWidth = 240.0;
    final menuWidth = desiredWidth.clamp(200.0, overlaySize.width - 24);
    double left = buttonTopLeft.dx;
    if (left + menuWidth > overlaySize.width - 12) left = overlaySize.width - menuWidth - 12;
    if (left < 12) left = 12;

    final buildings = factoryBuildings[group] ?? const <String>[];
    const rowHeight = 44.0;
    final fullHeight = buildings.length * rowHeight + 8.0;

    final padding = MediaQuery.of(context).padding;
    final bottomSpace = overlaySize.height - (buttonBottom + 6) - 12 - padding.bottom;
    final topSpace = (buttonTopLeft.dy - 6) - 12 - padding.top;

    double top;
    if (fullHeight <= bottomSpace) {
      top = buttonBottom + 6;
    } else if (fullHeight <= topSpace) {
      top = buttonTopLeft.dy - 6 - fullHeight;
      if (top < 12) top = 12;
    } else {
      top = (overlaySize.height - fullHeight) / 2;
      if (top < 12) top = 12;
    }

    final selected = await _showAnchoredMenuNoScroll(
      left: left,
      top: top,
      width: menuWidth,
      items: buildings,
    );
    if (selected == null) return;
    _selectBuilding(selected);
  }

  // ───────────────── 상단 공장 그룹 버튼 바 ─────────────────
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
                  backgroundColor: isSelected ? Colors.grey.shade700 : Colors.grey.shade300,
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

  // ───────────────── 지도 콘텐츠 ─────────────────
  Widget _buildMapContent() {
    if (selectedBuilding == null) {
      if (selectedFactoryGroup == 'SL 진량 본사') {
        return Container(
          margin: const EdgeInsets.all(10),
          child: buildJinryangMap(context, _selectBuilding),
        );
      }
      return const Center(child: Text('지도 준비 중'));
    }

    switch (selectedBuilding) {
      case '진량공장 B동':
        return ValueListenableBuilder<List<JigItemData>>(
          valueListenable: widget.jigsNotifier,
          builder: (_, items, __) {
            return JinryangBDongMap(
              onBack: _goBack,
              allItems: items,
              // 포화도 상한(대형 2개 = 10 → 빠르게 빨강)
              maxCapacityShelves: 10,
              maxCapacityF: 10,
              // size → 1/3/5 가중치
              weightOfItem: (it) => it.capacityWeight,
            );
          },
        );

      case '진량공장 A동':
        return JinryangADongMap(onBack: _goBack);
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
        return ValueListenableBuilder<List<JigItemData>>(
          valueListenable: widget.jigsNotifier,
          builder: (_, items, __) {
            return JinryangBaekwangTestBuildingMap(
              onBack: _goBack,
              allItems: items,                 // 지그 리스트 연동
              maxCapacityPerFloor: 10,         // 층 버튼 색상 상한
              weightOfItem: (it) => it.capacityWeight,
            );
          },
        );

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
