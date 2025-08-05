import 'package:flutter/material.dart';
import '../widgets/jig_item.dart';
import '../widgets/jig_form_bottom_sheet.dart';
import '../jig_item_data.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<JigItemData> jigItems = [
    JigItemData(
      image: "jig_example1.jpg",
      title: "LX3 진동&배광 지그 1대분",
      location: "진량공장 2층",
      description: "LX3 진동&배광 지그",
      registrant: "전장램프설계6팀 최은석 사원",
    )
  ]; // 초기 jig list
  String selectedLocation = '진량공장 2층';
  int selectedTab = 0;

  void _showAddOrEditJigDialog({JigItemData? editItem, int? editIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => JigFormBottomSheet(
        editItem: editItem,
        onSubmit: (newJig) {
          setState(() {
            selectedLocation = newJig.location;
            if (editIndex != null) {
              jigItems[editIndex] = newJig;
            } else {
              jigItems.add(newJig);
            }
          });
        },
      ),
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("삭제하시겠습니까?", style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("아니오")),
          TextButton(
            onPressed: () {
              setState(() => jigItems.removeAt(index));
              Navigator.pop(ctx);
            },
            child: const Text("예"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Text(selectedLocation),
            PopupMenuButton<String>(
              icon: const Icon(Icons.keyboard_arrow_down),
              onSelected: (String value) {
                setState(() => selectedLocation = value);
              },
              itemBuilder: (BuildContext context) => const [
                PopupMenuItem(value: '진량공장 2층', child: Text('진량공장 2층')),
                PopupMenuItem(value: '배광실 2층', child: Text('배광실 2층')),
                PopupMenuItem(value: '본관 4층', child: Text('본관 4층')),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade200,
      ), // 위치 선택 및 PopupMenu
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: jigItems.length,
        itemBuilder: (context, index) {
          final item = jigItems[index];
          if (item.location != selectedLocation) return const SizedBox.shrink();
          return Stack(
            children: [
              JigItem(
                image: item.image,
                title: item.title,
                location: item.location,
                price: item.description,
                registrant: item.registrant,
                likes: item.likes,
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black),
                      onPressed: () => _showAddOrEditJigDialog(editItem: item, editIndex: index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () => _confirmDelete(index),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ), // jigItems 리스트 출력
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white, // ✅ 흰색 배경 추가
        currentIndex: selectedTab,
        onTap: (index) {
          setState(() {
            selectedTab = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "지도"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "나의 지그"),
        ],
      ),
      floatingActionButton: selectedTab == 0
          ? OutlinedButton(
        onPressed: () => _showAddOrEditJigDialog(),
        child: const Text("+ 지그 등록"),
      )
          : null,
    );
  }
}