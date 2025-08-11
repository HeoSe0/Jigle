import 'package:flutter/material.dart';

/// 진량 B동 지도 화면 (선반별 간격/크기/위치 오버라이드 지원)
/// - 지도 위 C1/R1/L1, F1~F4는 bdong_map 표시영역 기준 비율 배치 + 스케일 조절
/// - 선반 다이얼로그의 1~4층 버튼은 전역/선반별/층별로 크기·위치·간격 오버라이드 가능

// 공용: capacity → 색상
Color colorForCapacity(int c) {
  final v = c.clamp(0, 10);
  const a = 0.35; // 투명도
  if (v == 0) return Colors.green.withValues(alpha: a);
  if (v >= 8) return Colors.red.withValues(alpha: a);
  return Colors.yellow.withValues(alpha: a);
}

class JinryangBDongMap extends StatefulWidget {
  final VoidCallback onBack;

  // L1/R1/C1 층별 Capacity
  final int l1Floor1Capacity, l1Floor2Capacity, l1Floor3Capacity, l1Floor4Capacity;
  final int r1Floor1Capacity, r1Floor2Capacity, r1Floor3Capacity, r1Floor4Capacity;
  final int c1Floor1Capacity, c1Floor2Capacity, c1Floor3Capacity, c1Floor4Capacity;

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
  final double overlayFloorBtnStackScaleY;          // 층간 간격 스케일 (1=기본)

  // 선반별(C1/R1/L1) 오버라이드(전역 대체)
  final Map<String, double>? overlayFloorBtnWidthFracByShelf;
  final Map<String, double>? overlayFloorBtnHeightFracOfQuarterByShelf;
  final Map<String, double>? overlayFloorBtnStackScaleYByShelf;
  final Map<String, double>? overlayFloorBtnCenterXFracByShelf;
  final Map<String, double>? overlayFloorBtnQuarterCenterYFracByShelf;
  final Map<String, Offset>? overlayFloorBtnGlobalOffsetFracByShelf;

  // NEW: 선반별 · 층별 세로비 오버라이드 (전역 per-floor 을 선반 단위로 덮어씀)
  // 예: { 'L1': {'1층': 0.70}, 'R1': {'1층': 0.68}, 'C1': {'1층': 0.62} }
  final Map<String, Map<String, double>>? overlayFloorBtnHeightOverrideFracByShelf;

  // NEW: 선반별 · 층별 위치 오프셋( disp 기준 비율 ) — 선반 단위로 per-floor 오프셋을 덮어씀
  // 예: { 'L1': {'4층': Offset(0,-0.015), '2층': Offset(0,0.015)} }
  final Map<String, Map<String, Offset>>? overlayFloorBtnOffsetOverrideFracByShelf;

  const JinryangBDongMap({
    super.key,
    required this.onBack,
    this.l1Floor1Capacity = 0, this.l1Floor2Capacity = 0, this.l1Floor3Capacity = 0, this.l1Floor4Capacity = 0,
    this.r1Floor1Capacity = 0, this.r1Floor2Capacity = 0, this.r1Floor3Capacity = 0, this.r1Floor4Capacity = 0,
    this.c1Floor1Capacity = 0, this.c1Floor2Capacity = 0, this.c1Floor3Capacity = 0, this.c1Floor4Capacity = 0,

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
    // 기본: L1/R1 아래 6%
    this.overlayFloorBtnGlobalOffsetFracByShelf = const {
      'L1': Offset(0.0, 0.08),
      'R1': Offset(0.0, 0.08),
    },

    this.overlayFloorBtnHeightOverrideFracByShelf = const {
      'L1': {'1층': 0.72},
      'R1': {'1층': 0.72},
      'C1': {'4층': 0.5,'3층': 0.5,'2층': 0.5, '1층': 0.85},
    },

    // 요청사항 반영 기본값: L1/R1에서 4↔3, 3↔2 간격만 더 좁게 보이도록(4층 ↓, 2층 ↑)
    this.overlayFloorBtnOffsetOverrideFracByShelf = const {
      'L1': {
        '4층': Offset(0,  0.04), // 4층 아래로 조금
        '3층': Offset(0,  0.012), // 3층 아래로 조금
        '2층': Offset(0, -0.014), // 2층 위로 조금
      },
      'R1': {
        '4층': Offset(0,  0.035),
        '3층': Offset(0,  0.010),
        '2층': Offset(0, -0.014),
      },
      'C1': {
        '4층': Offset(0,  0.00),
        '3층': Offset(0,  0.00),
        '2층': Offset(0, -0.00),
        '1층': Offset(0,  0.04),
      },
    },
  });

