import 'package:flutter/material.dart';

/// 공통 상수
const double kAlpha = 0.35; // 투명도

/// 층(1~4층)별 0~10 용량 지표를 가지는 선반 상태
class ShelfStatus {
  final String shelf; // L1 / C1 / R1
  final int f1, f2, f3, f4; // 1~4층 (0~10)

  /// const 생성자: 값 검증은 assert만 수행 (릴리즈에선 미동작)
  const ShelfStatus(
      this.shelf, {
        this.f1 = 0,
        this.f2 = 0,
        this.f3 = 0,
        this.f4 = 0,
      })  : assert(f1 >= 0 && f1 <= 10),
        assert(f2 >= 0 && f2 <= 10),
        assert(f3 >= 0 && f3 <= 10),
        assert(f4 >= 0 && f4 <= 10);

  /// 안전 생성자: 런타임 입력을 0~10으로 클램프해서 생성
  factory ShelfStatus.safe(
      String shelf, {
        int f1 = 0,
        int f2 = 0,
        int f3 = 0,
        int f4 = 0,
      }) {
    int clamp10(int v) => v < 0 ? 0 : (v > 10 ? 10 : v);
    return ShelfStatus(
      shelf,
      f1: clamp10(f1),
      f2: clamp10(f2),
      f3: clamp10(f3),
      f4: clamp10(f4),
    );
  }

  int get total => f1 + f2 + f3 + f4;
  double get capacityRatio => total / 40.0;

  Map<String, int> get floors => {'4층': f4, '3층': f3, '2층': f2, '1층': f1};
}

// 0~10 값을 색으로 변환 (0: green, 8~10: red, 그 외: yellow)
Color colorForCapacity(int c) {
  final v = c.clamp(0, 10);
  if (v == 0) return Colors.green.withValues(alpha: kAlpha);
  if (v >= 8) return Colors.red.withValues(alpha: kAlpha);
  return Colors.yellow.withValues(alpha: kAlpha);
}

// 상단 퍼센트/바 색
Color capacityProgressColor(double r) {
  if (r >= 0.8) return Colors.red;
  if (r <= 0.3) return Colors.green;
  return Colors.amber;
}

/// 흰 화면 (뒤로가기 아이콘 포함)
class WhiteScreen extends StatelessWidget {
  const WhiteScreen({super.key, this.title = '흰 화면'});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: const TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const SizedBox.expand(),
    );
  }
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

  void _openWhiteScreen(BuildContext context, {String? title}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WhiteScreen(title: title ?? '흰 화면'),
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
            onPressed: () => _openWhiteScreen(context, title: '흰 화면'),
            icon: const Icon(Icons.map_outlined),
            label: const Text('흰 화면'),
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
                      Text(
                        locationTitle,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
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
                      onDetail: () => _openWhiteScreen(context, title: shelves[i].shelf),
                      onFloorTap: (floor) =>
                          _openWhiteScreen(context, title: '${shelves[i].shelf} ${floor}층'),
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
    final cap = status.capacityRatio.clamp(0.0, 1.0);
    final progressColor = capacityProgressColor(cap);
    final background = Colors.black.withValues(alpha: 0.06);

    final labels = ['4층', '3층', '2층', '1층'];
    final values = [status.f4, status.f3, status.f2, status.f1];
    final floors = [4, 3, 2, 1];

    return Material(
      elevation: 1,
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onDetail, // 카드 전체 탭 → 흰 화면
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
                  child: Text(
                    status.shelf,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                const Spacer(),
                Semantics(
                  label: '총 포화도',
                  value: '${(cap * 100).toStringAsFixed(0)}퍼센트',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${(cap * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontWeight: FontWeight.w800, color: progressColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: cap),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 12,
                    color: progressColor,
                    backgroundColor: background,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            const Text('층별 지그 포화도', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: List.generate(labels.length, (i) {
                  return Expanded(
                    child: _FloorBox(
                      label: labels[i],
                      value: values[i],
                      onTap: onFloorTap == null ? null : () => onFloorTap!(floors[i]),
                    ),
                  );
                }),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onDetail, // 자세히 → 흰 화면
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
  const _FloorBox({required this.label, required this.value, this.onTap});
  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 10);
    final bg = colorForCapacity(clamped);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap, // 층 버튼 → 흰 화면
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Semantics(
            button: true,
            label: '$label 포화도',
            value: '$clamped / 10',
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
