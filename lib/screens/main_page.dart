import 'package:flutter/material.dart';
import '../widgets/jig_item.dart';
import '../widgets/jig_form_bottom_sheet.dart';
import '../widgets/jig_item_data.dart';
import '../screens/map_page.dart';
import '../screens/my_jigs_page.dart';

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
    ),
  ];

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

  Widget getBody() {
    switch (selectedTab) {
      case 0:
        return ListView.builder(
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
                        onPressed: () =>
                            _showAddOrEditJigDialog(editItem: item, editIndex: index),
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
        );
      case 1:
        return const MapPage();
      case 2:
        return const MyJigsPage();
      default:
        return const Center(child: Text("페이지 없음"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade200,
        elevation: 0,
        title: selectedTab == 0
            ? Row(
          children: [
            Text(selectedLocation, style: const TextStyle(color: Colors.black)),
            PopupMenuButton<String>(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
              color: Colors.white,
              onSelected: (String value) {
                setState(() => selectedLocation = value);
              },
              itemBuilder: (BuildContext context) => const [
                PopupMenuItem(
                  value: '진량공장 2층',
                  child: Text('진량공장 2층'),
                  textStyle: TextStyle(color: Colors.black),
                  height: 40,
                ),
                PopupMenuItem(
                  value: '배광실 2층',
                  child: Text('배광실 2층'),
                  textStyle: TextStyle(color: Colors.black),
                  height: 40,
                ),
                PopupMenuItem(
                  value: '본관 4층',
                  child: Text('본관 4층'),
                  textStyle: TextStyle(color: Colors.black),
                  height: 40,
                ),
              ],
            ),
          ],
        )
            : const Text(""), // 지도/나의지그 탭에서는 비워둠
      ),
      body: getBody(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: selectedTab,
        onTap: (index) {
          setState(() => selectedTab = index);
        },
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
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