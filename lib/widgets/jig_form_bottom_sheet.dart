import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'jig_item_data.dart';

class JigFormBottomSheet extends StatefulWidget {
  final JigItemData? editItem;
  final Function(JigItemData) onSubmit;

  // 맵에서 보낸 최초 위치 프리필
  final String? initialLocation;

  const JigFormBottomSheet({
    super.key,
    this.editItem,
    required this.onSubmit,
    this.initialLocation,
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

  // 지그 높이 옵션
  static const List<String> _jigHeightOptions = [
    '30cm 미만',
    '50cm 미만',
    '50cm 이상',
  ];

  // ---- 컨트롤러 & 상태 ----
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController registrantController;

  final FocusNode _titleFocus = FocusNode();
  bool _titleError = false;

  String location = '진량공장 B동';
  String jigSize = JigItemData.sizeSmall;
  String? jigHeight; // 신규 항목(필요 시 모델에 저장 로직 추가)

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
    descriptionController = TextEditingController(text: widget.editItem?.description ?? '');
    registrantController = TextEditingController(text: widget.editItem?.registrant ?? '');

    // editItem.location 없으면 initialLocation으로 프리필
    final incomingLocation = widget.editItem?.location ?? widget.initialLocation;

    if (incomingLocation != null && incomingLocation.trim().isNotEmpty) {
      if (incomingLocation.contains('/')) {
        final parts = incomingLocation.split('/').map((s) => s.trim()).toList();
        final parent = parts.isNotEmpty ? parts[0] : '진량공장 B동';
        final slot   = parts.length > 1 ? parts[1] : null;
        final floor  = parts.length > 2 ? parts[2] : null;

        location = _locations.contains(parent) ? parent : _locations.first;

        if (location == '진량공장 B동') {
          if (slot != null && _bdongSlots.contains(slot)) bDongSlot = slot;
          if (slot != null && _bdongSlotsNeedFloor.contains(slot)
              && floor != null && _floors.contains(floor)) {
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

    jigSize   = widget.editItem?.size ?? jigSize;
    startDate = widget.editItem?.storageDate;
    endDate   = widget.editItem?.disposalDate;
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

    final files = await picker.pickMultiImage(maxWidth: 1600, imageQuality: 85);
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
    final shot = await picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 85);
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
          endDate = startDate; // 간단 보정
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

  // ---- 배광 요약/초기화 ----
  void _clearBaekSelection() {
    setState(() {
      baekSlot = null;
      baekFloor = null;
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
        border: Border.all(color: Colors.blue.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18),
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
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
        ],
      ),
    );
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

    if (trimmedTitle.isEmpty) {
      setState(() => _titleError = true);
      _titleFocus.requestFocus();
      return;
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
      // TODO: jigHeight를 모델에 저장하려면 JigItemData에 필드를 추가하세요.
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
        label: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget heroPreview = (_images.isNotEmpty)
        ? Image(image: _providerFor(_images[_thumbIndex]), fit: BoxFit.cover)
        : (widget.editItem != null && widget.editItem!.image.trim().isNotEmpty)
        ? Image(image: _providerFor(widget.editItem!.image), fit: BoxFit.cover)
        : const Center(child: Text('썸네일 미리보기 없음', style: TextStyle(color: Colors.black54)));

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Material(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // 상단 툴바 영역
                Row(
                  children: [
                    const Icon(Icons.add_a_photo, color: Colors.black),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade100,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _pickFromGallery,
                      child: const Text('사진 추가하기'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade100,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _pickFromCamera,
                      child: const Text('카메라로 촬영'),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: '뒤로가기',
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Text('${_images.length}/$_maxImages'),
                  ],
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
                  child: ClipRRect(borderRadius: BorderRadius.circular(10), child: heroPreview),
                ),

                // 썸네일 그리드
                if (_images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _images.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                child: Image(image: _providerFor(_images[i]), fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFFFFE066) : Colors.black45,
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
                                child: Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],

                const SizedBox(height: 10),

                // 기본 필드들
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
                const Text("지그 사이즈", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [JigItemData.sizeSmall, JigItemData.sizeMedium, JigItemData.sizeLarge].map((s) {
                    final isSelected = jigSize == s;
                    final label = _sizeLabels[s] ?? s;
                    return _chip44(
                      label: label,
                      selected: isSelected,
                      onSelected: (_) => setState(() => jigSize = s),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                const Text("지그 높이", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _jigHeightOptions.map((h) {
                    final isSelected = jigHeight == h;
                    return _chip44(
                      label: h,
                      selected: isSelected,
                      onSelected: (_) => setState(() => jigHeight = h),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                const Text("보관 장소", style: TextStyle(fontWeight: FontWeight.bold)),
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
                      }),
                    );
                  }).toList(),
                ),

                // 진량공장 B동 세부
                if (location == '진량공장 B동') ...[
                  const SizedBox(height: 12),
                  const Text("지그 위치", style: TextStyle(fontWeight: FontWeight.bold)),
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
                        }),
                      );
                    }).toList(),
                  ),
                  if (bDongSlot != null && _bdongSlotsNeedFloor.contains(bDongSlot!)) ...[
                    const SizedBox(height: 12),
                    const Text("층 선택", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _floors.map((f) {
                        final isSelected = bDongFloor == f;
                        return _chip44(
                          label: f,
                          selected: isSelected,
                          onSelected: (_) => setState(() => bDongFloor = f),
                        );
                      }).toList(),
                    ),
                  ],
                  if (bDongSlot != null && !_bdongSlotsNeedFloor.contains(bDongSlot!)) ...[
                    const SizedBox(height: 12),
                    const Text("층 선택", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _disabledChip44('해당없음'),
                  ],
                ],

                // 배광시험동 2층 세부
                if (location == '배광시험동 2층') ...[
                  const SizedBox(height: 12),
                  const Text("지그 위치 (스크롤)", style: TextStyle(fontWeight: FontWeight.bold)),
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
                          padding: EdgeInsets.symmetric(vertical: _ROW_V_PADDING),
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
                    const Text("층 선택", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _baekFloors.map((f) {
                        final isSelected = baekFloor == f;
                        return _chip44(
                          label: f,
                          selected: isSelected,
                          onSelected: (_) => setState(() => baekFloor = f),
                        );
                      }).toList(),
                    ),
                  ],
                ],

                const SizedBox(height: 16),
                const Divider(height: 1),

                const SizedBox(height: 12),
                const Text("보관 기한", style: TextStyle(fontWeight: FontWeight.bold)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
}
