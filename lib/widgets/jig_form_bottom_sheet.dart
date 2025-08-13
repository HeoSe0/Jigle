// lib/widgets/jig_form_bottom_sheet.dart
import 'dart:convert';
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
  // ── 상수 ────────────────────────────────────────────────────────────────
  static const List<String> _locations = ['진량공장 B동', '배광시험동 2층', '후생동 4층'];
  static const List<String> _bdongSlots = ['L1', 'C1', 'R1', 'F1', 'F2', 'F3', 'F4'];
  static const List<String> _floors = ['1층', '2층', '3층', '4층'];
  static const Set<String> _bdongSlotsNeedFloor = {'L1', 'C1', 'R1'};
  static const int _baekMax = 24;
  static const List<String> _baekFloors = ['1층', '2층', '3층', '4층', '5층'];
  static const int _maxImages = 5;

  static const double _CHIP_HEIGHT_BDONG = 44;
  static const double _BAEK_SLOT_HEIGHT = 36;
  static const double _ROW_V_PADDING = 6;
  static const int _VISIBLE_ROWS = 3;

  static double get _baekListHeight =>
      (_BAEK_SLOT_HEIGHT + _ROW_V_PADDING * 2) * _VISIBLE_ROWS;

  // ── 상태 ────────────────────────────────────────────────────────────────
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController registrantController;

  String location = '진량공장 B동';
  String jigSize = JigItemData.sizeSmall;

  // B동
  String? bDongSlot; // L1/C1/R1/F1~F4
  String? bDongFloor; // 1~4층 (일부만)

  // 배광시험동 2층
  String? baekSlot; // R1~R24 / L1~L24
  String? baekFloor; // 1~5층

  DateTime? startDate;
  DateTime? endDate;

  // 📸 다중 이미지: data URI 문자열을 보관 (asset/http도 허용)
  final List<String> _images = <String>[];
  int _thumbIndex = 0;

  // ── 초기화 ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.editItem?.title ?? '');
    descriptionController =
        TextEditingController(text: widget.editItem?.description ?? '');
    registrantController =
        TextEditingController(text: widget.editItem?.registrant ?? '');

    _restoreLocationFromEdit(widget.editItem?.location);
    jigSize = widget.editItem?.size ?? jigSize;
    startDate = widget.editItem?.storageDate;
    endDate = widget.editItem?.disposalDate;

    // ✨ 이미지 복원: images가 있으면 전체 복원, 없으면 image(대표)만 복원
    if (widget.editItem != null) {
      final it = widget.editItem!;
      if ((it.images).isNotEmpty) {
        _images.addAll(it.images);
        _thumbIndex = (it.thumbnailIndex >= 0 &&
            it.thumbnailIndex < it.images.length)
            ? it.thumbnailIndex
            : 0;
      } else if (it.image.trim().isNotEmpty) {
        _images.add(it.image);
        _thumbIndex = 0;
      }
    }
  }

  void _restoreLocationFromEdit(String? incomingLocation) {
    if (incomingLocation != null && incomingLocation.trim().isNotEmpty) {
      if (incomingLocation.contains('/')) {
        final parts = incomingLocation.split('/').map((s) => s.trim()).toList();
        final parent = parts.isNotEmpty ? parts[0] : '진량공장 B동';
        final slot = parts.length > 1 ? parts[1] : null;
        final floor = parts.length > 2 ? parts[2] : null;

        location = _locations.contains(parent) ? parent : _locations.first;

        if (location == '진량공장 B동') {
          if (slot != null && _bdongSlots.contains(slot)) bDongSlot = slot;
          if (floor != null &&
              _bdongSlotsNeedFloor.contains(bDongSlot ?? '') &&
              _floors.contains(floor)) {
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
        location = _locations.contains(incomingLocation)
            ? incomingLocation
            : _locations.first;
      }
    } else {
      location = _locations.first;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    registrantController.dispose();
    super.dispose();
  }

  // ── 이미지 유틸 ─────────────────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final remain = _maxImages - _images.length;
    if (remain <= 0) {
      _toast('최대 $_maxImages장까지 등록할 수 있어요.');
      return;
    }

    final files = await picker.pickMultiImage(
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (!mounted || files.isEmpty) return;

    final adding = files.take(remain);
    for (final f in adding) {
      final bytes = await f.readAsBytes();
      final b64 = base64Encode(bytes);
      _images.add('data:image/jpeg;base64,$b64');
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    if (_images.length >= _maxImages) {
      _toast('최대 $_maxImages장까지 등록할 수 있어요.');
      return;
    }
    final shot = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (shot == null) return;
    final bytes = await shot.readAsBytes();
    if (!mounted) return;
    setState(() {
      _images.add('data:image/jpeg;base64,${base64Encode(bytes)}');
    });
  }

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

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
    return;
  }

  // ── 제출 ────────────────────────────────────────────────────────────────
  void _submit() {
    // 최종 장소 문자열
    String finalLocation = location;

    if (location == '진량공장 B동') {
      if (bDongSlot != null && bDongSlot!.isNotEmpty) {
        finalLocation = '$finalLocation / $bDongSlot';
        if (_bdongSlotsNeedFloor.contains(bDongSlot!) &&
            bDongFloor != null &&
            bDongFloor!.isNotEmpty) {
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

    // 대표 썸네일(없으면 기본)
    final String finalThumb = _images.isNotEmpty
        ? _images[_thumbIndex]
        : (widget.editItem?.image ?? 'jig_example1.png');

    // ✨ JigItemData(images/thumbnailIndex) 지원 시 보존됨. (없어도 컴파일/동작 OK)
    final newJig = JigItemData(
      image: finalThumb,
      title: titleController.text,
      location: finalLocation,
      description: descriptionController.text,
      registrant: registrantController.text,
      storageDate: startDate,
      disposalDate: endDate,
      size: jigSize,
      // 아래 두 필드는 jig_item_data.dart에 추가되어 있어도/없어도 안전하게 동작하도록
      // 기본값이 존재(옵션)해야 합니다.
      images: List<String>.from(_images),
      thumbnailIndex: _thumbIndex,
    );

    widget.onSubmit(newJig);
    Navigator.pop(context);
  }

  // ── 공통 위젯 ──────────────────────────────────────────────────────────
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

  // ── UI ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // 대표 미리보기
    final Widget heroPreview = (_images.isNotEmpty)
        ? Image(image: _providerFor(_images[_thumbIndex]), fit: BoxFit.cover)
        : (widget.editItem != null && widget.editItem!.image.trim().isNotEmpty)
        ? Image(image: _providerFor(widget.editItem!.image), fit: BoxFit.cover)
        : const Center(
        child: Text('썸네일 미리보기 없음',
            style: TextStyle(color: Colors.black54)));

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Material(
        color: Colors.white,
        child: Padding(
          padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📸 사진 버튼
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
                    Text('${_images.length}/$_maxImages'),
                  ],
                ),
                const SizedBox(height: 12),

                // 대표 썸네일 미리보기
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
                    child: heroPreview,
                  ),
                ),

                // 썸네일 선택용 그리드
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
                          // 대표 표시
                          Positioned(
                            right: 6,
                            top: 6,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor:
                              selected ? Colors.blue : Colors.black45,
                              child: Icon(
                                selected ? Icons.star : Icons.star_border,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // 삭제 버튼
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

                const SizedBox(height: 20),
                const Text("지그 등록 또는 수정", style: TextStyle(fontSize: 18)),
                const SizedBox(height: 10),

                // 제목/설명/등록자
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '제목'),
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

                // 사이즈
                const Text("지그 사이즈", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    JigItemData.sizeSmall,
                    JigItemData.sizeMedium,
                    JigItemData.sizeLarge
                  ].map((s) {
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

                // B동: 슬롯/층
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
                  if (bDongSlot != null &&
                      _bdongSlotsNeedFloor.contains(bDongSlot!)) ...[
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
                  if (bDongSlot != null &&
                      !_bdongSlotsNeedFloor.contains(bDongSlot!)) ...[
                    const SizedBox(height: 12),
                    const Text("층 선택", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _disabledChip44('해당없음'),
                  ],
                ],

                // 배광시험동 2층: 슬롯/층
                if (location == '배광시험동 2층') ...[
                  const SizedBox(height: 12),
                  const Text("지그 위치 (스크롤)", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: _baekListHeight,
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
                                    baekFloor = null;
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
                      style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.white),
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
                      style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.white),
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
