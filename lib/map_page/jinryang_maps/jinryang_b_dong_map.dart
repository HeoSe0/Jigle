// lib/map_page/jinryang_maps/jinryang_b_dong_map.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ValueListenable
import '../../widgets/jig_item.dart';
import '../../widgets/jig_item_data.dart';
import '../../widgets/jig_form_bottom_sheet.dart';

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

class JinryangBDongMap extends StatefulWidget {
  final VoidCallback onBack;

  /// 실시간 리스트(선택). 없으면 [allItems] 스냅샷 사용
  final ValueListenable<List<JigItemData>>? jigsListenable;

  /// 최초 진입 스냅샷(선택)
  final List<JigItemData> allItems;

  // 레거시 capacity (입력은 받되 표시엔 미사용)
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

  /// 맵에서 지그 추가 시 상위 리스트 반영(선택)
  final void Function(JigItemData newItem)? onCreateJig;

  /// 최초 진입 시 자동 팝업 열기 여부 (기본값 false)
  final bool autoOpenOnInit;

  const JinryangBDongMap({
    super.key,
    required this.onBack,
    this.jigsListenable,
    this.allItems = const [],

    // 레거시 입력(유지)
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

    this.autoOpenOnInit = false, // 자동 팝업 기본 비활성화
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

  // 마지막으로 본 위치 → FAB 프리필
  String? _lastSlot;   // L1/C1/R1/F1~F4
  String? _lastFloor;  // 1층~4층

  static const fButtons = <_AreaSpec>[
    _AreaSpec('F1', 0.22, 0.27, 0.27, 0.33),
    _AreaSpec('F2', 0.48, 0.27, 0.27, 0.33),
    _AreaSpec('F3', 0.22, 0.60, 0.27, 0.33),
    _AreaSpec('F4', 0.48, 0.60, 0.27, 0.33),
  ];

  // 항상 최신 리스트 사용
  List<JigItemData> get _items => widget.jigsListenable?.value ?? widget.allItems;

  @override
  void initState() {
    super.initState();
    widget.jigsListenable?.addListener(_onItemsChanged);
  }

  void _onItemsChanged() {
    if (mounted) setState(() {}); // 포화도 재계산
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final p in const [
      'assets/bdong_map.png',
      'assets/shelf_L1.png',
      'assets/shelf_R1.png',
      'assets/shelf_C1.png',
    ]) {
      precacheImage(AssetImage(p), context);
    }
    _resolveMapAspect();

    // ✅ 자동 오픈은 플래그가 true일 때만
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

  @override
  void didUpdateWidget(covariant JinryangBDongMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jigsListenable != widget.jigsListenable) {
      oldWidget.jigsListenable?.removeListener(_onItemsChanged);
      widget.jigsListenable?.addListener(_onItemsChanged);
    }
    if (oldWidget.allItems != widget.allItems ||
        oldWidget.maxCapacityF != widget.maxCapacityF ||
        oldWidget.maxCapacityShelves != widget.maxCapacityShelves ||
        oldWidget.weightOfItem != widget.weightOfItem) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.jigsListenable?.removeListener(_onItemsChanged);
    if (_mapListener != null && _mapStream != null) {
      _mapStream!.removeListener(_mapListener!);
    }
    super.dispose();
  }

  void _resolveMapAspect() {
    if (_mapListener != null && _mapStream != null) {
      _mapStream!.removeListener(_mapListener!);
      _mapStream = null;
      _mapListener = null;
    }
    final stream = const AssetImage('assets/bdong_map.png')
        .resolve(createLocalImageConfiguration(context));
    _mapStream = stream;
    _mapListener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() => _mapAspect = info.image.height == 0 ? null : info.image.width / info.image.height);
      stream.removeListener(_mapListener!);
      _mapStream = null;
      _mapListener = null;
    }, onError: (_, __) {
      if (!mounted) return;
      setState(() => _mapAspect = null);
      stream.removeListener(_mapListener!);
      _mapStream = null;
      _mapListener = null;
    });
    stream.addListener(_mapListener!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

            // 선반 버튼
            ...shelves.map((s) {
              final base = rectFromFrac(s.left, s.top, s.width, s.height);
              final rect = applyScale(base, s.label, isShelf: true);
              return _ShelfButton(spec: s, rect: rect, onTap: () => _onShelfTap(s));
            }),

            // F 버튼 (최신 리스트 + size 가중치 합계로 색상)
            ...fButtons.map((a) {
              final base = rectFromFrac(a.left, a.top, a.width, a.height);
              final rect = applyScale(base, a.label, isShelf: false);
              final used = _usedWeightForFZone(a.label);
              return _FloorSquareButton(
                label: a.label,
                rect: rect,
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
            style: IconButton.styleFrom(padding: const EdgeInsets.all(10)),
            tooltip: '뒤로',
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddJig(slot: _lastSlot, floor: _lastFloor),
        label: const Text('+ 지그 등록'),
      ),
    );
  }

  // -------- 위치 유틸 --------
  String _norm(String s) => s.replaceAll(RegExp(r'\s+'), '').trim();
  List<String> _parts(String loc) => loc.split('/').map((e) => e.trim()).toList();

  String? _shelfOf(String loc) {
    final p = _parts(loc);
    if (p.length < 2) return null;
    return p[1];
  }

  String? _floorOf(String loc) {
    final p = _parts(loc);
    if (p.length < 3) return null;
    final m = RegExp(r'(\d)').firstMatch(p[2]);
    return (m == null) ? null : '${m.group(1)}층';
  }

  List<JigItemData> _itemsForShelfFloor(String shelf, String floor) {
    final ns = _norm(shelf);
    final nf = _norm(floor);
    return _items.where((it) {
      final loc = it.location.trim();
      if (!loc.startsWith('진량공장 B동')) return false;
      final s = _shelfOf(loc);
      final f = _floorOf(loc);
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

  // -------- 가중치(소/중/대) 합산 --------
  int _weightOf(JigItemData it) {
    if (widget.weightOfItem != null) return widget.weightOfItem!(it);
    final size = (it.size ?? '').replaceAll(' ', '');
    switch (size) {
      case '대형':
      case '대':
        return 5;
      case '중형':
      case '중':
        return 3;
      case '소형':
      case '소':
      default:
        return 1;
    }
  }

  int _usedWeightForShelfFloor(String shelf, String floor) =>
      _itemsForShelfFloor(shelf, floor).fold(0, (sum, it) => sum + _weightOf(it));

  int _usedWeightForFZone(String fzone) =>
      _itemsForFZone(fzone).fold(0, (sum, it) => sum + _weightOf(it));

  // -------- 액션/다이얼로그 & 폼 --------
  String? _shelfImage(String shelf) {
    switch (shelf) {
      case 'L1': return 'assets/shelf_L1.png';
      case 'R1': return 'assets/shelf_R1.png';
      case 'C1': return 'assets/shelf_C1.png';
      default: return null;
    }
  }

  // 맵에서 ‘지그 등록’ 폼 열기 (현재 보고 있는 위치로 프리필)
  void _openAddJig({String? slot, String? floor}) {
    String loc = '진량공장 B동';
    if (slot != null && slot.isNotEmpty) loc += ' / $slot';
    // F1~F4는 층 없음
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
        initialLocation: loc,                    // ✅ 프리필만 전달
        onSubmit: (newJig) => widget.onCreateJig?.call(newJig),
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
        titlePadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        title: Text('$areaLabel Zone', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 560, height: 380,
          child: items.isEmpty
              ? const Center(child: Text('등록된 지그가 없습니다.', style: TextStyle(color: Colors.grey)))
              : _JigListPanel(items: items),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
            child: TextButton(
              onPressed: () {
                Navigator.pop(dctx);
                _openAddJig(slot: areaLabel); // F존에는 층 없음
              },
              child: const Text('+ 지그 등록'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
            child: TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('닫기')),
          ),
        ],
      ),
    );
  }

  Future<void> _showShelfDialog(
      BuildContext context,
      String label,
      String imagePath, {
        String? initialSelectedFloor,
      }) async {
    return showDialog<void>(
      context: context, barrierDismissible: true,
      builder: (dialogCtx) {
        String? dialogZone;
        return StatefulBuilder(
          builder: (ctx, setSB) => AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            title: Row(children: [
              Text('$label 선반', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              if (dialogZone != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFF2E9F7), borderRadius: BorderRadius.circular(12)),
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

              final perShelfW   = widget.overlayFloorBtnWidthFracByShelf?[label];
              final perShelfH   = widget.overlayFloorBtnHeightFracOfQuarterByShelf?[label];
              final perShelfStk = widget.overlayFloorBtnStackScaleYByShelf?[label];
              final perShelfCX  = widget.overlayFloorBtnCenterXFracByShelf?[label];
              final perShelfQY  = widget.overlayFloorBtnQuarterCenterYFracByShelf?[label];
              final perShelfOff = widget.overlayFloorBtnGlobalOffsetFracByShelf?[label];

              final perFloorHeightForThisShelf =
                  widget.overlayFloorBtnHeightOverrideFracByShelf?[label] ??
                      widget.overlayFloorBtnHeightOverrideFrac;
              final perFloorOffsetForThisShelf =
                  widget.overlayFloorBtnOffsetOverrideFracByShelf?[label] ??
                      widget.overlayFloorBtnOffsetOverrideFrac;

              return SizedBox(
                width: width, height: height,
                child: ShelfOverlayViewer4Floors(
                  imagePath: imagePath,
                  shelfLabel: label,
                  onZoneTap: (z) {
                    setSB(() => dialogZone = z);
                    _lastSlot = label;
                    _lastFloor = z;
                  },
                  bgProviderOverride: bgProvider,
                  inlinePanel: true,
                  floor1Capacity: u1, floor2Capacity: u2, floor3Capacity: u3, floor4Capacity: u4,
                  btnWidthFrac: perShelfW ?? widget.overlayFloorBtnWidthFrac,
                  btnHeightFracOfQuarter: perShelfH ?? widget.overlayFloorBtnHeightFracOfQuarter,
                  btnCenterXFrac: perShelfCX ?? widget.overlayFloorBtnCenterXFrac,
                  btnQuarterCenterYFrac: perShelfQY ?? widget.overlayFloorBtnQuarterCenterYFrac,
                  btnGlobalOffsetFrac: perShelfOff ?? widget.overlayFloorBtnGlobalOffsetFrac,
                  perFloorWidthFrac: widget.overlayFloorBtnWidthOverrideFrac,
                  perFloorHeightFrac: perFloorHeightForThisShelf,
                  perFloorOffsetFrac: perFloorOffsetForThisShelf,
                  btnStackScaleY: perShelfStk ?? widget.overlayFloorBtnStackScaleY,
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
                          : _JigListPanel(items: items),
                    );
                  },
                ),
              );
            }),
            actions: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    _openAddJig(slot: label, floor: dialogZone);
                  },
                  child: const Text('+ 지그 등록'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
                child: TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('닫기')),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShelfSpec {
  final String label;
  final double left, top, width, height;
  final String imagePath;
  const _ShelfSpec(this.label, this.left, this.top, this.width, this.height, this.imagePath);
}

class _AreaSpec {
  final String label;
  final double left, top, width, height;
  const _AreaSpec(this.label, this.left, this.top, this.width, this.height);
}

class _ShelfButton extends StatelessWidget {
  final _ShelfSpec spec;
  final Rect rect;
  final VoidCallback onTap;
  const _ShelfButton({required this.spec, required this.rect, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left, top: rect.top, width: rect.width, height: rect.height,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent, padding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Align(
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
            child: Text(spec.label,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

class _FloorSquareButton extends StatelessWidget {
  final String label;
  final Rect rect;
  final Color color;
  final VoidCallback onTap;
  const _FloorSquareButton({required this.label, required this.rect, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
              child: Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}

class ShelfOverlayViewer4Floors extends StatefulWidget {
  final String imagePath;
  final String shelfLabel;
  final void Function(String) onZoneTap;
  final bool inlinePanel;
  final int floor1Capacity, floor2Capacity, floor3Capacity, floor4Capacity;
  final ImageProvider? bgProviderOverride;
  final double btnWidthFrac;
  final double btnHeightFracOfQuarter;
  final double btnCenterXFrac;
  final double btnQuarterCenterYFrac;
  final Offset btnGlobalOffsetFrac;
  final Map<String, double>? perFloorWidthFrac;
  final Map<String, double>? perFloorHeightFrac;
  final Map<String, Offset>? perFloorOffsetFrac;
  final double btnStackScaleY;
  final int maxCapacity;
  final Widget Function(String shelfLabel, String floorLabel)? detailsBuilder;
  final String? initialSelectedFloor;

  const ShelfOverlayViewer4Floors({
    super.key,
    required this.imagePath,
    required this.shelfLabel,
    required this.onZoneTap,
    this.inlinePanel = true,
    this.floor1Capacity = 0,
    this.floor2Capacity = 0,
    this.floor3Capacity = 0,
    this.floor4Capacity = 0,
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
      _aspectStream = null;
      _aspectListener = null;
    }, onError: (_, __) {
      if (!mounted) return;
      setState(() => _imgAspect = null);
      stream.removeListener(_aspectListener!);
      _aspectStream = null;
      _aspectListener = null;
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
          : _JigDetailPanel(
        shelf: widget.shelfLabel,
        floor: _selectedZone!,
        showHeader: false,
        child: const SizedBox(),
      ))
          : Stack(key: const ValueKey('floors'), children: [
        Positioned.fill(
          child: Image(
            image: widget.bgProviderOverride ??
                ResizeImage(AssetImage(widget.imagePath), width: 1024),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.low,
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
                  onTap: () {
                    setState(() => _selectedZone = f.label);
                    widget.onZoneTap(f.label);
                  },
                );
              }),
            );
          }),
        ),
      ]),
    );
  }
}

class _FloorInfo {
  final String label;
  final int capacity;
  const _FloorInfo(this.label, this.capacity);
}

class _ZoneButtonRect extends StatelessWidget {
  final Rect rect;
  final String label;
  final Color color;
  final double radius;
  final VoidCallback onTap;
  const _ZoneButtonRect({
    required this.rect,
    required this.label,
    required this.color,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left, top: rect.top, width: rect.width, height: rect.height,
      child: Material(
        color: color, borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(radius),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}

class _JigDetailPanel extends StatelessWidget {
  final String shelf;
  final String floor;
  final Widget child;
  final bool showHeader;

  const _JigDetailPanel({
    required this.shelf,
    required this.floor,
    required this.child,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              color: const Color(0xFFF2E9F7),
              child: Row(
                children: [
                  Text('$shelf 선반', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Text(floor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          Expanded(child: ColoredBox(color: Colors.white, child: child)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: Color(0xFFF2E9F7)),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('돌아가기')),
            ]),
          ),
        ],
      ),
    );
  }
}

class _JigListPanel extends StatelessWidget {
  final List<JigItemData> items;
  const _JigListPanel({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
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
        );
      },
    );
  }
}
