// lib/widgets/jig_item_data.dart
import 'dart:convert';

/// 지그 아이템 데이터 모델 (다중 이미지 + 대표 썸네일 지원)
class JigItemData {
  // ===== 사이즈 상수 & 가중치 =====
  static const String sizeSmall = '소형';
  static const String sizeMedium = '중형';
  static const String sizeLarge = '대형';
  static const Set<String> allowedSizes = {sizeSmall, sizeMedium, sizeLarge};
  static const Map<String, int> sizeWeights = {
    sizeSmall: 1,
    sizeMedium: 3,
    sizeLarge: 5,
  };

  // ===== 지그 높이 상수 =====
  static const String heightLt30 = '30cm 미만';
  static const String heightLt50 = '50cm 미만';
  static const String heightGte50 = '50cm 이상';
  static const Set<String> allowedHeights = {
    heightLt30, heightLt50, heightGte50
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

  // ===== 기본 정보 (불변) =====
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

  /// 선택: 지그 높이(미선택 가능)
  final String? jigHeight;

  // ===== 좋아요 상태 (가변 - UI 토글용) =====
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
    this.jigHeight,
    this.likes = 0,
    this.isLiked = false,
  })  : assert(image.isNotEmpty, 'image는 비어 있을 수 없습니다.'),
        assert(title.isNotEmpty, 'title은 비어 있을 수 없습니다.'),
        assert(location.isNotEmpty, 'location은 비어 있을 수 없습니다.'),
        assert(allowedSizes.contains(size), 'size는 소형/중형/대형만 허용됩니다.'),
        assert(jigHeight == null || allowedHeights.contains(jigHeight),
        'jigHeight는 30cm 미만/50cm 미만/50cm 이상 중 하나여야 합니다.');

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
    String? jigHeight,
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
      jigHeight: jigHeight ?? this.jigHeight,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  /// 사이즈 → 포화도 가중치
  int get capacityWeight => sizeWeights[size] ?? 1;

  /// 높이 선택 여부
  bool get hasJigHeight => (jigHeight != null && jigHeight!.trim().isNotEmpty);

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
    'jigHeight': jigHeight,
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

    String? jh;
    final jhRaw = map['jigHeight'];
    if (jhRaw is String) {
      final t = jhRaw.trim();
      if (t.isNotEmpty && allowedHeights.contains(t)) jh = t;
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
      jigHeight: jh,
      likes: (map['likes'] ?? 0) as int,
      isLiked: (map['isLiked'] ?? false) as bool,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory JigItemData.fromJson(String source) =>
      JigItemData.fromMap(jsonDecode(source) as Map<String, dynamic>);

  // ===== 공통 높이 정책 (새 파일 없이 통합) =====
  /// 현재 위치/슬롯/층에서 허용되는 지그 높이 옵션을 반환
  /// - 진량공장 B동: L1/C1/R1
  ///   - 1~3층: 30/50 미만 허용
  ///   - 4층:   무제한(세 옵션 모두 허용)
  /// - F1~F4: 전부 허용
  /// - 그 외 건물: 전부 허용
  static List<String> resolveHeightOptions(String location, String? slot, String? floor) {
    final parent = location.split('/').first.trim();

    String? normFloor;
    if (floor != null && floor.trim().isNotEmpty) {
      final m = RegExp(r'(\d+)').firstMatch(floor);
      if (m != null) normFloor = '${m.group(1)}층';
    }

    if (parent == '진량공장 B동') {
      if (slot == 'L1' || slot == 'C1' || slot == 'R1') {
        switch (normFloor) {
          case '1층':
          case '2층':
          case '3층':
            return const [heightLt30, heightLt50];
          case '4층':
            return const [heightLt30, heightLt50, heightGte50];
          default:
            return const [heightLt30, heightLt50, heightGte50];
        }
      }
      // F1~F4
      return const [heightLt30, heightLt50, heightGte50];
    }

    // 배광시험동/후생동 등: 규칙 정의 전까지 전부 허용
    return const [heightLt30, heightLt50, heightGte50];
  }
}
