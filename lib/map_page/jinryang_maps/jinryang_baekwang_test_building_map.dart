// lib/map_page/jinryang_maps/jinryang_baekwang_test_building_map.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../widgets/jig_item_data.dart';
import '../../widgets/jig_item.dart';
import '../../widgets/jig_form_bottom_sheet.dart';
import '../../data/jigs_store.dart'; // ✅ 전역 스토어

Color _colorForUtil({required int used, required int max, double alpha = 0.35}) {
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

/// 배광시험동 2층 – R1~R24 / L1~L20 (각 슬롯 1~4층)
class JinryangBaekwangTestBuildingMap extends StatefulWidget {
  final VoidCallback onBack;

  /// (선택) 외부 주입; 기본은 JigsStore.notifier 사용
  final ValueListenable<List<JigItemData>>? jigsListenable;

  /// 최초 진입 스냅샷(선택)
  final List<JigItemData> allItems;

  /// 등록 시 상위로 전달(선택)
  final void Function(JigItemData newItem)? onCreateJig;

  /// 층 버튼 색상 상한(층 용량)
  final int maxCapacityPerFloor;

  /// (옵션) 지그 1개의 가중치 계산. 미제공 시 size -> 1/3/5
  final int Function(JigItemData item)? weightOfItem;

  /// 🔧 층 버튼/레이아웃 커스터마이즈
  final double floorBtnWidthFrac;
  final double floorBtnHeightFracOfFifth; // 균등 배치일 때만 사용
  final double floorBtnGap;               // 균등 배치일 때만 사용
  final double floorBtnRadius;
  final EdgeInsets overlayPadding;
  final double floorButtonsYOffsetPx;

  /// 🔧 선반 사진 기준 배치 옵션
  final bool useImageAnchors;                  // true면 사진 기준 앵커 사용
  final List<double> floorCenterFractions;     // 위→아래(4층→1층) 중앙 y비율(0~1)
  final double? floorBtnHeightPx;              // 앵커 모드 버튼 높이(px)
  final bool debugAnchorGuides;                // 앵커 가이드 라인

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
    this.floorBtnGap = 2,                 // ✅ 0.5배(4→2)
    this.floorBtnRadius = 10,
    this.overlayPadding = const EdgeInsets.all(8),
    this.floorButtonsYOffsetPx = 5,       // ✅ 전체 5px 하향
    this.useImageAnchors = true,          // ✅ 기본: 사진 기준
    this.floorCenterFractions = const [   // ✅ 4층→1층 중앙 y비율
      0.250, 0.440, 0.610, 0.790
    ],
    this.floorBtnHeightPx = 56,           // ✅ 기본 버튼 높이(px)
    this.debugAnchorGuides = false,
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
  String? _lastFloor;  // 1층~4층

  // ===== 전역/외부 주입 리스너 =====
  late ValueListenable<List<JigItemData>> _activeListenable;
  List<JigItemData> get _items => _activeListenable.value;

  @override
  void initState() {
    super.initState();
    _activeListenable = widget.jigsListenable ?? JigsStore.notifier;
    _activeListenable.addListener(_onItemsChanged);

    if (JigsStore.items.isEmpty && widget.allItems.isNotEmpty) {
      JigsStore.setInitial(widget.allItems);
    }
  }

  @override
  void didUpdateWidget(covariant JinryangBaekwangTestBuildingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.jigsListenable ?? JigsStore.notifier;
    if (!identical(next, _activeListenable)) {
      _activeListenable.removeListener(_onItemsChanged);
      _activeListenable = next;
      _activeListenable.addListener(_onItemsChanged);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _activeListenable.removeListener(_onItemsChanged);
    super.dispose();
  }

  void _onItemsChanged() {
    if (mounted) setState(() {}); // 포화도/리스트 갱신
  }

  // ===== Util =====
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
    return _items.where((it) {
      if (_parent(it.location) != '배광시험동 2층') return false;
      return _slot(it.location) == slot && _floor(it.location) == floor;
    }).toList();
  }

  int _usedFor(String slot, String floor) =>
      _itemsFor(slot, floor).fold<int>(0, (s, it) => s + _weight(it));

  int _usedTotalForSlot(String slot) {
    const floors = ['1층', '2층', '3층', '4층']; // ✅ 4층만 집계
    var sum = 0;
    for (final f in floors) {
      sum += _usedFor(slot, f);
    }
    return sum;
  }

  Color _slotColor(String slot) {
    final used = _usedTotalForSlot(slot);
    final max = widget.maxCapacityPerFloor * 4; // ✅ 4층 기준
    return _colorForUtil(used: used, max: max, alpha: 0.8);
  }

  // ---------- [중요] 전역+외부 동시 갱신 유틸 ----------
  void _addEverywhere(JigItemData newJig) {
    final store = JigsStore.notifier;
    store.value = [newJig, ...store.value];
    if (_activeListenable is ValueNotifier<List<JigItemData>> &&
        !identical(_activeListenable, store)) {
      final vn = _activeListenable as ValueNotifier<List<JigItemData>>;
      vn.value = [newJig, ...vn.value];
    }
  }

  void _replaceEverywhere(JigItemData oldItem, JigItemData updated) {
    void replaceIn(ValueNotifier<List<JigItemData>> vn) {
      final list = List<JigItemData>.from(vn.value);
      int i = list.indexOf(oldItem);
      if (i == -1) {
        i = list.indexWhere((e) =>
        e.title == oldItem.title &&
            e.location == oldItem.location &&
            e.registrant == oldItem.registrant);
      }
      if (i != -1) {
        final keep = list[i];
        list[i] = updated.copyWith(likes: keep.likes, isLiked: keep.isLiked);
        vn.value = list;
      }
    }

    final store = JigsStore.notifier;
    replaceIn(store);
    if (_activeListenable is ValueNotifier<List<JigItemData>> &&
        !identical(_activeListenable, store)) {
      replaceIn(_activeListenable as ValueNotifier<List<JigItemData>>);
    }
  }

  void _openEdit(BuildContext context, JigItemData original) {
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
          _replaceEverywhere(original, edited);
          Navigator.pop(context);
        },
      ),
    );
  }
  // -------------------------------------------------------

  // ===== 등록 폼 열기 =====
  void _openAddJig({String? slot, String? floor}) {
    // ✅ 1~4층만 허용
    const allowedFloors = ['1층', '2층', '3층', '4층'];
    final safeFloor =
    (floor != null && allowedFloors.contains(floor)) ? floor : null;

    String loc = '배광시험동 2층';
    if (slot != null && slot.isNotEmpty) loc += ' / $slot';
    if (safeFloor != null && safeFloor.isNotEmpty) loc += ' / $safeFloor';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => JigFormBottomSheet(
        initialLocation: loc,
        onSubmit: (newJig) {
          _addEverywhere(newJig);           // ✅ 전역 + 이 화면 동시 반영
          widget.onCreateJig?.call(newJig); // (선택) 외부 알림
        },
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
            padding:
            EdgeInsets.only(bottom: i == labels.length - 1 ? 0 : _kGapV),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: capColor,
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
                _lastSlot = label;
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
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 5),
                  color: Colors.green.shade800,
                ),
              ),
            ),
            Positioned(
              left: corridorLeft,
              top: 0,
              width: corridorWidth,
              height: rowHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                      child: Container(color: Colors.green.shade800)),
                  Positioned(
                      left: yellowEdgeInset,
                      top: 0,
                      bottom: 0,
                      width: yellowLineWidth,
                      child: Container(color: Colors.yellowAccent)),
                  Positioned(
                      right: yellowEdgeInset,
                      top: 0,
                      bottom: 0,
                      width: yellowLineWidth,
                      child: Container(color: Colors.yellowAccent)),
                ],
              ),
            ),
            Positioned(
                left: 0, top: 0, child: _buildShelfColumn(rightLabels, context)),
            Positioned(
                right: 0, top: 0, child: _buildShelfColumn(leftLabels, context)),
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
                      child: Text('$slot 슬롯',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis)),
                  if (selectedFloor != null)
                    Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(selectedFloor!,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700))),
                ],
              ),
              content: SizedBox(
                width: 720,
                height: 520,
                child: BaekwangShelfViewer4Floors(
                  slotLabel: slot,
                  maxCapacity: widget.maxCapacityPerFloor,
                  selectedFloor: selectedFloor,
                  onSelectFloor: (floor) {
                    setSB(() => selectedFloor = floor);
                    _lastSlot = slot;
                    _lastFloor = floor;
                  },
                  onBackToFloors: () => setSB(() => selectedFloor = null),
                  capacityForFloor: (floorLabel) => _usedFor(slot, floorLabel),
                  detailsBuilder: (slotLabel, floorLabel, onBack) {
                    final items = _itemsFor(slotLabel, floorLabel);
                    return _BaekJigDetailPanel(
                      child: items.isEmpty
                          ? const Center(
                          child: Text('등록된 지그가 없습니다.',
                              style: TextStyle(color: Colors.grey)))
                          : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
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
                                  icon: const Icon(Icons.edit,
                                      color: Colors.black),
                                  onPressed: () => _openEdit(context, it),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      onBack: onBack,
                    );
                  },
                  // 전달 파라미터
                  floorBtnWidthFrac: widget.floorBtnWidthFrac,
                  floorBtnHeightFracOfFifth: widget.floorBtnHeightFracOfFifth,
                  floorBtnGap: widget.floorBtnGap,
                  floorBtnRadius: widget.floorBtnRadius,
                  overlayPadding: widget.overlayPadding,
                  floorButtonsYOffsetPx: widget.floorButtonsYOffsetPx,
                  // 앵커 모드
                  useImageAnchors: widget.useImageAnchors,
                  floorCenterFractions: widget.floorCenterFractions,
                  floorBtnHeightPx: widget.floorBtnHeightPx,
                  debugAnchorGuides: widget.debugAnchorGuides,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 4, 8),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(dctx);
                      _openAddJig(slot: slot, floor: selectedFloor);
                    },
                    child: const Text('+ 지그 등록'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 16, 8),
                  child: TextButton(
                      onPressed: () => Navigator.pop(dctx),
                      child: const Text('돌아가기')),
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
    final leftLabelsAll = List.generate(20, (i) => 'L${i + 1}');
    final rightLabelsAll = List.generate(24, (i) => 'R${i + 1}');
    final rightTop = rightLabelsAll.sublist(0, 12);
    final rightBottom = rightLabelsAll.sublist(12);
    final leftTop = leftLabelsAll.sublist(0, 10);
    final leftBottom = leftLabelsAll.sublist(10);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Center(
                child: Container(
                  width: _rowWidth + 120,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF2DEBC),
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      const Column(children: [
                        Text('IN',
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Icon(Icons.arrow_downward,
                            size: 32, color: Colors.blue),
                        SizedBox(height: 20),
                      ]),
                      _buildShelfRow(
                          rightLabels: rightTop,
                          leftLabels: leftTop,
                          context: context),
                      const SizedBox(height: 50),
                      _buildShelfRow(
                          rightLabels: rightBottom,
                          leftLabels: leftBottom,
                          context: context),
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
                style:
                IconButton.styleFrom(padding: const EdgeInsets.all(10)),
                tooltip: '뒤로',
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddJig(slot: _lastSlot, floor: _lastFloor),
        label: const Text('+ 지그 등록'),
      ),
    );
  }
}

