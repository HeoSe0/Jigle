import 'package:flutter/material.dart';

import '../widgets/jig_item_data.dart';
import '../widgets/home_search_tab.dart';
import '../screens/map_page.dart';
import '../screens/warehouse_jigs_page.dart';
import '../screens/my_jigs_page.dart';

enum MainTab { home, map, warehouse, mine }

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // 관심목록을 상위에서 관리 (MyJigsPage 읽기, Warehouse 수정)
  final ValueNotifier<List<JigItemData>> _likedItems =
  ValueNotifier<List<JigItemData>>([]);

  MainTab _currentTab = MainTab.home;

  Widget _buildBody() {
    switch (_currentTab) {
      case MainTab.home:
        return HomeSearchTab(
          logoAssetPath: 'assets/jigle_logo.png',
          slLogoAssetPath: 'assets/sl_logo.png',
          logoHeight: 150,   //Jigle logo 크기
          slLogoHeight: 28,  //SL logo 크기
          onSearch: (query) {
            debugPrint('검색어: $query');

          },
        );
      case MainTab.map:
        return const MapPage();
      case MainTab.warehouse:
        return WarehouseJigsPage(likedItemsNotifier: _likedItems);
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
        onTap: (index) => setState(() {
          _currentTab = MainTab.values[index];
        }),
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
