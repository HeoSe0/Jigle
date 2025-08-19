// lib/widgets/jig_form_bottom_sheet.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'jig_item_data.dart';

class JigFormBottomSheet extends StatefulWidget {
  final JigItemData? editItem;
  final Function(JigItemData) onSubmit;

  /// 맵에서 보낸 최초 위치 프리필
  final String? initialLocation;

  /// 현재 위치/선반/층에 따른 허용 높이 규칙(없으면 JigItemData.resolveHeightOptions 사용)
  final List<String> Function(String location, String? slot, String? floor)?
  heightPolicyResolver;

  /// 지그 사이즈/높이 가이드 이미지(asset 경로)
  final String sizeGuideAssetPath;

  const JigFormBottomSheet({
    super.key,
    this.editItem,
    required this.onSubmit,
    this.initialLocation,
    this.heightPolicyResolver,
    this.sizeGuideAssetPath = 'assets/jig_size_guide_kr.png',
  });

  @override
  State<JigFormBottomSheet> createState() => _JigFormBottomSheetState();
}

class _JigFormBottomSheetState extends State<JigFormBottomSheet> {
  // ---- 상수들 ----
  static const List<String> _locations = ['진량공장 B동', '배광시험동 2층', '후생동 4층'];
  static const List<String> _bdongSlots = ['L1', 'C1', 'R1', 'F1', 'F2', 'F3', 'F4'];
  static const List<String> _floors = ['1층', '2층', '3층', '4층'];
  static const Set<String> _bdongSlotsNeedFloor = {'L1', 'C1', 'R1'};

  // 배광시험동: R은 1~24, L은 1~20
  static const int _baekMaxR = 24;
  static const int _baekMaxL = 20;
  static const List<String> _baekFloors = ['1층', '2층', '3층', '4층', '5층'];

  static const int _maxImages = 5;

  static const double _CHIP_HEIGHT_BDONG = 44;
  static const double _BAEK_SLOT_HEIGHT = 36;
  static const double _ROW_V_PADDING = 6;
  static const int _VISIBLE_ROWS = 3;

  static double get _baekListHeight =>
      (_BAEK_SLOT_HEIGHT + _ROW_V_PADDING * 2) * _VISIBLE_ROWS;

  // 지그 사이즈 라벨(내부 값은 기존 상수 유지)
  static const Map<String, String> _sizeLabels = {
    JigItemData.sizeSmall: '소형 (15 ~ 20cm 미만)',
    JigItemData.sizeMedium: '중형 (20 ~ 50cm 미만)',
    JigItemData.sizeLarge: '대형 (50cm 이상)',
  };

  // 지그 높이 옵션(항상 3개 모두 노출; 규칙은 경고로 처리)
  static const List<String> _jigHeightOptions = [
    JigItemData.heightLt30,
    JigItemData.heightLt50,
    JigItemData.heightGte50,
  ];

  // ---- 컨트롤러 & 상태 ----
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController registrantController;

  // 제목/필수 항목 에러 표시
  final FocusNode _titleFocus = FocusNode();
  bool _titleError = false;
  bool _heightError = false;
  bool _slotError = false;
  bool _floorError = false;

  String location = '진량공장 B동';
  String jigSize = JigItemData.sizeSmall;
  String? jigHeight; // 신규 항목

  String? bDongSlot;
  String? bDongFloor;

  String? baekSlot;
  String? baekFloor;

  DateTime? startDate;
  DateTime? endDate;

