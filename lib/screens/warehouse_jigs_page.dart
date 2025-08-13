// lib/screens/warehouse_jigs_page.dart
// (final) 공용 지그 리스트 연동 + 상위 장소 드롭다운 + B동 지도 연동
import 'package:flutter/material.dart';

import '../widgets/jig_item.dart';
import '../widgets/jig_form_bottom_sheet.dart';
import '../widgets/jig_item_data.dart';
import '../map_page/jinryang_maps/jinryang_b_dong_map.dart';

class WarehouseJigsPage extends StatefulWidget {
  const WarehouseJigsPage({
    super.key,
    required this.jigsNotifier,        // ✅ 공용 지그 리스트 (읽기/쓰기)
    required this.likedItemsNotifier,  // ❤️ 관심목록
  });

  final ValueNotifier<List<JigItemData>> jigsNotifier;
  final ValueNotifier<List<JigItemData>> likedItemsNotifier;

  @override
  State<WarehouseJigsPage> createState() => _WarehouseJigsPageState();
}

class _WarehouseJigsPageState extends State<WarehouseJigsPage> {
  static const List<String> _preferLocations = [
    '진량공장 B동',
    '배광시험동 2층',
    '후생동 4층',
  ];

  String? _selectedLocation; // 상위(부모) 장소만
  String _selectedSort = '최신순';

  @override
  void initState() {
    super.initState();
    widget.jigsNotifier.addListener(_onJigsChanged);
    _ensureSelectedLocation();
  }

  @override
  void dispose() {
    widget.jigsNotifier.removeListener(_onJigsChanged);
    super.dispose();
  }

  void _onJigsChanged() {
    if (!mounted) return;
    setState(_ensureSelectedLocation);
  }

  String _parentOf(String loc) {
    final t = loc.trim();
    if (!t.contains('/')) return t;
    return t.split('/').first.trim();
  }

  List<String> get _topLocations {
    final items = widget.jigsNotifier.value;
    final set = <String>{};
    for (final it in items) {
      set.add(_parentOf(it.location));
    }

    final list = set.toList()..sort();
    list.sort((a, b) {
      final ia = _preferLocations.indexOf(a);
      final ib = _preferLocations.indexOf(b);
      if (ia != -1 && ib == -1) return -1;
      if (ib != -1 && ia == -1) return 1;
      return a.compareTo(b);
    });
    return list;
  }

  void _ensureSelectedLocation() {
    final locs = _topLocations;
    if (locs.isEmpty) {
      _selectedLocation = null;
      return;
    }
    if (_selectedLocation == null || !locs.contains(_selectedLocation)) {
      for (final p in _preferLocations) {
        if (locs.contains(p)) {
          _selectedLocation = p;
          return;
        }
      }
      _selectedLocation = locs.first;
    }
  }

  DateTime _dateOrEpoch(DateTime? d) => d ?? DateTime.fromMillisecondsSinceEpoch(0);

  List<JigItemData> get _filtered {
    final all = widget.jigsNotifier.value;
    final parent = _selectedLocation;
    if (parent == null) return const [];

    final f = all.where((e) => _parentOf(e.location) == parent).toList();

    if (_selectedSort == '이름순') {
      f.sort((a, b) => a.title.compareTo(b.title));
    } else if (_selectedSort == '최신순') {
      f.sort((a, b) => _dateOrEpoch(b.storageDate).compareTo(_dateOrEpoch(a.storageDate)));
    } else if (_selectedSort == '오래된순') {
      f.sort((a, b) => _dateOrEpoch(a.storageDate).compareTo(_dateOrEpoch(b.storageDate)));
    }
    return f;
  }

  String? _slotOf(String loc) {
    final p = loc.split('/').map((e) => e.trim()).toList();
    return p.length > 1 ? p[1] : null; // L1/C1/R1/F1~F4
  }

  String? _floorOf(String loc) {
    final p = loc.split('/').map((e) => e.trim()).toList();
    if (p.length > 2) {
      final m = RegExp(r'(\d)').firstMatch(p[2]);
      if (m != null) return '${m.group(1)}층';
    }
    return null;
  }

  Map<String, int> _capsFrom(List<JigItemData> items) {
    final out = <String, int>{};
    for (final it in items) {
      final loc = it.location.trim();
      if (!loc.startsWith('진량공장 B동')) continue;

      final slot = _slotOf(loc);
      if (slot == null) continue;

      final w = it.capacityWeight;

      if (slot.startsWith('F')) {
        out[slot] = (out[slot] ?? 0) + w;
      } else {
        final fl = _floorOf(loc);
        if (fl != null) {
          final key = '$slot/$fl';
          out[key] = (out[key] ?? 0) + w;
        }
      }
    }
    return out;
  }

