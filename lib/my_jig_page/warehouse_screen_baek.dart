import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../widgets/jig_item.dart';
import '../widgets/jig_item_data.dart';
import '../data/jigs_store.dart';

const String kPlantBaek = '배광시험동 2층';
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

/* ------------------ 모델/집계(1~4층) ------------------ */
class BaekShelfStatus {
  final String shelf; // Rn or Ln
  final int f1, f2, f3, f4;
  final int maxPerFloor;
  const BaekShelfStatus(this.shelf, {this.f1 = 0, this.f2 = 0, this.f3 = 0, this.f4 = 0, required this.maxPerFloor});

  int get total => f1 + f2 + f3 + f4;
  int get maxTotal => (maxPerFloor * 4).clamp(1, 1 << 30);
  double get ratio => (total / maxTotal).clamp(0.0, 1.0);
}

class _BaekAgg {
  static BaekShelfStatus makeFor(List<JigItemData> items, {required String shelf, required int maxPerFloor}) {
    int f1 = 0, f2 = 0, f3 = 0, f4 = 0;
    for (final it in items) {
      if (_parentOf(it.location) != kPlantBaek) continue;
      if (_slotOf(it.location) != shelf) continue;
      final fl = _floorOf(it.location);
      final w  = _weightOfItem(it);
      if (fl == '1층') f1 += w;
      else if (fl == '2층') f2 += w;
      else if (fl == '3층') f3 += w;
      else if (fl == '4층') f4 += w;
    }
    int clamp(int v) => v.clamp(0, maxPerFloor);
    return BaekShelfStatus(shelf, f1: clamp(f1), f2: clamp(f2), f3: clamp(f3), f4: clamp(f4), maxPerFloor: maxPerFloor);
  }
}

/* ------------------ 바텀시트(층 필터 토글 포함) ------------------ */
void _showJigListBottomSheetBaek({
  required BuildContext context,
  required String title,
  required bool Function(JigItemData) baseFilter,
  required ValueListenable<List<JigItemData>> itemsListenable,
  List<String> floorChoices = const ['1층', '2층', '3층', '4층'],
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    builder: (_) {
      final Set<String> selectedFloors = {};
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('전체'),
                          selected: selectedFloors.isEmpty,
                          onSelected: (_) => setSB(() => selectedFloors.clear()),
                        ),
                        for (final f in floorChoices)
                          FilterChip(
                            label: Text(f),
                            selected: selectedFloors.contains(f),
                            onSelected: (sel) => setSB(() {
                              if (sel) {
                                selectedFloors.add(f);
                              } else {
                                selectedFloors.remove(f);
                              }
                            }),
                          ),
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
class WarehouseScreenEmbeddedBaek extends StatelessWidget {
  const WarehouseScreenEmbeddedBaek({super.key, this.maxPerFloor = 10});
  final int maxPerFloor;

  List<String> get _rightShelves => List.generate(24, (i) => 'R${i + 1}'); // 좌측 열
  List<String> get _leftShelves  => List.generate(20, (i) => 'L${i + 1}'); // 우측 열

  @override
  Widget build(BuildContext context) {
    final listenable = JigsStore.notifier;

    return ValueListenableBuilder<List<JigItemData>>(
      valueListenable: listenable,
      builder: (context, allItems, _) {
        BaekShelfStatus make(String s) => _BaekAgg.makeFor(allItems, shelf: s, maxPerFloor: maxPerFloor);
        final right = _rightShelves.map(make).toList();
        final left  = _leftShelves.map(make).toList();

        Widget _columnOf(List<BaekShelfStatus> list) {
          return Column(
            children: [
              for (final s in list) ...[
                _BaekShelfCard(
                  status: s,
                  onDetail: () => _showJigListBottomSheetBaek(
                    context: context,
                    title: '${s.shelf} 전체',
                    baseFilter: (it) => _parentOf(it.location) == kPlantBaek && _slotOf(it.location) == s.shelf,
                    itemsListenable: listenable,
                    floorChoices: const ['1층', '2층', '3층', '4층'], // ✅ 1~4층
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _columnOf(right)), // 좌: R1~24
              const SizedBox(width: 12),
              Expanded(child: _columnOf(left)),  // 우: L1~20
            ],
          ),
        );
      },
    );
  }
}

/* ------------------ 카드 (오직 '자세히' 버튼) ------------------ */
class _BaekShelfCard extends StatelessWidget {
  const _BaekShelfCard({required this.status, this.onDetail});
  final BaekShelfStatus status;
  final VoidCallback? onDetail;

  @override
  Widget build(BuildContext context) {
    final cap = status.ratio;
    final barColor = _progressColor(cap);
    final barBg = Colors.black.withOpacity(0.06);

    Widget _floorBox(String label, int v, int max) => Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: null,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: _colorForRatio((v / max).clamp(0, 1)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('$v / $max', style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );

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
              Row(children: [
                _floorBox('4층', status.f4, status.maxPerFloor),
                const SizedBox(width: 6),
                _floorBox('3층', status.f3, status.maxPerFloor),
                const SizedBox(width: 6),
                _floorBox('2층', status.f2, status.maxPerFloor),
                const SizedBox(width: 6),
                _floorBox('1층', status.f1, status.maxPerFloor),
              ]),
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
