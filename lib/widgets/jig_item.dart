import 'package:flutter/material.dart';  //지그 1개 아이템 카드 UI

class JigItem extends StatelessWidget {
  final String image, title, location, price, registrant;
  final int likes;
  final bool isLiked;
  final DateTime? storageDate;
  final DateTime? disposalDate;
  final VoidCallback? onLikePressed;

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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(2, 2),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(image, width: 100, height: 100, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 2),
                Text(location, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                if (storageDate != null && disposalDate != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      "${storageDate!.toLocal().toString().split(' ')[0]} ~ ${disposalDate!.toLocal().toString().split(' ')[0]}",
                      style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                    ),
                  ),
                Text(price.trim().isNotEmpty ? price : '지그 설명 없음', style: const TextStyle(fontSize: 13)),
                Text("등록자: $registrant", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: onLikePressed,
                      child: Icon(
                        Icons.favorite,
                        size: 16,
                        color: isLiked ? Colors.red : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('$likes'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
