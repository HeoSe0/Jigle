class JigItemData {
  final String image;
  final String title;
  final String location;
  final String description;
  final String registrant;

  // ✅ 새 필드
  final String size; // '소형' | '중형' | '대형'

  int likes;
  bool isLiked;
  final DateTime? storageDate;
  final DateTime? disposalDate;

  JigItemData({
    required this.image,
    required this.title,
    required this.location,
    required this.description,
    required this.registrant,

    // ✅ 기본값: 소형
    this.size = '소형',

    this.likes = 0,
    this.isLiked = false,
    this.storageDate,
    this.disposalDate,
  });
}
