// lib/screens/warehouse_jigs_page.dart (final, refactored for immutable JigItemData + ascending sort)
import 'package:flutter/material.dart';
import '../widgets/jig_item.dart';
import '../widgets/jig_form_bottom_sheet.dart';
import '../widgets/jig_item_data.dart';

class WarehouseJigsPage extends StatefulWidget {
  final ValueNotifier<List<JigItemData>> likedItemsNotifier;

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

  final List<JigItemData> _jigItems = [
    JigItemData(
      image: 'jig_example1.jpg',
      title: 'LX3 진동&배광 지그 1대분',
      location: '진량공장 2층',
      description: 'LX3 진동&배광 지그',
      registrant: '전장램프설계6팀 최은석 사원',
      storageDate: DateTime.now(),
    ),
  ];

  DateTime _dateOrEpoch(DateTime? d) => d ?? DateTime.fromMillisecondsSinceEpoch(0);

  List<JigItemData> get _filtered {
    final f = _jigItems.where((e) => e.location == _selectedLocation).toList();
    if (_selectedSort == '이름순') {
      f.sort((a, b) => a.title.compareTo(b.title));
    } else if (_selectedSort == '최신순') {
      f.sort((a, b) => _dateOrEpoch(b.storageDate).compareTo(_dateOrEpoch(a.storageDate)));
    } else if (_selectedSort == '오래된순') {
      f.sort((a, b) => _dateOrEpoch(a.storageDate).compareTo(_dateOrEpoch(b.storageDate)));
    }
    return f;
  }

  JigItemData _withPreservedLikeState({
    required JigItemData edited,
    required JigItemData old,
  }) {
    return JigItemData(
      image: edited.image,
      title: edited.title,
      location: edited.location,
      description: edited.description,
      registrant: edited.registrant,
      storageDate: edited.storageDate,
      disposalDate: edited.disposalDate,
      likes: old.likes,
      isLiked: old.isLiked,
    );
  }

  void _applyEditReplace(JigItemData oldItem, JigItemData editedFromForm) {
    final updated = _withPreservedLikeState(edited: editedFromForm, old: oldItem);

    final idx = _jigItems.indexOf(oldItem);
    if (idx != -1) {
      _jigItems[idx] = updated;
    }

    final liked = List<JigItemData>.from(widget.likedItemsNotifier.value);
    final li = liked.indexOf(oldItem);
    if (li != -1) {
      liked[li] = updated;
      widget.likedItemsNotifier.value = List<JigItemData>.from(liked);
    }

    _selectedLocation = updated.location;
  }

  void _toggleLike(JigItemData item) {
    setState(() {
      final current = List<JigItemData>.from(widget.likedItemsNotifier.value);
      final alreadyLiked = current.contains(item);

      if (!alreadyLiked) {
        item.isLiked = true;
        item.likes = item.likes + 1;
        current.add(item);
      } else {
        item.isLiked = false;
        item.likes = item.likes > 0 ? item.likes - 1 : 0;
        current.remove(item);
      }

      widget.likedItemsNotifier.value = List<JigItemData>.from(current);
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
            if (editIndex != null) {
              final old = _jigItems[editIndex];
              _applyEditReplace(old, newJig);
            } else {
              _jigItems.insert(0, newJig);
              _selectedLocation = newJig.location;
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
              setState(() {
                final removed = _jigItems.removeAt(index);
                final current = List<JigItemData>.from(widget.likedItemsNotifier.value);
                if (current.remove(removed)) {
                  widget.likedItemsNotifier.value = List<JigItemData>.from(current);
                }
              });
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
                      style: TextStyle(color: _selectedSort == '최신순' ? Colors.black : Colors.grey)),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedSort = '오래된순'),
                  child: Text('오래된순',
                      style: TextStyle(color: _selectedSort == '오래된순' ? Colors.black : Colors.grey)),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedSort = '이름순'),
                  child: Text('이름순',
                      style: TextStyle(color: _selectedSort == '이름순' ? Colors.black : Colors.grey)),
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
                              editIndex: _jigItems.indexOf(item),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black),
                            onPressed: () => _confirmDelete(_jigItems.indexOf(item)),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditJigDialog(),
        label: const Text('+ 지그 등록'),
      ),
    );
  }
}
