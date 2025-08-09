// lib/screens/warehouse_jigs_page.dart
import 'package:flutter/material.dart';
import '../widgets/jig_item.dart';
import '../widgets/jig_form_bottom_sheet.dart';
import '../widgets/jig_item_data.dart';

class WarehouseJigsPage extends StatefulWidget {
  final ValueNotifier<List<JigItemData>> likedItemsNotifier; // 공유되는 건 이것뿐

  const WarehouseJigsPage({
    super.key,
    required this.likedItemsNotifier,
  });

  @override
  State<WarehouseJigsPage> createState() => _WarehouseJigsPageState();
}

class _WarehouseJigsPageState extends State<WarehouseJigsPage> {
  static const _locations = ['진량공장 2층', '배광실 2층', '본관 4층'];
  String _selectedLocation = _locations.first;
  String _selectedSort = '최신순';

  // 이 페이지 전용 상태
  final List<JigItemData> _jigItems = [
    JigItemData(
      image: 'jig_example1.jpg',
      title: 'LX3 진동&배광 지그 1대분',
      location: '진량공장 2층',
      description: 'LX3 진동&배광 지그',
      registrant: '전장램프설계6팀 최은석 사원',
    ),
  ];

  List<JigItemData> get _filtered {
    final f = _jigItems.where((e) => e.location == _selectedLocation).toList();
    if (_selectedSort == '이름순') {
      f.sort((a, b) => a.title.compareTo(b.title));
    }
    return f;
  }

  void _toggleLike(JigItemData item) {
    setState(() {
      item.isLiked = !item.isLiked;
      final liked = [...widget.likedItemsNotifier.value];
      if (item.isLiked) {
        if (!liked.contains(item)) liked.add(item);
        item.likes += 1;
      } else {
        liked.remove(item);
        item.likes = item.likes > 0 ? item.likes - 1 : 0;
      }
      widget.likedItemsNotifier.value = liked; // MyJigsPage에 반영
    });
  }

  void _showAddOrEditJigDialog({JigItemData? editItem, int? editIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => JigFormBottomSheet(
        editItem: editItem,
        onSubmit: (newJig) {
          setState(() {
            _selectedLocation = newJig.location;
            if (editIndex != null) {
              _jigItems[editIndex] = newJig;
            } else {
              _jigItems.insert(0, newJig);
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
        title: const Text('삭제하시겠습니까?', style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('아니오')),
          TextButton(
            onPressed: () {
              setState(() => _jigItems.removeAt(index));
              Navigator.pop(ctx);
            },
            child: const Text('예'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text(_selectedLocation, style: const TextStyle(color: Colors.black)),
            PopupMenuButton<String>(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
              color: Colors.white,
              onSelected: (v) => setState(() => _selectedLocation = v),
              itemBuilder: (_) => _locations
                  .map(
                    (loc) => PopupMenuItem<String>(
                  value: loc,
                  height: 40,
                  textStyle: const TextStyle(color: Colors.black),
                  child: Text(loc),
                ),
              )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _selectedSort = '최신순'),
                  child: Text('최신순',
                      style: TextStyle(
                        color: _selectedSort == '최신순' ? Colors.black : Colors.grey,
                      )),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedSort = '이름순'),
                  child: Text('이름순',
                      style: TextStyle(
                        color: _selectedSort == '이름순' ? Colors.black : Colors.grey,
                      )),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: items.length,
              itemBuilder: (_, index) {
                final item = items[index];
                return Stack(
                  children: [
                    JigItem(
                      image: item.image,
                      title: item.title,
                      location: item.location,
                      price: item.description,
                      registrant: item.registrant,
                      likes: item.likes,
                      isLiked: item.isLiked,
                      onLikePressed: () => _toggleLike(item),
                      storageDate: item.storageDate,
                      disposalDate: item.disposalDate,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.black),
                            onPressed: () => _showAddOrEditJigDialog(
                              editItem: item,
                              editIndex: index,
                            ),
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
            ),
          ),
        ],
      ),
      floatingActionButton: OutlinedButton(
        onPressed: () => _showAddOrEditJigDialog(),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black),
        ),
        child: const Text('+ 지그 등록'),
      ),
    );
  }
}
