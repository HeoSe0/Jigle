// lib/map_page/jinryang_maps/jinryang_baekwang_test_building_map.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../widgets/jig_item_data.dart';
import '../../widgets/jig_item.dart';
import '../../widgets/jig_form_bottom_sheet.dart';

/// B동과 동일한 포화도 색상(알파 조절 가능)
Color _colorForUtil({
  required int used,
  required int max,
  double alpha = 0.35,
}) {
  final m = (max <= 0) ? 1 : max;
  final u = (used.clamp(0, m)) / m;
  if (u <= 0) return Colors.green.withOpacity(alpha);
  if (u >= 1) return Colors.red.withOpacity(alpha);
  const mid = 0.6;
  final base = (u < mid)
      ? Color.lerp(Colors.green, Colors.yellow, u / mid)!
      : Color.lerp(Colors.yellow, Colors.red, (u - mid) / (1 - mid))!;
  return base.withOpacity(alpha);
}

/// 배광시험동 2층 – R1~R24 / L1~L20 (각 슬롯 1~5층)
class JinryangBaekwangTestBuildingMap extends StatefulWidget {
  final VoidCallback onBack;

  /// 실시간 리스트(선택). 없으면 [allItems] 스냅샷 사용
  final ValueListenable<List<JigItemData>>? jigsListenable;

  /// 최초 진입 스냅샷(선택)
  final List<JigItemData> allItems;

  /// 등록 시 상위로 전달(선택) – 부모에서 전역 리스트 갱신
  final void Function(JigItemData newItem)? onCreateJig;

  /// 층 버튼 색상 상한 (가중치 합계가 이 값에 가까울수록 빨강)
  final int maxCapacityPerFloor;

  /// (옵션) 지그 1개의 가중치 계산. 미제공 시 size -> 1/3/5
  final int Function(JigItemData item)? weightOfItem;

  /// 🔧 층 버튼/레이아웃 커스터마이즈
  final double floorBtnWidthFrac;          // 0~1, 버튼 너비 비율
  final double floorBtnHeightFracOfFifth;  // 0~1, 각 1/5 스트립 대비 버튼 높이
  final double floorBtnGap;                // 버튼 사이 세로 간격(px)
  final double floorBtnRadius;             // 버튼 모서리(px)
  final EdgeInsets overlayPadding;         // 배경 이미지 안쪽 패딩
  final double floorButtonsYOffsetPx;      // 전체 버튼 스택 상하 이동(px)

