// lib/map_page/jinryang_maps/jinryang_b_dong_map.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ValueListenable
import '../../widgets/jig_item.dart';
import '../../widgets/jig_item_data.dart';
import '../../widgets/jig_form_bottom_sheet.dart';
import '../../data/jigs_store.dart'; // ✅ 전역 스토어 연동

Color colorForUtil({required int used, required int max}) {
  final _max = (max <= 0) ? 1 : max;
  final u = used.clamp(0, _max) / _max;
  const a = 0.35;
  if (u <= 0) return Colors.green.withOpacity(a);
  if (u >= 1) return Colors.red.withOpacity(a);
  const mid = 0.6;
  final base = (u < mid)
      ? Color.lerp(Colors.green, Colors.yellow, u / mid)!
      : Color.lerp(Colors.yellow, Colors.red, (u - mid) / (1 - mid))!;
  return base.withOpacity(a);
}

// [신규] 선반 버튼용 구간형 색상: <30% 초록 / 30~90% 노랑 / ≥90% 빨강
Color colorForUtilBand({required int used, required int maxTotal}) {
  final _max = (maxTotal <= 0) ? 1 : maxTotal;
  final u = used.clamp(0, _max) / _max;
  const a = 0.35;
  if (u < 0.30) return Colors.green.withOpacity(a);
  if (u < 0.90) return Colors.yellow.withOpacity(a);
  return Colors.red.withOpacity(a);
}

class JinryangBDongMap extends StatefulWidget {
  final VoidCallback onBack;

  /// 외부에서 별도 ValueListenable 을 주입하고 싶으면 사용(선택).
  /// 기본은 JigsStore.notifier 를 내부에서 사용한다.
  final ValueListenable<List<JigItemData>>? jigsListenable;

  /// 최초 진입 스냅샷(선택) – 스토어가 비어있을 때 한 번만 주입
  final List<JigItemData> allItems;

  // 레거시 capacity
  final int l1Floor1Capacity, l1Floor2Capacity, l1Floor3Capacity, l1Floor4Capacity;
  final int r1Floor1Capacity, r1Floor2Capacity, r1Floor3Capacity, r1Floor4Capacity;
  final int c1Floor1Capacity, c1Floor2Capacity, c1Floor3Capacity, c1Floor4Capacity;
  final int f1Capacity, f2Capacity, f3Capacity, f4Capacity;

  // 색상 상한
  final int maxCapacityShelves;
  final int maxCapacityF;

  // 버튼 스케일
  final double shelfButtonWidthFactor;
  final double shelfButtonHeightFactor;
  final double fButtonWidthFactor;
  final double fButtonHeightFactor;
  final Map<String, double>? shelfButtonWidthOverrides;
  final Map<String, double>? shelfButtonHeightOverrides;
  final Map<String, double>? fButtonWidthOverrides;
  final Map<String, double>? fButtonHeightOverrides;

  // 오버레이 파라미터
  final double overlayFloorBtnWidthFrac;
  final double overlayFloorBtnHeightFracOfQuarter;
  final double overlayFloorBtnCenterXFrac;
  final double overlayFloorBtnQuarterCenterYFrac;
  final Offset overlayFloorBtnGlobalOffsetFrac;
  final Map<String, double>? overlayFloorBtnWidthOverrideFrac;
  final Map<String, double>? overlayFloorBtnHeightOverrideFrac;
  final Map<String, Offset>? overlayFloorBtnOffsetOverrideFrac;
  final double overlayFloorBtnStackScaleY;

  final Map<String, double>? overlayFloorBtnWidthFracByShelf;
  final Map<String, double>? overlayFloorBtnHeightFracOfQuarterByShelf;
  final Map<String, double>? overlayFloorBtnStackScaleYByShelf;
  final Map<String, double>? overlayFloorBtnCenterXFracByShelf;
  final Map<String, double>? overlayFloorBtnQuarterCenterYFracByShelf;
  final Map<String, Offset>? overlayFloorBtnGlobalOffsetFracByShelf;
  final Map<String, Map<String, double>>? overlayFloorBtnHeightOverrideFracByShelf;
  final Map<String, Map<String, Offset>>? overlayFloorBtnOffsetOverrideFracByShelf;

