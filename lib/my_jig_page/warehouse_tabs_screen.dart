// lib/my_jig_page/warehouse_tabs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../data/jigs_store.dart';
import '../widgets/jig_item_data.dart';

// 탭 본문
import 'warehouse_screen.dart';       // 진량공장 B동(embedded 지원)
import 'warehouse_screen_baek.dart';  // 배광시험동 2층(embedded 지원)

// 지도 위젯
import '../map_page/jinryang_maps/jinryang_b_dong_map.dart';
import '../map_page/jinryang_maps/jinryang_baekwang_test_building_map.dart';

class WarehouseTabsScreen extends StatefulWidget {
  const WarehouseTabsScreen({super.key});

  @override
  State<WarehouseTabsScreen> createState() => _WarehouseTabsScreenState();
}

class _WarehouseTabsScreenState extends State<WarehouseTabsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  ValueListenable<List<JigItemData>> get _itemsVN => JigsStore.notifier;

  void _openMapForCurrentTab(BuildContext context) {
    final idx = _tab.index;

    if (idx == 0) {
      // 진량공장 B동 지도
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JinryangBDongMap(
            onBack: () => Navigator.pop(context),
            jigsListenable: _itemsVN,
            maxCapacityShelves: 10,
            maxCapacityF: 10,
            weightOfItem: (it) => it.capacityWeight,
            onCreateJig: JigsStore.add,
          ),
        ),
      );
    } else {
      // 배광시험동 2층 지도 (층: 1~4)
      final all = _itemsVN.value;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JinryangBaekwangTestBuildingMap(
            onBack: () => Navigator.pop(context),
            allItems: all,
            maxCapacityPerFloor: 10,
            weightOfItem: (it) => it.capacityWeight,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('창고 현황'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: '진량공장 B동'),
            Tab(text: '배광시험동 2층'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _openMapForCurrentTab(context),
            icon: const Icon(Icons.map_outlined, size: 20),
            label: const Text('지도 보기'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          // AppBar는 탭 상단 하나만 쓰므로, 각 화면은 embedded=true로 body만 렌더
          WarehouseScreen(
            embedded: true,
            showMapButton: false, // 내부에서 또 지도 버튼 안보이게
          ),
          WarehouseScreenBaek(
            embedded: true,
            // Baek 화면은 자체 지도 버튼을 쓰지 않으므로 별도 옵션 불필요
          ),
        ],
      ),
    );
  }
}