  const JinryangBaekwangTestBuildingMap({
    super.key,
    required this.onBack,
    this.jigsListenable,
    this.allItems = const [],
    this.onCreateJig,
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
  static double get _rowWidth => _kBtnW * 2 + _kColGap;

  // ===== 최근 본 위치(FAB 프리필) =====
  String? _lastSlot;   // Ln / Rn
  String? _lastFloor;  // 1층~5층

  // ===== 내부 로컬 리스트 (전역 연결 없을 때 사용) =====
  late List<JigItemData> _localItems;

  // ===== 최신 아이템 접근 =====
  List<JigItemData> get _items =>
      widget.jigsListenable?.value ?? _localItems;

  @override
  void initState() {
    super.initState();
    _localItems = List<JigItemData>.from(widget.allItems);
    widget.jigsListenable?.addListener(_onItemsChanged);
  }

  @override
  void didUpdateWidget(covariant JinryangBaekwangTestBuildingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jigsListenable != widget.jigsListenable) {
      oldWidget.jigsListenable?.removeListener(_onItemsChanged);
      widget.jigsListenable?.addListener(_onItemsChanged);
    }
    // allItems prop이 바뀌면 로컬 스냅샷 갱신
    if (!listEquals(oldWidget.allItems, widget.allItems) &&
        widget.jigsListenable == null) {
      _localItems = List<JigItemData>.from(widget.allItems);
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.jigsListenable?.removeListener(_onItemsChanged);
    super.dispose();
  }

  void _onItemsChanged() {
    if (mounted) setState(() {}); // 포화도 재계산
  }

  // ===== 문자열 정규화/파싱 =====
  String _norm(String s) => s.replaceAll(RegExp(r'\s+'), '').trim();
  List<String> _parts(String loc) => loc.split('/').map((e) => e.trim()).toList();

  int _weight(JigItemData it) {
    if (widget.weightOfItem != null) return widget.weightOfItem!(it);
    switch ((it.size ?? '').replaceAll(' ', '')) {
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

  String _parent(String loc) => _parts(loc).first.trim();

  String? _slot(String loc) {
    final p = _parts(loc);
    return p.length > 1 ? p[1] : null; // Rn/Ln
  }

  String? _floor(String loc) {
    final p = _parts(loc);
    if (p.length > 2) {
      final m = RegExp(r'(\d)').firstMatch(p[2]);
      if (m != null) return '${m.group(1)}층';
    }
    return null;
  }

  bool _isBaek2F(String loc) => _norm(_parent(loc)) == _norm('배광시험동 2층');

  List<JigItemData> _itemsFor(String slot, String floor) {
    final ns = _norm(slot);
    final nf = _norm(floor);
    return _items.where((it) {
      final loc = it.location;
      if (!_isBaek2F(loc)) return false;
      final s = _slot(loc);
      final f = _floor(loc);
      return _norm(s ?? '') == ns && _norm(f ?? '') == nf;
    }).toList();
  }

  int _usedFor(String slot, String floor) {
    final list = _itemsFor(slot, floor);
    return list.fold<int>(0, (s, it) => s + _weight(it));
  }

  // ▶ 슬롯(5층 합계) 사용량
  int _usedTotalForSlot(String slot) {
    const floors = ['1층', '2층', '3층', '4층', '5층'];
    var sum = 0;
    for (final f in floors) {
      sum += _usedFor(slot, f);
    }
    return sum;
  }

  /// ▶ 슬롯 버튼 색상 (B동과 동일 기준)
  Color _slotColor(String slot) {
    final used = _usedTotalForSlot(slot);
    final max = widget.maxCapacityPerFloor * 5; // 5층 합계 기준
    return _colorForUtil(used: used, max: max, alpha: 0.8);
  }

  // ===== 등록 처리: 전역 반영 보장 + 로컬 폴백 =====
  void _handleCreateJig(JigItemData newJig) {
    bool handled = false;

    // 1) 부모 콜백이 있으면 사용 (전역 연동)
    if (widget.onCreateJig != null) {
      widget.onCreateJig!(newJig);
      handled = true;
    }

    // 2) jigsListenable가 ValueNotifier면 내부에서 바로 append (전역 연동)
    final ln = widget.jigsListenable;
    if (!handled && ln is ValueNotifier<List<JigItemData>>) {
      final cur = List<JigItemData>.from(ln.value);
      ln.value = [...cur, newJig];
      handled = true;
    }

    // 3) 둘 다 없으면 로컬 리스트에 추가 (화면 즉시 반영)
    if (!handled) {
      setState(() {
        _localItems = [..._localItems, newJig];
      });
    }

    // 최근 위치(FAB 프리필)
    _lastSlot = _slot(newJig.location) ?? _lastSlot;
    _lastFloor = _floor(newJig.location) ?? _lastFloor;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(handled
              ? '지그가 등록되었습니다.'
              : '지그가 등록되어 이 화면에는 반영되었습니다. (전역 연동은 onCreateJig 또는 ValueNotifier 연결 권장)'),
        ),
      );
    }
  }

  // ===== 등록 폼 열기 (B동과 동일 패턴) =====
  void _openAddJig({String? slot, String? floor}) {
    String loc = '배광시험동 2층';
    if (slot != null && slot.isNotEmpty) loc += ' / $slot';
    if (floor != null && floor.isNotEmpty) loc += ' / $floor';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => JigFormBottomSheet(
        initialLocation: loc, // 프리필만 전달
        onSubmit: (newJig) => _handleCreateJig(newJig),
      ),
    );
  }

