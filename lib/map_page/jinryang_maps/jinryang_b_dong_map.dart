// (final) 진량 B동 지도: 선반/층 · F존 포화도 표시, 지그 목록 연동, 초기 포커스, 위치 파서 정규화
import 'package:flutter/material.dart';

// 지그 카드/데이터
import '../../widgets/jig_item.dart';
import '../../widgets/jig_item_data.dart';

/// used/max 포화도 비율 → 색상(초→노→빨)
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

  // 지그 전체 목록(선반/층, F존 다이얼로그에서 필터링)
  final List<JigItemData> allItems;

  // L1/R1/C1 층별 Capacity(합계)
  final int l1Floor1Capacity, l1Floor2Capacity, l1Floor3Capacity, l1Floor4Capacity;
  final int r1Floor1Capacity, r1Floor2Capacity, r1Floor3Capacity, r1Floor4Capacity;
  final int c1Floor1Capacity, c1Floor2Capacity, c1Floor3Capacity, c1Floor4Capacity;

  // F1~F4 영역 Capacity(합계)
  final int f1Capacity, f2Capacity, f3Capacity, f4Capacity;

  // 상한(색상 계산용)
  final int maxCapacityShelves; // L1/C1/R1(층) 상한
  final int maxCapacityF;       // F1~F4 상한

  // 지도 위 버튼 스케일
  final double shelfButtonWidthFactor;
  final double shelfButtonHeightFactor;
  final double fButtonWidthFactor;
  final double fButtonHeightFactor;
  final Map<String, double>? shelfButtonWidthOverrides;
  final Map<String, double>? shelfButtonHeightOverrides;
  final Map<String, double>? fButtonWidthOverrides;
  final Map<String, double>? fButtonHeightOverrides;

  // 다이얼로그(1~4층) 전역 파라미터
  final double overlayFloorBtnWidthFrac;            // dispW 비율
  final double overlayFloorBtnHeightFracOfQuarter;  // quarterH 비율
  final double overlayFloorBtnCenterXFrac;          // 0~1
  final double overlayFloorBtnQuarterCenterYFrac;   // 0~1
  final Offset overlayFloorBtnGlobalOffsetFrac;     // disp 비율
  final Map<String, double>? overlayFloorBtnWidthOverrideFrac;   // {'1층':0.7,...}
  final Map<String, double>? overlayFloorBtnHeightOverrideFrac;  // {'1층':0.7,...}
  final Map<String, Offset>? overlayFloorBtnOffsetOverrideFrac;  // {'1층':Offset(...)}
  final double overlayFloorBtnStackScaleY;          // 층간 간격 스케일

  // 선반별(C1/R1/L1) 오버라이드(전역 대체)
  final Map<String, double>? overlayFloorBtnWidthFracByShelf;
  final Map<String, double>? overlayFloorBtnHeightFracOfQuarterByShelf;
  final Map<String, double>? overlayFloorBtnStackScaleYByShelf;
  final Map<String, double>? overlayFloorBtnCenterXFracByShelf;
  final Map<String, double>? overlayFloorBtnQuarterCenterYFracByShelf;
  final Map<String, Offset>? overlayFloorBtnGlobalOffsetFracByShelf;

  // 선반별 · 층별 세로비/오프셋 오버라이드
  final Map<String, Map<String, double>>? overlayFloorBtnHeightOverrideFracByShelf;
  final Map<String, Map<String, Offset>>? overlayFloorBtnOffsetOverrideFracByShelf;

  // 초기 포커스(옵션)
  final String? initialShelf; // 'L1' | 'C1' | 'R1'
  final String? initialFloor; // '1층' | '2층' | '3층' | '4층'
  final String? initialFZone; // 'F1' ~ 'F4'

  const JinryangBDongMap({
    super.key,
    required this.onBack,
    this.allItems = const [],

    // L1/R1/C1 초기값
    this.l1Floor1Capacity = 0, this.l1Floor2Capacity = 0, this.l1Floor3Capacity = 0, this.l1Floor4Capacity = 0,
    this.r1Floor1Capacity = 0, this.r1Floor2Capacity = 0, this.r1Floor3Capacity = 0, this.r1Floor4Capacity = 0,
    this.c1Floor1Capacity = 0, this.c1Floor2Capacity = 0, this.c1Floor3Capacity = 0, this.c1Floor4Capacity = 0,

    // F1~F4 + 상한 기본값
    this.f1Capacity = 0, this.f2Capacity = 0, this.f3Capacity = 0, this.f4Capacity = 0,
    this.maxCapacityShelves = 10,
    this.maxCapacityF = 10,

    // 버튼 스케일
    this.shelfButtonWidthFactor = 1.2,
    this.shelfButtonHeightFactor = 0.9,
    this.fButtonWidthFactor = 0.9,
    this.fButtonHeightFactor = 0.95,
    this.shelfButtonWidthOverrides,
    this.shelfButtonHeightOverrides,
    this.fButtonWidthOverrides,
    this.fButtonHeightOverrides,

    // 다이얼로그 전역 파라미터
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

    // 기본: L1/R1 아래 8%
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

  // 지도 위 F1~F4 버튼 상대좌표
  static const fButtons = <_AreaSpec>[
    _AreaSpec('F1', 0.22, 0.27, 0.27, 0.33),
    _AreaSpec('F2', 0.48, 0.27, 0.27, 0.33),
    _AreaSpec('F3', 0.22, 0.60, 0.27, 0.33),
    _AreaSpec('F4', 0.48, 0.60, 0.27, 0.33),
  ];

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

    // 초기 포커스 자동 오픈(처음 1회)
    if (!_didAutoOpen) {
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
  void dispose() {
    if (_mapListener != null && _mapStream != null) {
      _mapStream!.removeListener(_mapListener!);
    }
    super.dispose();
  }

  void _resolveMapAspect() {
    final stream = const AssetImage('assets/bdong_map.png')
        .resolve(createLocalImageConfiguration(context));
    _mapStream = stream;
    _mapListener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() => _mapAspect =
      info.image.height == 0 ? null : info.image.width / info.image.height);
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

          final shelves = <_ShelfSpec>[
            const _ShelfSpec('L1', 0.08, 0.25, 0.13, 0.63, 'assets/shelf_L1.png'),
            const _ShelfSpec('R1', 0.75, 0.25, 0.13, 0.63, 'assets/shelf_R1.png'),
            const _ShelfSpec('C1', 0.31, 0.10, 0.37, 0.14, 'assets/shelf_C1.png'),
          ];

          return Stack(children: [
            Positioned(
              left: offX, top: offY, width: dispW, height: dispH,
              child: Image.asset('assets/bdong_map.png',
                  width: dispW, height: dispH, fit: BoxFit.fill, filterQuality: FilterQuality.low),
            ),

            // 선반 버튼
            ...shelves.map((s) {
              final base = rectFromFrac(s.left, s.top, s.width, s.height);
              final rect = applyScale(base, s.label, isShelf: true);
              return _ShelfButton(spec: s, rect: rect, onTap: () => _onShelfTap(s));
            }),

            // F 버튼
            ...fButtons.map((a) {
              final base = rectFromFrac(a.left, a.top, a.width, a.height);
              final rect = applyScale(base, a.label, isShelf: false);
              final used = _capacityForArea(a.label);
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
            onPressed: widget.onBack, icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(padding: const EdgeInsets.all(10)), tooltip: '뒤로',
          ),
        ),
      ]),
    );
  }

  // ---- 위치 파서(정규화) & 필터 ----
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
    return widget.allItems.where((it) {
      final loc = it.location.trim();
      if (!loc.startsWith('진량공장 B동')) return false;
      final s = _shelfOf(loc);
      final f = _floorOf(loc);
      return _norm(s ?? '') == ns && _norm(f ?? '') == nf;
    }).toList();
  }

  List<JigItemData> _itemsForFZone(String fzone) {
    final nf = _norm(fzone).toUpperCase(); // F1~F4
    return widget.allItems.where((it) {
      final loc = it.location.trim();
      if (!loc.startsWith('진량공장 B동')) return false;
      final p = _parts(loc);
      if (p.length < 2) return false;
      return _norm(p[1]).toUpperCase() == nf;
    }).toList();
  }

  // ---- 액션 ----
  int _capacityForArea(String label) {
    switch (label) {
      case 'F1': return widget.f1Capacity;
      case 'F2': return widget.f2Capacity;
      case 'F3': return widget.f3Capacity;
      case 'F4': return widget.f4Capacity;
      default:   return 0;
    }
  }

  String? _shelfImage(String shelf) {
    switch (shelf) {
      case 'L1': return 'assets/shelf_L1.png';
      case 'R1': return 'assets/shelf_R1.png';
      case 'C1': return 'assets/shelf_C1.png';
      default: return null;
    }
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
    setState(() => _dialogOpen = true);
    try {
      final items = _itemsForFZone(label);
      await _showFZoneDialog(context, label, items);
    } finally {
      if (mounted) setState(() => _dialogOpen = false);
    }
  }

  // ---- 다이얼로그 ----
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
        actions: [Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('닫기')),
        )],
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

              // 선반별 capacity 선택
              int f1, f2, f3, f4;
              if (label == 'L1') {
                f1 = widget.l1Floor1Capacity; f2 = widget.l1Floor2Capacity;
                f3 = widget.l1Floor3Capacity; f4 = widget.l1Floor4Capacity;
              } else if (label == 'R1') {
                f1 = widget.r1Floor1Capacity; f2 = widget.r1Floor2Capacity;
                f3 = widget.r1Floor3Capacity; f4 = widget.r1Floor4Capacity;
              } else {
                f1 = widget.c1Floor1Capacity; f2 = widget.c1Floor2Capacity;
                f3 = widget.c1Floor3Capacity; f4 = widget.c1Floor4Capacity;
              }

              // 선반별 오버라이드
              final perShelfW   = widget.overlayFloorBtnWidthFracByShelf?[label];
              final perShelfH   = widget.overlayFloorBtnHeightFracOfQuarterByShelf?[label];
              final perShelfStk = widget.overlayFloorBtnStackScaleYByShelf?[label];
              final perShelfCX  = widget.overlayFloorBtnCenterXFracByShelf?[label];
              final perShelfQY  = widget.overlayFloorBtnQuarterCenterYFracByShelf?[label];
              final perShelfOff = widget.overlayFloorBtnGlobalOffsetFracByShelf?[label];

              // 선반별·층별 세로비/오프셋(없으면 전역 per-floor 사용)
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
                  onZoneTap: (z) => setSB(() => dialogZone = z),
                  bgProviderOverride: bgProvider,
                  inlinePanel: true,
                  floor1Capacity: f1, floor2Capacity: f2, floor3Capacity: f3, floor4Capacity: f4,
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

                  // ✅ 초기 선택 층이 있으면 바로 상세 패널
                  initialSelectedFloor: initialSelectedFloor,

                  // ✅ 상세 패널에 지그 리스트 주입(헤더는 다이얼로그 타이틀만 사용)
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('닫기')),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- 모델/버튼 위젯 ---