  // 초기 포커스(선택)
  final String? initialShelf;
  final String? initialFloor;
  final String? initialFZone;

  /// 소/중/대 → 1/3/5 매핑(선택)
  final int Function(JigItemData item)? weightOfItem;

  /// 맵에서 지그 추가 시 상위 리스트 반영(선택) – (참고) 내부에서 전역+외부 양쪽 처리하므로 필수 아님
  final void Function(JigItemData newItem)? onCreateJig;

  /// 최초 진입 시 자동 팝업 열기 여부
  final bool autoOpenOnInit;

  const JinryangBDongMap({
    super.key,
    required this.onBack,
    this.jigsListenable,
    this.allItems = const [],
    this.l1Floor1Capacity = 0, this.l1Floor2Capacity = 0, this.l1Floor3Capacity = 0, this.l1Floor4Capacity = 0,
    this.r1Floor1Capacity = 0, this.r1Floor2Capacity = 0, this.r1Floor3Capacity = 0, this.r1Floor4Capacity = 0,
    this.c1Floor1Capacity = 0, this.c1Floor2Capacity = 0, this.c1Floor3Capacity = 0, this.c1Floor4Capacity = 0,
    this.f1Capacity = 0, this.f2Capacity = 0, this.f3Capacity = 0, this.f4Capacity = 0,
    this.maxCapacityShelves = 10,
    this.maxCapacityF = 10,
    this.shelfButtonWidthFactor = 1.2,
    this.shelfButtonHeightFactor = 0.9,
    this.fButtonWidthFactor = 0.9,
    this.fButtonHeightFactor = 0.95,
    this.shelfButtonWidthOverrides,
    this.shelfButtonHeightOverrides,
    this.fButtonWidthOverrides,
    this.fButtonHeightOverrides,
    this.overlayFloorBtnWidthFrac = 0.78,
    this.overlayFloorBtnHeightFracOfQuarter = 0.4,
    this.overlayFloorBtnCenterXFrac = 0.5,
    this.overlayFloorBtnQuarterCenterYFrac = -0.2,
    this.overlayFloorBtnGlobalOffsetFrac = Offset.zero,
    this.overlayFloorBtnWidthOverrideFrac,
    this.overlayFloorBtnHeightOverrideFrac,
    this.overlayFloorBtnOffsetOverrideFrac,
    this.overlayFloorBtnStackScaleY = 0.6,
    this.overlayFloorBtnWidthFracByShelf,
    this.overlayFloorBtnHeightFracOfQuarterByShelf,
    this.overlayFloorBtnStackScaleYByShelf,
    this.overlayFloorBtnCenterXFracByShelf,
    this.overlayFloorBtnQuarterCenterYFracByShelf,
    this.overlayFloorBtnGlobalOffsetFracByShelf = const {
      'L1': Offset(0.0, 0.08),
      'R1': Offset(0.0, 0.08),
    },
    this.overlayFloorBtnHeightOverrideFracByShelf = const {
      'L1': {'1층': 0.72},
      'R1': {'1층': 0.72},
      'C1': {'4층': 0.5, '3층': 0.5, '2층': 0.5, '1층': 0.85},
    },
    this.overlayFloorBtnOffsetOverrideFracByShelf = const {
      'L1': {'4층': Offset(0, 0.04), '3층': Offset(0, 0.012), '2층': Offset(0, -0.014)},
      'R1': {'4층': Offset(0, 0.035), '3층': Offset(0, 0.010), '2층': Offset(0, -0.014)},
      'C1': {'4층': Offset(0, 0.00), '3층': Offset(0, 0.00), '2층': Offset(0, -0.00), '1층': Offset(0, 0.04)},
    },
    this.initialShelf,
    this.initialFloor,
    this.initialFZone,
    this.weightOfItem,
    this.onCreateJig,
    this.autoOpenOnInit = false,
  });

  @override
  State<JinryangBDongMap> createState() => _JinryangBDongMapState();
}

class _JinryangBDongMapState extends State<JinryangBDongMap> {
  bool _dialogOpen = false;
  bool _didAutoOpen = false;
  double? _mapAspect;
  ImageStream? _mapStream;
  ImageStreamListener? _mapListener;

  // 전역 또는 외부 주입 리스너(단일 통로)
  late ValueListenable<List<JigItemData>> _activeListenable;

