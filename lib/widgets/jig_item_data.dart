// lib/widgets/jig_item_data.dart
import 'dart:convert';

/// 지그 아이템 데이터 모델 (다중 이미지 + 대표 썸네일 지원)
class JigItemData {
  // 사이즈 상수 & 가중치
  static const String sizeSmall = '소형';
  static const String sizeMedium = '중형';
  static const String sizeLarge = '대형';
  static const Set<String> allowedSizes = {sizeSmall, sizeMedium, sizeLarge};
  static const Map<String, int> sizeWeights = {
    sizeSmall: 1,
    sizeMedium: 3,
    sizeLarge: 5,
  };

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) {
      final t = v.trim();
      if (t.isEmpty) return null;
      return DateTime.tryParse(t);
    }
    return null;
  }

  // 기본 정보 (불변)
  final String image;            // 대표 썸네일
  final List<String> images;     // 전체 이미지(최대 5)
  final int thumbnailIndex;      // 대표 인덱스(0~)
  final String title;
  final String location;         // 예: '진량공장 B동 / L1 / 2층'
  final String description;
  final String registrant;
  final DateTime? storageDate;
  final DateTime? disposalDate;
  final String size;             // '소형' | '중형' | '대형'

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
    this.images = const <String>[],
    this.thumbnailIndex = 0,
    this.likes = 0,
    this.isLiked = false,
  })  : assert(image.isNotEmpty, 'image는 비어 있을 수 없습니다.'),
        assert(title.isNotEmpty, 'title은 비어 있을 수 없습니다.'),
        assert(location.isNotEmpty, 'location은 비어 있을 수 없습니다.'),
        assert(allowedSizes.contains(size), 'size는 소형/중형/대형만 허용됩니다.');

  JigItemData copyWith({
    String? image,
    List<String>? images,
    int? thumbnailIndex,
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
      images: images ?? this.images,
      thumbnailIndex: thumbnailIndex ?? this.thumbnailIndex,
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

  /// 사이즈 → 포화도 가중치
  int get capacityWeight => sizeWeights[size] ?? 1;

  Map<String, dynamic> toMap() => {
    'image': image,
    'images': images,
    'thumbnailIndex': thumbnailIndex,
    'title': title,
    'location': location,
    'description': description,
    'registrant': registrant,
    'storageDate': storageDate?.toIso8601String(),
    'disposalDate': disposalDate?.toIso8601String(),
    'size': size,
    'likes': likes,
    'isLiked': isLiked,
  };

  factory JigItemData.fromMap(Map<String, dynamic> map) {
    final imgs = <String>[];
    final raw = map['images'];
    if (raw is List) {
      for (final e in raw) {
        if (e is String && e.trim().isNotEmpty) imgs.add(e);
      }
    }
    return JigItemData(
      image: (map['image'] ?? '') as String,
      images: imgs,
      thumbnailIndex: (map['thumbnailIndex'] ?? 0) as int,
      title: (map['title'] ?? '') as String,
      location: (map['location'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      registrant: (map['registrant'] ?? '') as String,
      storageDate: _parseDate(map['storageDate']),
      disposalDate: _parseDate(map['disposalDate']),
      size: (map['size'] ?? sizeSmall) as String,
      likes: (map['likes'] ?? 0) as int,
      isLiked: (map['isLiked'] ?? false) as bool,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory JigItemData.fromJson(String source) =>
      JigItemData.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
