// lib/widgets/jig_form_bottom_sheet.dart
import 'dart:io';
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
  // 보관 장소 목록
  static const List<String> _locations = ['진량공장 B동', '배광실 2층'];

  // 진량공장 B동 하위 지그 위치 목록
  static const List<String> _bdongSlots = ['L1', 'C1', 'R1', 'F1', 'F2', 'F3', 'F4'];

  // 진량공장 B동 하위 층 목록
  static const List<String> _floors = ['1층', '2층', '3층', '4층'];

  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController registrantController;

  String location = '진량공장 B동'; // 상위 장소
  String jigSize = '소형';

  // B동 하위 선택 상태
  String? bDongSlot;   // L1/C1/R1/F1/F2/F3/F4
  String? bDongFloor;  // 1층/2층/3층/4층

  DateTime? startDate;
  DateTime? endDate;
  XFile? pickedImage;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.editItem?.title ?? '');
    descriptionController = TextEditingController(text: widget.editItem?.description ?? '');
    registrantController = TextEditingController(text: widget.editItem?.registrant ?? '');

    // location 초기화 + 편집 모드 파싱
    final incomingLocation = widget.editItem?.location;
    if (incomingLocation != null && incomingLocation.trim().isNotEmpty) {
      // "진량공장 B동 / L1 / 2층" 형태 분리 처리
      if (incomingLocation.contains('/')) {
        final parts = incomingLocation.split('/').map((s) => s.trim()).toList();
        final parent = parts.isNotEmpty ? parts[0] : '진량공장 B동';
        final slot   = parts.length > 1 ? parts[1] : null;
        final floor  = parts.length > 2 ? parts[2] : null;

        location = _locations.contains(parent) ? parent : _locations.first;
        if (location == '진량공장 B동') {
          if (slot != null && _bdongSlots.contains(slot)) {
            bDongSlot = slot;
          }
          if (floor != null && _floors.contains(floor)) {
            bDongFloor = floor;
          }
        }
      } else {
        // 단일 명칭만 저장된 경우
        location = _locations.contains(incomingLocation) ? incomingLocation : _locations.first;
      }
    } else {
      // 신규 기본값
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

  Future<void> _pickImage({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (image != null) {
      setState(() => pickedImage = image);
    }
  }

  void _submit() {
    // 저장 시: B동이면 "진량공장 B동 / 슬롯 / 층" 형태 구성
    String finalLocation = location;
    if (location == '진량공장 B동') {
      if (bDongSlot != null && bDongSlot!.isNotEmpty) {
        finalLocation = '$finalLocation / $bDongSlot';
        if (bDongFloor != null && bDongFloor!.isNotEmpty) {
          finalLocation = '$finalLocation / $bDongFloor';
        }
      }
    }

    final newJig = JigItemData(
      image: pickedImage?.path ?? widget.editItem?.image ?? 'jig_example1.jpg',
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

  @override
  Widget build(BuildContext context) {
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
                // 📸 사진 추가 버튼 + 카메라
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
                  ],
                ),
                const SizedBox(height: 12),

                // 🖼 썸네일 미리보기
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: pickedImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(pickedImage!.path), fit: BoxFit.cover),
                  )
                      : const Center(
                    child: Text('썸네일 미리보기 없음', style: TextStyle(color: Colors.black54)),
                  ),
                ),

                const SizedBox(height: 20),
                const Text("지그 등록 또는 수정", style: TextStyle(fontSize: 18)),
                const SizedBox(height: 10),

                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '제목'),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: '설명'),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: registrantController,
                  decoration: const InputDecoration(labelText: '등록자'),
                ),
                const SizedBox(height: 16),

                // ✅ 지그 사이즈
                const Text("지그 사이즈", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['소형', '중형', '대형'].map((s) {
                    final isSelected = jigSize == s;
                    return ChoiceChip(
                      label: Text(s, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                      selected: isSelected,
                      selectedColor: Colors.blue,
                      backgroundColor: Colors.white,
                      onSelected: (_) => setState(() => jigSize = s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // ✅ 보관 장소
                const Text("보관 장소", style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: _locations.map((place) {
                    final isSelected = location == place;
                    return ChoiceChip(
                      label: Text(place, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                      selected: isSelected,
                      selectedColor: Colors.blue,
                      backgroundColor: Colors.white,
                      onSelected: (_) => setState(() {
                        location = place;
                        // 장소 변경 시 B동 관련 선택 초기화
                        if (location != '진량공장 B동') {
                          bDongSlot = null;
                          bDongFloor = null;
                        }
                      }),
                    );
                  }).toList(),
                ),

                // ✅ 진량공장 B동 선택 시: 슬롯 노출
                if (location == '진량공장 B동') ...[
                  const SizedBox(height: 12),
                  const Text("지그 위치", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _bdongSlots.map((slot) {
                      final isSelected = bDongSlot == slot;
                      return ChoiceChip(
                        label: Text(slot, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                        selected: isSelected,
                        selectedColor: Colors.blue,
                        backgroundColor: Colors.white,
                        onSelected: (_) => setState(() {
                          bDongSlot = slot;
                          // 슬롯 바꾸면 층 초기화
                          bDongFloor = null;
                        }),
                      );
                    }).toList(),
                  ),

                  // ✅ 슬롯 선택되면: 층 노출
                  if (bDongSlot != null) ...[
                    const SizedBox(height: 12),
                    const Text("층 선택", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: _floors.map((f) {
                        final isSelected = bDongFloor == f;
                        return ChoiceChip(
                          label: Text(f, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                          selected: isSelected,
                          selectedColor: Colors.blue,
                          backgroundColor: Colors.white,
                          onSelected: (_) => setState(() => bDongFloor = f),
                        );
                      }).toList(),
                    ),
                  ],
                ],

                const SizedBox(height: 16),

                // ✅ 보관 기한
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
