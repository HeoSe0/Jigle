class JigItemData {
  final String image;
  final String title;
  final String location;
  final String description;
  final String registrant;
  int likes;
  bool isLiked; // ← 이 필드 추가

  JigItemData({
    required this.image,
    required this.title,
    required this.location,
    required this.description,
    required this.registrant,
    this.likes = 0,
    this.isLiked = false, // ← 초기값 지정
  });
}