/// 배광 슬롯 뷰어(4층)
class BaekwangShelfViewer4Floors extends StatelessWidget {
  final String slotLabel;
  final int maxCapacity;
  final String? selectedFloor;
  final ValueChanged<String> onSelectFloor;
  final VoidCallback onBackToFloors;
  final int Function(String floorLabel) capacityForFloor;
  final Widget Function(
      String slotLabel, String floorLabel, VoidCallback onBack) detailsBuilder;

  // 공통 옵션
  final double floorBtnWidthFrac,
      floorBtnHeightFracOfFifth,
      floorBtnGap,
      floorBtnRadius;
  final EdgeInsets overlayPadding;
  final double floorButtonsYOffsetPx;

  // 앵커 모드
  final bool useImageAnchors;
  final List<double> floorCenterFractions; // 위→아래(4층→1층)
  final double? floorBtnHeightPx;
  final bool debugAnchorGuides;

  const BaekwangShelfViewer4Floors({
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
    this.floorBtnGap = 2,                 // ✅ 기본 2px
    this.floorBtnRadius = 10,
    this.overlayPadding = const EdgeInsets.all(8),
    this.floorButtonsYOffsetPx = 5,       // ✅ 기본 5px
    this.useImageAnchors = true,
    this.floorCenterFractions = const [0.135, 0.355, 0.595, 0.835],
    this.floorBtnHeightPx,
    this.debugAnchorGuides = false,
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
    return LayoutBuilder(
      key: const ValueKey('floors'),
      builder: (context, c) {
        final pad = overlayPadding.resolve(Directionality.of(context));
        final W = c.maxWidth, H = c.maxHeight;
        final innerW = (W - pad.horizontal).clamp(0.0, double.infinity);
        final innerH = (H - pad.vertical).clamp(0.0, double.infinity);

        const floorsCount = 4; // ✅ 4층 고정
        final btnW = innerW * floorBtnWidthFrac;
        final left = pad.left + (innerW - btnW) / 2;

        // ----- 모드 1: 선반 사진 기준(앵커) -----
        if (useImageAnchors && floorCenterFractions.length == floorsCount) {
          final double btnH = (floorBtnHeightPx ?? 56).clamp(24.0, innerH);

          final children = <Widget>[
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/shelf_empty.png', fit: BoxFit.fill),
              ),
            ),
          ];

          for (int i = 0; i < floorsCount; i++) {
            final frac = floorCenterFractions[i].clamp(0.0, 1.0);
            final floorLabel = '${floorsCount - i}층';
            final used = maxCapacity == 0 ? 0 : capacityForFloor(floorLabel);

            final centerY = pad.top + floorButtonsYOffsetPx + innerH * frac;
            final top =
            (centerY - btnH / 2).clamp(pad.top, pad.top + innerH - btnH);

            children.add(Positioned(
              left: left,
              top: top,
              width: btnW,
              height: btnH,
              child: Material(
                color: _colorForUtil(used: used, max: maxCapacity, alpha: 0.5),
                borderRadius: BorderRadius.circular(floorBtnRadius),
                child: InkWell(
                  borderRadius: BorderRadius.circular(floorBtnRadius),
                  onTap: () => onSelectFloor(floorLabel),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$floorLabel  (사용:$used/$maxCapacity)',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
            ));

            if (debugAnchorGuides) {
              children.add(Positioned(
                left: pad.left,
                right: pad.right,
                top: centerY - 0.5,
                height: 1,
                child: Container(color: Colors.purple.withOpacity(0.9)),
              ));
            }
          }

          return Stack(children: children);
        }

        // ----- 모드 2: 균등 배치(실제 보이는 gap = floorBtnGap) -----
        final totalGap = floorBtnGap * (floorsCount - 1);
        final perFloorH = (innerH - totalGap) / floorsCount;
        final desiredBtnH = 58.0 * floorBtnHeightFracOfFifth;
        final btnH2 = desiredBtnH.clamp(24.0, perFloorH);
        final centerOffset = (perFloorH - btnH2) / 2;

        final children = <Widget>[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/shelf_empty.png', fit: BoxFit.fill),
            ),
          ),
        ];

        for (int i = 0; i < floorsCount; i++) {
          final floorLabel = '${floorsCount - i}층';
          final used = maxCapacity == 0 ? 0 : capacityForFloor(floorLabel);
          final top = pad.top +
              floorButtonsYOffsetPx +
              i * (btnH2 + floorBtnGap) +
              centerOffset;

          children.add(Positioned(
            left: left,
            top: top,
            width: btnW,
            height: btnH2,
            child: Material(
              color: _colorForUtil(used: used, max: maxCapacity, alpha: 0.5),
              borderRadius: BorderRadius.circular(floorBtnRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(floorBtnRadius),
                onTap: () => onSelectFloor(floorLabel),
                child: Center(
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$floorLabel  (사용:$used/$maxCapacity)',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
          ));
        }

        return Stack(children: children);
      },
    );
  }
}

class _BaekJigDetailPanel extends StatelessWidget {
  final Widget child;
  final VoidCallback onBack;
  const _BaekJigDetailPanel({required this.child, required this.onBack});
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
            child:
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: onBack, child: const Text('돌아가기')),
            ]),
          ),
        ],
      ),
    );
  }
}
