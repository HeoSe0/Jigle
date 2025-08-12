// lib/widgets/jig_item_data.dart

/// 지그 아이템 데이터 모델
/// - 대부분의 속성은 불변(final)
/// - 좋아요 상태만 화면에서 토글 가능하도록 가변(likes, isLiked)
class JigItemData {
  // 기본 정보 (불변)
  final String image;
  final String title;
  final String location;      // 예: '진량공장 B동 / L1 / 2층'
  final String description;
  final String registrant;
  final DateTime? storageDate;
  final DateTime? disposalDate;
  final String size;          // '소형' | '중형' | '대형'

  // 좋아요 상태 (가변 - UI 토글용)
  int likes;
  bool isLiked;

  JigItemData({
    required this.image,
    required this.title,
    required this.location,
    required this.description,
    required this.registrant,
    required this.size,
    this.storageDate,
    this.disposalDate,
    this.likes = 0,
    this.isLiked = false,
  });

  /// 불변 필드를 유지하면서 일부만 바꾸고 싶을 때 사용
  JigItemData copyWith({
    String? image,
    String? title,
    String? location,
    String? description,
    String? registrant,
    DateTime? storageDate,
    DateTime? disposalDate,
    String? size,
    int? likes,
    bool? isLiked,
  }) {
    return JigItemData(
      image: image ?? this.image,
      title: title ?? this.title,
      location: location ?? this.location,
      description: description ?? this.description,
      registrant: registrant ?? this.registrant,
      storageDate: storageDate ?? this.storageDate,
      disposalDate: disposalDate ?? this.disposalDate,
      size: size ?? this.size,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

/// 사이즈 → 포화도 가중치(소형 1, 중형 3, 대형 5)
extension JigCapacity on JigItemData {
  int get capacityWeight {
    switch (size) {
      case '소형':
        return 1;
      case '중형':
        return 3;
      case '대형':
        return 5;
      default:
        return 1; // 안전값
    }
  }
}
