import 'package:flutter/material.dart';

import '../widgets/jig_item.dart';
import '../widgets/jig_form_bottom_sheet.dart';
import '../widgets/jig_item_data.dart';

// 지도 위젯
import '../map_page/jinryang_maps/jinryang_b_dong_map.dart';
import '../map_page/jinryang_maps/jinryang_baekwang_test_building_map.dart';

class WarehouseJigsPage extends StatefulWidget {
  const WarehouseJigsPage({
    super.key,
    required this.jigsNotifier,
    required this.likedItemsNotifier,
  });

  final ValueNotifier<List<JigItemData>> jigsNotifier;
  final ValueNotifier<List<JigItemData>> likedItemsNotifier;

  @override
  State<WarehouseJigsPage> createState() => _WarehouseJigsPageState();
}

class _WarehouseJigsPageState extends State<WarehouseJigsPage> {
  // 상위 장소 우선순위(앞일수록 기본 선택 우선)
  static const List<String> _preferLocations = [
    '진량공장 B동',
    '배광시험동 2층',
    '후생동 4층',
  ];

  String? _selectedLocation; // 상위(부모) 장소
  String _selectedSort = '최신순';

  // ====== 지도 열기 중복/로딩 제어 ======
  bool _openingMap = false;

  Future<void> _precacheAssets(List<String> assetPaths) async {
    for (final p in assetPaths) {
      try {
        await precacheImage(AssetImage(p), context);
      } catch (_) {/* ignore precache errors */}
    }
  }

