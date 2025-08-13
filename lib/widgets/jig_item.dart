// lib/widgets/jig_item.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 지그 1개 아이템 카드 UI
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

  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d.toLocal());

  String? get _dateRangeText {
    if (storageDate != null && disposalDate != null) {
      return '${_fmt(storageDate!)} ~ ${_fmt(disposalDate!)}';
    }
    if (storageDate != null) return '보관: ${_fmt(storageDate!)}';
    if (disposalDate != null) return '폐기: ${_fmt(disposalDate!)}';
    return null;
  }

  bool get _isNetwork =>
      image.startsWith('http://') || image.startsWith('https://');
  bool get _isDataUrl => image.startsWith('data:');

  @override
  Widget build(BuildContext context) {
    final dateText = _dateRangeText;
    const w = 100.0, h = 100.0;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheW = (w * dpr).round();
    final border = BorderRadius.circular(10);

    final placeholder = Container(
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: border,
      ),
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );

    Widget thumb;
    if (_isNetwork) {
      thumb = Image.network(
        image,
        width: w,
        height: h,
        fit: BoxFit.cover,
        cacheWidth: cacheW,
        loadingBuilder: (c, child, progress) =>
        progress == null ? child : placeholder,
        errorBuilder: (c, e, s) => placeholder,
      );
    } else if (_isDataUrl) {
      final comma = image.indexOf(',');
      if (comma > 0) {
        final b64 = image.substring(comma + 1);
        final bytes = base64Decode(b64);
        thumb = Image.memory(bytes, width: w, height: h, fit: BoxFit.cover);
      } else {
        thumb = placeholder;
      }
    } else {
      thumb = Image.asset(
        image,
        width: w,
        height: h,
        fit: BoxFit.cover,
        cacheWidth: cacheW,
        errorBuilder: (c, e, s) => placeholder,
      );
    }

    return Semantics(
      label: '지그 카드: $title',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 2),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(borderRadius: border, child: thumb),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87),
                  ),
                  if (dateText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        dateText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, color: Colors.black54),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      price.trim().isNotEmpty ? price : '지그 설명 없음',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '등록자: $registrant',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: isLiked ? '좋아요 취소' : '좋아요',
                        child: IconButton(
                          onPressed: onLikePressed,
                          tooltip: isLiked ? '좋아요 취소' : '좋아요',
                          iconSize: 18,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          splashRadius: 16,
                          icon: Icon(
                            Icons.favorite,
                            color: isLiked ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('$likes', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
