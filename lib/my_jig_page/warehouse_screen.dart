import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../widgets/jig_item.dart';
import '../widgets/jig_item_data.dart';
import '../widgets/jig_form_bottom_sheet.dart';
import '../data/jigs_store.dart';
import '../map_page/jinryang_maps/jinryang_b_dong_map.dart';

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

// ---------- 모델 ----------
class ShelfStatus {
  final String shelf; // L1 / C1 / R1
  final int f1, f2, f3, f4;
  final int maxPerFloor;
  const ShelfStatus(this.shelf,{this.f1=0,this.f2=0,this.f3=0,this.f4=0,required this.maxPerFloor});
  int get total => f1 + f2 + f3 + f4;
  int get maxTotal => (maxPerFloor * 4).clamp(1, 1<<30);
  double get ratio => (total / maxTotal).clamp(0.0, 1.0);
}
class ZoneStatus {
  final String zone; final int value; final int maxPerZone;
  const ZoneStatus(this.zone, this.value, {required this.maxPerZone});
  double get ratio => (value / maxPerZone).clamp(0.0, 1.0);
}

// ---------- 집계 ----------
class _CapacityAgg {
  static List<ShelfStatus> shelvesFrom(List<JigItemData> items,{int maxPerFloor=10}) {
    int clampToMax(int v)=>v.clamp(0,maxPerFloor);
    final Map<String, Map<String,int>> acc={
      'L1': {'1층':0,'2층':0,'3층':0,'4층':0},
      'C1': {'1층':0,'2층':0,'3층':0,'4층':0},
      'R1': {'1층':0,'2층':0,'3층':0,'4층':0},
    };
    for(final it in items){
      if(_parentOf(it.location)!=kPlantB) continue;
      final s=_slotOf(it.location); final fl=_floorOf(it.location);
      if(s==null||fl==null) continue; if(!acc.containsKey(s)) continue;
      acc[s]![fl]=(acc[s]![fl]??0)+_weightOfItem(it);
    }
    ShelfStatus mk(String s){ final m=acc[s]!;
    return ShelfStatus(s,
        f1:clampToMax(m['1층']??0), f2:clampToMax(m['2층']??0),
        f3:clampToMax(m['3층']??0), f4:clampToMax(m['4층']??0),
        maxPerFloor:maxPerFloor);
    }
    return [mk('L1'), mk('C1'), mk('R1')];
  }

  static List<ZoneStatus> zonesFrom(List<JigItemData> items,{int maxPerZone=10}){
    int clampToMax(int v)=>v.clamp(0,maxPerZone);
    final map={'F1':0,'F2':0,'F3':0,'F4':0};
    for(final it in items){
      if(_parentOf(it.location)!=kPlantB) continue;
      final s=_slotOf(it.location); if(s==null) continue;
      if(!map.containsKey(s)) continue; map[s]=(map[s]??0)+_weightOfItem(it);
    }
    return [
      ZoneStatus('F1',clampToMax(map['F1']??0),maxPerZone:maxPerZone),
      ZoneStatus('F2',clampToMax(map['F2']??0),maxPerZone:maxPerZone),
      ZoneStatus('F3',clampToMax(map['F3']??0),maxPerZone:maxPerZone),
      ZoneStatus('F4',clampToMax(map['F4']??0),maxPerZone:maxPerZone),
    ];
  }
}