  Future<void> _openMapSafely({
    required List<String> assetsToPrecache,
    required Widget Function() buildPage,
  }) async {
    if (_openingMap) return;
    _openingMap = true;

    // 로딩
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _precacheAssets(assetsToPrecache);
      if (!mounted) return;
      Navigator.of(context).pop(); // 로딩 닫기
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => buildPage()),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('지도를 여는 중 오류가 발생했어요: $e')),
        );
      }
    } finally {
      _openingMap = false;
    }
  }
  // ===================================

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

  // ------- 장소 유틸 -------
  // '진량공장 B동 / L1 / 2층' → '진량공장 B동'
  String _parentOf(String loc) {
    final t = loc.trim();
    if (!t.contains('/')) return t;
    return t.split('/').first.trim();
  }

  List<String> get _topLocations {
    final items = widget.jigsNotifier.value;
    final set = <String>{for (final it in items) _parentOf(it.location)};
    final list = set.toList()..sort();
    // 우선순위 반영
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

  // ------- 정렬/필터 -------
  DateTime _dateOrEpoch(DateTime? d) =>
      d ?? DateTime.fromMillisecondsSinceEpoch(0);

  List<JigItemData> get _filtered {
    final all = widget.jigsNotifier.value;
    final parent = _selectedLocation;
    if (parent == null) return const [];

    final f = all.where((e) => _parentOf(e.location) == parent).toList();

    if (_selectedSort == '이름순') {
      f.sort((a, b) => a.title.compareTo(b.title));
    } else if (_selectedSort == '최신순') {
      f.sort((a, b) =>
          _dateOrEpoch(b.storageDate).compareTo(_dateOrEpoch(a.storageDate)));
    } else if (_selectedSort == '오래된순') {
      f.sort((a, b) =>
          _dateOrEpoch(a.storageDate).compareTo(_dateOrEpoch(b.storageDate)));
    }
    return f;
  }

  // ------- 가중치(소/중/대) -------
  int _weightForSize(String sizeRaw) {
    final size = sizeRaw.replaceAll(' ', '');
    switch (size) {
      case '대형':
      case '대':
        return 5;
      case '중형':
      case '중':
        return 3;
      case '소형':
      case '소':
      default:
        return 1;
    }
  }

  // ------- 좋아요 보존 유틸 -------
  JigItemData _withPreservedLike({
    required JigItemData edited,
    required JigItemData old,
  }) =>
      edited.copyWith(likes: old.likes, isLiked: old.isLiked);

  void _replaceInLiked(JigItemData oldItem, JigItemData newItem) {
    final liked = List<JigItemData>.from(widget.likedItemsNotifier.value);
    final li = liked.indexOf(oldItem);
    if (li != -1) {
      liked[li] = newItem;
      widget.likedItemsNotifier.value = List<JigItemData>.from(liked);
    }
  }

  // ------- 추가/수정/삭제/좋아요 -------
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
        title:
        const Text('삭제하시겠습니까?', style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('아니오')),
          TextButton(
            onPressed: () {
              final list = List<JigItemData>.from(widget.jigsNotifier.value);
              setState(() {
                final removed = list.removeAt(index);
                widget.jigsNotifier.value = list;

                final liked =
                List<JigItemData>.from(widget.likedItemsNotifier.value);
                if (liked.remove(removed)) {
                  widget.likedItemsNotifier.value =
                  List<JigItemData>.from(liked);
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
      final currentLiked =
      List<JigItemData>.from(widget.likedItemsNotifier.value);
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

  // ------- B동 초기 포커스 추정 (최근 항목 기준) -------
  String? _slotOf(String loc) {
    final p = loc.split('/').map((e) => e.trim()).toList();
    return p.length > 1 ? p[1] : null;
  }

  String? _floorOf(String loc) {
    final p = loc.split('/').map((e) => e.trim()).toList();
    if (p.length > 2) {
      final m = RegExp(r'(\d)').firstMatch(p[2]);
      if (m != null) return '${m.group(1)}층';
    }
    return null;
  }

  ({String? fzone, String? shelf, String? floor}) _inferInitialFocusForBDong(
      List<JigItemData> items) {
    final sorted = List<JigItemData>.from(items)
      ..sort((a, b) =>
          _dateOrEpoch(b.storageDate).compareTo(_dateOrEpoch(a.storageDate)));

    for (final it in sorted) {
      final loc = it.location.trim();
      if (!loc.startsWith('진량공장 B동')) continue;
      final slot = _slotOf(loc);
      if (slot == null) continue;

      if (slot.startsWith('F')) {
        return (fzone: slot, shelf: null, floor: null);
      }
      final fl = _floorOf(loc);
      if (fl != null) {
        return (fzone: null, shelf: slot, floor: fl);
      }
    }
    return (fzone: null, shelf: null, floor: null);
  }

  // ====== 지도 열기 (프리캐시 + 로딩) ======
  void _openBDongMap() {
    final items = widget.jigsNotifier.value;
    final focus = _inferInitialFocusForBDong(items);

    _openMapSafely(
      assetsToPrecache: const [
        'assets/bdong_map.png',
        'assets/shelf_L1.png',
        'assets/shelf_R1.png',
        'assets/shelf_C1.png',
      ],
      buildPage: () => JinryangBDongMap(
        onBack: () => Navigator.pop(context),
        // 실시간 포화도 반영
        jigsListenable: widget.jigsNotifier,
        allItems: items, // 스냅샷(백업)

        // 최근 항목 위치로 자동 포커스
        initialFZone: focus.fzone,
        initialShelf: focus.shelf,
        initialFloor: focus.floor,

        maxCapacityShelves: 10,
        maxCapacityF: 10,
        weightOfItem: (JigItemData it) => _weightForSize(it.size),

        // 지도에서 '+ 지그 등록' → 상위 리스트 갱신
        onCreateJig: (newJig) {
          final list = List<JigItemData>.from(widget.jigsNotifier.value);
          list.insert(0, newJig);
          widget.jigsNotifier.value = list;
        },
      ),
    );
  }

  void _openBaekwangMap() {
    final items = widget.jigsNotifier.value;
    _openMapSafely(
      assetsToPrecache: const ['assets/shelf_empty.png'],
      buildPage: () => JinryangBaekwangTestBuildingMap(
        onBack: () => Navigator.pop(context),
        allItems: items,
        maxCapacityPerFloor: 10,
        weightOfItem: (JigItemData it) => _weightForSize(it.size),
      ),
    );
  }
  // ===================================

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    // 현재 선택 장소에 맞는 지도 액션
    VoidCallback? _mapAction;
    if (_selectedLocation == '진량공장 B동') {
      _mapAction = _openBDongMap;
    } else if (_selectedLocation == '배광시험동 2층') {
      _mapAction = _openBaekwangMap;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 15,
        title: Row(
          children: [
            Text(_selectedLocation ?? '장소 선택',
                style: const TextStyle(color: Colors.black)),
            PopupMenuButton<String>(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
              color: Colors.white,
              onSelected: (v) => setState(() => _selectedLocation = v),
              itemBuilder: (_) => _topLocations
                  .map((loc) => PopupMenuItem<String>(
                value: loc,
                height: 40,
                textStyle: const TextStyle(color: Colors.black),
                child: Text(loc),
              ))
                  .toList(growable: false),
            ),
          ],
        ),
        actions: [
          if (_mapAction != null)
            TextButton.icon(
              onPressed: _mapAction,
              icon: const Icon(Icons.map, color: Colors.black),
              label: const Text('지도 보기',
                  style: TextStyle(color: Colors.black)),
            ),
        ],
      ),
      body: Column(
        children: [
          // 정렬 바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _selectedSort = '최신순'),
                  child: Text('최신순',
                      style: TextStyle(
                          color: _selectedSort == '최신순'
                              ? Colors.black
                              : Colors.grey)),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedSort = '오래된순'),
                  child: Text('오래된순',
                      style: TextStyle(
                          color: _selectedSort == '오래된순'
                              ? Colors.black
                              : Colors.grey)),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedSort = '이름순'),
                  child: Text('이름순',
                      style: TextStyle(
                          color: _selectedSort == '이름순'
                              ? Colors.black
                              : Colors.grey)),
                ),
              ],
            ),
          ),

          // 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: items.length,
              itemBuilder: (_, index) {
                final item = items[index];
                final globalIndex = widget.jigsNotifier.value.indexOf(item);
                final effectiveIndex = globalIndex >= 0 ? globalIndex : index;

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
                              editIndex: effectiveIndex,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black),
                            onPressed: () => _confirmDelete(effectiveIndex, item),
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

      // + 지그 등록
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditJigDialog(),
        label: const Text('+ 지그 등록'),
      ),
    );
  }
}
