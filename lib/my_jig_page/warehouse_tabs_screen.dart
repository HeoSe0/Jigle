import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../widgets/jig_item_data.dart';
import 'warehouse_screen.dart';
import 'warehouse_screen_baek.dart';

class WarehouseTabsScreen extends StatelessWidget {
  const WarehouseTabsScreen({
    super.key,
    required this.itemsListenable,
  });

  final ValueListenable<List<JigItemData>> itemsListenable;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          title: const Text('창고 현황'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            labelColor: Colors.black,
            tabs: [
              Tab(text: '진량공장 B동'),
              Tab(text: '배광시험동 2층'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            WarehouseScreen(embedded: true, itemsListenable: itemsListenable),
            WarehouseScreenBaek(
              embedded: true,
              itemsListenable: itemsListenable,
              showAll: false, // 데이터 있는 선반만 카드 노출 (원하면 true로)
            ),
          ],
        ),
      ),
    );
  }
}
