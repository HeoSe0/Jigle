import 'package:flutter/material.dart';
import '../map_page/jinryang_maps/jinryang_b_dong_map.dart';

/// 층(1~4층)별 0~10 용량 지표를 가지는 선반 상태
class ShelfStatus {
  final String shelf; // L1 / C1 / R1
  final int f1, f2, f3, f4; // 1~4층 (0~10)
  const ShelfStatus(this.shelf, {this.f1 = 0, this.f2 = 0, this.f3 = 0, this.f4 = 0});

  /// 0.0~1.0 (전체 용량 대비 비율)
  double get capacityRatio => (f1 + f2 + f3 + f4) / 40.0;
  Map<String, int> get floors => {'4층': f4, '3층': f3, '2층': f2, '1층': f1};
}

// 0~10 값을 색으로 변환
Color colorForCapacity(int c) {
  final v = c.clamp(0, 10);
  const a = 0.35; // 투명도
  if (v == 0) return Colors.green.withValues(alpha: a);
  if (v >= 8) return Colors.red.withValues(alpha: a);
  return Colors.yellow.withValues(alpha: a);
}

// 상단 퍼센트/바 색
Color capacityProgressColor(double r) {
  if (r >= 0.8) return Colors.red;
  if (r <= 0.3) return Colors.green;
  return Colors.amber;
}

class WarehouseScreen extends StatelessWidget {
  const WarehouseScreen({
    super.key,
    this.title = '창고 현황',
    this.locationTitle = '진량공장 B동',
    this.l1 = const ShelfStatus('L1', f1: 1, f2: 2, f3: 3, f4: 1),
    this.c1 = const ShelfStatus('C1', f1: 5, f2: 5, f3: 5, f4: 2),
    this.r1 = const ShelfStatus('R1', f1: 8, f2: 7, f3: 9, f4: 4),
  });

  final String title;
  final String locationTitle;
  final ShelfStatus l1, c1, r1;

  void _openJinryangBMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => JinryangBDongMap(
          onBack: () => Navigator.pop(ctx),
          // L1
          l1Floor1Capacity: l1.f1,
          l1Floor2Capacity: l1.f2,
          l1Floor3Capacity: l1.f3,
          l1Floor4Capacity: l1.f4,
          // R1
          r1Floor1Capacity: r1.f1,
          r1Floor2Capacity: r1.f2,
          r1Floor3Capacity: r1.f3,
          r1Floor4Capacity: r1.f4,
          // C1
          c1Floor1Capacity: c1.f1,
          c1Floor2Capacity: c1.f2,
          c1Floor3Capacity: c1.f3,
          c1Floor4Capacity: c1.f4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shelves = [l1, c1, r1];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _openJinryangBMap(context),
            icon: const Icon(Icons.map_outlined),
            label: const Text('지도 보기'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final isWide = c.maxWidth >= 900;
          final crossAxisCount = isWide ? 3 : (c.maxWidth >= 600 ? 2 : 1);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text(locationTitle,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2E9F7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('선반별 지그 포화도', style: TextStyle(fontWeight: FontWeight.w700)),
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
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 220,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, i) => ShelfCapacityCard(
                      status: shelves[i],
                      onDetail: () => _openJinryangBMap(context),
                    ),
                    childCount: shelves.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ShelfCapacityCard extends StatelessWidget {
  const ShelfCapacityCard({super.key, required this.status, this.onDetail});
  final ShelfStatus status;
  final VoidCallback? onDetail;

  @override
  Widget build(BuildContext context) {
    final cap = status.capacityRatio.clamp(0.0, 1.0);
    final progressColor = capacityProgressColor(cap);
    final background = Colors.black.withValues(alpha: 0.06);

    return Material(
      elevation: 1,
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onDetail,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(status.shelf,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${(cap * 100).round()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: progressColor,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: cap,
                minHeight: 12,
                color: progressColor,
                backgroundColor: background,
              ),
            ),
            const SizedBox(height: 12),
            const Text('층별 지그 포화도', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: status.floors.entries.map((e) {
                  return Expanded(child: _FloorBox(label: e.key, value: e.value));
                }).toList(),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onDetail,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('자세히'),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

class _FloorBox extends StatelessWidget {
  const _FloorBox({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final bg = colorForCapacity(value);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
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
          Text('$value / 10',
              style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
