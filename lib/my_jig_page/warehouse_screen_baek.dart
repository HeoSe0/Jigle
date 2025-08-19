// lib/my_jig_page/warehouse_screen_baek.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/jig_item.dart';
import '../widgets/jig_item_data.dart';
import '../widgets/jig_form_bottom_sheet.dart';
import '../data/jigs_store.dart';

/// ===== 공통 상수/유틸 =====
const String kPlantBaek = '배광시험동 2층'; // 위치 문자열의 부모명

const double _kAlpha = 0.35;

/// 진행바 색: 낮으면 초록, 중간은 호박색, 높으면 빨강
Color _progressColor(double r) {
  if (r >= 0.8) return Colors.red;
  if (r <= 0.3) return Colors.green;
  return Colors.amber;
}

/// 타일 배경색(포화도): 0~1 비율을 초록→노랑→빨강으로 보간(+투명도)
Color _colorForRatio(double r) {
  final v = r.clamp(0.0, 1.0);
  if (v == 0) return Colors.green.withOpacity(_kAlpha);
  if (v >= 0.8) return Colors.red.withOpacity(_kAlpha);
  return Colors.yellow.withOpacity(_kAlpha);
}

/// 위치 파싱 유틸
String _parentOf(String loc) => loc.split('/').first.trim();

String? _slotOf(String loc) {
  final p = loc.split('/').map((e) => e.trim()).toList();
  return p.length > 1 ? p[1] : null; // Rn / Ln
}

String? _floorOf(String loc) {
  final p = loc.split('/').map((e) => e.trim()).toList();
  if (p.length > 2) {
    final m = RegExp(r'(\d+)').firstMatch(p[2]); // "3층" 등에서 숫자만
    if (m != null) return '${m.group(1)}층';
  }
  return null;
}

/// 지그 가중치(소/중/대 → 1/3/5)
int _weightOfItem(JigItemData it) => it.capacityWeight;

/// ===== 모델 =====
class ShelfStatus {
  final String shelf; // R1/L1 ...
  final int f1, f2, f3, f4; // 1~4층
  final int maxPerFloor;
  const ShelfStatus(
      this.shelf, {
        this.f1 = 0,
        this.f2 = 0,
        this.f3 = 0,
        this.f4 = 0,
        required this.maxPerFloor,
      });

  int get total => f1 + f2 + f3 + f4;
  int get maxTotal => (maxPerFloor * 4).clamp(1, 1 << 30);
  double get ratio => (total / maxTotal).clamp(0.0, 1.0);
}

/// ===== 집계 =====
class _BaekAgg {
  /// 배광시험동 모든 선반(R1~R24, L1~L24)을 생성하고 데이터 누적
  static List<ShelfStatus> shelvesFrom(
      List<JigItemData> items, {
        int maxPerFloor = 10,
        bool showAll = true,
      }) {
    // 모든 선반 키 미리 구성
    final List<String> allSlots = [
      for (int i = 1; i <= 24; i++) 'R$i',
      for (int i = 1; i <= 24; i++) 'L$i',
    ];
    final Map<String, Map<String, int>> acc = {
      for (final s in allSlots) s: {'1층': 0, '2층': 0, '3층': 0, '4층': 0},
    };

    for (final it in items) {
      if (_parentOf(it.location) != kPlantBaek) continue;
      final slot = _slotOf(it.location);
      final fl = _floorOf(it.location);
      if (slot == null || fl == null) continue;
      if (!acc.containsKey(slot)) continue;
      acc[slot]![fl] = (acc[slot]![fl] ?? 0) + _weightOfItem(it);
    }

    int clampTo(int v) => v.clamp(0, maxPerFloor);
    ShelfStatus make(String s) {
      final m = acc[s]!;
      return ShelfStatus(
        s,
        f1: clampTo(m['1층'] ?? 0),
        f2: clampTo(m['2층'] ?? 0),
        f3: clampTo(m['3층'] ?? 0),
        f4: clampTo(m['4층'] ?? 0),
        maxPerFloor: maxPerFloor,
      );
    }

    final list = [for (final s in allSlots) make(s)];
    if (showAll) return list;

    // showAll=false면 상위 몇 개만 노출(가볍게 보기). 포화도 높은 순.
    list.sort((a, b) => b.ratio.compareTo(a.ratio));
    return list.take(8).toList();
  }
}

