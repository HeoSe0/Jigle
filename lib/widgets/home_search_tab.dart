import 'package:flutter/material.dart';

class HomeSearchTab extends StatefulWidget {
  final void Function(String query)? onSearch;
  final String hintText;
  final String logoAssetPath;   // 상단 큰 로고 경로
  final String slLogoAssetPath; // 하단 SL 로고 경로

  /// 레이아웃 커스터마이즈 옵션
  final double logoHeight;           // 상단 로고 높이
  final double slLogoHeight;         // 하단 SL 로고 높이
  final double contentMaxWidth;      // 중앙 콘텐츠 최대 폭
  final double searchBarRadius;      // 검색바 라운드
  final EdgeInsetsGeometry padding;  // 좌우 패딩
  final Color actionColor;           // 전송 버튼 배경색
  final double gapLogoToSearch;      // 로고 ↔ 검색바 간격
  final double gapSearchToNotice;    // 검색바 ↔ 안내 문구 간격
  final double slLogoBottomPadding;  // SL 로고 하단 여백

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.contentMaxWidth),
            child: Padding(
              padding: widget.padding,
              child: Column(
                children: [
                  const Spacer(), // 상단 여백(가변)

                  // 상단 큰 로고
                  Image.asset(
                    widget.logoAssetPath,
                    height: widget.logoHeight,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: widget.gapLogoToSearch),

                  // 검색 바
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

                  // 안내 문구
                  const Text(
                    '생성형 AI는 실수할 수 있습니다. 중요한 정보를 확인하세요.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(), // 중앙 공간 확보 → SL 로고가 하단으로 내려감

                  // 하단 SL 로고
                  Image.asset(
                    widget.slLogoAssetPath,
                    height: widget.slLogoHeight,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: widget.slLogoBottomPadding),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------- SearchBar 서브 위젯 ---------------- */
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
              color: Colors.black.withValues(alpha: 0.08),
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