  final List<String> _images = <String>[];
  int _thumbIndex = 0;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.editItem?.title ?? '');
    descriptionController =
        TextEditingController(text: widget.editItem?.description ?? '');
    registrantController =
        TextEditingController(text: widget.editItem?.registrant ?? '');

    // editItem.location 없으면 initialLocation으로 프리필
    final incomingLocation = widget.editItem?.location ?? widget.initialLocation;

    if (incomingLocation != null && incomingLocation.trim().isNotEmpty) {
      if (incomingLocation.contains('/')) {
        final parts = incomingLocation.split('/').map((s) => s.trim()).toList();
        final parent = parts.isNotEmpty ? parts[0] : '진량공장 B동';
        final slot = parts.length > 1 ? parts[1] : null;
        final floor = parts.length > 2 ? parts[2] : null;

        location = _locations.contains(parent) ? parent : _locations.first;

        if (location == '진량공장 B동') {
          if (slot != null && _bdongSlots.contains(slot)) bDongSlot = slot;
          if (slot != null &&
              _bdongSlotsNeedFloor.contains(slot) &&
              floor != null &&
              _floors.contains(floor)) {
            bDongFloor = floor;
          } else {
            bDongFloor = null;
          }
          baekSlot = null;
          baekFloor = null;
        } else if (location == '배광시험동 2층') {
          if (slot != null) {
            final s = slot.trim();
            if (s.startsWith('L')) {
              final n = int.tryParse(s.substring(1));
              if (n != null && n >= 1 && n <= _baekMaxL) baekSlot = s;
            } else if (s.startsWith('R')) {
              final n = int.tryParse(s.substring(1));
              if (n != null && n >= 1 && n <= _baekMaxR) baekSlot = s;
            }
          }
          if (floor != null && _baekFloors.contains(floor)) baekFloor = floor;
          bDongSlot = null;
          bDongFloor = null;
        } else {
          bDongSlot = null;
          bDongFloor = null;
          baekSlot = null;
          baekFloor = null;
        }
      } else {
        location = _locations.contains(incomingLocation)
            ? incomingLocation
            : _locations.first;
      }
    } else {
      location = _locations.first;
    }

    jigSize = widget.editItem?.size ?? jigSize;
    startDate = widget.editItem?.storageDate;
    endDate = widget.editItem?.disposalDate;

    // 높이
    jigHeight = widget.editItem?.jigHeight;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    registrantController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  // ---- 이미지 선택 ----
  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final remain = _maxImages - _images.length;
    if (remain <= 0) {
      _toast('최대 $_maxImages장까지 등록할 수 있어요.');
      return;
    }

    final files =
    await picker.pickMultiImage(maxWidth: 1600, imageQuality: 85);
    if (!mounted || files.isEmpty) return;

    final adding = files.take(remain);
    for (final f in adding) {
      final bytes = await f.readAsBytes();
      final b64 = base64Encode(bytes);
      _images.add('data:image/jpeg;base64,$b64');
    }
    setState(() {});
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    if (_images.length >= _maxImages) {
      _toast('최대 $_maxImages장까지 등록할 수 있어요.');
      return;
    }
    final shot = await picker.pickImage(
        source: ImageSource.camera, maxWidth: 1600, imageQuality: 85);
    if (shot == null) return;
    final bytes = await shot.readAsBytes();
    if (!mounted) return;
    setState(() {
      _images.add('data:image/jpeg;base64,${base64Encode(bytes)}');
    });
  }

  // ---- 이미지 유틸 ----
  void _removeAt(int index) {
    if (index < 0 || index >= _images.length) return;
    setState(() {
      _images.removeAt(index);
      if (_images.isEmpty) {
        _thumbIndex = 0;
      } else if (_thumbIndex >= _images.length) {
        _thumbIndex = _images.length - 1;
      }
    });
  }

  void _setThumb(int index) {
    if (index < 0 || index >= _images.length) return;
    setState(() => _thumbIndex = index);
  }

  ImageProvider _providerFor(String src) {
    if (src.startsWith('data:')) {
      final i = src.indexOf(',');
      final b64 = i >= 0 ? src.substring(i + 1) : src;
      return MemoryImage(base64Decode(b64));
    } else if (src.startsWith('http')) {
      return NetworkImage(src);
    } else {
      return AssetImage(src);
    }
  }

  // ---- 공용 ----
  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = (isStart ? startDate : endDate) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: isStart ? '보관 날짜 선택' : '폐기 날짜 선택',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        startDate = DateTime(picked.year, picked.month, picked.day);
        if (endDate != null && endDate!.isBefore(startDate!)) {
          endDate = startDate;
        }
      } else {
        endDate = DateTime(picked.year, picked.month, picked.day);
      }
    });
  }

  String _dateLabel(DateTime? d, String placeholder) {
    if (d == null) return placeholder;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  // ---- 높이 규칙 체크 ----
  List<String> _allowedHeights() {
    String? slot, floor;
    if (location == '진량공장 B동') {
      slot = bDongSlot;
      floor = bDongFloor;
    } else if (location == '배광시험동 2층') {
      slot = baekSlot;
      floor = baekFloor;
    }
    final resolver =
        widget.heightPolicyResolver ?? JigItemData.resolveHeightOptions;
    return resolver(location, slot, floor);
  }

  bool get _isHeightSelectionAllowed {
    if (jigHeight == null) return true; // 미선택은 경고 미표시(필수 검사는 별도)
    return _allowedHeights().contains(jigHeight);
  }

  // ---- 필수 항목 로직(게터) ----
  bool get _needSlotSelection {
    // B동/배광시험동은 '지그 위치(슬롯)' 필수, 후생동 4층은 슬롯 개념 없음
    return location == '진량공장 B동' || location == '배광시험동 2층';
  }

  bool get _isSlotSelected {
    if (!_needSlotSelection) return true;
    if (location == '진량공장 B동') {
      return bDongSlot != null && bDongSlot!.isNotEmpty;
    }
    if (location == '배광시험동 2층') {
      return baekSlot != null && baekSlot!.isNotEmpty;
    }
    return true;
  }

  bool get _needsFloorSelected {
    if (location == '진량공장 B동') {
      if (bDongSlot == null) return false;
      return _bdongSlotsNeedFloor.contains(bDongSlot!); // L1/C1/R1만 층 필수
    }
    if (location == '배광시험동 2층') {
      return baekSlot != null; // 배광시험동은 슬롯 선택 시 층 필수
    }
    return false;
  }

  bool get _isFloorSelected {
    if (!_needsFloorSelected) return true;
    if (location == '진량공장 B동') {
      return bDongFloor != null && bDongFloor!.isNotEmpty;
    }
    if (location == '배광시험동 2층') {
      return baekFloor != null && baekFloor!.isNotEmpty;
    }
    return true;
  }

  // ---- 오류 알약 UI ----
  Widget _errorPill(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        border: Border.all(color: const Color(0xFFFF6B6B)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 16, color: Color(0xFFB00020)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              msg,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB00020),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ---- 가이드 이미지 다이얼로그 ----
  Future<void> _showSizeGuide() async {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
        contentPadding: const EdgeInsets.all(8),
        title: Row(
          children: [
            const Text(
              '지그 사이즈/높이 가이드',
              style: TextStyle(fontWeight: FontWeight.w300, fontSize: 16),
            ),
            const Spacer(),
            IconButton(
              tooltip: '닫기',
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 900),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.asset(
              widget.sizeGuideAssetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.low,
            ),
          ),
        ),
      ),
    );
  }

  // ---- 제출 전 검증 (필수 항목) ----
  bool _validateAndMarkErrors() {
    bool ok = true;

    // 높이
    if (jigHeight == null || jigHeight!.trim().isEmpty) {
      _heightError = true;
      ok = false;
    } else {
      _heightError = false;
    }

    // 슬롯
    if (_needSlotSelection && !_isSlotSelected) {
      _slotError = true;
      ok = false;
    } else {
      _slotError = false;
    }

    // 층
    if (_needsFloorSelected && !_isFloorSelected) {
      _floorError = true;
      ok = false;
    } else {
      _floorError = false;
    }

    setState(() {});
    return ok;
  }

  // ---- 로케이션 문자열 안전 구성 ----
  String _buildLocationString() {
    final parts = <String>[];
    parts.add(location);

    if (location == '진량공장 B동') {
      if ((bDongSlot ?? '').isNotEmpty) parts.add(bDongSlot!);
      if ((bDongSlot ?? '').isNotEmpty &&
          _bdongSlotsNeedFloor.contains(bDongSlot!) &&
          (bDongFloor ?? '').isNotEmpty) {
        parts.add(bDongFloor!);
      }
    } else if (location == '배광시험동 2층') {
      if ((baekSlot ?? '').isNotEmpty) parts.add(baekSlot!);
      if ((baekFloor ?? '').isNotEmpty) parts.add(baekFloor!);
    }
    return parts.where((e) => e.trim().isNotEmpty).join(' / ');
  }

  // ---- 제출 ----
  void _submit() {
    final trimmedTitle = titleController.text.trim();

    // 제목 에러 표시
    if (trimmedTitle.isEmpty) {
      setState(() => _titleError = true);
      _titleFocus.requestFocus();
    }

    // 높이/슬롯/층 필수 검증
    final okRequired = _validateAndMarkErrors();

    // 하나라도 에러면 등록 차단
    if (_titleError || !okRequired) {
      if (_heightError) {
        _toast('지그 높이를 선택해주세요.');
      } else if (_slotError) {
        _toast('지그 위치를 선택해주세요.');
      } else if (_floorError) {
        _toast('층을 선택해주세요.');
      } else {
        _toast('필수 항목을 확인해주세요.');
      }
      return;
    }

    // 선택이 규칙에 어긋나더라도(허용 외 높이) 등록은 허용
    if (!_isHeightSelectionAllowed) {
      _toast('지그 높이 때문에 보관이 어려울 수 있습니다. 그래도 등록합니다.');
    }

    final String finalLocation = _buildLocationString();

    final String finalThumb = _images.isNotEmpty
        ? _images[_thumbIndex]
        : (widget.editItem?.image ?? 'assets/sample_box1.png');

    final newJig = JigItemData(
      image: finalThumb,
      title: trimmedTitle,
      location: finalLocation,
      description: descriptionController.text.trim(),
      registrant: registrantController.text.trim(),
      storageDate: startDate,
      disposalDate: endDate,
      size: jigSize,
      jigHeight: jigHeight, // 저장
    );

    widget.onSubmit(newJig);
    Navigator.pop(context);
  }

  // ---- 작은 위젯들 ----
  Widget _chip44({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return SizedBox(
      height: _CHIP_HEIGHT_BDONG,
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(color: selected ? Colors.white : Colors.black)),
        selected: selected,
        selectedColor: Colors.blue,
        backgroundColor: Colors.white,
        onSelected: onSelected,
      ),
    );
  }

  Widget _disabledChip44(String label) {
    return SizedBox(
      height: _CHIP_HEIGHT_BDONG,
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(color: Colors.black54)),
        selected: true,
        selectedColor: Colors.grey.shade300,
        backgroundColor: Colors.grey.shade200,
        onSelected: null,
      ),
    );
  }

  Widget _slotButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: _BAEK_SLOT_HEIGHT,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? Colors.blue : Colors.white,
          foregroundColor: selected ? Colors.white : Colors.black,
          side: BorderSide(color: selected ? Colors.blue : Colors.black12),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    final Widget heroPreview = (_images.isNotEmpty)
        ? Image(image: _providerFor(_images[_thumbIndex]), fit: BoxFit.cover)
        : (widget.editItem != null &&
        widget.editItem!.image.trim().isNotEmpty)
        ? Image(image: _providerFor(widget.editItem!.image), fit: BoxFit.cover)
        : const Center(
        child: Text('썸네일 미리보기 없음',
            style: TextStyle(color: Colors.black54)));

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Material(
        color: Colors.white,
        child: Padding(
          // 키보드가 올라올 때만 하단 여백 추가
          padding: EdgeInsets.only(bottom: keyboard),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomSafe),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 툴바 영역 (카메라 아이콘 제거 + SafeArea로 상단 겹침 방지)
                SafeArea(
                  top: true,
                  bottom: false,
                  child: Row(
                    children: [
                      // 뒤로가기: 왼쪽으로 붙이기
                      IconButton(
                        tooltip: '뒤로가기',
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.black),
                        visualDensity: VisualDensity.compact,
                        constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                      const SizedBox(width: 4),

                      // 사진 추가
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade100,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _pickFromGallery,
                        child: const Text('사진 추가하기'),
                      ),

                      const SizedBox(width: 8),

                      // 카메라로 촬영
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade100,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _pickFromCamera,
                        child: const Text('카메라로 촬영'),
                      ),

                      const Spacer(),
                      Text('${_images.length}/$_maxImages'),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 썸네일 프리뷰
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: heroPreview),
                ),

                // 썸네일 그리드
                if (_images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _images.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, i) {
                      final selected = i == _thumbIndex;
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                onTap: () => _setThumb(i),
                                child: Image(
                                  image: _providerFor(_images[i]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFFFE066)
                                    : Colors.black45,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '대표',
                                style: TextStyle(
                                  color: selected ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 6,
                            top: 6,
                            child: InkWell(
                              onTap: () => _removeAt(i),
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],

                const SizedBox(height: 10),

                // 제목 (필수, 에러 하이라이트)
                TextField(
                  controller: titleController,
                  focusNode: _titleFocus,
                  decoration: InputDecoration(
                    labelText: '제목',
                    errorText: _titleError ? '제목은 필수입니다.' : null,
                    filled: _titleError,
                    fillColor: Colors.red.withOpacity(0.06),
                    border: const OutlineInputBorder(),
                    enabledBorder: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _titleError ? Colors.red : Colors.blue,
                        width: _titleError ? 2 : 1.5,
                      ),
                    ),
                    errorBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  onChanged: (v) {
                    if (_titleError && v.trim().isNotEmpty) {
                      setState(() => _titleError = false);
                    }
                  },
                  maxLines: 1,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: '설명'),
                  maxLines: 1,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: registrantController,
                  decoration: const InputDecoration(labelText: '등록자'),
                  maxLines: 1,
                ),

                const SizedBox(height: 16),
                const Text("지그 사이즈",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children:
                  [JigItemData.sizeSmall, JigItemData.sizeMedium, JigItemData.sizeLarge]
                      .map((s) {
                    final isSelected = jigSize == s;
                    final label = _sizeLabels[s] ?? s;
                    return _chip44(
                      label: label,
                      selected: isSelected,
                      onSelected: (_) => setState(() => jigSize = s),
                    );
                  }).toList(),
                ),

                // 지그 높이: 모든 옵션 노출 + (필수 미선택: 빨간 에러) / (규칙 위반: 노랑 경고)
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("지그 높이",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),

                    if (_heightError)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _errorPill('지그 높이를 선택해주세요.'),
                        ),
                      )
                    else if (!_isHeightSelectionAllowed)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3CD),
                              border:
                              Border.all(color: const Color(0xFFEEA236)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.warning_amber_rounded,
                                    size: 16, color: Color(0xFF8A6D3B)),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '지그 높이 때문에 보관이 어려울 수 있습니다.',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF8A6D3B)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      const Spacer(),

                    // 오른쪽 도움말 아이콘
                    IconButton(
                      tooltip: '지그 사이즈/높이 가이드',
                      onPressed: _showSizeGuide,
                      icon: const Icon(Icons.help_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _jigHeightOptions.map((h) {
                    final isSelected = jigHeight == h;
                    final disallowedSelected =
                        isSelected && !_allowedHeights().contains(h);
                    return SizedBox(
                      height: _CHIP_HEIGHT_BDONG,
                      child: ChoiceChip(
                        label: Text(
                          h,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight:
                            disallowedSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor:
                        disallowedSelected ? Colors.redAccent : Colors.blue,
                        backgroundColor: Colors.white,
                        side: disallowedSelected
                            ? const BorderSide(
                            color: Colors.redAccent, width: 1.5)
                            : const BorderSide(color: Colors.transparent),
                        onSelected: (_) => setState(() {
                          jigHeight = h;
                          if (_heightError) _heightError = false;
                        }),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                const Text("보관 장소",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: _locations.map((place) {
                    final isSelected = location == place;
                    return _chip44(
                      label: place,
                      selected: isSelected,
                      onSelected: (_) => setState(() {
                        location = place;
                        if (location == '진량공장 B동') {
                          baekSlot = null;
                          baekFloor = null;
                        } else if (location == '배광시험동 2층') {
                          bDongSlot = null;
                          bDongFloor = null;
                        } else {
                          bDongSlot = null;
                          bDongFloor = null;
                          baekSlot = null;
                          baekFloor = null;
                        }
                        _slotError = false;
                        _floorError = false;
                      }),
                    );
                  }).toList(),
                ),

                // 진량공장 B동 세부
                if (location == '진량공장 B동') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text("지그 위치",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      if (_slotError) _errorPill('지그 위치를 선택해주세요.'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _bdongSlots.map((slot) {
                      final isSelected = bDongSlot == slot;
                      return _chip44(
                        label: slot,
                        selected: isSelected,
                        onSelected: (_) => setState(() {
                          bDongSlot = slot;
                          if (!_bdongSlotsNeedFloor.contains(slot)) {
                            bDongFloor = null;
                          }
                          if (_slotError) _slotError = false;
                          _floorError = false;
                        }),
                      );
                    }).toList(),
                  ),
                  if (bDongSlot != null &&
                      _bdongSlotsNeedFloor.contains(bDongSlot!)) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text("층 선택",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (_floorError) _errorPill('층을 선택해주세요.'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _floors.map((f) {
                        final isSelected = bDongFloor == f;
                        return _chip44(
                          label: f,
                          selected: isSelected,
                          onSelected: (_) => setState(() {
                            bDongFloor = f;
                            if (_floorError) _floorError = false;
                          }),
                        );
                      }).toList(),
                    ),
                  ],
                  if (bDongSlot != null &&
                      !_bdongSlotsNeedFloor.contains(bDongSlot!)) ...[
                    const SizedBox(height: 12),
                    const Text("층 선택",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _disabledChip44('해당없음'),
                  ],
                ],

                // 배광시험동 2층 세부
                if (location == '배광시험동 2층') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text("지그 위치 (스크롤)",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      if (_slotError) _errorPill('지그 위치를 선택해주세요.'),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 선택 요약
                  _baekSummaryWidget(),
                  const SizedBox(height: 6),

                  SizedBox(
                    height: _baekListHeight,
                    child: ListView.builder(
                      itemCount: _baekMaxR, // R 최대 길이에 맞춤
                      itemBuilder: (context, index) {
                        final n = index + 1;
                        final r = 'R$n';
                        final l = 'L$n';
                        final showR = n <= _baekMaxR;
                        final showL = n <= _baekMaxL;

                        final isRSelected = baekSlot == r;
                        final isLSelected = baekSlot == l;

                        return Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: _ROW_V_PADDING),
                          child: Row(
                            children: [
                              if (showR)
                                Expanded(
                                  child: _slotButton(
                                    label: r,
                                    selected: isRSelected,
                                    onTap: () => setState(() {
                                      baekSlot = r;
                                      baekFloor = null;
                                      if (_slotError) _slotError = false;
                                      _floorError = false;
                                    }),
                                  ),
                                )
                              else
                                const Expanded(child: SizedBox.shrink()),

                              const SizedBox(width: 10),

                              if (showL)
                                Expanded(
                                  child: _slotButton(
                                    label: l,
                                    selected: isLSelected,
                                    onTap: () => setState(() {
                                      baekSlot = l;
                                      baekFloor = null;
                                      if (_slotError) _slotError = false;
                                      _floorError = false;
                                    }),
                                  ),
                                )
                              else
                                const Expanded(child: SizedBox.shrink()),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (baekSlot != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text("층 선택",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (_floorError) _errorPill('층을 선택해주세요.'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _baekFloors.map((f) {
                        final isSelected = baekFloor == f;
                        return _chip44(
                          label: f,
                          selected: isSelected,
                          onSelected: (_) => setState(() {
                            baekFloor = f;
                            if (_floorError) _floorError = false;
                          }),
                        );
                      }).toList(),
                    ),
                  ],
                ],

                const SizedBox(height: 16),
                const Divider(height: 1),

                const SizedBox(height: 12),
                const Text("보관 기한",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(isStart: true),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_dateLabel(startDate, '보관 날짜')),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(isStart: false),
                      icon: const Icon(Icons.event_busy),
                      label: Text(_dateLabel(endDate, '폐기 날짜')),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('등록 완료'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- 배광시험동 선택 요약 ----
  void _clearBaekSelection() {
    setState(() {
      baekSlot = null;
      baekFloor = null;
      _slotError = false;
      _floorError = false;
    });
  }

  Widget _baekSummaryWidget() {
    final hasSelection = (baekSlot != null) || (baekFloor != null);
    final summary = (baekSlot == null)
        ? '선택 없음 · 지그 위치를 먼저 선택하세요'
        : '선택: $baekSlot${baekFloor != null ? ' · $baekFloor' : ' · 층 미선택'}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
          (_slotError || _floorError) ? const Color(0xFFFF6B6B) : Colors.blue.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            (_slotError || _floorError)
                ? Icons.error_outline
                : Icons.info_outline,
            size: 18,
            color: (_slotError || _floorError)
                ? const Color(0xFFB00020)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summary,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (hasSelection)
            TextButton.icon(
              onPressed: _clearBaekSelection,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('초기화'),
              style: TextButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8)),
            ),
        ],
      ),
    );
  }
}