/// ===== 상세(지그 리스트) 바텀시트 =====
void _showJigListBottomSheet({
  required BuildContext context,
  required String title,
  required bool Function(JigItemData) filter,
  required ValueListenable<List<JigItemData>> itemsListenable,
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
              final updated =
              edited.copyWith(likes: original.likes, isLiked: original.isLiked);
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
              Navigator.pop(context);
            },
          ),
        );
      }

      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (ctx, scroll) => ValueListenableBuilder<List<JigItemData>>(
          valueListenable: itemsListenable,
          builder: (ctx, latest, __) {
            final items = latest.where(filter).toList();
            return Column(
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
                      Text(title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Text('${items.length}건',
                          style: const TextStyle(color: Colors.black54)),
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
            );
          },
        ),
      );
    },
  );
}

/// ===== 화면(배광시험동 2층) =====
/// 탭 안에서 쓸 때는 [embedded=true]로 AppBar 없이 본문만 그립니다.
class WarehouseScreenBaek extends StatelessWidget {
  const WarehouseScreenBaek({
    super.key,
    this.itemsListenable,
    this.title = '창고 현황',
    this.locationTitle = kPlantBaek,
    this.maxPerFloor = 10,
    this.embedded = true,
    this.showAll = false, // false면 상위 몇 개만
  });

  final ValueListenable<List<JigItemData>>? itemsListenable;
  final String title;
  final String locationTitle;
  final int maxPerFloor;
  final bool embedded;
  final bool showAll;

  ValueListenable<List<JigItemData>> get _source =>
      itemsListenable ?? JigsStore.notifier;

  @override
  Widget build(BuildContext context) {
    final body = ValueListenableBuilder<List<JigItemData>>(
      valueListenable: _source,
      builder: (context, allItems, _) {
        final shelves = _BaekAgg.shelvesFrom(
          allItems,
          maxPerFloor: maxPerFloor,
          showAll: showAll,
        );

        Widget grid(BuildContext c) {
          final isWide = MediaQuery.of(c).size.width >= 900;
          final crossAxisCount = isWide ? 3 : (MediaQuery.of(c).size.width >= 600 ? 2 : 1);
          final mainExtent = isWide ? 210.0 : 220.0;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text(locationTitle,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2E9F7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('선반 포화도',
                            style: TextStyle(fontWeight: FontWeight.w700)),
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
                  delegate: SliverChildBuilderDelegate(
                        (context, i) {
                      final s = shelves[i];
                      return _BaekShelfCard(
                        status: s,
                        onDetail: () => _showJigListBottomSheet(
                          context: context,
                          title: '${s.shelf} 전체',
                          filter: (it) =>
                          _parentOf(it.location) == kPlantBaek &&
                              _slotOf(it.location) == s.shelf,
                          itemsListenable: _source,
                        ),
                        onFloorTap: (floor) => _showJigListBottomSheet(
                          context: context,
                          title: '${s.shelf} ${floor}층',
                          filter: (it) {
                            if (_parentOf(it.location) != kPlantBaek) return false;
                            return _slotOf(it.location) == s.shelf &&
                                _floorOf(it.location) == '${floor}층';
                          },
                          itemsListenable: _source,
                        ),
                      );
                    },
                    childCount: shelves.length,
                  ),
                ),
              ),
            ],
          );
        }

        return LayoutBuilder(builder: (_, __) => grid(context));
      },
    );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: body,
    );
  }
}

/// ===== 카드/타일 =====
class _BaekShelfCard extends StatelessWidget {
  const _BaekShelfCard({
    required this.status,
    this.onDetail,
    this.onFloorTap,
  });

  final ShelfStatus status;
  final VoidCallback? onDetail;
  final void Function(int floor)? onFloorTap; // 1~4

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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(status.shelf,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ),
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: barColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${(cap * 100).round()}%',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: barColor)),
                ),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: cap,
                  minHeight: 10,
                  color: barColor,
                  backgroundColor: barBg,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Row(
                  children: [
                    _FloorBox(
                        label: '4층',
                        value: status.f4,
                        max: status.maxPerFloor,
                        onTap: onFloorTap == null ? null : () => onFloorTap!(4)),
                    const SizedBox(width: 6),
                    _FloorBox(
                        label: '3층',
                        value: status.f3,
                        max: status.maxPerFloor,
                        onTap: onFloorTap == null ? null : () => onFloorTap!(3)),
                    const SizedBox(width: 6),
                    _FloorBox(
                        label: '2층',
                        value: status.f2,
                        max: status.maxPerFloor,
                        onTap: onFloorTap == null ? null : () => onFloorTap!(2)),
                    const SizedBox(width: 6),
                    _FloorBox(
                        label: '1층',
                        value: status.f1,
                        max: status.maxPerFloor,
                        onTap: onFloorTap == null ? null : () => onFloorTap!(1)),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onDetail,
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
  const _FloorBox({
    required this.label,
    required this.value,
    required this.max,
    this.onTap,
  });

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
                Text(
                  '$clamped / $max',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
