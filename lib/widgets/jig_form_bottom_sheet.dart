// lib/widgets/jig_form_bottom_sheet.dart 수정본
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'jig_item_data.dart';

class JigFormBottomSheet extends StatefulWidget {
  final JigItemData? editItem;
  final Function(JigItemData) onSubmit;

  const JigFormBottomSheet({super.key, this.editItem, required this.onSubmit});

  @override
  State<JigFormBottomSheet> createState() => _JigFormBottomSheetState();
}

class _JigFormBottomSheetState extends State<JigFormBottomSheet> {
  // ── 상수 설정 ──────────────────────────────────────────────────────────
  static const List<String> _locations = ['진량공장 B동', '배광시험동 2층', '후생동 4층'];

  // 진량공장 B동: 슬롯 & 층
  static const List<String> _bdongSlots = ['L1', 'C1', 'R1', 'F1', 'F2', 'F3', 'F4'];
  static const List<String> _floors = ['1층', '2층', '3층', '4층'];

  // B동에서 층 선택이 필요한 슬롯만 정의 (F1~F4는 층 선택 없음)
  static const Set<String> _bdongSlotsNeedFloor = {'L1', 'C1', 'R1'};

  // 배광시험동 2층: R1~R24, L1~L24 + 층(1~5층)
  static const int _baekMax = 24;
  static const List<String> _baekFloors = ['1층', '2층', '3층', '4층', '5층'];

  // 디자인: 높이/간격
  static const double _CHIP_HEIGHT_BDONG = 44; // B동 ChoiceChip 높이
  static const double _BAEK_SLOT_HEIGHT  = 36; // 배광시험동 버튼 높이
  static const double _ROW_V_PADDING     = 6;  // R/L 한 줄의 위아래 패딩
  static const int    _VISIBLE_ROWS      = 3;  // 동시에 보이는 줄 수

  static double get _baekListHeight =>
      (_BAEK_SLOT_HEIGHT + _ROW_V_PADDING * 2) * _VISIBLE_ROWS; // 36+12=48 → 48*3=144

  // ── 상태값 ─────────────────────────────────────────────────────────────
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController registrantController;

  String location = '진량공장 B동';
  String jigSize = JigItemData.sizeSmall;

  // B동 선택 상태
  String? bDongSlot;   // L1/C1/R1/F1/F2/F3/F4
  String? bDongFloor;  // 1~4층 (일부 슬롯만 사용)

  // 배광시험동 2층 선택 상태
  String? baekSlot;    // R1~R24 / L1~L24
  String? baekFloor;   // 1~5층

  DateTime? startDate;
  DateTime? endDate;

