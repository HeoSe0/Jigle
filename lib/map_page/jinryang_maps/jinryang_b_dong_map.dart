import 'package:flutter/material.dart';

/// 진량 B동 지도 화면 (L1/R1/C1 모두 1~4층 버튼 오버레이)
/// - 선반 버튼 → 다이얼로그 (중복 오픈 가드 + 이미지 프리캐시 + 프레임 양보)
/// - Capacity(0~10): 0=녹색, 8~10=빨간색, 그 외=노란색
class JinryangBDongMap extends StatefulWidget {
  final VoidCallback onBack;

  // L1 층별 Capacity(0~10)
  final int l1Floor1Capacity;
  final int l1Floor2Capacity;
  final int l1Floor3Capacity;
  final int l1Floor4Capacity;

  // R1 층별 Capacity(0~10)
  final int r1Floor1Capacity;
  final int r1Floor2Capacity;
  final int r1Floor3Capacity;
  final int r1Floor4Capacity;

  // C1 층별 Capacity(0~10)
  final int c1Floor1Capacity;
  final int c1Floor2Capacity;
  final int c1Floor3Capacity;
  final int c1Floor4Capacity;

  const JinryangBDongMap({
    super.key,
    required this.onBack,
    this.l1Floor1Capacity = 0,
    this.l1Floor2Capacity = 0,
    this.l1Floor3Capacity = 0,
    this.l1Floor4Capacity = 0,
    this.r1Floor1Capacity = 0,
    this.r1Floor2Capacity = 0,
    this.r1Floor3Capacity = 0,
    this.r1Floor4Capacity = 0,
    this.c1Floor1Capacity = 0,
    this.c1Floor2Capacity = 0,
    this.c1Floor3Capacity = 0,
    this.c1Floor4Capacity = 0,
  });

  @override
  State<JinryangBDongMap> createState() => _JinryangBDongMapState();
}

