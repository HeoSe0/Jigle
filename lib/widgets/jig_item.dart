// lib/widgets/jig_item.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 지그 1개 아이템 카드 UI
class JigItem extends StatelessWidget {
  final String image, title, location, price, registrant;
  final int likes;
  final bool isLiked;
  final DateTime? storageDate;
  final DateTime? disposalDate;
  final VoidCallback? onLikePressed;

  /// 선택: 지그 사이즈('소형' | '중형' | '대형')
  final String? size;

  /// 선택: 지그 높이('30cm 미만' | '50cm 미만' | '50cm 이상')
  final String? jigHeight;

  /// 선택: 높이 허용 규칙 커스터마이즈
  ///  - 인자: (parentLocation, slot, floor) → 허용 가능한 높이 라벨 리스트
  final List<String> Function(String parent, String? slot, String? floor)?
  heightPolicyResolver;

  const JigItem({
    super.key,
    required this.image,
    required this.title,
    required this.location,
    required this.price,
    required this.registrant,
    required this.likes,
    required this.storageDate,
    required this.disposalDate,
    this.isLiked = false,
    this.onLikePressed,

    // ⬇️ 추가(선택)
    this.size,
    this.jigHeight,
    this.heightPolicyResolver,
  });

  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d.toLocal());

  String? get _dateRangeText {
    if (storageDate != null && disposalDate != null) {
      return '${_fmt(storageDate!)} ~ ${_fmt(disposalDate!)}';
    }
    if (storageDate != null) return '보관: ${_fmt(storageDate!)}';
    if (disposalDate != null) return '폐기: ${_fmt(disposalDate!)}';
    return null;
  }

  bool get _isNetwork =>
      image.startsWith('http://') || image.startsWith('https://');
  bool get _isDataUrl => image.startsWith('data:');

  // ---------- 라벨/정책 유틸 ----------
  String? get _sizePretty {
    final s = size?.trim();
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

  List<String> _parts(String loc) =>
      loc.split('/').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  String _parentLocation(String loc) =>
      _parts(loc).isNotEmpty ? _parts(loc)[0] : loc;
  String? _slotOf(String loc) => _parts(loc).length >= 2 ? _parts(loc)[1] : null;
  String? _floorOf(String loc) {
    final p = _parts(loc);
    if (p.length < 3) return null;
    final m = RegExp(r'(\d+)').firstMatch(p[2]);
    return (m == null) ? null : '${m.group(1)}층';
  }

  // 기본 높이 정책 (진량공장 B동: 1~3층은 30/50 미만, 4층은 무제한)
  List<String> _defaultHeightPolicy(String parent, String? slot, String? floor) {
    const all = ['30cm 미만', '50cm 미만', '50cm 이상'];
    if (parent.startsWith('진량공장 B동')) {
      if (floor == '4층') return all; // 무제한 = 모두 허용
      return const ['30cm 미만', '50cm 미만'];
    }
    // 기타 장소는 모두 허용
    return all;
    // 필요 시 다른 건물 규칙을 여기 분기 추가
  }

  bool get _isHeightAllowed {
    final jh = jigHeight?.trim();
    if (jh == null || jh.isEmpty) return true; // 미선택은 경고 표시 안 함
    final parent = _parentLocation(location);
    final slot = _slotOf(location);
    final floor = _floorOf(location);
    final allowed = (heightPolicyResolver ?? _defaultHeightPolicy)(
      parent,
      slot,
      floor,
    );
    return allowed.contains(jh);
  }

  // 공통 배지 위젯
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
      waitDuration: const Duration(milliseconds: 350),
      showDuration: const Duration(seconds: 4),
      preferBelow: false,
      margin: const EdgeInsets.all(8),
      verticalOffset: 8,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _dateRangeText;
    const w = 100.0, h = 100.0;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheW = (w * dpr).round();
    final border = BorderRadius.circular(10);

    final placeholder = Container(
      width: w, height: h, alignment: Alignment.center,
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: border),
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );

    Widget thumb;
    if (_isNetwork) {
      thumb = Image.network(
        image, width: w, height: h, fit: BoxFit.cover, cacheWidth: cacheW,
        loadingBuilder: (c, child, progress) => progress == null ? child : placeholder,
        errorBuilder: (c, e, s) => placeholder,
      );
    } else if (_isDataUrl) {
      final comma = image.indexOf(',');
      if (comma > 0) {
        final b64 = image.substring(comma + 1);
        final bytes = base64Decode(b64);
        thumb = Image.memory(bytes, width: w, height: h, fit: BoxFit.cover);
      } else {
        thumb = placeholder;
      }
    } else {
      thumb = Image.asset(
        image, width: w, height: h, fit: BoxFit.cover, cacheWidth: cacheW,
        errorBuilder: (c, e, s) => placeholder,
      );
    }

    final prettySize = _sizePretty;
    final prettyHeight = (jigHeight != null && jigHeight!.trim().isNotEmpty)
        ? '지그 높이 ${jigHeight!}'
        : null;

    final heightOk = _isHeightAllowed;
    final heightBg = heightOk ? const Color(0xFFEFFAF3) : const Color(0xFFFFF3CD);
    final heightFg = heightOk ? const Color(0xFF1B8E5A) : const Color(0xFF8A6D3B);
    final heightIcon = heightOk ? Icons.height : Icons.warning_amber_rounded;

    return Semantics(
      label: '지그 카드: $title',
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
            ClipRRect(borderRadius: border, child: thumb),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16.5),
                  ),
                  const SizedBox(height: 2),
                  // 위치
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: Colors.black87),
                  ),
                  // 날짜
                  if (dateText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        dateText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                      ),
                    ),
                  // 설명
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      price.trim().isNotEmpty ? price : '지그 설명 없음',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),

                  // === 배지(지그 사이즈 / 지그 높이) ===
                  if (prettySize != null || prettyHeight != null) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      children: [
                        if (prettySize != null)
                          _badge(
                            prettySize,
                            bg: const Color(0xFFEFF1FF),
                            fg: const Color(0xFF3D4ED7),
                            icon: Icons.widgets_outlined,
                          ),
                        if (prettyHeight != null)
                          _withTooltip(
                            message: heightOk ? null : '현재 위치에서 허용되지 않는 높이일 수 있어요',
                            child: _badge(
                              prettyHeight,
                              bg: heightBg,
                              fg: heightFg,
                              icon: heightIcon,
                            ),
                          ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 6),
                  // 등록자 + 좋아요
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '등록자: $registrant',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: isLiked ? '좋아요 취소' : '좋아요',
                        child: IconButton(
                          onPressed: onLikePressed,
                          tooltip: isLiked ? '좋아요 취소' : '좋아요',
                          iconSize: 18,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          splashRadius: 16,
                          icon: Icon(Icons.favorite, color: isLiked ? Colors.red : Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('$likes', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