  XFile? pickedImage;
  Uint8List? pickedBytes;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.editItem?.title ?? '');
    descriptionController = TextEditingController(text: widget.editItem?.description ?? '');
    registrantController = TextEditingController(text: widget.editItem?.registrant ?? '');

    // location 초기화 + 편집 모드 파싱
    final incomingLocation = widget.editItem?.location;
    if (incomingLocation != null && incomingLocation.trim().isNotEmpty) {
      if (incomingLocation.contains('/')) {
        final parts = incomingLocation.split('/').map((s) => s.trim()).toList();
        final parent = parts.isNotEmpty ? parts[0] : '진량공장 B동';
        final slot   = parts.length > 1 ? parts[1] : null;
        final floor  = parts.length > 2 ? parts[2] : null;

        location = _locations.contains(parent) ? parent : _locations.first;

        if (location == '진량공장 B동') {
          if (slot != null && _bdongSlots.contains(slot)) bDongSlot = slot;
          // F1~F4는 층 선택 없음 → floor가 들어와도 무시
          if (floor != null && _bdongSlotsNeedFloor.contains(bDongSlot ?? '') && _floors.contains(floor)) {
            bDongFloor = floor;
          } else {
            bDongFloor = null;
          }
          baekSlot = null;
          baekFloor = null;
        } else if (location == '배광시험동 2층') {
          if (slot != null) baekSlot = slot;
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
        location = _locations.contains(incomingLocation) ? incomingLocation : _locations.first;
      }
    } else {
      location = _locations.first;
    }

    jigSize = widget.editItem?.size ?? jigSize;
    startDate = widget.editItem?.storageDate;
    endDate = widget.editItem?.disposalDate;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    registrantController.dispose();
    super.dispose();
  }

  // ── 이미지 처리 ────────────────────────────────────────────────────────
  Future<void> _pickImage({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      pickedImage = image;
      pickedBytes = bytes;
    });
  }

  void _removeImage() {
    setState(() {
      pickedImage = null;
      pickedBytes = null;
    });
  }

  void _submit() {
    // 저장 문자열 구성
    String finalLocation = location;

    if (location == '진량공장 B동') {
      if (bDongSlot != null && bDongSlot!.isNotEmpty) {
        finalLocation = '$finalLocation / $bDongSlot';
        // L1/C1/R1만 층 붙임 (F1~F4는 미부착)
        if (_bdongSlotsNeedFloor.contains(bDongSlot!) && bDongFloor != null && bDongFloor!.isNotEmpty) {
          finalLocation = '$finalLocation / $bDongFloor';
        }
      }
    } else if (location == '배광시험동 2층') {
      if (baekSlot != null && baekSlot!.isNotEmpty) {
        finalLocation = '$finalLocation / $baekSlot';
        if (baekFloor != null && baekFloor!.isNotEmpty) {
          finalLocation = '$finalLocation / $baekFloor';
        }
      }
    }

    // 이미지 저장 (base64 data URI)
    String finalImage;
    if (pickedBytes != null) {
      final b64 = base64Encode(pickedBytes!);
      finalImage = 'data:image/jpeg;base64,$b64';
    } else {
      finalImage = widget.editItem?.image ?? 'jig_example1.jpg';
    }

    final newJig = JigItemData(
      image: finalImage,
      title: titleController.text,
      location: finalLocation,
      description: descriptionController.text,
      registrant: registrantController.text,
      storageDate: startDate,
      disposalDate: endDate,
      size: jigSize,
    );

    widget.onSubmit(newJig);
    Navigator.pop(context);
  }

  // ── 공통 위젯 ──────────────────────────────────────────────────────────
  // B동 ChoiceChip을 44 높이로 맞추는 래퍼
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

  // ‘해당없음’ 비활성 칩 (B동 F1~F4 선택 시 노출)
  Widget _disabledChip44(String label) {
    return SizedBox(
      height: _CHIP_HEIGHT_BDONG,
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(color: Colors.black54)),
        selected: true,
        selectedColor: Colors.grey.shade300,
        backgroundColor: Colors.grey.shade200,
        onSelected: null, // 비활성
      ),
    );
  }

  // 배광시험동 R/L 고정 크기 버튼 (높이 가변 가능)
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

  // ── UI ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // 미리보기 위젯
    Widget preview;
    if (pickedBytes != null) {
      preview = Image.memory(pickedBytes!, fit: BoxFit.cover);
    } else if (widget.editItem != null) {
      final src = widget.editItem!.image;
      if (src.startsWith('data:')) {
        final comma = src.indexOf(',');
        if (comma > 0) {
          final b64 = src.substring(comma + 1);
          final bytes = base64Decode(b64);
          preview = Image.memory(bytes, fit: BoxFit.cover);
        } else {
          preview = const Center(child: Text('썸네일 미리보기 없음', style: TextStyle(color: Colors.black54)));
        }
      } else if (src.startsWith('http')) {
        preview = Image.network(src, fit: BoxFit.cover);
      } else {
        preview = Image.asset(src, fit: BoxFit.cover);
      }
    } else {
      preview = const Center(child: Text('썸네일 미리보기 없음', style: TextStyle(color: Colors.black54)));
    }

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
                // 사진 추가/촬영 + 삭제
                Row(
                  children: [
                    const Icon(Icons.add_a_photo, color: Colors.black),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade100,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => _pickImage(fromCamera: false),
                      child: const Text('사진 추가하기'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade100,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => _pickImage(fromCamera: true),
                      child: const Text('카메라로 촬영'),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: '사진 제거',
                      onPressed: (pickedBytes != null) ? _removeImage : null,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 썸네일 미리보기
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: preview,
                  ),
                ),

                const SizedBox(height: 20),
                const Text("지그 등록 또는 수정", style: TextStyle(fontSize: 18)),
                const SizedBox(height: 10),

                // 제목
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '제목'),
                  maxLines: 1,
                ),
                const SizedBox(height: 10),

                // 설명 (동일 높이)
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: '설명'),
                  maxLines: 1,
                ),
                const SizedBox(height: 10),

                // 등록자
                TextField(
                  controller: registrantController,
                  decoration: const InputDecoration(labelText: '등록자'),
                  maxLines: 1,
                ),
                const SizedBox(height: 16),

                // 지그 사이즈
                const Text("지그 사이즈", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [JigItemData.sizeSmall, JigItemData.sizeMedium, JigItemData.sizeLarge].map((s) {
                    final isSelected = jigSize == s;
                    return _chip44(
                      label: s,
                      selected: isSelected,
                      onSelected: (_) => setState(() => jigSize = s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 보관 장소
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
                        } else { // 후생동 등
                          bDongSlot = null;
                          bDongFloor = null;
                          baekSlot = null;
                          baekFloor = null;
                        }
                      }),
                    );
                  }).toList(),
                ),

                // 진량공장 B동: 슬롯 → (일부만) 층
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
                          // 슬롯 변경 시: 층이 필요한 슬롯이 아니면 층 초기화
                          if (!_bdongSlotsNeedFloor.contains(slot)) {
                            bDongFloor = null;
                          }
                        }),
                      );
                    }).toList(),
                  ),

                  // L1/C1/R1 에서만 층 선택 노출
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

                  // F1/F2/F3/F4 선택 시: ‘해당없음’ 표시 (비활성)
                  if (bDongSlot != null && !_bdongSlotsNeedFloor.contains(bDongSlot!)) ...[
                    const SizedBox(height: 12),
                    const Text("층 선택", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _disabledChip44('해당없음'),
                  ],
                ],

                // 배광시험동 2층: 스크롤 / 한 줄에 Rn, Ln (3줄만 보이도록)
                if (location == '배광시험동 2층') ...[
                  const SizedBox(height: 12),
                  const Text("지그 위치 (스크롤)", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),

                  SizedBox(
                    height: _baekListHeight, // 3줄만 표시 (144)
                    child: ListView.builder(
                      itemCount: _baekMax,
                      itemBuilder: (context, index) {
                        final r = 'R${index + 1}';
                        final l = 'L${index + 1}';
                        final isRSelected = baekSlot == r;
                        final isLSelected = baekSlot == l;

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: _ROW_V_PADDING),
                          child: Row(
                            children: [
                              Expanded(
                                child: _slotButton(
                                  label: r,
                                  selected: isRSelected,
                                  onTap: () => setState(() {
                                    baekSlot = r;
                                    baekFloor = null; // 슬롯 변경 시 층 초기화
                                  }),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _slotButton(
                                  label: l,
                                  selected: isLSelected,
                                  onTap: () => setState(() {
                                    baekSlot = l;
                                    baekFloor = null;
                                  }),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // 슬롯 선택 후: 1~5층 노출
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

                // 보관 기한
                const Text("보관 기한", style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => startDate = picked);
                      },
                      child: Text(
                        startDate == null
                            ? '보관 날짜'
                            : '${startDate!.year}-${startDate!.month}-${startDate!.day}',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => endDate = picked);
                      },
                      child: Text(
                        endDate == null
                            ? '폐기 날짜'
                            : '${endDate!.year}-${endDate!.month}-${endDate!.day}',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      minimumSize: const Size(200, 45),
                      side: const BorderSide(color: Colors.blueAccent),
                    ),
                    onPressed: _submit,
                    child: Text(
                      widget.editItem == null ? "등록 완료" : "수정 완료",
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