  // ===== UI: 버튼들 =====
  Widget _buildShelfColumn(List<String> labels, BuildContext context) {
    return Column(
      children: List.generate(labels.length, (i) {
        final label = labels[i];
        final capColor = _slotColor(label);
        return SizedBox(
          width: _kBtnW,
          height: _kBtnH,
          child: Padding(
            padding: EdgeInsets.only(bottom: i == labels.length - 1 ? 0 : _kGapV),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: capColor,          // 포화도 색상(불투명)
                foregroundColor: Colors.black,
                shape: const RoundedRectangleBorder(
                  side: BorderSide(color: Colors.black),
                  borderRadius: BorderRadius.zero,
                ),
                padding: EdgeInsets.zero,
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              onPressed: () {
                _lastSlot = label;   // 최근 슬롯 기억(FAB 프리필)
                _openSlotDialog(context, label);
              },
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
    final rCount = rightLabels.length;
    final lCount = leftLabels.length;
    final maxCount = rCount > lCount ? rCount : lCount;
    final rowHeight = maxCount * _kBtnH + (maxCount - 1) * _kGapV;

    // 중앙 통로 위치/크기
    final corridorLeft = _kBtnW;
    final corridorWidth = _kColGap;

    const yellowLineWidth = 5.0;
    const yellowEdgeInset = 0.0;

    return Center(
      child: SizedBox(
        width: _rowWidth,
        height: rowHeight,
        child: Stack(
          children: [
            // 바깥 테두리 + 내부 초록 배경(슬롯 사이 여백 포함)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 5),
                  color: Colors.green.shade800,
                ),
              ),
            ),

            // 중앙 통로: 진녹색 + 양옆 노란 라인
            Positioned(
              left: corridorLeft,
              top: 0,
              width: corridorWidth,
              height: rowHeight,
              child: Stack(
                children: [
                  Positioned.fill(child: Container(color: Colors.green.shade800)),
                  Positioned(
                    left: yellowEdgeInset,
                    top: 0,
                    bottom: 0,
                    width: yellowLineWidth,
                    child: Container(color: Colors.yellowAccent),
                  ),
                  Positioned(
                    right: yellowEdgeInset,
                    top: 0,
                    bottom: 0,
                    width: yellowLineWidth,
                    child: Container(color: Colors.yellowAccent),
                  ),
                ],
              ),
            ),

            // 좌/우 슬롯 버튼 컬럼
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
                  onSelectFloor: (floor) {
                    setSB(() => selectedFloor = floor);
                    _lastSlot = slot;
                    _lastFloor = floor; // 최근 층도 기억
                  },
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
                            onLikePressed: () {},
                            storageDate: it.storageDate,
                            disposalDate: it.disposalDate,
                            size: it.size,
                            jigHeight: it.jigHeight,
                          );
                        },
                      ),
                      onBack: onBack,
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
                // ➕ 지그 등록 버튼(선택한 층 프리필)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 4, 8),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(dctx); // 다이얼로그 닫고
                      _openAddJig(slot: slot, floor: selectedFloor);
                    },
                    child: const Text('+ 지그 등록'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 16, 8),
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
    // ✅ L은 1~20, R은 1~24
    final leftLabelsAll  = List.generate(20, (i) => 'L${i + 1}');
    final rightLabelsAll = List.generate(24, (i) => 'R${i + 1}');

    // 상단/하단 분할 (R: 12/12, L: 10/10)
    final rightTop    = rightLabelsAll.sublist(0, 12);
    final rightBottom = rightLabelsAll.sublist(12);
    final leftTop     = leftLabelsAll.sublist(0, 10);
    final leftBottom  = leftLabelsAll.sublist(10);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Center(
                child: Container(
                  // ▶ 베이지 사각형으로 주변을 감싸기
                  width: _rowWidth + 120, // 슬롯행 너비 + 여유
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2DEBC), // 베이지
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      const Column(
                        children: [
                          Text('IN',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Icon(Icons.arrow_downward, size: 32, color: Colors.blue),
                          SizedBox(height: 20),
                        ],
                      ),
                      _buildShelfRow(
                        rightLabels: rightTop,
                        leftLabels: leftTop,
                        context: context,
                      ),
                      const SizedBox(height: 50),
                      _buildShelfRow(
                        rightLabels: rightBottom,
                        leftLabels: leftBottom,
                        context: context,
                      ),
                    ],
                  ),
                ),
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

      // ▶ B동과 동일: 최근 위치 프리필로 바로 등록
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddJig(slot: _lastSlot, floor: _lastFloor),
        label: const Text('+ 지그 등록'),
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
  final Widget Function(String slotLabel, String floorLabel, VoidCallback onBack)
  detailsBuilder;

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
    // shelf_empty.png 위에 5층 버튼 수직 배치
    return LayoutBuilder(
      key: const ValueKey('floors'),
      builder: (context, c) {
        final pad = overlayPadding.resolve(Directionality.of(context));
        final W = c.maxWidth, H = c.maxHeight;
        final innerW = (W - pad.horizontal).clamp(0.0, double.infinity);
        final innerH = (H - pad.vertical).clamp(0.0, double.infinity);

        // 총 4개의 gap 반영 후 스트립 높이
        final totalGap = floorBtnGap * 4.0;
        final stripH = (innerH - totalGap) / 5.6;

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
              + floorButtonsYOffsetPx
              + i * (stripH + floorBtnGap)
              + inStripOffset;

          children.add(
            Positioned(
              left: left,
              top: top,
              width: btnW,
              height: 58,
              child: Material(
                // 복도(층) 버튼은 더 뚜렷하게 보이도록 alpha를 높임
                color: _colorForUtil(used: used, max: maxCapacity, alpha: 0.5),
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

/// 상세 패널(층 선택 후): 지그 리스트 + 하단 '돌아가기' 버튼
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
