// lib/screens/main_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

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
  // 앱 전역 공유 리스트
  final ValueNotifier<List<JigItemData>> _jigsNotifier =
  ValueNotifier<List<JigItemData>>([]);

  // ‘나의 지그(좋아요)’ 목록
  final ValueNotifier<List<JigItemData>> _likedItems =
  ValueNotifier<List<JigItemData>>([]);

  MainTab _current = MainTab.home;

  // 뒤로가기: 홈이 아니면 홈으로 이동
  Future<bool> _onWillPop() async {
    if (_current != MainTab.home) {
      setState(() => _current = MainTab.home);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      // 홈
      HomeSearchTab(
        logoAssetPath: 'assets/jigle_logo.png',
        slLogoAssetPath: 'assets/sl_logo.png',
        logoHeight: 150,
        slLogoHeight: 28,
        onSearch: (q) => debugPrint('검색어: $q'),
      ),

      // 지도 (전역 지그 목록 공유)
      MapPage(jigsNotifier: _jigsNotifier),

      // 창고별 지그
      WarehouseJigsPage(
        likedItemsNotifier: _likedItems,
        jigsNotifier: _jigsNotifier,
      ),

      // 나의 지그
      ValueListenableBuilder<List<JigItemData>>(
        valueListenable: _likedItems,
        builder: (_, liked, __) => MyJigsPage(
          likedItems: liked,
          jigsNotifier: _jigsNotifier,
        ),
      ),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // 각 탭 상태 유지
        body: IndexedStack(
          index: _current.index,
          children: pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: _current.index,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          onTap: (i) => setState(() => _current = MainTab.values[i]),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: '지도'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: '창고별 지그'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: '나의 지그'),
          ],
        ),
      ),
    );
  }
}