  // 마지막으로 본 위치 → FAB 프리필
  String? _lastSlot;   // L1/C1/R1/F1~F4
  String? _lastFloor;  // 1층~4층

  static const fButtons = <_AreaSpec>[
    _AreaSpec('F1', 0.22, 0.27, 0.27, 0.33),
    _AreaSpec('F2', 0.48, 0.27, 0.27, 0.33),
    _AreaSpec('F3', 0.22, 0.60, 0.27, 0.33),
    _AreaSpec('F4', 0.48, 0.60, 0.27, 0.33),
  ];

  List<JigItemData> get _items => _activeListenable.value;

  @override
  void initState() {
    super.initState();
    _activeListenable = widget.jigsListenable ?? JigsStore.notifier;
    _activeListenable.addListener(_onItemsChanged);

    // 스토어가 비어있고 최초 스냅샷이 있으면 1회 주입
    if (JigsStore.items.isEmpty && widget.allItems.isNotEmpty) {
      JigsStore.setInitial(widget.allItems);
    }
  }

  @override
  void didUpdateWidget(covariant JinryangBDongMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.jigsListenable ?? JigsStore.notifier;
    if (!identical(next, _activeListenable)) {
      _activeListenable.removeListener(_onItemsChanged);
      _activeListenable = next;
      _activeListenable.addListener(_onItemsChanged);
      setState(() {}); // 포화도 재계산
    }
  }

  @override
  void dispose() {
    _activeListenable.removeListener(_onItemsChanged);
    if (_mapListener != null && _mapStream != null) {
      _mapStream!.removeListener(_mapListener!);
    }
    super.dispose();
  }

  void _onItemsChanged() {
    if (mounted) setState(() {}); // 최신 리스트로 리빌드
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
  // ---------------------------------------------

  // -------- 위치 유틸 --------
  String _norm(String s) => s.replaceAll(RegExp(r'\s+'), '').trim();
  List<String> _parts(String loc) => loc.split('/').map((e) => e.trim()).toList();
  String? _shelfOf(String loc) {
    final p = _parts(loc); if (p.length < 2) return null; return p[1];
  }
  String? _floorOf(String loc) {
    final p = _parts(loc); if (p.length < 3) return null;
    final m = RegExp(r'(\d)').firstMatch(p[2]); return (m == null) ? null : '${m.group(1)}층';
  }

  List<JigItemData> _itemsForShelfFloor(String shelf, String floor) {
    final ns = _norm(shelf), nf = _norm(floor);
    return _items.where((it) {
      final loc = it.location.trim();
      if (!loc.startsWith('진량공장 B동')) return false;
      final s = _shelfOf(loc), f = _floorOf(loc);
      return _norm(s ?? '') == ns && _norm(f ?? '') == nf;
    }).toList();
  }

  List<JigItemData> _itemsForFZone(String fzone) {
    final nf = _norm(fzone).toUpperCase();
    return _items.where((it) {
      final loc = it.location.trim();
      if (!loc.startsWith('진량공장 B동')) return false;
      final p = _parts(loc);
      if (p.length < 2) return false;
      return _norm(p[1]).toUpperCase() == nf;
    }).toList();
  }

  int _weightOf(JigItemData it) {
    if (widget.weightOfItem != null) return widget.weightOfItem!(it);
    final size = (it.size ?? '').replaceAll(' ', '');
    switch (size) {
      case '대형':
      case '대': return 5;
      case '중형':
      case '중': return 3;
      default: return 1;
    }
  }

  int _usedWeightForShelfFloor(String shelf, String floor) =>
      _itemsForShelfFloor(shelf, floor).fold(0, (sum, it) => sum + _weightOf(it));
  int _usedWeightForFZone(String fzone) =>
      _itemsForFZone(fzone).fold(0, (sum, it) => sum + _weightOf(it));
  int _usedWeightForShelf(String shelf) =>
      _usedWeightForShelfFloor(shelf, '1층') +
          _usedWeightForShelfFloor(shelf, '2층') +
          _usedWeightForShelfFloor(shelf, '3층') +
          _usedWeightForShelfFloor(shelf, '4층');

  String? _shelfImage(String shelf) {
    switch (shelf) {
      case 'L1': return 'assets/shelf_L1.png';
      case 'R1': return 'assets/shelf_R1.png';
      case 'C1': return 'assets/shelf_C1.png';
      default: return null;
    }
  }

  // 맵에서 ‘지그 등록’ 폼 열기 (현재 포커스 프리필)
  void _openAddJig({String? slot, String? floor}) {
    String loc = '진량공장 B동';
    if (slot != null && slot.isNotEmpty) loc += ' / $slot';
    if (floor != null && floor.isNotEmpty && !(slot ?? '').startsWith('F')) {
      loc += ' / $floor';
    }

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
          widget.onCreateJig?.call(newJig); // (선택) 외부 알림 용도
        },
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final p in const [
      'assets/bdong_map.png','assets/shelf_L1.png','assets/shelf_R1.png','assets/shelf_C1.png',
    ]) {
      precacheImage(AssetImage(p), context);
    }
    _resolveMapAspect();

