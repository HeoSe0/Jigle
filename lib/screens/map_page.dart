// lib/screens/map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../widgets/jig_item_data.dart';

import '../map_page/jinryang_map.dart';
import '../map_page/jinryang_maps/jinryang_a_dong_map.dart';
import '../map_page/jinryang_maps/jinryang_b_dong_map.dart';
import '../map_page/jinryang_maps/jinryang_main_building_map.dart';
import '../map_page/jinryang_maps/jinryang_husaengdong_map.dart';
import '../map_page/jinryang_maps/jinryang_singwan_map.dart';
import '../map_page/jinryang_maps/jinryang_production_tech_center_map.dart';
import '../map_page/jinryang_maps/jinryang_adas_center_map.dart';
import '../map_page/jinryang_maps/jinryang_central_test_building_map.dart';
import '../map_page/jinryang_maps/jinryang_baekwang_test_building_map.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.jigsNotifier});
  final ValueListenable<List<JigItemData>> jigsNotifier;

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

  void _goBack() => setState(() => selectedBuilding = null);
  void _selectBuilding(String building) => setState(() => selectedBuilding = building);

  // ---------- 커스텀 앵커 메뉴(스크롤 없음) ----------
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
                                width: 24, height: 24, alignment: Alignment.center,
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
      transitionBuilder: (context, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
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

    final bottomSpace = overlaySize.height - (buttonBottom + 6) - 12 - MediaQuery.of(context).padding.bottom;
    final topSpace = (buttonTopLeft.dy - 6) - 12 - MediaQuery.of(context).padding.top;

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
      left: left, top: top, width: menuWidth, items: buildings,
    );
    if (selected == null) return;
    _selectBuilding(selected);
  }

  // ---------- 상단 공장 그룹 버튼 바 ----------
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

  // ---------- B동 포화도 집계 유틸 ----------
  int _weightForSize(String size) {
    switch (size) {
      case '대형': return 5;
      case '중형': return 3;
      case '소형':
      default: return 1;
    }
  }

  String? _slotOf(String loc) {
    final p = loc.split('/').map((e) => e.trim()).toList();
    return p.length > 1 ? p[1] : null; // L1/C1/R1/F1~F4
  }
  String? _floorOf(String loc) {
    final p = loc.split('/').map((e) => e.trim()).toList();
    if (p.length > 2) {
      final m = RegExp(r'(\d)').firstMatch(p[2]);
      if (m != null) return '${m.group(1)}층';
    }
    return null;
  }

  Map<String, int> _capsFrom(List<JigItemData> items) {
    final out = <String, int>{};
    for (final it in items) {
      final loc = it.location.trim();
      if (!loc.startsWith('진량공장 B동')) continue;
      final slot = _slotOf(loc);
      final w = _weightForSize(it.size);
      if (slot == null) continue;

      if (slot.startsWith('F')) {
        out[slot] = (out[slot] ?? 0) + w;
      } else {
        final fl = _floorOf(loc);
        if (fl != null) out['$slot/$fl'] = (out['$slot/$fl'] ?? 0) + w;
          }
         }
            return out;
        }

  // ---------- 지도 콘텐츠 ----------
  Widget _buildMapContent() {
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

    switch (selectedBuilding) {
      case '진량공장 B동':
        return ValueListenableBuilder<List<JigItemData>>(
          valueListenable: widget.jigsNotifier,
          builder: (_, items, __) {
            final caps = _capsFrom(items);
            return JinryangBDongMap(
              onBack: _goBack,
              allItems: items,
              // 선반/층 포화도
              l1Floor1Capacity: caps['L1/1층'] ?? 0,
              l1Floor2Capacity: caps['L1/2층'] ?? 0,
              l1Floor3Capacity: caps['L1/3층'] ?? 0,
              l1Floor4Capacity: caps['L1/4층'] ?? 0,
              r1Floor1Capacity: caps['R1/1층'] ?? 0,
              r1Floor2Capacity: caps['R1/2층'] ?? 0,
              r1Floor3Capacity: caps['R1/3층'] ?? 0,
              r1Floor4Capacity: caps['R1/4층'] ?? 0,
              c1Floor1Capacity: caps['C1/1층'] ?? 0,
              c1Floor2Capacity: caps['C1/2층'] ?? 0,
              c1Floor3Capacity: caps['C1/3층'] ?? 0,
              c1Floor4Capacity: caps['C1/4층'] ?? 0,
              // F 존 포화도
              f1Capacity: caps['F1'] ?? 0,
              f2Capacity: caps['F2'] ?? 0,
              f3Capacity: caps['F3'] ?? 0,
              f4Capacity: caps['F4'] ?? 0,
              // 상한(색상 스케일)
              maxCapacityShelves: 40,
              maxCapacityF: 20,
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
