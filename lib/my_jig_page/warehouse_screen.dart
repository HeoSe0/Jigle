// lib/screens/warehouse_screen.dart
import 'package:flutter/material.dart';

import '../widgets/jig_item.dart';
import '../widgets/jig_item_data.dart';

// (선택) 지도 페이지로 이동하고 싶다면 활성화하세요.
// import '../map_page/jinryang_maps/jinryang_b_dong_map.dart';

/// ==== 공통 색/가중치 유틸 ====
const double _kAlpha = 0.35; // 투명도

Color _colorForCapacity(int c) {
  final v = c.clamp(0, 10);
  if (v == 0) return Colors.green.withValues(alpha: _kAlpha);
  if (v >= 8) return Colors.red.withValues(alpha: _kAlpha);
  return Colors.yellow.withValues(alpha: _kAlpha);
}

Color _progressColor(double r) {
  if (r >= 0.8) return Colors.red;
  if (r <= 0.3) return Colors.green;
  return Colors.amber;
}

int _weightOfItem(JigItemData it) => it.capacityWeight;

/// ==== 위치 파서 ====
String _parentOf(String loc) => loc.split('/').first.trim();

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

/// ==== 모델 ====
class ShelfStatus {
  final String shelf; // L1 / C1 / R1
  final int f1, f2, f3, f4; // 1~4층 (0~10)
  const ShelfStatus(this.shelf, {this.f1 = 0, this.f2 = 0, this.f3 = 0, this.f4 = 0});

  int get total => f1 + f2 + f3 + f4; // 최대 40
  double get ratio => (total / 40.0).clamp(0.0, 1.0);
}

class ZoneStatus {
  final String zone; // F1 ~ F4
  final int value;   // 0~10
  const ZoneStatus(this.zone, this.value);

  double get ratio => (value / 10.0).clamp(0.0, 1.0);
}

/// ==== 캐파 집계 ====
class _CapacityAgg {
  /// B동 L1/C1/R1: 층별 가중치 합 → 0~10로 클램프
  static List<ShelfStatus> shelvesFrom(
      List<JigItemData> items, {
        int maxPerFloor = 10,
      }) {
    int clamp10(int v) => v < 0 ? 0 : (v > 10 ? 10 : v);
    final Map<String, Map<String, int>> acc = {
      'L1': {'1층': 0, '2층': 0, '3층': 0, '4층': 0},
      'C1': {'1층': 0, '2층': 0, '3층': 0, '4층': 0},
      'R1': {'1층': 0, '2층': 0, '3층': 0, '4층': 0},
    };

    for (final it in items) {
      if (_parentOf(it.location) != '진량공장 B동') continue;
      final slot = _slotOf(it.location);
      final fl = _floorOf(it.location);
      if (slot == null || fl == null) continue;
      if (!acc.containsKey(slot)) continue; // L1/C1/R1만
      acc[slot]![fl] = (acc[slot]![fl] ?? 0) + _weightOfItem(it);
    }

    ShelfStatus make(String s) {
      final m = acc[s]!;
      return ShelfStatus(
        s,
        f1: clamp10((m['1층'] ?? 0).clamp(0, maxPerFloor)),
        f2: clamp10((m['2층'] ?? 0).clamp(0, maxPerFloor)),
        f3: clamp10((m['3층'] ?? 0).clamp(0, maxPerFloor)),
        f4: clamp10((m['4층'] ?? 0).clamp(0, maxPerFloor)),
      );
    }

    return [make('L1'), make('C1'), make('R1')];
  }

  /// B동 F1~F4: 존 합 → 0~10로 클램프
  static List<ZoneStatus> zonesFrom(
      List<JigItemData> items, {
        int maxPerZone = 10,
      }) {
    int clamp10(int v) => v < 0 ? 0 : (v > 10 ? 10 : v);
    final map = {'F1': 0, 'F2': 0, 'F3': 0, 'F4': 0};

    for (final it in items) {
      if (_parentOf(it.location) != '진량공장 B동') continue;
      final slot = _slotOf(it.location);
      if (slot == null) continue;
      if (!map.containsKey(slot)) continue; // F1~F4만
      map[slot] = (map[slot] ?? 0) + _weightOfItem(it);
    }

    return [
      ZoneStatus('F1', clamp10((map['F1'] ?? 0).clamp(0, maxPerZone))),
      ZoneStatus('F2', clamp10((map['F2'] ?? 0).clamp(0, maxPerZone))),
      ZoneStatus('F3', clamp10((map['F3'] ?? 0).clamp(0, maxPerZone))),
      ZoneStatus('F4', clamp10((map['F4'] ?? 0).clamp(0, maxPerZone))),
    ];
  }
}

