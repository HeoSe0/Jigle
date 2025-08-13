// lib/map_page/jinryang_maps/jinryang_baekwang_test_building_map.dart
import 'package:flutter/material.dart';
import '../../widgets/jig_item_data.dart';
import '../../widgets/jig_item.dart';

// 공용: 사용률에 따른 색상
Color _colorForUtil({required int used, required int max}) {
  final m = (max <= 0) ? 1 : max;
  final u = (used.clamp(0, m)) / m;
  const a = 0.35;
  if (u <= 0) return Colors.green.withValues(alpha: a);
  if (u >= 1) return Colors.red.withValues(alpha: a);
  const mid = 0.6;
  final base = (u < mid)
      ? Color.lerp(Colors.green, Colors.yellow, u / mid)!
      : Color.lerp(Colors.yellow, Colors.red, (u - mid) / (1 - mid))!;
  return base.withValues(alpha: a);
}

/// 배광시험동 2층 – R1~R24 / L1~L24 (각 슬롯 1~5층) 지도
class JinryangBaekwangTestBuildingMap extends StatefulWidget {
  final VoidCallback onBack;
  final List<JigItemData> allItems;

  /// 층 버튼 색상 상한 (가중치 합계가 이 값에 가까울수록 빨강)
  final int maxCapacityPerFloor;

  /// (옵션) 지그 1개의 가중치 계산. 미제공 시 size -> 1/3/5
  final int Function(JigItemData item)? weightOfItem;

  /// 🔧 층 버튼/레이아웃 커스터마이즈
  final double floorBtnWidthFrac;          // 0~1, 버튼 너비 비율
  final double floorBtnHeightFracOfFifth;  // 0~1, 각 1/5 스트립 대비 버튼 높이
  final double floorBtnGap;                // 버튼 사이 세로 간격(px) — 총 4개 갭
  final double floorBtnRadius;             // 버튼 모서리(px)
  final EdgeInsets overlayPadding;         // 배경 이미지 안쪽 패딩
  final double floorButtonsYOffsetPx;      // ▶ 전체 버튼 스택 상하 이동(px, 음수면 위로)

  const JinryangBaekwangTestBuildingMap({
    super.key,
    required this.onBack,
    this.allItems = const [],
    this.maxCapacityPerFloor = 20,
    this.weightOfItem,
    this.floorBtnWidthFrac = 0.86,
    this.floorBtnHeightFracOfFifth = 0.82,
    this.floorBtnGap = 4,
    this.floorBtnRadius = 10,
    this.overlayPadding = const EdgeInsets.all(8),
    this.floorButtonsYOffsetPx = 0,
  });

  @override
  State<JinryangBaekwangTestBuildingMap> createState() =>
      _JinryangBaekwangTestBuildingMapState();
}

