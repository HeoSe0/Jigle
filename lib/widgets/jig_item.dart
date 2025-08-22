// lib/widgets/jig_item.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl; // 별칭 임포트 (format 이름 충돌 방지)

import 'jig_item_data.dart';

class JigItem extends StatefulWidget {
  final String image;
  final List<String>? images;
  final int thumbnailIndex;

  final String title, location, description, registrant;
  final int likes;
  final bool isLiked;
  final DateTime? storageDate;
  final DateTime? disposalDate;
  final VoidCallback? onLikePressed;

  final String? size;
  final String? jigHeight;

  final List<String> Function(String parent, String? slot, String? floor)?
  heightPolicyResolver;

  const JigItem({
    super.key,
    required this.image,
    this.images,
    this.thumbnailIndex = 0,
    required this.title,
    required this.location,
    String? description,
    @Deprecated('Use "description:" instead of "price:".') String? price,
    required this.registrant,
    required this.likes,
    required this.storageDate,
    required this.disposalDate,
    this.isLiked = false,
    this.onLikePressed,
    this.size,
    this.jigHeight,
    this.heightPolicyResolver,
  }) : description = (description ?? price ?? '');

  @override
  State<JigItem> createState() => _JigItemState();
}

class _JigItemState extends State<JigItem> {
  static const _thumbW = 100.0;
  static const _thumbH = 100.0;
  final _thumbBorder = BorderRadius.circular(10);

  late PageController _pageController;
  late int _current;

  // 좋아요 낙관적 상태
  late bool _liked;
  late int _likes;

  @override
  void initState() {
    super.initState();
    final g = _gallery;
    _current = g.isEmpty ? 0 : widget.thumbnailIndex.clamp(0, g.length - 1);
    _pageController = PageController(initialPage: _current);

    _liked = widget.isLiked;
    _likes = widget.likes;
  }

  @override
  void didUpdateWidget(covariant JigItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked || oldWidget.likes != widget.likes) {
      _liked = widget.isLiked;
      _likes = widget.likes;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ---------- 날짜 포맷(로케일 지정 없이 숫자 표기) ----------
  String _fmt(DateTime d) => intl.DateFormat('yyyy-MM-dd').format(d.toLocal());

  String? get _dateRangeText {
    if (widget.storageDate != null && widget.disposalDate != null) {
      return '${_fmt(widget.storageDate!)} ~ ${_fmt(widget.disposalDate!)}';
    }
    if (widget.storageDate != null) return '보관: ${_fmt(widget.storageDate!)}';
    if (widget.disposalDate != null) return '폐기: ${_fmt(widget.disposalDate!)}';
    return null;
  }

  // ---------- 이미지 유틸 ----------
  List<String> get _gallery =>
      (widget.images != null && widget.images!.isNotEmpty)
          ? widget.images!
          : [widget.image];

  bool _isNetworkSrc(String src) =>
      src.startsWith('http://') || src.startsWith('https://');
  bool _isDataUrlSrc(String src) => src.startsWith('data:');

  Widget _buildImage(
      String src, {
        double? width,
        double? height,
        BoxFit fit = BoxFit.cover,
        int? cacheWidth,
        BorderRadius? radius,
      }) {
    final placeholder = Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: radius ?? _thumbBorder,
      ),
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );

