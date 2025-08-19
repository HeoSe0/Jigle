// lib/widgets/home_search_tab.dart
import 'package:flutter/material.dart';

class HomeSearchTab extends StatefulWidget {
  final void Function(String query)? onSearch;
  final String hintText;
  final String logoAssetPath;   // 상단 큰 로고
  final String slLogoAssetPath; // 하단 SL 로고

  // 레이아웃 옵션
  final double logoHeight;
  final double slLogoHeight;
  final double contentMaxWidth;
  final double searchBarRadius;
  final EdgeInsetsGeometry padding;
  final Color actionColor;
  final double gapLogoToSearch;
  final double gapSearchToNotice;
  final double slLogoBottomPadding;

  const HomeSearchTab({
    super.key,
    this.onSearch,
    this.hintText = '질문을 입력해주세요.',
    required this.logoAssetPath,
    required this.slLogoAssetPath,
    this.logoHeight = 110,
    this.slLogoHeight = 24,
    this.contentMaxWidth = 760,
    this.searchBarRadius = 28,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.actionColor = const Color(0xFF0B5CAD),
    this.gapLogoToSearch = 32,
    this.gapSearchToNotice = 16,
    this.slLogoBottomPadding = 20,
  });

  @override
  State<HomeSearchTab> createState() => _HomeSearchTabState();
}

class _HomeSearchTabState extends State<HomeSearchTab> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _submit() {
    final q = _controller.text.trim();
    if (q.isEmpty) {
      _focusNode.requestFocus();
      return;
    }
    widget.onSearch?.call(q);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const hintStyle = TextStyle(color: Color(0xFF9CA3AF));
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Stack(
      children: [
        // 항상 순백 배경
        const Positioned.fill(child: ColoredBox(color: Colors.white)),

        // 가운데 컨텐츠(로고/검색/안내)
        Positioned.fill(
          child: SafeArea(
            child: Center(
              child: LayoutBuilder(
                builder: (context, c) {
                  // 가로에선 SL로고를 우하단으로 보내므로 예약 공간을 최소화
                  final reservedForBottom = isLandscape
                      ? (bottomSafe + 12)
                      : (widget.slLogoHeight +
                      widget.slLogoBottomPadding +
                      bottomSafe +
                      32);

                  // 가로 모드에서 공간이 부족하면 간격/로고 크기 축소
                  const _kSearchBarHeight = 56.0;
                  const _kNoticeHeight = 20.0;
                  final availableCenter =
                  (c.maxHeight - reservedForBottom).clamp(0.0, double.infinity);

                  final idealCenter =
                      widget.logoHeight +
                          widget.gapLogoToSearch +
                          _kSearchBarHeight +
                          widget.gapSearchToNotice +
                          _kNoticeHeight;

                  double raw = availableCenter / idealCenter;
                  final scaleGaps = isLandscape ? raw.clamp(0.15, 1.0) : 1.0;
                  final scaleLogo = isLandscape ? raw.clamp(0.60, 1.0) : 1.0;

                  final gap1 = widget.gapLogoToSearch * scaleGaps;
                  final gap2 = widget.gapSearchToNotice * scaleGaps;
                  final logoH = widget.logoHeight * scaleLogo;

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: availableCenter),
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                          BoxConstraints(maxWidth: widget.contentMaxWidth),
                          child: Padding(
                            padding: widget.padding,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  widget.logoAssetPath,
                                  height: logoH,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(height: gap1),
                                _SearchBar(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  hintText: widget.hintText,
                                  hintStyle: hintStyle,
                                  radius: widget.searchBarRadius,
                                  actionColor: widget.actionColor,
                                  onSubmit: _submit,
                                ),
                                SizedBox(height: gap2),
                                Text(
                                  '생성형 AI는 실수할 수 있습니다. 중요한 정보를 확인하세요.',
                                  style: TextStyle(
                                    color: const Color(0xFF6B7280),
                                    fontSize: isLandscape ? 14.0 : 13.0,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // 하단 SL 로고: 세로=중앙, 가로=우하단
        Positioned(
          left: isLandscape ? 40 : 0,
          right: isLandscape ? null : 0,
          bottom: bottomSafe + widget.slLogoBottomPadding,
          child: isLandscape
              ? Image.asset(
            widget.slLogoAssetPath,
            height: widget.slLogoHeight,
            fit: BoxFit.contain,
          )
              : Center(
            child: Image.asset(
              widget.slLogoAssetPath,
              height: widget.slLogoHeight,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

/* ---------------- SearchBar ---------------- */
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final TextStyle hintStyle;
  final double radius;
  final Color actionColor;
  final VoidCallback onSubmit;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.hintStyle,
    required this.radius,
    required this.actionColor,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '검색 입력',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onSubmitted: (_) => onSubmit(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: hintStyle,
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Material(
              color: actionColor,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onSubmit,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.arrow_upward, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
