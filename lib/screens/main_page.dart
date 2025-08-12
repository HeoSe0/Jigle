// lib/screens/main_page.dart
import 'package:flutter/material.dart';

import '../widgets/jig_item_data.dart';
import '../widgets/home_search_tab.dart';
import 'map_page.dart';
import 'warehouse_jigs_page.dart';
import 'my_jigs_page.dart';

enum MainTab { home, map, warehouse, mine }

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // ✅ 앱 전역에서 공유할 지그 리스트
  final ValueNotifier<List<JigItemData>> _jigsNotifier =
  ValueNotifier<List<JigItemData>>([
    // 초기 샘플이 필요하면 여기에 추가하세요.
    // JigItemData(
    //   image: 'jig_example1.jpg',
    //   title: 'LX3 진동&배광 지그 1대분',
    //   location: '진량공장 B동 / L1 / 2층',
    //   description: 'LX3 진동&배광 지그',
    //   registrant: '전장램프설계6팀 최은석 사원',
    //   storageDate: DateTime.now(),
    //   size: '중형',
    // ),
  ]);

  // 좋아요(나의 지그) 목록
  final ValueNotifier<List<JigItemData>> _likedItems =
  ValueNotifier<List<JigItemData>>([]);

  MainTab _currentTab = MainTab.home;

  Widget _buildBody() {
    switch (_currentTab) {
      case MainTab.home:
        return HomeSearchTab(
          logoAssetPath: 'assets/jigle_logo.png',
          slLogoAssetPath: 'assets/sl_logo.png',
          logoHeight: 150,
          slLogoHeight: 28,
          onSearch: (query) => debugPrint('검색어: $query'),
        );

      case MainTab.map:
      // ✅ 지도 페이지에도 같은 지그 리스트 전달
        return MapPage(jigsNotifier: _jigsNotifier);

      case MainTab.warehouse:
      // ✅ 창고별 지그 페이지에도 같은 지그 리스트 전달
        return WarehouseJigsPage(
          likedItemsNotifier: _likedItems,
          jigsNotifier: _jigsNotifier,
        );

      case MainTab.mine:
        return ValueListenableBuilder<List<JigItemData>>(
          valueListenable: _likedItems,
          builder: (_, liked, __) => MyJigsPage(likedItems: liked),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentTab.index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentTab = MainTab.values[index]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '지도'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: '창고별 지그'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '나의 지그'),
        ],
      ),
    );
  }
}
