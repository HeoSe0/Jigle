// lib/screens/main_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../widgets/jig_item_data.dart';
import '../widgets/home_search_tab.dart';
import '../data/jigle_api.dart'; // ← 추가
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
  final ValueNotifier<List<JigItemData>> _jigsNotifier =
      ValueNotifier<List<JigItemData>>([]);
  final ValueNotifier<List<JigItemData>> _likedItems =
      ValueNotifier<List<JigItemData>>([]);

  final _api = JigleApi(); // ← 기본 baseUrl 자동 설정(필요시 직접 지정)
  bool _loading = false;

  MainTab _current = MainTab.home;

  bool _isCreateIntent(String q) {
    // 등록/추가/보관/저장 "행위" 표현이 있는지
    final intent = RegExp(r'(등록해줘|등록해|추가해줘|추가해|보관할게|보관해줘|보관해|저장해줘|저장해)');
    // 필수 필드 중 최소 하나라도 문장에 포함되는지(휴대폰/차종/램프/위치/사이즈)
    final hasSomeField = RegExp(
      r'(01[016789]\d{7,8}' // 휴대폰
      r'|[A-Z]{1,3}\d{1,2}' // 차종코드 DN8/LQ2 등
      r'|헤드|리어|안개|콤비|head|tail|fog' // 램프 단서
      r'|동\s*\d+층|[A-Z]-\d{2}-\d{2}' // 위치 단서(예: 공장B동 2층, A-03-12)
      r'|사이즈\s*[1-3]|[1-3]\s*(호|번|형))', // 사이즈 코드
    );
    return intent.hasMatch(q) && hasSomeField.hasMatch(q);
  }

  Future<void> _onSearch(String q) async {
    setState(() => _loading = true);
    try {
      if (_isCreateIntent(q)) {
        final r = await _api.createJigByNL(q);
        final msg = (r.status == 'created' || r.status == 'updated')
            ? '상태: ${r.status}\n보관넘버: ${r.jig?['storage_no']}\n차종: ${r.jig?['car_model']}\n램프: ${r.jig?['lamp_type']}\n위치: ${r.jig?['storage_location']}\n사이즈코드: ${r.jig?['jig_size_code']}'
            : '상태: ${r.status}\n필요 정보: ${r.missingFields?.join(', ') ?? '-'}\n힌트: ${r.hint ?? '-'}';
        _showBottomSheet(msg, title: '지그 등록 결과');
      } else {
        final out = await _api.ask(q, topK: 8);
        _showBottomSheet(out.answer, title: '검색 결과');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showBottomSheet(String text, {String title = '결과'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: ListView(
            controller: controller,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SelectableText(text),
            ],
          ),
        ),
      ),
    );
  }

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
      Stack(
        children: [
          HomeSearchTab(
            logoAssetPath: 'assets/jigle_logo.png',
            slLogoAssetPath: 'assets/sl_logo.png',
            logoHeight: 150,
            slLogoHeight: 28,
            onSearch: _onSearch, // ← 여기만 연결하면 됩니다
            hintText: '예) DN8 헤드램프 어디 있어? / 사이즈 1짜리 등록',
          ),
          if (_loading)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: false,
                child: Container(
                  color: Colors.black.withOpacity(0.08),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
              ),
            ),
        ],
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
        builder: (_, liked, __) =>
            MyJigsPage(likedItems: liked, jigsNotifier: _jigsNotifier),
      ),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(index: _current.index, children: pages),
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
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2),
              label: '창고별 지그',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: '나의 지그'),
          ],
        ),
      ),
    );
  }
}