class _ShelfSpec {
  final String label;
  final double left, top, width, height;
  final String imagePath;
  const _ShelfSpec(this.label, this.left, this.top, this.width, this.height, this.imagePath);
}

class _AreaSpec {
  final String label;
  final double left, top, width, height; // (0~1)
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

/// 선반 이미지 위 1~4층 버튼 오버레이 + 상세 패널
class ShelfOverlayViewer4Floors extends StatefulWidget {
  final String imagePath;
  final String shelfLabel; // L1/C1/R1
  final void Function(String) onZoneTap;
  final bool inlinePanel;
  final int floor1Capacity, floor2Capacity, floor3Capacity, floor4Capacity;
  final ImageProvider? bgProviderOverride;

  // 버튼 파라미터
  final double btnWidthFrac;            // dispW 기준
  final double btnHeightFracOfQuarter;  // quarterH 기준
  final double btnCenterXFrac;          // dispW 내 가로 위치(0~1)
  final double btnQuarterCenterYFrac;   // 각 quarter 내 세로 위치(0~1)
  final Offset btnGlobalOffsetFrac;     // disp 기준 전역 오프셋
  final Map<String, double>? perFloorWidthFrac;
  final Map<String, double>? perFloorHeightFrac;  // {'1층': 0.7, ...}
  final Map<String, Offset>? perFloorOffsetFrac;  // {'1층': Offset(0, 0.01)}
  final double btnStackScaleY;          // 층간 간격 스케일

  // 층 상한(색상 계산용)
  final int maxCapacity;

  // 상세 패널 빌더(선택 시)
  final Widget Function(String shelfLabel, String floorLabel)? detailsBuilder;

  // 초기 선택 층(있으면 바로 상세 패널 진입)
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
    _selectedZone ??= widget.initialSelectedFloor; // 초기 선택 적용
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
      setState(() => _imgAspect =
      info.image.height == 0 ? null : info.image.width / info.image.height);
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

              // 0(top)=4층 ... 3(bottom)=1층
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
                  rect: rectFor(i, f.label), label: f.label,
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
  const _ZoneButtonRect({required this.rect, required this.label, required this.color, required this.radius, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left, top: rect.top, width: rect.width, height: rect.height,
      child: Material(
        color: color, borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(radius),
          child: Center(
              child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87))),
        ),
      ),
    );
  }
}

// ---- 상세 패널 & 지그 리스트 ----

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
          onLikePressed: () {}, // 지도 안에서는 보기만
          storageDate: it.storageDate,
          disposalDate: it.disposalDate,
        );
      },
    );
  }
}
