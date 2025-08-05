import 'package:flutter/material.dart';
import 'jig_item_data.dart';

class JigFormBottomSheet extends StatefulWidget {
  final JigItemData? editItem;
  final Function(JigItemData) onSubmit;

  const JigFormBottomSheet({super.key, this.editItem, required this.onSubmit});

  @override
  State<JigFormBottomSheet> createState() => _JigFormBottomSheetState();
}

class _JigFormBottomSheetState extends State<JigFormBottomSheet> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController registrantController;
  String location = '진량공장 2층';
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.editItem?.title ?? '');
    descriptionController = TextEditingController(
      text: widget.editItem?.description ?? '',
    );
    registrantController = TextEditingController(
      text: widget.editItem?.registrant ?? '',
    );
    location = widget.editItem?.location ?? location;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    registrantController.dispose();
    super.dispose();
  }

  void _submit() {
    final newJig = JigItemData(
      image: "jig_example1.jpg",
      title: titleController.text,
      location: location,
      description:
          "${startDate?.toLocal().toString().split(' ')[0]} ~ ${endDate?.toLocal().toString().split(' ')[0]}\n${descriptionController.text}",
      registrant: registrantController.text,
    );
    widget.onSubmit(newJig);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // ✅ 전체 배경 흰색
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 10),

            const Text("보관 장소", style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: ['진량공장 2층', '배광실 2층', '본관 4층'].map((place) {
                final isSelected = location == place;
                return ChoiceChip(
                  label: Text(
                    place,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.blue,
                  backgroundColor: Colors.white,
                  onSelected: (_) => setState(() => location = place),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            const Text("보관 기한", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
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

            // ✅ 하단 중앙 "수정 완료" 버튼
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
    );
  }
}