    if (!_didAutoOpen && widget.autoOpenOnInit) {
      _didAutoOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (widget.initialFZone != null) {
          await _onFloorTap(widget.initialFZone!);
        } else if (widget.initialShelf != null && widget.initialFloor != null) {
          final label = widget.initialShelf!;
          final img = _shelfImage(label);
          if (img != null) {
            await _openShelfWithInitial(label, img, widget.initialFloor!);
          }
        }
      });
    }
  }

  void _resolveMapAspect() {
    if (_mapListener != null && _mapStream != null) {
      _mapStream!.removeListener(_mapListener!);
      _mapStream = null; _mapListener = null;
    }
    final stream = const AssetImage('assets/bdong_map.png')
        .resolve(createLocalImageConfiguration(context));
    _mapStream = stream;
    _mapListener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() => _mapAspect = info.image.height == 0 ? null : info.image.width / info.image.height);
      stream.removeListener(_mapListener!);
      _mapStream = null; _mapListener = null;
    }, onError: (_, __) {
      if (!mounted) return; setState(() => _mapAspect = null);
      stream.removeListener(_mapListener!);
      _mapStream = null; _mapListener = null;
    });
    stream.addListener(_mapListener!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,   // ← 추가
      body: Stack(children: [
        LayoutBuilder(builder: (context, c) {
          final cw = c.maxWidth, ch = c.maxHeight;
          final ar = _mapAspect ?? (16 / 9);
          double dispW, dispH, offX = 0, offY = 0;
          if (cw / ch > ar) { dispH = ch; dispW = dispH * ar; offX = (cw - dispW) / 2; }
          else { dispW = cw; dispH = dispW / ar; offY = (ch - dispH) / 2; }

          Rect rectFromFrac(double l, double t, double w, double h) =>
              Rect.fromLTWH(offX + l * dispW, offY + t * dispH, w * dispW, h * dispH);

          Rect scaleRect(Rect r, {required double wf, required double hf}) {
            final cx = r.left + r.width / 2, cy = r.top + r.height / 2;
            final nw = r.width * wf, nh = r.height * hf;
            return Rect.fromLTWH(cx - nw / 2, cy - nh / 2, nw, nh);
          }

          Rect applyScale(Rect base, String label, {required bool isShelf}) {
            double wf = isShelf ? widget.shelfButtonWidthFactor : widget.fButtonWidthFactor;
            double hf = isShelf ? widget.shelfButtonHeightFactor : widget.fButtonHeightFactor;
            if (isShelf) {
              wf *= widget.shelfButtonWidthOverrides?[label] ?? 1.0;
              hf *= widget.shelfButtonHeightOverrides?[label] ?? 1.0;
            } else {
              wf *= widget.fButtonWidthOverrides?[label] ?? 1.0;
              hf *= widget.fButtonHeightOverrides?[label] ?? 1.0;
            }
            return scaleRect(base, wf: wf, hf: hf);
          }

          const shelves = <_ShelfSpec>[
            _ShelfSpec('L1', 0.08, 0.25, 0.13, 0.63, 'assets/shelf_L1.png'),
            _ShelfSpec('R1', 0.75, 0.25, 0.13, 0.63, 'assets/shelf_R1.png'),
            _ShelfSpec('C1', 0.31, 0.10, 0.37, 0.14, 'assets/shelf_C1.png'),
          ];

          return Stack(children: [
            Positioned(
              left: offX, top: offY, width: dispW, height: dispH,
              child: Image.asset(
                'assets/bdong_map.png',
                width: dispW, height: dispH,
                fit: BoxFit.fill, filterQuality: FilterQuality.low,
                cacheWidth: (dispW * MediaQuery.of(context).devicePixelRatio).round(),
              ),
            ),
            // 선반 버튼 = 4층 합산 포화도
            ...shelves.map((s) {
              final base = rectFromFrac(s.left, s.top, s.width, s.height);
              final rect = applyScale(base, s.label, isShelf: true);
              final usedShelf = _usedWeightForShelf(s.label);
              final maxTotal = widget.maxCapacityShelves * 4; // 4층 합산 상한
              final shelfColor = colorForUtilBand(used: usedShelf, maxTotal: maxTotal);
              return _ShelfButton(
                spec: s, rect: rect, onTap: () => _onShelfTap(s), backgroundColor: shelfColor,
              );
            }),
            // F 버튼
            ...fButtons.map((a) {
              final base = rectFromFrac(a.left, a.top, a.width, a.height);
              final rect = applyScale(base, a.label, isShelf: false);
              final used = _usedWeightForFZone(a.label);
              return _FloorSquareButton(
                label: a.label, rect: rect,
                color: colorForUtil(used: used, max: widget.maxCapacityF),
                onTap: () => _onFloorTap(a.label),
              );
            }),
          ]);
        }),
        Positioned(
          top: 12, left: 12,
          child: IconButton.filledTonal(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(padding: const EdgeInsets.all(10),backgroundColor: Colors.white),
            tooltip: '뒤로',
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddJig(slot: _lastSlot, floor: _lastFloor),
        label: const Text('+ 지그 등록', style: const TextStyle (color: Colors.black)),
        backgroundColor: Colors.white,
      ),
    );
  }

  Future<void> _openShelfWithInitial(String shelf, String imagePath, String initialFloor) async {
    if (_dialogOpen || !mounted) return;
    setState(() => _dialogOpen = true);
    try {
      final size = MediaQuery.of(context).size;
      final provider = ResizeImage(AssetImage(imagePath),
          width: (size.width * 0.5).clamp(320.0, 1600.0).toInt());
      await precacheImage(provider, context);
      await Future<void>.delayed(Duration.zero);
      await _showShelfDialog(context, shelf, imagePath, initialSelectedFloor: initialFloor);
    } finally {
      if (mounted) setState(() => _dialogOpen = false);
    }
  }

  Future<void> _onShelfTap(_ShelfSpec s) async {
    if (_dialogOpen || !mounted) return;
    setState(() => _dialogOpen = true);
    try {
      final size = MediaQuery.of(context).size;
      final provider = ResizeImage(AssetImage(s.imagePath),
          width: (size.width * s.width).clamp(320.0, 1600.0).toInt());
      await precacheImage(provider, context);
      await Future<void>.delayed(Duration.zero);
      await _showShelfDialog(context, s.label, s.imagePath);
    } finally {
      if (mounted) setState(() => _dialogOpen = false);
    }
  }

  Future<void> _onFloorTap(String label) async {
    if (_dialogOpen || !mounted) return;
    setState(() {
      _dialogOpen = true;
      _lastSlot = label;   // F1~F4
      _lastFloor = null;
    });
    try {
      final items = _itemsForFZone(label);
      await _showFZoneDialog(context, label, items);
    } finally {
      if (mounted) setState(() => _dialogOpen = false);
    }
  }

  Future<void> _showFZoneDialog(BuildContext context, String areaLabel, List<JigItemData> items) async {
    return showDialog<void>(
      context: context, barrierDismissible: true,
      builder: (dctx) => AlertDialog(
        backgroundColor: Colors.white,      // ← 추가
        surfaceTintColor: Colors.white,     // ← 추가 (Material3 틴트 제거)
        titlePadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        title: Text('$areaLabel Zone', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 560, height: 380,
          child: items.isEmpty
              ? const Center(child: Text('등록된 지그가 없습니다.', style: TextStyle(color: Colors.grey)))
              : _JigListPanel(items: items, onEdit: (it) => _openEdit(context, it)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
            child: TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              onPressed: () {
                Navigator.pop(dctx);
                _openAddJig(slot: areaLabel); // F존에는 층 없음
              },
              child: const Text('+ 지그 등록'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
            child: TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                onPressed: () => Navigator.pop(dctx), child: const Text('닫기')),
          ),
        ],
      ),
    );
  }

  Future<void> _showShelfDialog(BuildContext context, String label, String imagePath, {String? initialSelectedFloor}) async {
    return showDialog<void>(
      context: context, barrierDismissible: true,
      builder: (dialogCtx) {
        String? dialogZone;
        return StatefulBuilder(
          builder: (ctx, setSB) => AlertDialog(
            backgroundColor: Colors.white,      // ← 추가
            surfaceTintColor: Colors.white,     // ← 추가 (Material3 틴트 제거)
            titlePadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            title: Row(children: [
              Text('$label 선반', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              if (dialogZone != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(12)),
                  child: Text(dialogZone!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
            ]),
            content: Builder(builder: (context) {
              final screen = MediaQuery.of(context).size;
              final width = screen.width.clamp(320.0, 900.0).toDouble();
              final height = screen.height.clamp(320.0, 700.0).toDouble();
              final bgProvider = ResizeImage(AssetImage(imagePath), width: width.toInt());

              final u1 = _usedWeightForShelfFloor(label, '1층');
              final u2 = _usedWeightForShelfFloor(label, '2층');
              final u3 = _usedWeightForShelfFloor(label, '3층');
              final u4 = _usedWeightForShelfFloor(label, '4층');

              return SizedBox(
                width: width, height: height,
                child: ShelfOverlayViewer4Floors(
                  imagePath: imagePath,
                  shelfLabel: label,
                  onZoneTap: (z) { setSB(() => dialogZone = z); _lastSlot = label; _lastFloor = z; },
                  bgProviderOverride: bgProvider,
                  inlinePanel: true,
                  floor1Capacity: u1, floor2Capacity: u2, floor3Capacity: u3, floor4Capacity: u4,
                  btnWidthFrac: 0.78,
                  btnHeightFracOfQuarter: 0.4,
                  btnCenterXFrac: 0.5,
                  btnQuarterCenterYFrac: -0.2,
                  btnGlobalOffsetFrac: Offset.zero,
                  perFloorWidthFrac: null,
                  perFloorHeightFrac: const {'1층': 0.72},
                  perFloorOffsetFrac: const {'4층': Offset(0, 0.00), '3층': Offset(0, 0.00), '2층': Offset(0, -0.00), '1층': Offset(0, 0.04)},
                  btnStackScaleY: 0.6,
                  maxCapacity: widget.maxCapacityShelves,
                  initialSelectedFloor: initialSelectedFloor,
                  detailsBuilder: (shelf, floor) {
                    final items = _itemsForShelfFloor(shelf, floor);
                    return _JigDetailPanel(
                      shelf: shelf,
                      floor: floor,
                      showHeader: false,
                      child: items.isEmpty
                          ? const Center(child: Text('등록된 지그가 없습니다.', style: TextStyle(color: Colors.grey)))
                          : _JigListPanel(items: items, onEdit: (it) => _openEdit(context, it)),
                    );
                  },
                ),
              );
            }),
            actions: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.black),
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    _openAddJig(slot: label, floor: dialogZone);
                  },
                  child: const Text('+ 지그 등록'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
                child: TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.black),
                    onPressed: () => Navigator.pop(dialogCtx), child: const Text('닫기')),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------- 이하 UI 보조 위젯들 ----------
class _ShelfSpec {
  final String label; final double left, top, width, height; final String imagePath;
  const _ShelfSpec(this.label, this.left, this.top, this.width, this.height, this.imagePath);
}
class _AreaSpec {
  final String label; final double left, top, width, height;
  const _AreaSpec(this.label, this.left, this.top, this.width, this.height);
}
class _ShelfButton extends StatelessWidget {
  final _ShelfSpec spec; final Rect rect; final VoidCallback onTap; final Color backgroundColor;
  const _ShelfButton({required this.spec, required this.rect, required this.onTap, this.backgroundColor = Colors.transparent});
  @override Widget build(BuildContext context) {
    return Positioned(
      left: rect.left, top: rect.top, width: rect.width, height: rect.height,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(backgroundColor: backgroundColor, padding: EdgeInsets.zero, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
        child: Align(
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
            child: Text(spec.label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
class _FloorSquareButton extends StatelessWidget {
  final String label; final Rect rect; final Color color; final VoidCallback onTap;
  const _FloorSquareButton({required this.label, required this.rect, required this.color, required this.onTap});
  @override Widget build(BuildContext context) {
    return Positioned(
      left: rect.left, top: rect.top, width: rect.width, height: rect.height,
      child: Material(
        color: color, borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}

class ShelfOverlayViewer4Floors extends StatefulWidget {
  final String imagePath; final String shelfLabel; final void Function(String) onZoneTap; final bool inlinePanel;
  final int floor1Capacity, floor2Capacity, floor3Capacity, floor4Capacity;
  final ImageProvider? bgProviderOverride; final double btnWidthFrac; final double btnHeightFracOfQuarter;
  final double btnCenterXFrac; final double btnQuarterCenterYFrac; final Offset btnGlobalOffsetFrac;
  final Map<String, double>? perFloorWidthFrac; final Map<String, double>? perFloorHeightFrac; final Map<String, Offset>? perFloorOffsetFrac;
  final double btnStackScaleY; final int maxCapacity; final Widget Function(String shelfLabel, String floorLabel)? detailsBuilder;
  final String? initialSelectedFloor;

  const ShelfOverlayViewer4Floors({
    super.key,
    required this.imagePath,
    required this.shelfLabel,
    required this.onZoneTap,
    this.inlinePanel = true,
    this.floor1Capacity = 0, this.floor2Capacity = 0, this.floor3Capacity = 0, this.floor4Capacity = 0,
    this.bgProviderOverride,
    this.btnWidthFrac = 0.78,
    this.btnHeightFracOfQuarter = 0.42,
    this.btnCenterXFrac = 0.5,
    this.btnQuarterCenterYFrac = 0.5,
    this.btnGlobalOffsetFrac = Offset.zero,
    this.perFloorWidthFrac,
    this.perFloorHeightFrac,
    this.perFloorOffsetFrac,
    this.btnStackScaleY = 1.0,
    this.maxCapacity = 10,
    this.detailsBuilder,
    this.initialSelectedFloor,
  });

  @override
  State<ShelfOverlayViewer4Floors> createState() => _ShelfOverlayViewer4FloorsState();
}

class _ShelfOverlayViewer4FloorsState extends State<ShelfOverlayViewer4Floors> {
  String? _selectedZone;
  double? _imgAspect;
  ImageStream? _aspectStream;
  ImageStreamListener? _aspectListener;
  static const double _btnRadius = 12.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImageAspect();
    _selectedZone ??= widget.initialSelectedFloor;
  }

  @override
  void dispose() {
    if (_aspectListener != null && _aspectStream != null) {
      _aspectStream!.removeListener(_aspectListener!);
    }
    super.dispose();
  }

  void _resolveImageAspect() {
    if (_aspectListener != null && _aspectStream != null) {
      _aspectStream!.removeListener(_aspectListener!);
    }
    final effectiveProvider = widget.bgProviderOverride ?? AssetImage(widget.imagePath);
    final stream = effectiveProvider.resolve(createLocalImageConfiguration(context));
    _aspectStream = stream;
    _aspectListener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() => _imgAspect = info.image.height == 0 ? null : info.image.width / info.image.height);
      stream.removeListener(_aspectListener!);
      _aspectStream = null; _aspectListener = null;
    }, onError: (_, __) {
      if (!mounted) return;
      setState(() => _imgAspect = null);
      stream.removeListener(_aspectListener!);
      _aspectStream = null; _aspectListener = null;
    });
    stream.addListener(_aspectListener!);
  }

  @override
  Widget build(BuildContext context) {
    final showPanel = widget.inlinePanel && _selectedZone != null;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: showPanel
          ? (widget.detailsBuilder != null
          ? widget.detailsBuilder!(widget.shelfLabel, _selectedZone!)
          : _JigDetailPanel(shelf: widget.shelfLabel, floor: _selectedZone!, showHeader: false, child: const SizedBox()))
          : Stack(key: const ValueKey('floors'), children: [
        Positioned.fill(
          child: Image(
            image: widget.bgProviderOverride ?? ResizeImage(AssetImage(widget.imagePath), width: 1024),
            fit: BoxFit.contain, filterQuality: FilterQuality.low,
          ),
        ),
        Positioned.fill(
          child: LayoutBuilder(builder: (context, c) {
            final cw = c.maxWidth, ch = c.maxHeight;
            final ar = _imgAspect ?? (16 / 9);
            double dispW, dispH, offX = 0, offY = 0;
            if (cw / ch > ar) { dispH = ch; dispW = dispH * ar; offX = (cw - dispW) / 2; }
            else { dispW = cw; dispH = dispW / ar; offY = (ch - dispH) / 2; }

            Rect rectFor(int idx, String floorLabel) {
              final quarterH = dispH / 4;
              final wFrac = widget.perFloorWidthFrac?[floorLabel] ?? widget.btnWidthFrac;
              final hFrac = widget.perFloorHeightFrac?[floorLabel] ?? widget.btnHeightFracOfQuarter;
              final extra = widget.perFloorOffsetFrac?[floorLabel] ?? Offset.zero;

              final btnW = dispW * wFrac;
              final btnH = quarterH * hFrac;

              final baseNormY = (idx + widget.btnQuarterCenterYFrac) / 4.0;
              final scaledNormY = 0.5 + (baseNormY - 0.5) * widget.btnStackScaleY;

              final centerX = offX + dispW * (widget.btnCenterXFrac + widget.btnGlobalOffsetFrac.dx + extra.dx);
              final centerY = offY + dispH * (scaledNormY + widget.btnGlobalOffsetFrac.dy + extra.dy);

              return Rect.fromLTWH(centerX - btnW / 2, centerY - btnH / 2, btnW, btnH);
            }

            final floors = <_FloorInfo>[
              _FloorInfo('4층', widget.floor4Capacity),
              _FloorInfo('3층', widget.floor3Capacity),
              _FloorInfo('2층', widget.floor2Capacity),
              _FloorInfo('1층', widget.floor1Capacity),
            ];

            return Stack(
              children: List.generate(floors.length, (i) {
                final f = floors[i];
                return _ZoneButtonRect(
                  rect: rectFor(i, f.label),
                  label: f.label,
                  color: colorForUtil(used: f.capacity, max: widget.maxCapacity),
                  radius: _btnRadius,
                  onTap: () { setState(() => _selectedZone = f.label); widget.onZoneTap(f.label); },
                );
              }),
            );
          }),
        ),
      ]),
    );
  }
}

class _FloorInfo { final String label; final int capacity; const _FloorInfo(this.label, this.capacity); }
class _ZoneButtonRect extends StatelessWidget {
  final Rect rect; final String label; final Color color; final double radius; final VoidCallback onTap;
  const _ZoneButtonRect({required this.rect, required this.label, required this.color, required this.radius, required this.onTap});
  @override Widget build(BuildContext context) {
    return Positioned(
      left: rect.left, top: rect.top, width: rect.width, height: rect.height,
      child: Material(
        color: color, borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(radius),
          child: Center(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87))),
        ),
      ),
    );
  }
}

class _JigDetailPanel extends StatelessWidget {
  final String shelf; final String floor; final Widget child; final bool showHeader;
  const _JigDetailPanel({required this.shelf, required this.floor, required this.child, this.showHeader = true});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), color: Colors.white,
              child: Row(children: [
                Text('$shelf 선반', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Text(floor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          Expanded(child: ColoredBox(color: Colors.white, child: child)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: const BoxDecoration(color: Colors.white),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('돌아가기', style: TextStyle(color: Colors.black))),
            ]),
          ),
        ],
      ),
    );
  }
}

class _JigListPanel extends StatelessWidget {
  final List<JigItemData> items;
  final void Function(JigItemData item)? onEdit;
  const _JigListPanel({required this.items, this.onEdit});
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final it = items[i];
        return Stack(
          children: [
            JigItem(
              image: it.image,
              images: it.images,
              thumbnailIndex: it.thumbnailIndex,
              title: it.title,
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
            ),
            if (onEdit != null)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  tooltip: '수정',
                  icon: const Icon(Icons.edit, color: Colors.black),
                  onPressed: () => onEdit!(it),
                ),
              ),
          ],
        );
      },
    );
  }
}