class _JinryangBaekwangTestBuildingMapState
    extends State<JinryangBaekwangTestBuildingMap> {
  // ===== Layout =====
  static const double _kBtnW = 80;
  static const double _kBtnH = 160;
  static const double _kGapV = 8;
  static const double _kColGap = 70;
  static const int _kItemsPerColumn = 12;

  static double get _rowWidth => _kBtnW * 2 + _kColGap;
  static double get _rowHeight =>
      _kItemsPerColumn * _kBtnH + (_kItemsPerColumn - 1) * _kGapV;

  // ===== Util =====
  int _weight(JigItemData it) {
    if (widget.weightOfItem != null) return widget.weightOfItem!(it);
    switch (it.size.replaceAll(' ', '')) {
      case '대형':
      case '대':
        return 5;
      case '중형':
      case '중':
        return 3;
      default:
        return 1;
    }
  }

  String _parent(String loc) => loc.split('/').first.trim();

  String? _slot(String loc) {
    final p = loc.split('/').map((e) => e.trim()).toList();
    return p.length > 1 ? p[1] : null; // Rn/Ln
  }

  String? _floor(String loc) {
    final p = loc.split('/').map((e) => e.trim()).toList();
    if (p.length > 2) {
      final m = RegExp(r'(\d)').firstMatch(p[2]);
      if (m != null) return '${m.group(1)}층';
    }
    return null;
  }

  List<JigItemData> _itemsFor(String slot, String floor) {
    return widget.allItems.where((it) {
      if (_parent(it.location) != '배광시험동 2층') return false;
      return _slot(it.location) == slot && _floor(it.location) == floor;
    }).toList();
  }

  int _usedFor(String slot, String floor) {
    final list = _itemsFor(slot, floor);
    return list.fold<int>(0, (s, it) => s + _weight(it));
  }

  // ===== UI: 버튼들 =====
  Widget _buildShelfColumn(List<String> labels, BuildContext context) {
    return Column(
      children: List.generate(labels.length, (i) {
        final label = labels[i];
        return SizedBox(
          width: _kBtnW,
          height: _kBtnH,
          child: Padding(
            padding: EdgeInsets.only(bottom: i == labels.length - 1 ? 0 : _kGapV),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue.shade100,
                foregroundColor: Colors.black,
                shape: const RoundedRectangleBorder(
                  side: BorderSide(color: Colors.black),
                  borderRadius: BorderRadius.zero,
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: () => _openSlotDialog(context, label),
              child: Text(label),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildShelfRow({
    required List<String> rightLabels,
    required List<String> leftLabels,
    required BuildContext context,
  }) {
    return Center(
      child: SizedBox(
        width: _rowWidth,
        height: _rowHeight,
        child: Stack(
          children: [
            // 중앙 박스 (좌/우 컬럼 사이)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 5),
                ),
              ),
            ),
            // 좌/우 버튼 컬럼
            Positioned(left: 0, top: 0, child: _buildShelfColumn(rightLabels, context)),
            Positioned(right: 0, top: 0, child: _buildShelfColumn(leftLabels, context)),
          ],
        ),
      ),
    );
  }

  // ====== 다이얼로그(선반 → 층 → 상세 전환) ======
  Future<void> _openSlotDialog(BuildContext context, String slot) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        String? selectedFloor;
        return StatefulBuilder(
          builder: (dctx, setSB) {
            return AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              // 상단: 슬롯명(좌) + 선택된 층(우, 투명)
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$slot 슬롯',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (selectedFloor != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        selectedFloor!,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
              content: SizedBox(
                width: 720,
                height: 520,
                child: BaekwangShelfViewer5Floors(
                  slotLabel: slot,
                  maxCapacity: widget.maxCapacityPerFloor,
                  selectedFloor: selectedFloor,
                  onSelectFloor: (floor) => setSB(() => selectedFloor = floor),
                  onBackToFloors: () => setSB(() => selectedFloor = null),
                  capacityForFloor: (floorLabel) => _usedFor(slot, floorLabel),
                  detailsBuilder: (slotLabel, floorLabel, onBack) {
                    final items = _itemsFor(slotLabel, floorLabel);
                    return _BaekJigDetailPanel(
                      child: items.isEmpty
                          ? const Center(
                        child: Text('등록된 지그가 없습니다.', style: TextStyle(color: Colors.grey)),
                      )
                          : ListView.separated(
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
                            onLikePressed: () {}, // 필요 시 연결
                            storageDate: it.storageDate,
                            disposalDate: it.disposalDate,
                          );
                        },
                      ),
                      onBack: onBack, // 층 화면으로 전환
                    );
                  },
                  // 🔧 크기/간격/이동 파라미터 전달
                  floorBtnWidthFrac: widget.floorBtnWidthFrac,
                  floorBtnHeightFracOfFifth: widget.floorBtnHeightFracOfFifth,
                  floorBtnGap: widget.floorBtnGap,
                  floorBtnRadius: widget.floorBtnRadius,
                  overlayPadding: widget.overlayPadding,
                  floorButtonsYOffsetPx: widget.floorButtonsYOffsetPx,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextButton(
                    onPressed: () => Navigator.pop(dctx),
                    child: const Text('돌아가기'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final leftLabels = List.generate(24, (i) => 'L${i + 1}');
    final rightLabels = List.generate(24, (i) => 'R${i + 1}');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Column(
                children: [
                  const Column(
                    children: [
                      Text('IN', style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
                      Icon(Icons.arrow_downward, size: 32, color: Colors.blue),
                      SizedBox(height: 20),
                    ],
                  ),
                  _buildShelfRow(
                    rightLabels: rightLabels.sublist(0, 12),
                    leftLabels: leftLabels.sublist(0, 12),
                    context: context,
                  ),
                  const SizedBox(height: 50),
                  _buildShelfRow(
                    rightLabels: rightLabels.sublist(12),
                    leftLabels: leftLabels.sublist(12),
                    context: context,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton.filledTonal(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(padding: const EdgeInsets.all(10)),
                tooltip: '뒤로',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 배광 슬롯 뷰어(5층): 초기에는 층 버튼 오버레이만 노출, 층 탭 시 상세 패널로 전환
class BaekwangShelfViewer5Floors extends StatelessWidget {
  final String slotLabel;
  final int maxCapacity;

  /// 현재 선택된 층. null이면 층 버튼 화면
  final String? selectedFloor;

  /// 층을 탭했을 때 호출 (부모에서 selectedFloor를 갱신)
  final ValueChanged<String> onSelectFloor;

  /// 상세에서 '돌아가기'를 눌렀을 때 호출 (부모에서 selectedFloor=null)
  final VoidCallback onBackToFloors;

  /// '1층' ~ '5층' → 사용량
  final int Function(String floorLabel) capacityForFloor;

  /// 상세 패널(지그 카드 리스트 등)
  final Widget Function(String slotLabel, String floorLabel, VoidCallback onBack) detailsBuilder;

  /// 🔧 크기/간격 파라미터
  final double floorBtnWidthFrac;          // 0~1
  final double floorBtnHeightFracOfFifth;  // 0~1
  final double floorBtnGap;                // px (총 4개 gap 반영)
  final double floorBtnRadius;             // px
  final EdgeInsets overlayPadding;
  final double floorButtonsYOffsetPx;      // ▶ 전체 버튼 스택 상하 이동(px)

  const BaekwangShelfViewer5Floors({
    super.key,
    required this.slotLabel,
    required this.maxCapacity,
    required this.selectedFloor,
    required this.onSelectFloor,
    required this.onBackToFloors,
    required this.capacityForFloor,
    required this.detailsBuilder,
    this.floorBtnWidthFrac = 0.86,
    this.floorBtnHeightFracOfFifth = 0.82,
    this.floorBtnGap = 4,
    this.floorBtnRadius = 10,
    this.overlayPadding = const EdgeInsets.all(8),
    this.floorButtonsYOffsetPx = 0,
  });

  @override
  Widget build(BuildContext context) {
    final showDetails = selectedFloor != null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: showDetails
          ? detailsBuilder(slotLabel, selectedFloor!, onBackToFloors)
          : _buildFloorsOverlay(context),
    );
  }

  Widget _buildFloorsOverlay(BuildContext context) {
    // shelf_empty.png 위에 5층 버튼 수직 배치 (크기/간격/위치 커스터마이즈)
    return LayoutBuilder(
      key: const ValueKey('floors'),
      builder: (context, c) {
        final pad = overlayPadding.resolve(Directionality.of(context));
        final W = c.maxWidth, H = c.maxHeight;
        final innerW = (W - pad.horizontal).clamp(0.0, double.infinity);
        final innerH = (H - pad.vertical).clamp(0.0, double.infinity);

        // ✅ 총 4개의 gap 반영 후 스트립 높이 산출
        final totalGap = floorBtnGap * 4.0;
        final stripH = (innerH - totalGap) / 5.0;

        final btnH = stripH * floorBtnHeightFracOfFifth;
        final btnW = innerW * floorBtnWidthFrac;
        final left = pad.left + (innerW - btnW) / 2;
        final inStripOffset = (stripH - btnH) / 2;

        final children = <Widget>[
          // 배경
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/shelf_empty.png', fit: BoxFit.fill),
            ),
          ),
        ];

        for (int i = 0; i < 5; i++) {
          final floorLabel = '${5 - i}층'; // 위=5층, 아래=1층
          final used = capacityForFloor(floorLabel);

          final top = pad.top
              + floorButtonsYOffsetPx              // ▶ 전체 스택 상하 이동
              + i * (stripH + floorBtnGap)          // ✅ 간격 반영
              + inStripOffset;

          children.add(
            Positioned(
              left: left,
              top: top,
              width: btnW,
              height: btnH,
              child: Material(
                color: _colorForUtil(used: used, max: maxCapacity),
                borderRadius: BorderRadius.circular(floorBtnRadius),
                child: InkWell(
                  borderRadius: BorderRadius.circular(floorBtnRadius),
                  onTap: () => onSelectFloor(floorLabel),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$floorLabel  (사용:$used/$maxCapacity)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Stack(children: children);
      },
    );
  }
}

/// 상세 패널(층 선택 후): 지그 리스트 + 하단 '돌아가기' 버튼(배경 투명)
class _BaekJigDetailPanel extends StatelessWidget {
  final Widget child;
  final VoidCallback onBack;

  const _BaekJigDetailPanel({
    required this.child,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: const ValueKey('details'),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: ColoredBox(color: Colors.white, child: child)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onBack, child: const Text('돌아가기')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
