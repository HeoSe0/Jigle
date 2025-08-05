import 'package:flutter/material.dart';  //지그 1개 아이템 카드 UI

class JigItem extends StatelessWidget {
  final String image, title, location, price, registrant;
  final int likes;

  const JigItem({
    super.key,
    required this.image,
    required this.title,
    required this.location,
    required this.price,
    required this.registrant,
    this.likes = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Image.asset(image, width: 100, height: 100, fit: BoxFit.cover),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(location),
                Text(price),
                Text("등록자: $registrant"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.favorite, size: 16, color: Colors.red),
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