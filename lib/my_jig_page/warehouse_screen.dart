import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../widgets/jig_item.dart';
import '../widgets/jig_item_data.dart';
import '../data/jigs_store.dart';

const String kPlantB = '진량공장 B동';
const double _kAlpha = 0.35;

Color _colorForRatio(double r) {
  if (r >= 0.8) return Colors.red.withOpacity(_kAlpha);
  if (r <= 0.3) return Colors.green.withOpacity(_kAlpha);
  return Colors.yellow.withOpacity(_kAlpha);
}
Color _progressColor(double r) {
  if (r >= 0.8) return Colors.red;
  if (r <= 0.3) return Colors.green;
  return Colors.amber;
}

int _weightOfItem(JigItemData it) => it.capacityWeight;
String _parentOf(String loc) => loc.split('/').first.trim();
String? _slotOf(String loc) {
  final p = loc.split('/').map((e) => e.trim()).toList();
  return p.length > 1 ? p[1] : null;
}
String? _floorOf(String loc) {
  final p = loc.split('/').map((e) => e.trim()).toList();
  if (p.length > 2) {
    final m = RegExp(r'(\d+)').firstMatch(p[2]);
    if (m != null) return '${m.group(1)}층';
  }
  return null;
}

/* ------------------ 모델/집계 ------------------ */
class ShelfStatus {
  final String shelf; // L1 / C1 / R1
  final int f1, f2, f3, f4;
  final int maxPerFloor;
  const ShelfStatus(this.shelf, {this.f1 = 0, this.f2 = 0, this.f3 = 0, this.f4 = 0, required this.maxPerFloor});
  int get total => f1 + f2 + f3 + f4;
  int get maxTotal => (maxPerFloor * 4).clamp(1, 1 << 30);
  double get ratio => (total / maxTotal).clamp(0.0, 1.0);
}

class ZoneStatus {
  final String zone; // F1 ~ F4
  final int value;
  final int maxPerZone;
  const ZoneStatus(this.zone, this.value, {required this.maxPerZone});
  double get ratio => (value / maxPerZone).clamp(0.0, 1.0);
}

class _CapacityAgg {
  static List<ShelfStatus> shelvesFrom(List<JigItemData> items, {int maxPerFloor = 10}) {
    int clampToMax(int v) => v.clamp(0, maxPerFloor);
    final Map<String, Map<String, int>> acc = {
      'L1': {'1층': 0, '2층': 0, '3층': 0, '4층': 0},
      'C1': {'1층': 0, '2층': 0, '3층': 0, '4층': 0},
      'R1': {'1층': 0, '2층': 0, '3층': 0, '4층': 0},
    };
    for (final it in items) {
      if (_parentOf(it.location) != kPlantB) continue;
      final s = _slotOf(it.location);
      final f = _floorOf(it.location);
      if (s == null || f == null) continue;
      if (!acc.containsKey(s)) continue;
      acc[s]![f] = (acc[s]![f] ?? 0) + _weightOfItem(it);
    }
    ShelfStatus make(String s) {
      final m = acc[s]!;
      return ShelfStatus(
        s,
        f1: clampToMax(m['1층'] ?? 0),
        f2: clampToMax(m['2층'] ?? 0),
        f3: clampToMax(m['3층'] ?? 0),
        f4: clampToMax(m['4층'] ?? 0),
        maxPerFloor: maxPerFloor,
      );
    }
    return [make('L1'), make('C1'), make('R1')];
  }

  static List<ZoneStatus> zonesFrom(List<JigItemData> items, {int maxPerZone = 10}) {
    int clampToMax(int v) => v.clamp(0, maxPerZone);
    final map = {'F1': 0, 'F2': 0, 'F3': 0, 'F4': 0};
    for (final it in items) {
      if (_parentOf(it.location) != kPlantB) continue;
      final s = _slotOf(it.location);
      if (s == null) continue;
      if (!map.containsKey(s)) continue;
      map[s] = (map[s] ?? 0) + _weightOfItem(it);
    }
    return [
      ZoneStatus('F1', clampToMax(map['F1'] ?? 0), maxPerZone: maxPerZone),
      ZoneStatus('F2', clampToMax(map['F2'] ?? 0), maxPerZone: maxPerZone),
      ZoneStatus('F3', clampToMax(map['F3'] ?? 0), maxPerZone: maxPerZone),
      ZoneStatus('F4', clampToMax(map['F4'] ?? 0), maxPerZone: maxPerZone),
    ];
  }
}