  @override
  State<JinryangBDongMap> createState() => _JinryangBDongMapState();
}

class _JinryangBDongMapState extends State<JinryangBDongMap> {
  bool _dialogOpen = false;
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
              return _FloorSquareButton(
                label: a.label,
                rect: rect,
                color: colorForCapacity(_capacityForArea(a.label)),
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

  int _capacityForArea(String _) => 0;

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
      await _showEmptyAreaDialog(context, label);
    } finally {
      if (mounted) setState(() => _dialogOpen = false);
    }
  }

  Future<void> _showEmptyAreaDialog(BuildContext context, String areaLabel) async {
    return showDialog<void>(
      context: context, barrierDismissible: true,
      builder: (dctx) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        title: Text('$areaLabel Zone', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: const SizedBox(
          width: 420, height: 320,
          child: Center(child: Text('내용 없음', style: TextStyle(fontSize: 16, color: Colors.grey))),
        ),
        actions: [Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('닫기')),
        )],
      ),
    );
  }

  Future<void> _showShelfDialog(BuildContext context, String label, String imagePath) async {
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

              // 선반별·층별 세로비 오버라이드(없으면 전역 per-floor 사용)
              final perFloorHeightForThisShelf =
                  widget.overlayFloorBtnHeightOverrideFracByShelf?[label] ??
                      widget.overlayFloorBtnHeightOverrideFrac;

              // NEW: 선반별·층별 오프셋(없으면 전역 per-floor 사용)
              final perFloorOffsetForThisShelf =
                  widget.overlayFloorBtnOffsetOverrideFracByShelf?[label] ??
                      widget.overlayFloorBtnOffsetOverrideFrac;

              return SizedBox(
                width: width, height: height,
                child: ShelfOverlayViewer4Floors(
                  imagePath: imagePath,
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
                  perFloorOffsetFrac: perFloorOffsetForThisShelf, // 선반별·층별 오프셋 전달
                  btnStackScaleY: perShelfStk ?? widget.overlayFloorBtnStackScaleY,
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
            child: Text(spec.label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}

/// 선반 이미지 위 1~4층 버튼 오버레이
class ShelfOverlayViewer4Floors extends StatefulWidget {
  final String imagePath;
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

  const ShelfOverlayViewer4Floors({
    super.key,
    required this.imagePath,
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
    // 불필요한 미사용 변수 제거, 직접 사용할 provider만 생성
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
    final showWhitePanel = widget.inlinePanel && _selectedZone != null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: showWhitePanel
          ? _WhitePanel(title: '${_selectedZone ?? ''} 화면', onBack: () => setState(() => _selectedZone = null))
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
              final baseNormY = (idx + widget.btnQuarterCenterYFrac) / 4.0; // 0~1
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
                  color: colorForCapacity(f.capacity), radius: _btnRadius,
                  onTap: () {
                    if (widget.inlinePanel) setState(() => _selectedZone = f.label);
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
          child: Center(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87))),
        ),
      ),
    );
  }
}

class _WhitePanel extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _WhitePanel({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(child: ColoredBox(color: Colors.white, child: SizedBox.expand())),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: Color(0xFFF2E9F7)),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: onBack, child: const Text('돌아가기')),
            ]),
          ),
        ],
      ),
    );
  }
}
