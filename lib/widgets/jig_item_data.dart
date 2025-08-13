// lib/widgets/jig_item_data.dart
import 'dart:convert';

/// 지그 아이템 데이터 모델
/// - 대부분의 속성은 불변(final)
/// - 좋아요 상태만 화면에서 토글 가능(likes, isLiked)
class JigItemData {
  // 사이즈 상수
  static const String sizeSmall = '소형';
  static const String sizeMedium = '중형';
  static const String sizeLarge = '대형';

  static const Set<String> allowedSizes = {sizeSmall, sizeMedium, sizeLarge};
  static const Map<String, int> sizeWeights = {
    sizeSmall: 1,
    sizeMedium: 3,
    sizeLarge: 5,
  };

  // 날짜 파서(유연)
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

  // ── 기본 정보 (불변) ────────────────────────────────────────────────
  /// 대표 썸네일(항상 존재)
  final String image;

  /// 원본 이미지 목록(최대 5장 가정). 비어 있으면 [image]만 사용된 이전 데이터일 수 있음.
  final List<String> images;

  /// 대표 썸네일이 가리키는 인덱스(0 기반). 유효 범위 자동 보정됨.
  final int thumbnailIndex;

  final String title;
  final String location;      // 예: '진량공장 B동 / L1 / 2층'
  final String description;
  final String registrant;
  final DateTime? storageDate;
  final DateTime? disposalDate;
  final String size;          // '소형' | '중형' | '대형'

  // ── 좋아요 상태 (가변 - UI 토글용) ───────────────────────────────────
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
    this.images = const [],
    this.thumbnailIndex = 0,
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

  /// 사이즈 → 포화도 가중치(소형 1, 중형 3, 대형 5)
  int get capacityWeight => sizeWeights[size] ?? 1;

  // ── 직렬화 ───────────────────────────────────────────────────────────
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
    // 1) 대표/목록/인덱스 로드
    final rawImage = (map['image'] ?? '') as String;
    final List<String> imgs = (map['images'] is List)
        ? (map['images'] as List)
        .whereType<String>()
        .where((e) => e.trim().isNotEmpty)
        .toList(growable: false)
        : const <String>[];

    int ti = (map['thumbnailIndex'] is int) ? map['thumbnailIndex'] as int : 0;

    // 2) 레거시/혼합 케이스 보정
    List<String> fixedImgs = imgs;
    String fixedImage = rawImage;

    if (fixedImgs.isEmpty) {
      // 예전 데이터: image만 있음
      if (fixedImage.trim().isNotEmpty) {
        fixedImgs = [fixedImage];
        ti = 0;
      } else {
        fixedImgs = const <String>[];
        ti = 0;
      }
    } else {
      // images가 존재하는 경우 thumbnailIndex 보정
      if (ti < 0 || ti >= fixedImgs.length) ti = 0;
      // image가 비어 있으면 대표를 동기화
      if (fixedImage.trim().isEmpty) {
        fixedImage = fixedImgs[ti];
      }
    }

    return JigItemData(
      image: fixedImage,
      images: fixedImgs,
      thumbnailIndex: ti,
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