    if (_isNetworkSrc(src)) {
      return ClipRRect(
        borderRadius: radius ?? _thumbBorder,
        child: Image.network(
          src,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: cacheWidth,
          loadingBuilder: (c, child, p) => p == null ? child : placeholder,
          errorBuilder: (c, e, s) => placeholder,
        ),
      );
    } else if (_isDataUrlSrc(src)) {
      final comma = src.indexOf(',');
      if (comma > 0) {
        final b64 = src.substring(comma + 1);
        final bytes = base64Decode(b64);
        return ClipRRect(
          borderRadius: radius ?? _thumbBorder,
          child: Image.memory(bytes, width: width, height: height, fit: fit),
        );
      }
      return placeholder;
    } else {
      return ClipRRect(
        borderRadius: radius ?? _thumbBorder,
        child: Image.asset(
          src,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: cacheWidth,
          errorBuilder: (c, e, s) => placeholder,
        ),
      );
    }
  }

  // ---------- 라벨/정책 ----------
  String? get _sizePretty {
    final s = widget.size?.trim();
    if (s == null || s.isEmpty) return null;
    switch (s) {
      case '소형':
        return '소형 (15 ~ 20cm 미만)';
      case '중형':
        return '중형 (20 ~ 50cm 미만)';
      case '대형':
        return '대형 (50cm 이상)';
      default:
        return s;
    }
  }

  // 경로 파싱
  List<String> _parts(String loc) =>
      loc.split('/').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  // "배광시험동 2층" → "배광시험동"
  String _stripTrailingFloor(String s) =>
      s.replaceFirst(RegExp(r'\s*\d+층$'), '');

  // 첫 토큰에서 부모 추출(토큰에 층이 붙어 있어도 제거)
  String _parentLocation(String loc) {
    final first = _parts(loc).isNotEmpty ? _parts(loc)[0] : loc;
    return _stripTrailingFloor(first);
  }

  String? _slotOf(String loc) => _parts(loc).length >= 2 ? _parts(loc)[1] : null;

  // 1) 3번째 토큰이 층이면 사용, 2) 1번째 토큰 끝의 "n층"도 인식
  String? _floorOf(String loc) {
    final p = _parts(loc);
    if (p.length >= 3) {
      final m = RegExp(r'(\d+)').firstMatch(p[2]);
      return (m == null) ? null : '${m.group(1)}층';
    }
    final first = p.isNotEmpty ? p[0] : loc;
    final m2 = RegExp(r'(\d+)층').firstMatch(first);
    return m2?.group(0);
  }

  // 기본 정책은 모델의 공통 규칙에 위임
  List<String> _defaultHeightPolicy(String parent, String? slot, String? floor) {
    return JigItemData.resolveHeightOptions(parent, slot, floor);
  }

  bool get _isHeightAllowed {
    final jh = widget.jigHeight?.trim();
    if (jh == null || jh.isEmpty) return true;
    final parent = _parentLocation(widget.location);
    final slot = _slotOf(widget.location);
    final floor = _floorOf(widget.location);
    final allowed =
    (widget.heightPolicyResolver ?? _defaultHeightPolicy)(parent, slot, floor);
    return allowed.contains(jh);
  }

  /// 경고 문자열(String)로 단순화
  String? get _heightWarningText {
    final parent = _parentLocation(widget.location);
    final slot = _slotOf(widget.location);
    final floor = _floorOf(widget.location);
    return JigItemData.resolveHeightWarning(parent, slot, floor, widget.jigHeight);
  }

  Widget _badge(String text, {Color? bg, Color? fg, IconData? icon}) {
    final background = bg ?? Colors.blue.withOpacity(0.08);
    final foreground = fg ?? Colors.blue.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      margin: const EdgeInsets.only(right: 6, top: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: foreground,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _withTooltip({required Widget child, String? message}) {
    if (message == null || message.trim().isEmpty) return child;
    return Tooltip(
      message: message,
      textStyle: const TextStyle(
        fontSize: 9.0,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      waitDuration: const Duration(milliseconds: 350),
      showDuration: const Duration(seconds: 4),
      preferBelow: false,
      margin: const EdgeInsets.all(8),
      verticalOffset: 8,
      child: child,
    );
  }

  void _openGallery({
    required List<String> gallery,
    required int startIndex,
    required String heroTag,
  }) {
    final pageController = PageController(initialPage: startIndex);
    int current = startIndex;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: Stack(
                children: [
                  Center(
                    child: PageView.builder(
                      controller: pageController,
                      onPageChanged: (i) => setState(() => current = i),
                      itemCount: gallery.length,
                      itemBuilder: (c, i) {
                        final content = InteractiveViewer(
                          panEnabled: true,
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: _buildImage(
                            gallery[i],
                            fit: BoxFit.contain,
                            radius: BorderRadius.zero,
                          ),
                        );
                        return i == startIndex
                            ? Hero(tag: heroTag, child: content)
                            : content;
                      },
                    ),
                  ),
                  Positioned(
                    top: 16 + MediaQuery.of(ctx).padding.top,
                    right: 16,
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: '닫기',
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24 + MediaQuery.of(ctx).padding.bottom,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${current + 1} / ${gallery.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _heroTagFor(int index, List<String> gallery) =>
      Object.hash(widget.title, gallery[index], index).toString();

  void _handleLikeTap() {
    setState(() {
      if (_liked) {
        _liked = false;
        if (_likes > 0) _likes -= 1;
      } else {
        _liked = true;
        _likes += 1;
      }
    });
    widget.onLikePressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final gallery = _gallery;
    final dateText = _dateRangeText;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheW = (_thumbW * dpr).round();
    final prettyHeight = (widget.jigHeight != null &&
        widget.jigHeight!.trim().isNotEmpty)
        ? '지그 높이 ${widget.jigHeight!}'
        : null;

    final heightOk = _isHeightAllowed;
    final heightBg =
    heightOk ? const Color(0xFFEFFAF3) : const Color(0xFFFFF3CD);
    final heightFg =
    heightOk ? const Color(0xFF1B8E5A) : const Color(0xFF8A6D3B);
    final heightIcon = heightOk ? Icons.height : Icons.warning_amber_rounded;
    final warningText = _heightWarningText; // String?

    Widget core = Semantics(
      label: '지그 카드: ${widget.title}',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일
            Semantics(
              button: true,
              label: '이미지 갤러리 열기',
              child: InkWell(
                borderRadius: _thumbBorder,
                onTap: () => _openGallery(
                  gallery: gallery,
                  startIndex: _current,
                  heroTag: _heroTagFor(_current, gallery),
                ),
                child: SizedBox(
                  width: _thumbW,
                  height: _thumbH,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: _thumbBorder,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (i) => setState(() => _current = i),
                          itemCount: gallery.length,
                          itemBuilder: (_, i) => Hero(
                            tag: _heroTagFor(i, gallery),
                            child: _buildImage(
                              gallery[i],
                              width: _thumbW,
                              height: _thumbH,
                              fit: BoxFit.cover,
                              cacheWidth: cacheW,
                              radius: _thumbBorder,
                            ),
                          ),
                        ),
                      ),
                      if (gallery.length > 1)
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${_current + 1}/${gallery.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 정보 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // 위치
                  Text(
                    widget.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  // 날짜
                  if (dateText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        dateText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  // 설명
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      widget.description.trim().isNotEmpty
                          ? widget.description
                          : '지그 설명 없음',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // 배지(지그 사이즈 / 지그 높이)
                  if (_sizePretty != null || prettyHeight != null) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      children: [
                        if (_sizePretty != null)
                          _badge(
                            _sizePretty!,
                            bg: const Color(0xFFEFF1FF),
                            fg: const Color(0xFF3D4ED7),
                            icon: Icons.widgets_outlined,
                          ),
                        if (prettyHeight != null)
                          _withTooltip(
                            message: warningText ??
                                (_isHeightAllowed
                                    ? null
                                    : '현재 위치에서 허용되지 않는 높이일 수 있어요'),
                            child: _badge(
                              prettyHeight!,
                              bg: heightBg,
                              fg: heightFg,
                              icon: heightIcon,
                            ),
                          ),
                      ],
                    ),
                  ],

                  // 등록자
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '등록자: ${widget.registrant}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 좋아요 (상위 제스처 컨테이너 안에서도 잘 눌리도록 처리)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Semantics(
                        button: true,
                        label: _liked ? '좋아요 취소' : '좋아요',
                        child: Tooltip(
                          message: _liked ? '좋아요 취소' : '좋아요',
                          textStyle: const TextStyle(
                            fontSize: 9.0,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (_) {}, // 제스처 선점
                            onTap: _handleLikeTap,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.favorite,
                                size: 20,
                                color: _liked ? Colors.red : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('$_likes', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // 좁은 폭에서 자동 스케일 다운
    const double kBaseWidthForScale = 420.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        if (maxW + 0.5 >= kBaseWidthForScale) return core;
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kBaseWidthForScale),
            child: core,
          ),
        );
      },
    );
  }
}