class _JinryangBDongMapState extends State<JinryangBDongMap> {
  bool _dialogOpen = false;

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
  }

  @override
  Widget build(BuildContext context) {
    final shelves = <_ShelfSpec>[
      const _ShelfSpec('L1', 0.08, 0.25, 0.13, 0.63, 'assets/shelf_L1.png'),
      const _ShelfSpec('R1', 0.75, 0.25, 0.13, 0.63, 'assets/shelf_R1.png'),
      const _ShelfSpec('C1', 0.31, 0.10, 0.37, 0.14, 'assets/shelf_C1.png'),
    ];

    return Scaffold(
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final imageWidth = constraints.maxWidth;
              final imageHeight = constraints.maxHeight;
              final dpr = MediaQuery.of(context).devicePixelRatio;

              return Center(
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/bdong_map.png',
                      width: imageWidth,
                      height: imageHeight,
                      fit: BoxFit.contain,
                      cacheWidth: (imageWidth * dpr).round(),
                      cacheHeight: (imageHeight * dpr).round(),
                      filterQuality: FilterQuality.low,
                    ),
                    ...shelves.map(
                          (s) => _ShelfButton(
                        spec: s,
                        imageWidth: imageWidth,
                        imageHeight: imageHeight,
                        onTap: () => _onShelfTap(s),
                      ),
                    ),
                  ],
                ),
              );
            },
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
    );
  }

  Future<void> _onShelfTap(_ShelfSpec s) async {
    if (_dialogOpen || !mounted) return;
    setState(() => _dialogOpen = true);
    try {
      final size = MediaQuery.of(context).size;
      final targetW = (size.width * s.width).clamp(320.0, 1600.0).toInt();
      final targetH = (size.height * s.height).clamp(320.0, 1200.0).toInt();
      final provider = ResizeImage(AssetImage(s.imagePath), width: targetW, height: targetH);
      await precacheImage(provider, context);
      await Future<void>.delayed(Duration.zero);
      await _showImageDialog(context, s.label, s.imagePath);
    } finally {
      if (mounted) setState(() => _dialogOpen = false);
    }
  }

  Future<void> _showImageDialog(BuildContext context, String label, String imagePath) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        String? dialogZone;
        return StatefulBuilder(
          builder: (ctx, setSB) => AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            title: Row(
              children: [
                Text('$label 선반', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                if (dialogZone != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2E9F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(dialogZone!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            content: Builder(
              builder: (context) {
                final screen = MediaQuery.of(context).size;
                final width = screen.width.clamp(320.0, 900.0).toDouble();
                final height = screen.height.clamp(320.0, 700.0).toDouble();
                final bgProvider = ResizeImage(AssetImage(imagePath), width: width.toInt());

                Widget overlayFor(String shelfLabel) {
                  switch (shelfLabel) {
                    case 'L1':
                      return ShelfOverlayViewer4Floors(
                        imagePath: imagePath,
                        onZoneTap: (z) => setSB(() => dialogZone = z),
                        bgProviderOverride: bgProvider,
                        inlinePanel: true,
                        floor1Capacity: widget.l1Floor1Capacity,
                        floor2Capacity: widget.l1Floor2Capacity,
                        floor3Capacity: widget.l1Floor3Capacity,
                        floor4Capacity: widget.l1Floor4Capacity,
                      );
                    case 'R1':
                      return ShelfOverlayViewer4Floors(
                        imagePath: imagePath,
                        onZoneTap: (z) => setSB(() => dialogZone = z),
                        bgProviderOverride: bgProvider,
                        inlinePanel: true,
                        floor1Capacity: widget.r1Floor1Capacity,
                        floor2Capacity: widget.r1Floor2Capacity,
                        floor3Capacity: widget.r1Floor3Capacity,
                        floor4Capacity: widget.r1Floor4Capacity,
                      );
                    case 'C1':
                    default:
                      return ShelfOverlayViewer4Floors(
                        imagePath: imagePath,
                        onZoneTap: (z) => setSB(() => dialogZone = z),
                        bgProviderOverride: bgProvider,
                        inlinePanel: true,
                        floor1Capacity: widget.c1Floor1Capacity,
                        floor2Capacity: widget.c1Floor2Capacity,
                        floor3Capacity: widget.c1Floor3Capacity,
                        floor4Capacity: widget.c1Floor4Capacity,
                      );
                  }
                }

                return SizedBox(width: width, height: height, child: overlayFor(label));
              },
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('닫기'),
                ),
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

class _ShelfButton extends StatelessWidget {
  final _ShelfSpec spec;
  final double imageWidth, imageHeight;
  final VoidCallback onTap;
  const _ShelfButton({
    required this.spec,
    required this.imageWidth,
    required this.imageHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: imageWidth * spec.left,
      top: imageHeight * spec.top,
      width: imageWidth * spec.width,
      height: imageHeight * spec.height,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: EdgeInsets.zero,
        ),
        child: Align(
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              spec.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShelfOverlayViewer4Floors extends StatefulWidget {
  final String imagePath;
  final void Function(String) onZoneTap;
  final bool inlinePanel;
  final int floor1Capacity;
  final int floor2Capacity;
  final int floor3Capacity;
  final int floor4Capacity;
  final ImageProvider? bgProviderOverride;

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
  });

  @override
  State<ShelfOverlayViewer4Floors> createState() => _ShelfOverlayViewer4FloorsState();
}

class _ShelfOverlayViewer4FloorsState extends State<ShelfOverlayViewer4Floors> {
  String? _selectedZone;
  double? _imgAspect;
  ImageStream? _aspectStream;
  ImageStreamListener? _aspectListener;

  static const double _btnWidthFrac = 0.78;
  static const double _btnHeightFrac = 0.42;
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
    final provider = widget.bgProviderOverride ?? AssetImage(widget.imagePath);
    final stream = provider.resolve(createLocalImageConfiguration(context));
    _aspectStream = stream;

    final listener = ImageStreamListener((info, _) {
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

    _aspectListener = listener;
    stream.addListener(listener);
  }

  Color _colorForCapacity(int c) {
    final v = c.clamp(0, 10);
    if (v == 0) return Colors.green.withValues(alpha: 0.35);
    if (v >= 8) return Colors.red.withValues(alpha: 0.35);
    return Colors.yellow.withValues(alpha: 0.35);
  }

  @override
  Widget build(BuildContext context) {
    final showWhitePanel = widget.inlinePanel && _selectedZone != null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: showWhitePanel
          ? _WhitePanel(
        title: '${_selectedZone ?? ''} 화면',
        onBack: () => setState(() => _selectedZone = null),
      )
          : Stack(
        key: const ValueKey('floors'),
        children: [
          Positioned.fill(
            child: Image(
              image: widget.bgProviderOverride ??
                  const ResizeImage(AssetImage('assets/placeholder.png'), width: 1024),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.low,
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, c) {
                final cw = c.maxWidth, ch = c.maxHeight;
                final ar = _imgAspect ?? (16 / 9);
                double dispW, dispH, offX = 0, offY = 0;

                if (cw / ch > ar) {
                  dispH = ch;
                  dispW = dispH * ar;
                  offX = (cw - dispW) / 2;
                } else {
                  dispW = cw;
                  dispH = dispW / ar;
                  offY = (ch - dispH) / 2;
                }

                Rect rectFor(int idx) {
                  final quarterH = dispH / 4;
                  final btnW = dispW * _btnWidthFrac;
                  final btnH = quarterH * _btnHeightFrac;
                  final centerY = offY + quarterH * (idx + 0.5);
                  final left = offX + (dispW - btnW) / 2;
                  final top = centerY - btnH / 2;
                  return Rect.fromLTWH(left, top, btnW, btnH);
                }

                final floorsTopToBottom = <_FloorInfo>[
                  _FloorInfo('4층', widget.floor4Capacity),
                  _FloorInfo('3층', widget.floor3Capacity),
                  _FloorInfo('2층', widget.floor2Capacity),
                  _FloorInfo('1층', widget.floor1Capacity),
                ];

                return Stack(
                  children: List.generate(floorsTopToBottom.length, (idx) {
                    final f = floorsTopToBottom[idx];
                    return _ZoneButtonRect(
                      rect: rectFor(idx),
                      label: f.label,
                      color: _colorForCapacity(f.capacity),
                      radius: _btnRadius,
                      onTap: () {
                        if (widget.inlinePanel) {
                          setState(() => _selectedZone = f.label);
                        }
                        widget.onZoneTap(f.label);
                      },
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FloorInfo {
  final String label;
  final int capacity;
  const _FloorInfo(this.label, this.capacity);
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
          const Expanded(
            child: ColoredBox(color: Colors.white, child: SizedBox.expand()),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: Color(0xFFF2E9F7)),
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
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