/* ------------------ 바텀시트(층 필터 토글 포함) ------------------ */
void _showJigListBottomSheet({
  required BuildContext context,
  required String title,
  required bool Function(JigItemData) baseFilter,
  required ValueListenable<List<JigItemData>> itemsListenable,
  List<String> floorChoices = const [], // ✅ 없으면 토글 숨김
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    builder: (_) {
      final Set<String> selectedFloors = {}; // 비어 있으면 '전체'
      return StatefulBuilder(
        builder: (ctx, setSB) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (ctx, scroll) => ValueListenableBuilder<List<JigItemData>>(
            valueListenable: itemsListenable,
            builder: (ctx, latest, __) {
              Iterable<JigItemData> base = latest.where(baseFilter);
              final items = base.where((it) {
                if (selectedFloors.isEmpty) return true;
                final fl = _floorOf(it.location);
                return fl != null && selectedFloors.contains(fl);
              }).toList();

              return Column(
                children: [
                  Container(
                    width: 48, height: 5,
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
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
                  if (floorChoices.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // 전체
                          FilterChip(
                            label: const Text('전체'),
                            selected: selectedFloors.isEmpty,
                            onSelected: (_) => setSB(() => selectedFloors.clear()),
                            // ▼ 색상 커스터마이즈
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFFEDE7F6), // 선택 시 칩 배경
                            showCheckmark: true,
                            checkmarkColor: Colors.black,           // 체크 아이콘(✓) 색
                            labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                            shape: const StadiumBorder(side: BorderSide(color: Colors.black26)),
                          ),
                          for (final f in floorChoices)
                            FilterChip(
                              label: Text(f),
                              selected: selectedFloors.contains(f),
                              onSelected: (sel) => setSB(() {
                                if (sel) { selectedFloors.add(f); } else { selectedFloors.remove(f); }
                              }),
                              // ▼ 동일한 스타일
                              backgroundColor: Colors.white,
                              selectedColor: const Color(0xFFEDE7F6),
                              showCheckmark: true,
                              checkmarkColor: Colors.black,
                              labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                              shape: const StadiumBorder(side: BorderSide(color: Colors.black26)),
                            ),
                        ],
                      ),
                    ),
                  ],
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
                          images: it.images,                 // ✅ 여러 장 전달
                          thumbnailIndex: it.thumbnailIndex,
                          location: it.location,
                          description: it.description,
                          registrant: it.registrant,
                          likes: it.likes,
                          isLiked: it.isLiked,
                          onLikePressed: () {},
                          storageDate: it.storageDate,
                          disposalDate: it.disposalDate,
                          size: it.size,
                          jigHeight: it.jigHeight,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

/* ------------------ 화면 (임베디드) ------------------ */
class WarehouseScreenEmbeddedB extends StatelessWidget {
  const WarehouseScreenEmbeddedB({super.key, this.maxPerFloor = 10, this.maxPerZone = 10});
  final int maxPerFloor;
  final int maxPerZone;

  @override
  Widget build(BuildContext context) {
    final listenable = JigsStore.notifier;

    return ValueListenableBuilder<List<JigItemData>>(
      valueListenable: listenable,
      builder: (context, allItems, _) {
        final shelves = _CapacityAgg.shelvesFrom(allItems, maxPerFloor: maxPerFloor);
        final zones   = _CapacityAgg.zonesFrom(allItems,   maxPerZone: maxPerZone);

        final cards = <Widget>[
          for (final s in shelves)
            ShelfCapacityCard(
              status: s,
              onDetail: () => _showJigListBottomSheet(
                context: context,
                title: '${s.shelf} 전체',
                baseFilter: (it) => _parentOf(it.location) == kPlantB && _slotOf(it.location) == s.shelf,
                itemsListenable: listenable,
                floorChoices: const ['1층', '2층', '3층', '4층'], // ✅ 층 토글 표시
              ),
            ),
          for (final z in zones)
            ZoneCapacityCard(
              status: z,
              onDetail: () => _showJigListBottomSheet(
                context: context,
                title: '${z.zone} 존',
                baseFilter: (it) => _parentOf(it.location) == kPlantB && _slotOf(it.location) == z.zone,
                itemsListenable: listenable,
                floorChoices: const [], // ✅ 존은 층 개념 없음 → 숨김
              ),
            ),
        ];

        return LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 900;
            final cross = isWide ? 3 : (c.maxWidth >= 600 ? 2 : 1);
            final mainExtent = isWide ? 210.0 : 220.0;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
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
        );
      },
    );
  }
}

/* ------------------ 카드 ------------------ */
class ShelfCapacityCard extends StatelessWidget {
  const ShelfCapacityCard({super.key, required this.status, this.onDetail});
  final ShelfStatus status;
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
        onTap: null, // 오직 '자세히'만
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
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(value: cap, minHeight: 6, color: barColor, backgroundColor: barBg),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Row(children: [
                  _FloorBox(label: '4층', value: status.f4, max: status.maxPerFloor, onTap: null),
                  const SizedBox(width: 6),
                  _FloorBox(label: '3층', value: status.f3, max: status.maxPerFloor, onTap: null),
                  const SizedBox(width: 6),
                  _FloorBox(label: '2층', value: status.f2, max: status.maxPerFloor, onTap: null),
                  const SizedBox(width: 6),
                  _FloorBox(label: '1층', value: status.f1, max: status.maxPerFloor, onTap: null),
                ]),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onDetail,
                  icon: const Icon(Icons.list_alt, color: Colors.black),
                  label: const Text('자세히', style: TextStyle(color: Colors.black)),
                ),
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
        onTap: null,
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
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(value: cap, minHeight: 10, color: barColor, backgroundColor: barBg),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _colorForRatio(status.ratio),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: Text('${status.value} / ${status.maxPerZone}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onDetail,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,  // 텍스트+아이콘 색
                    overlayColor: Colors.black12,   // 눌렀을 때 잉크 효과
                  ),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('자세히'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloorBox extends StatelessWidget {
  const _FloorBox({required this.label, required this.value, required this.max, this.onTap});
  final String label;
  final int value;
  final int max;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, max);
    final bg = _colorForRatio((clamped / max).clamp(0, 1));
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
                Text('$clamped / $max', style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
