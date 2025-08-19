// lib/widgets/home_search_tab.dart
import 'package:flutter/material.dart';

class HomeSearchTab extends StatefulWidget {
  final void Function(String query)? onSearch;
  final String hintText;
  final String logoAssetPath;
  final String slLogoAssetPath;

  // 커스텀 옵션
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

    return Stack(
      children: [
        // 1) 항상 순백 배경 (Material3 색조 영향 제거)
        const Positioned.fill(child: ColoredBox(color: Colors.white)),

        // 2) 가운데 컨텐츠(로고 + 검색바 + 안내문구)
        Positioned.fill(
          child: SafeArea(
            child: Center(
              child: LayoutBuilder(
                builder: (context, c) {
                  // 하단 SL 로고 영역을 미리 빼서 가운데 정렬 공간 확보
                  final reservedForBottom =
                      widget.slLogoHeight + widget.slLogoBottomPadding + bottomSafe + 24;

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        // 남는 공간이 있을 땐 세로 가운데, 부족하면 스크롤
                        minHeight: (c.maxHeight - reservedForBottom).clamp(0, double.infinity),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: widget.contentMaxWidth),
                          child: Padding(
                            padding: widget.padding,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  widget.logoAssetPath,
                                  height: widget.logoHeight,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(height: widget.gapLogoToSearch),
                                _SearchBar(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  hintText: widget.hintText,
                                  hintStyle: hintStyle,
                                  radius: widget.searchBarRadius,
                                  actionColor: widget.actionColor,
                                  onSubmit: _submit,
                                ),
                                SizedBox(height: widget.gapSearchToNotice),
                                const Text(
                                  '생성형 AI는 실수할 수 있습니다. 중요한 정보를 확인하세요.',
                                  style: TextStyle(color: Color(0xFF6B7280)),
                                  textAlign: TextAlign.center,
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

        // 3) 하단 SL 로고(바닥 고정)
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomSafe + widget.slLogoBottomPadding,
          child: Center(
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
