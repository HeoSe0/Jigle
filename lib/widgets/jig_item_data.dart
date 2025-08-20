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

  // ===== 이미지 제한 =====
  static const int maxImages = 5;

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

  // --- images 정규화 ---
  static List<String> _normalizeImages(List<String>? images, String image) {
    final out = <String>[];

    void addOne(String s) {
      final t = s.trim();
      if (t.isNotEmpty && !out.contains(t)) out.add(t);
    }

    if (images != null) {
      for (final e in images) {
        if (e is String) addOne(e);
      }
    }
    addOne(image); // 대표 이미지를 항상 포함

    // 최대 장수 제한
    return List.unmodifiable(out.take(maxImages).toList());
  }

  static List<String> _parseImagesFlexible(dynamic raw) {
    // 1) 이미 List<String>
    if (raw is List) {
      final tmp = <String>[];
      for (final e in raw) {
        if (e is String && e.trim().isNotEmpty) tmp.add(e.trim());
      }
      return tmp;
    }
    // 2) JSON 문자열 (예: '["a","b"]')
    if (raw is String && raw.trim().isNotEmpty) {
      final s = raw.trim();
      if (s.startsWith('[')) {
        try {
          final decoded = jsonDecode(s);
          if (decoded is List) {
            return decoded
                .whereType<String>()
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
        } catch (_) {/* fallthrough */}
      }
      // 3) CSV 문자열 (예: 'a,b,c')
      return s
          .split(RegExp(r'[,\n;]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  static int _safeIndex(int i, int len) {
    if (len <= 0) return 0;
    if (i < 0) return 0;
    if (i >= len) return len - 1;
    return i;
  }

  // ===== 기본 정보 (불변) =====
  final String image;            // 대표 썸네일(= images[thumbnailIndex])
  final List<String> images;     // 전체 이미지
  final int thumbnailIndex;      // 대표 인덱스(0~)
  final String title;
  final String location;         // 예: '진량공장 B동 / L1 / 2층'
  final String description;
  final String registrant;
  final DateTime? storageDate;
  final DateTime? disposalDate;
  final String size;             // '소형' | '중형' | '대형'
  final String? jigHeight;       // 선택: 지그 높이(미선택 가능)

  // ===== 좋아요 상태 (가변 - UI 토글용) =====
  int likes;
  bool isLiked;

  JigItemData({
    required String image,
    List<String>? images,
    int thumbnailIndex = 0,
    required this.title,
    required this.location,
    required this.description,
    required this.registrant,
    required String size,
    this.storageDate,
    this.disposalDate,
    this.jigHeight,
    this.likes = 0,
    this.isLiked = false,
  })  : assert(title.isNotEmpty, 'title은 비어 있을 수 없습니다.'),
        assert(location.isNotEmpty, 'location은 비어 있을 수 없습니다.'),
        size = (allowedSizes.contains(size) ? size : sizeSmall),
  // 1차 정규화
        images = _normalizeImages(images, image),
  // 2차: 대표 인덱스 보정
        thumbnailIndex = _safeIndex(thumbnailIndex, _normalizeImages(images, image).length),
  // 3차: 대표 이미지 동기화(항상 images[thumbnailIndex]와 동일하게 유지)
        image = _normalizeImages(images, image).isNotEmpty
            ? _normalizeImages(images, image)[_safeIndex(thumbnailIndex, _normalizeImages(images, image).length)]
            : image,
  // 높이 검증(널 허용)
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
    final nextTitle = title ?? this.title;
    final nextLocation = location ?? this.location;
    final nextSize = size ?? this.size;

    // 대표/목록/인덱스 일관성 유지
    final seedImage = image ?? this.image;
    final normalized = _normalizeImages(images ?? this.images, seedImage);
    final safeThumb = _safeIndex(thumbnailIndex ?? this.thumbnailIndex, normalized.length);
    final rep = normalized.isNotEmpty ? normalized[safeThumb] : seedImage;

    return JigItemData(
      image: rep,
      images: normalized,
      thumbnailIndex: safeThumb,
      title: nextTitle,
      location: nextLocation,
      description: description ?? this.description,
      registrant: registrant ?? this.registrant,
      storageDate: storageDate ?? this.storageDate,
      disposalDate: disposalDate ?? this.disposalDate,
      size: nextSize,
      jigHeight: jigHeight ?? this.jigHeight,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  /// 사이즈 → 포화도 가중치
  int get capacityWeight => sizeWeights[size] ?? 1;

  /// 높이 선택 여부
  bool get hasJigHeight => (jigHeight != null && jigHeight!.trim().isNotEmpty);

  /// 최소 1장 보장 갤러리
  List<String> get gallery => images.isNotEmpty ? images : [image];

  /// 대표 이미지(= gallery[thumbnailIndex] 보정)
  String get representativeImage =>
      gallery[_safeIndex(thumbnailIndex, gallery.length)];

  /// 총 이미지 수
  int get imagesCount => gallery.length;

  Map<String, dynamic> toMap() => {
    // 항상 대표 인덱스의 이미지를 image로 내보냄(카드/리스트 하위호환)
    'image': representativeImage,
    'images': images, // 대표 포함된 배열(중복 제거/최대 5장)
    'thumbnailIndex': _safeIndex(thumbnailIndex, images.length),
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
    final rawImage = (map['image'] ?? '') as String;

    // 유연 파싱: List / JSON String / CSV String
    final parsed = _parseImagesFlexible(map['images']);
    var normalized = _normalizeImages(parsed, rawImage);

    // 썸네일 인덱스 보정
    final rawThumb = (map['thumbnailIndex'] ?? 0);
    final safeThumb = _safeIndex(
      (rawThumb is int) ? rawThumb : int.tryParse('$rawThumb') ?? 0,
      normalized.length,
    );

    // 대표 이미지 확정: DB의 image가 비어 있어도 safe하게 선택
    final rep = normalized.isNotEmpty
        ? normalized[safeThumb]
        : (rawImage.isNotEmpty ? rawImage : '');

    // 높이 파싱 검증
    String? jh;
    final jhRaw = map['jigHeight'];
    if (jhRaw is String) {
      final t = jhRaw.trim();
      if (t.isNotEmpty && allowedHeights.contains(t)) jh = t;
    }

    final rawSize = (map['size'] ?? sizeSmall) as String;
    final safeSize = allowedSizes.contains(rawSize) ? rawSize : sizeSmall;

    return JigItemData(
      image: rep,
      images: normalized,
      thumbnailIndex: safeThumb,
      title: (map['title'] ?? '') as String,
      location: (map['location'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      registrant: (map['registrant'] ?? '') as String,
      storageDate: _parseDate(map['storageDate']),
      disposalDate: _parseDate(map['disposalDate']),
      size: safeSize,
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
      return const [heightLt30, heightLt50, heightGte50];
    }
    return const [heightLt30, heightLt50, heightGte50];
  }
}
