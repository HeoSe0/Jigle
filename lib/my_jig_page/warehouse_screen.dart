// lib/my_jig_page/warehouse_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../widgets/jig_item.dart';
import '../widgets/jig_item_data.dart';
import '../widgets/jig_form_bottom_sheet.dart';
import '../data/jigs_store.dart';
import '../map_page/jinryang_maps/jinryang_b_dong_map.dart';

// ==== 공통 색/가중치 유틸 ====
const double _kAlpha = 0.35;
Color _colorForCapacity(int c) {
  final v = c.clamp(0, 10);
  if (v == 0) return Colors.green.withOpacity(_kAlpha);
  if (v >= 8) return Colors.red.withOpacity(_kAlpha);
  return Colors.yellow.withOpacity(_kAlpha);
}

Color _progressColor(double r) {
  if (r >= 0.8) return Colors.red;
  if (r <= 0.3) return Colors.green;
  return Colors.amber;
}

int _weightOfItem(JigItemData it) => it.capacityWeight;

// ==== 위치 파서 ====
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

// ==== 모델 ====
class ShelfStatus {
  final String shelf; // L1 / C1 / R1
  final int f1, f2, f3, f4;
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

// ==== 캐파 집계 ====
class _CapacityAgg {
  static List<ShelfStatus> shelvesFrom(List<JigItemData> items, {int maxPerFloor = 10}) {
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
      if (!acc.containsKey(slot)) continue;
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

  static List<ZoneStatus> zonesFrom(List<JigItemData> items, {int maxPerZone = 10}) {
    int clamp10(int v) => v < 0 ? 0 : (v > 10 ? 10 : v);
    final map = {'F1': 0, 'F2': 0, 'F3': 0, 'F4': 0};

    for (final it in items) {
      if (_parentOf(it.location) != '진량공장 B동') continue;
      final slot = _slotOf(it.location);
      if (slot == null) continue;
      if (!map.containsKey(slot)) continue;
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

// ==== 상세(지그 리스트) 공용 ====
void _showJigListBottomSheet({
  required BuildContext context,
  required String title,
  required List<JigItemData> items,
  ValueListenable<List<JigItemData>>? itemsListenable,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) {
      void _openEdit(JigItemData original) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => JigFormBottomSheet(
            editItem: original,
            onSubmit: (edited) {
              // 좋아요/하트 보존
              final updated = edited.copyWith(likes: original.likes, isLiked: original.isLiked);

              // 1) 전역 스토어 교체
              final g = List<JigItemData>.from(JigsStore.notifier.value);
              int gi = g.indexOf(original);
              if (gi == -1) {
                gi = g.indexWhere((e) =>
                e.title == original.title &&
                    e.location == original.location &&
                    e.registrant == original.registrant);
              }
              if (gi != -1) {
                g[gi] = updated;
                JigsStore.notifier.value = g;
              }

              // 2) 주입된 ValueNotifier도 있으면 동기화
              if (itemsListenable is ValueNotifier<List<JigItemData>>) {
                final vnList = List<JigItemData>.from(itemsListenable.value);
                final li = vnList.indexWhere((e) =>
                identical(e, original) ||
                    (e.title == original.title &&
                        e.location == original.location &&
                        e.registrant == original.registrant));
                if (li != -1) {
                  vnList[li] = updated;
                  itemsListenable.value = vnList;
                }
              }

              Navigator.pop(context); // edit sheet 닫기
            },
          ),
        );
      }

      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (ctx, scroll) => Column(
          children: [
            Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
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
                  return Stack(
                    children: [
                      JigItem(
                        image: it.image,
                        title: it.title,
                        location: it.location,
                        price: it.description,
                        registrant: it.registrant,
                        likes: it.likes,
                        isLiked: it.isLiked,
                        onLikePressed: () {},
                        storageDate: it.storageDate,
                        disposalDate: it.disposalDate,
                        size: it.size,
                        jigHeight: it.jigHeight,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          tooltip: '수정',
                          icon: const Icon(Icons.edit, color: Colors.black),
                          onPressed: () => _openEdit(it),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// ==== 창고 현황 스크린 (진량공장 B동) ====
class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({
    super.key,
    this.title = '창고 현황',
    this.locationTitle = '진량공장 B동',
    this.maxPerFloor = 10,
    this.maxPerZone = 10,
    this.showMapButton = true,
    this.itemsListenable, // (선택) 외부 주입 - 표시는 전역 스토어를 구독합니다.
  });

  final String title;
  final String locationTitle;
  final int maxPerFloor;
  final int maxPerZone;
  final bool showMapButton;

  /// 주입은 받지만, 화면 표시는 전역 스토어(JigsStore.notifier)를 단일 소스로 사용합니다.
  final ValueListenable<List<JigItemData>>? itemsListenable;

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  // 지도 열기
  void _openMap(BuildContext context, ValueListenable<List<JigItemData>> listenable) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => JinryangBDongMap(
        onBack: () => Navigator.pop(context),
        jigsListenable: listenable,           // ✅ 전역 스토어 주입
        maxCapacityShelves: widget.maxPerFloor,
        maxCapacityF: widget.maxPerZone,
        weightOfItem: (it) => it.capacityWeight,
        onCreateJig: JigsStore.add,           // ✅ 지도에서 등록해도 전역 반영
      ),
    ));
  }

  void _openAddFromWarehouse(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => JigFormBottomSheet(
        initialLocation: '진량공장 B동',
        onSubmit: JigsStore.add,              // ✅ 전역 반영 → 지도/창고 동시 갱신
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔴 핵심: 화면 표시는 언제나 전역 스토어를 단일 소스로 구독
    final listenable = JigsStore.notifier;

    return ValueListenableBuilder<List<JigItemData>>(
      valueListenable: listenable,
      builder: (context, allItems, _) {
        final shelves = _CapacityAgg.shelvesFrom(allItems, maxPerFloor: widget.maxPerFloor);
        final zones   = _CapacityAgg.zonesFrom(allItems,   maxPerZone: widget.maxPerZone);

        // 필터 함수(리스트 뷰용)
        List<JigItemData> _itemsForShelfFloor(String shelf, int floor) {
          final floorLabel = '$floor층';
          return allItems.where((it) {
            if (_parentOf(it.location) != '진량공장 B동') return false;
            return _slotOf(it.location) == shelf && _floorOf(it.location) == floorLabel;
          }).toList();
        }

        List<JigItemData> _itemsForZone(String zone) {
          return allItems.where((it) {
            if (_parentOf(it.location) != '진량공장 B동') return false;
            return _slotOf(it.location) == zone;
          }).toList();
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            title: Text(widget.title),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (widget.showMapButton)
                TextButton.icon(
                  onPressed: () => _openMap(context, listenable),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('지도 보기'),
                ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, c) {
              final isWide = c.maxWidth >= 900;
              final crossAxisCount = isWide ? 3 : (c.maxWidth >= 600 ? 2 : 1);
              final mainExtent = isWide ? 210.0 : 220.0;

              final cards = <Widget>[
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
                      itemsListenable: listenable,
                    ),
                    onFloorTap: (floor) => _showJigListBottomSheet(
                      context: context,
                      title: '${s.shelf} ${floor}층',
                      items: _itemsForShelfFloor(s.shelf, floor),
                      itemsListenable: listenable,
                    ),
                  ),
                for (final z in zones)
                  ZoneCapacityCard(
                    status: z,
                    onDetail: () => _showJigListBottomSheet(
                      context: context,
                      title: '${z.zone} 존',
                      items: _itemsForZone(z.zone),
                      itemsListenable: listenable,
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
                          Text(widget.locationTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
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
                        mainAxisExtent: mainExtent,
                      ),
                      delegate: SliverChildListDelegate.fixed(cards),
                    ),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddFromWarehouse(context),
            label: const Text('+ 지그 등록'),
          ),
        );
      },
    );
  }
}

// ==== 카드 위젯 ====
class ShelfCapacityCard extends StatelessWidget {
  const ShelfCapacityCard({super.key, required this.status, this.onDetail, this.onFloorTap});
  final ShelfStatus status;
  final VoidCallback? onDetail;
  final void Function(int floor)? onFloorTap;

  @override
  Widget build(BuildContext context) {
    final cap = status.ratio;
    final barColor = _progressColor(cap);
    final barBg = Colors.black.withOpacity(0.06);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                  child: Text(status.shelf, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: barColor.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                  child: Text('${(cap * 100).round()}%', style: TextStyle(fontWeight: FontWeight.w800, color: barColor)),
                ),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(value: cap, minHeight: 10, color: barColor, backgroundColor: barBg),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Row(children: [
                  _FloorBox(label: '4층', value: status.f4, onTap: onFloorTap == null ? null : () => onFloorTap!(4)),
                  const SizedBox(width: 6),
                  _FloorBox(label: '3층', value: status.f3, onTap: onFloorTap == null ? null : () => onFloorTap!(3)),
                  const SizedBox(width: 6),
                  _FloorBox(label: '2층', value: status.f2, onTap: onFloorTap == null ? null : () => onFloorTap!(2)),
                  const SizedBox(width: 6),
                  _FloorBox(label: '1층', value: status.f1, onTap: onFloorTap == null ? null : () => onFloorTap!(1)),
                ]),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(onPressed: onDetail, icon: const Icon(Icons.list_alt), label: const Text('자세히')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ZoneCapacityCard extends StatelessWidget {
  const ZoneCapacityCard({super.key, required this.status, this.onDetail});
  final ZoneStatus status;
  final VoidCallback? onDetail;

  @override
  Widget build(BuildContext context) {
    final cap = status.ratio;
    final barColor = _progressColor(cap);
    final barBg = Colors.black.withOpacity(0.06);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                  child: Text(status.zone, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: barColor.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                  child: Text('${(cap * 100).round()}%', style: TextStyle(fontWeight: FontWeight.w800, color: barColor)),
                ),
              ]),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(value: cap, minHeight: 12, color: barColor, backgroundColor: barBg),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _colorForCapacity((status.value).clamp(0, 10)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: Text('${status.value} / 10', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(onPressed: onDetail, icon: const Icon(Icons.list_alt), label: const Text('자세히')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('$clamped / 10', style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