// ---------- 지그 리스트 공통 바텀시트 ----------
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
              final updated = edited.copyWith(likes: original.likes, isLiked: original.isLiked);
              final g = List<JigItemData>.from(JigsStore.notifier.value);
              int gi = g.indexOf(original);
              if (gi == -1) {
                gi = g.indexWhere((e) =>
                e.title==original.title && e.location==original.location && e.registrant==original.registrant);
              }
              if (gi != -1) { g[gi] = updated; JigsStore.notifier.value = g; }
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
                Container(width: 48, height: 5, margin: const EdgeInsets.only(top:10,bottom:6),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(999))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16,0,16,8),
                  child: Row(children:[
                    Text(title, style: const TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
                    const Spacer(),
                    Text('${items.length}건', style: const TextStyle(color: Colors.black54)),
                  ]),
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
                      return Stack(children: [
                        JigItem(
                          image: it.image, title: it.title, location: it.location, price: it.description,
                          registrant: it.registrant, likes: it.likes, isLiked: it.isLiked,
                          onLikePressed: () {}, storageDate: it.storageDate, disposalDate: it.disposalDate,
                          size: it.size, jigHeight: it.jigHeight,
                        ),
                        Positioned(
                          top: 0, right: 0,
                          child: IconButton(
                            tooltip: '수정', icon: const Icon(Icons.edit, color: Colors.black),
                            onPressed: () => _openEdit(it),
                          ),
                        ),
                      ]);
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

// ---------- 화면 ----------
class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({
    super.key,
    this.title = '창고 현황',
    this.locationTitle = kPlantB,
    this.maxPerFloor = 10,
    this.maxPerZone = 10,
    this.showMapButton = true,
    this.itemsListenable,
    this.embedded = false,      // ✅ 추가
  });

  final String title;
  final String locationTitle;
  final int maxPerFloor;
  final int maxPerZone;
  final bool showMapButton;
  final ValueListenable<List<JigItemData>>? itemsListenable;
  final bool embedded;          // ✅ 추가

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  void _openMap(BuildContext context, ValueListenable<List<JigItemData>> listenable) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => JinryangBDongMap(
        onBack: () => Navigator.pop(context),
        jigsListenable: listenable,
        maxCapacityShelves: widget.maxPerFloor,
        maxCapacityF: widget.maxPerZone,
        weightOfItem: (it) => it.capacityWeight,
        onCreateJig: JigsStore.add,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final listenable = JigsStore.notifier;

    Widget buildBody(List<JigItemData> allItems) {
      final shelves = _CapacityAgg.shelvesFrom(allItems, maxPerFloor: widget.maxPerFloor);
      final zones   = _CapacityAgg.zonesFrom(allItems,   maxPerZone: widget.maxPerZone);

      return LayoutBuilder(
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
                  filter: (it) => _parentOf(it.location) == kPlantB && _slotOf(it.location) == s.shelf,
                  itemsListenable: listenable,
                ),
                onFloorTap: (floor) => _showJigListBottomSheet(
                  context: context,
                  title: '${s.shelf} ${floor}층',
                  filter: (it) =>
                  _parentOf(it.location) == kPlantB &&
                      _slotOf(it.location) == s.shelf &&
                      _floorOf(it.location) == '${floor}층',
                  itemsListenable: listenable,
                ),
              ),
            for (final z in zones)
              ZoneCapacityCard(
                status: z,
                onDetail: () => _showJigListBottomSheet(
                  context: context,
                  title: '${z.zone} 존',
                  filter: (it) => _parentOf(it.location) == kPlantB && _slotOf(it.location) == z.zone,
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
      );
    }

    return ValueListenableBuilder<List<JigItemData>>(
      valueListenable: listenable,
      builder: (context, allItems, _) {
        if (widget.embedded) {
          return buildBody(allItems); // ✅ AppBar 없이 본문만
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
          body: buildBody(allItems),
        );
      },
    );
  }
}

// ---------- 카드 공용 ----------
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
      elevation: 1, color: Colors.white, borderRadius: BorderRadius.circular(16), clipBehavior: Clip.antiAlias,
      child: InkWell(
          borderRadius: BorderRadius.circular(16), onTap: onDetail,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
                child: Row(
                  children: [
                    _FloorBox(
                      label: '4층',
                      value: status.f4,
                      max: status.maxPerFloor,
                      onTap: onFloorTap == null ? null : () => onFloorTap!(4),
                    ),
                    const SizedBox(width: 6),
                    _FloorBox(
                      label: '3층',
                      value: status.f3,
                      max: status.maxPerFloor,
                      onTap: onFloorTap == null ? null : () => onFloorTap!(3),
                    ),
                    const SizedBox(width: 6),
                    _FloorBox(
                      label: '2층',
                      value: status.f2,
                      max: status.maxPerFloor,
                      onTap: onFloorTap == null ? null : () => onFloorTap!(2),
                    ),
                    const SizedBox(width: 6),
                    _FloorBox(
                      label: '1층',
                      value: status.f1,
                      max: status.maxPerFloor,
                      onTap: onFloorTap == null ? null : () => onFloorTap!(1),
                    ),
                  ],
                ),
              ),

              Align(alignment: Alignment.centerRight,
              child: TextButton.icon(onPressed: onDetail, icon: const Icon(Icons.list_alt), label: const Text('자세히'))),
          ]),
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
      elevation: 1, color: Colors.white, borderRadius: BorderRadius.circular(16), clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16), onTap: onDetail,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
                    color: _colorForRatio(status.ratio),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: Text('${status.value} / ${status.maxPerZone}', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ),
            Align(alignment: Alignment.centerRight,
                child: TextButton.icon(onPressed: onDetail, icon: const Icon(Icons.list_alt), label: const Text('자세히'))),
          ]),
        ),
      ),
    );
  }
}

class _FloorBox extends StatelessWidget {
  const _FloorBox({required this.label, required this.value, required this.max, this.onTap});
  final String label; final int value; final int max; final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, max);
    final bg = _colorForRatio((clamped / max).clamp(0, 1));
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('$clamped / $max', style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }
}