  JigItemData _withPreservedLike({
    required JigItemData edited,
    required JigItemData old,
  }) {
    return edited.copyWith(likes: old.likes, isLiked: old.isLiked);
  }

  void _replaceInLiked(JigItemData oldItem, JigItemData newItem) {
    final liked = List<JigItemData>.from(widget.likedItemsNotifier.value);
    final li = liked.indexOf(oldItem);
    if (li != -1) {
      liked[li] = newItem;
      widget.likedItemsNotifier.value = List<JigItemData>.from(liked);
    }
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
          final list = List<JigItemData>.from(widget.jigsNotifier.value);
          setState(() {
            if (editIndex != null) {
              final old = list[editIndex];
              final updated = _withPreservedLike(edited: newJig, old: old);
              list[editIndex] = updated;
              _replaceInLiked(old, updated);
              _selectedLocation = _parentOf(updated.location);
            } else {
              list.insert(0, newJig);
              _selectedLocation = _parentOf(newJig.location);
            }
            widget.jigsNotifier.value = list;
          });
        },
      ),
    );
  }

  void _confirmDelete(int index, JigItemData item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('삭제하시겠습니까?', style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('아니오')),
          TextButton(
            onPressed: () {
              final list = List<JigItemData>.from(widget.jigsNotifier.value);
              setState(() {
                final removed = list.removeAt(index);
                widget.jigsNotifier.value = list;

                final liked = List<JigItemData>.from(widget.likedItemsNotifier.value);
                if (liked.remove(removed)) {
                  widget.likedItemsNotifier.value = List<JigItemData>.from(liked);
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

  void _toggleLike(JigItemData item) {
    setState(() {
      final currentLiked = List<JigItemData>.from(widget.likedItemsNotifier.value);
      final alreadyLiked = currentLiked.contains(item);

      if (!alreadyLiked) {
        item.isLiked = true;
        item.likes = item.likes + 1;
        currentLiked.add(item);
      } else {
        item.isLiked = false;
        item.likes = item.likes > 0 ? item.likes - 1 : 0;
        currentLiked.remove(item);
      }
      widget.likedItemsNotifier.value = List<JigItemData>.from(currentLiked);
    });
  }

  void _openBDongMap() {
    final items = widget.jigsNotifier.value;
    final caps = _capsFrom(items);

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => JinryangBDongMap(
        onBack: () => Navigator.pop(context),
        allItems: items,

        l1Floor1Capacity: caps['L1/1층'] ?? 0,
        l1Floor2Capacity: caps['L1/2층'] ?? 0,
        l1Floor3Capacity: caps['L1/3층'] ?? 0,
        l1Floor4Capacity: caps['L1/4층'] ?? 0,

        r1Floor1Capacity: caps['R1/1층'] ?? 0,
        r1Floor2Capacity: caps['R1/2층'] ?? 0,
        r1Floor3Capacity: caps['R1/3층'] ?? 0,
        r1Floor4Capacity: caps['R1/4층'] ?? 0,

        c1Floor1Capacity: caps['C1/1층'] ?? 0,
        c1Floor2Capacity: caps['C1/2층'] ?? 0,
        c1Floor3Capacity: caps['C1/3층'] ?? 0,
        c1Floor4Capacity: caps['C1/4층'] ?? 0,

        f1Capacity: caps['F1'] ?? 0,
        f2Capacity: caps['F2'] ?? 0,
        f3Capacity: caps['F3'] ?? 0,
        f4Capacity: caps['F4'] ?? 0,

        maxCapacityShelves: 40,
        maxCapacityF: 20,
      ),
    ));
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
            Text(
              _selectedLocation ?? '장소 선택',
              style: const TextStyle(color: Colors.black),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
              color: Colors.white,
              onSelected: (v) => setState(() => _selectedLocation = v),
              itemBuilder: (_) => _topLocations
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
        actions: [
          if (_selectedLocation == '진량공장 B동')
            TextButton.icon(
              onPressed: _openBDongMap,
              icon: const Icon(Icons.map, color: Colors.black),
              label: const Text('지도 보기', style: TextStyle(color: Colors.black)),
            ),
        ],
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
                final globalIndex = widget.jigsNotifier.value.indexOf(item);
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
                              editIndex: globalIndex >= 0 ? globalIndex : null,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black),
                            onPressed: () => _confirmDelete(
                              globalIndex >= 0 ? globalIndex : index,
                              item,
                            ),
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
