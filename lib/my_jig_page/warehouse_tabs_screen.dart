import 'package:flutter/material.dart';
import '../data/jigs_store.dart';
import '../map_page/jinryang_maps/jinryang_b_dong_map.dart';
import '../map_page/jinryang_maps/jinryang_baekwang_test_building_map.dart';
import 'warehouse_screen.dart';
import 'warehouse_screen_baek.dart';
import '../widgets/jig_item_data.dart';

class WarehouseTabsScreen extends StatefulWidget {
  const WarehouseTabsScreen({super.key});

  @override
  State<WarehouseTabsScreen> createState() => _WarehouseTabsScreenState();
}

class _WarehouseTabsScreenState extends State<WarehouseTabsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  void _openMapForCurrentTab() {
    final idx = _tab.index;
    if (idx == 0) {
      // 진량공장 B동 지도
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => JinryangBDongMap(
          onBack: () => Navigator.pop(context),
          jigsListenable: JigsStore.notifier,
          maxCapacityShelves: 10,
          maxCapacityF: 10,
          weightOfItem: (JigItemData it) => it.capacityWeight,
          onCreateJig: JigsStore.add,
        ),
      ));
    } else {
      // 배광시험동 2층 지도 (ValueListenableBuilder로 items 주입)
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ValueListenableBuilder<List<JigItemData>>(
          valueListenable: JigsStore.notifier,
          builder: (context, items, __) => JinryangBaekwangTestBuildingMap(
            onBack: () => Navigator.pop(context),
            allItems: items,
            maxCapacityPerFloor: 10,
            weightOfItem: (JigItemData it) => it.capacityWeight,
          ),
        ),
      ));
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
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: '뒤로가기',
        ),
        title: const Text('창고 현황', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          TextButton.icon(
            onPressed: _openMapForCurrentTab,
            icon: const Icon(Icons.map_outlined, color: Colors.black),
            label: const Text('지도 보기', style: const TextStyle (color: Colors.black)),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: '진량공장 B동'),
            Tab(text: '배광시험동 2층'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          // AppBar 없는 임베디드 화면
          WarehouseScreenEmbeddedB(),
          WarehouseScreenEmbeddedBaek(),
        ],
      ),
    );
  }
}