/// ==== 상세(지그 리스트) 공용 ====
void _showJigListBottomSheet({
  required BuildContext context,
  required String title,
  required List<JigItemData> items,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scroll) => Column(
        children: [
          Container(
            width: 48, height: 5, margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${items.length}건', style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              controller: scroll,
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final it = items[i];
                return JigItem(
                  image: it.image,
                  title: it.title,
                  location: it.location,
                  price: it.description,
                  registrant: it.registrant,
                  likes: it.likes,
                  isLiked: it.isLiked,
                  onLikePressed: () {}, // 필요 시 연동
                  storageDate: it.storageDate,
                  disposalDate: it.disposalDate,
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

/// ==== 창고 현황 스크린 (진량공장 B동) ====
/// - 선반(L1/C1/R1) + 존(F1~F4) 카드
/// - 카드 탭/층 버튼 탭 시 지그 리스트
/// - 상단 '지도 보기' 버튼(옵션) 제공
class WarehouseScreen extends StatelessWidget {
  const WarehouseScreen({
    super.key,
    required this.allItems,
    this.title = '창고 현황',
    this.locationTitle = '진량공장 B동',
    this.maxPerFloor = 10,
    this.maxPerZone = 10,
    this.showMapButton = true,
  });

  final String title;
  final String locationTitle;
  final List<JigItemData> allItems;
  final int maxPerFloor; // L/C/R 층별 상한(색 보정용)
  final int maxPerZone;  // F 존 상한
  final bool showMapButton;

  // B동: 특정 선반/층의 지그 추출
  List<JigItemData> _itemsForShelfFloor(String shelf, int floor) {
    final floorLabel = '$floor층';
    return allItems.where((it) {
      if (_parentOf(it.location) != '진량공장 B동') return false;
      return _slotOf(it.location) == shelf && _floorOf(it.location) == floorLabel;
    }).toList();
  }

  // B동: 특정 F존 지그 추출
  List<JigItemData> _itemsForZone(String zone) {
    return allItems.where((it) {
      if (_parentOf(it.location) != '진량공장 B동') return false;
      return _slotOf(it.location) == zone;
    }).toList();
  }

  void _openMap(BuildContext context) {
    // 지도페이지를 쓰려면 import 주석 해제 후 아래 사용.
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (_) => JinryangBDongMap(
    //     onBack: () => Navigator.pop(context),
    //     allItems: allItems,
    //     maxCapacityShelves: maxPerFloor,
    //     maxCapacityF: maxPerZone,
    //     weightOfItem: (it) => it.capacityWeight,
    //   ),
    // ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('지도 보기 연동은 주석을 해제해 사용하세요.'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shelves = _CapacityAgg.shelvesFrom(allItems, maxPerFloor: maxPerFloor);
    final zones   = _CapacityAgg.zonesFrom(allItems,   maxPerZone: maxPerZone);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, foregroundColor: Colors.black,
        title: Text(title),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          if (showMapButton)
            TextButton.icon(
              onPressed: () => _openMap(context),
              icon: const Icon(Icons.map_outlined),
              label: const Text('지도 보기'),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final isWide = c.maxWidth >= 900;
          final crossAxisCount = isWide ? 3 : (c.maxWidth >= 600 ? 2 : 1);
          final mainExtent = isWide ? 210.0 : 220.0; // 카드 높이 (내부 버튼 안깨지게)

          final cards = <Widget>[
            // 선반 카드 3개
            for (final s in shelves)
              ShelfCapacityCard(
                status: s,
                onDetail: () => _showJigListBottomSheet(
                  context: context,
                  title: '${s.shelf} 전체',
                  items: [
                    ..._itemsForShelfFloor(s.shelf, 1),
                    ..._itemsForShelfFloor(s.shelf, 2),
                    ..._itemsForShelfFloor(s.shelf, 3),
                    ..._itemsForShelfFloor(s.shelf, 4),
                  ],
                ),
                onFloorTap: (floor) => _showJigListBottomSheet(
                  context: context,
                  title: '${s.shelf} ${floor}층',
                  items: _itemsForShelfFloor(s.shelf, floor),
                ),
              ),

            // F 존 카드 4개
            for (final z in zones)
              ZoneCapacityCard(
                status: z,
                onDetail: () => _showJigListBottomSheet(
                  context: context,
                  title: '${z.zone} 존',
                  items: _itemsForZone(z.zone),
                ),
              ),
          ];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text(locationTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2E9F7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('선반/존 포화도', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: mainExtent, // 내부 버튼이 깨지지 않도록 고정 높이 적용
                  ),
                  delegate: SliverChildListDelegate.fixed(cards),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ==== 카드: 선반(L1/C1/R1) ====
class ShelfCapacityCard extends StatelessWidget {
  const ShelfCapacityCard({
    super.key,
    required this.status,
    this.onDetail,
    this.onFloorTap,
  });

  final ShelfStatus status;
  final VoidCallback? onDetail;
  final void Function(int floor)? onFloorTap; // 1~4층

  @override
  Widget build(BuildContext context) {
    final cap = status.ratio;
    final barColor = _progressColor(cap);
    final barBg = Colors.black.withValues(alpha: 0.06);

    return Material(
      elevation: 1,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onDetail,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, c) {
              // 내부 요소가 작은 화면에서도 깨지지 않도록 최소 높이/간격 조절
              final isTight = 200;
              final barHeight = 10.0;
              final gapSmall = 6.0;
              final gapLarge = 10.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 헤더
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(status.shelf, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: barColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${(cap * 100).round()}%',
                          style: TextStyle(fontWeight: FontWeight.w800, color: barColor),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: gapLarge),

                  // 진행바
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: cap,
                      minHeight: barHeight,
                      color: barColor,
                      backgroundColor: barBg,
                    ),
                  ),
                  SizedBox(height: gapLarge),

                  // 층별 버튼(4개)
                  Expanded(
                    child: Row(
                      children: [
                        _FloorBox(label: '4층', value: status.f4, onTap: onFloorTap == null ? null : () => onFloorTap!(4)),
                        const SizedBox(width: 6),
                        _FloorBox(label: '3층', value: status.f3, onTap: onFloorTap == null ? null : () => onFloorTap!(3)),
                        const SizedBox(width: 6),
                        _FloorBox(label: '2층', value: status.f2, onTap: onFloorTap == null ? null : () => onFloorTap!(2)),
                        const SizedBox(width: 6),
                        _FloorBox(label: '1층', value: status.f1, onTap: onFloorTap == null ? null : () => onFloorTap!(1)),
                      ],
                    ),
                  ),

                  // 자세히
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onDetail,
                      icon: const Icon(Icons.list_alt),
                      label: const Text('자세히'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ==== 카드: 존(F1~F4) ====
class ZoneCapacityCard extends StatelessWidget {
  const ZoneCapacityCard({
    super.key,
    required this.status,
    this.onDetail,
  });

  final ZoneStatus status;
  final VoidCallback? onDetail;

  @override
  Widget build(BuildContext context) {
    final cap = status.ratio;
    final barColor = _progressColor(cap);
    final barBg = Colors.black.withValues(alpha: 0.06);

    return Material(
      elevation: 1,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onDetail,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, c) {
              final isTight = 100;
              final barHeight = 12.0;
              final gapLarge = 12.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 헤더
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(status.zone, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: barColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${(cap * 100).round()}%',
                          style: TextStyle(fontWeight: FontWeight.w800, color: barColor),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: gapLarge),

                  // 진행바
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: cap,
                      minHeight: barHeight,
                      color: barColor,
                      backgroundColor: barBg,
                    ),
                  ),
                  SizedBox(height: gapLarge),

                  // 본문: 0~10
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: _colorForCapacity((status.value).clamp(0, 10)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                        ),
                        child: Text(
                          '${status.value} / 10',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),

                  // 자세히
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onDetail,
                      icon: const Icon(Icons.list_alt),
                      label: const Text('자세히'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ==== 내부 층 버튼 ====
class _FloorBox extends StatelessWidget {
  const _FloorBox({required this.label, required this.value, this.onTap});
  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 10);
    final bg = _colorForCapacity(clamped);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  '$clamped / 10',
                  style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
