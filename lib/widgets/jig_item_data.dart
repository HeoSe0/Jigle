// lib/widgets/jig_item_data.dart
import 'dart:convert';
import 'dart:math';

/// 지그 아이템 데이터 모델 (다중 이미지 + 대표 썸네일 지원, ID 기반 단일키)
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

  // ===== 내부: ID 생성기 =====
  static final Random _rand = Random();
  static const int _randMax = 0x3fffffff; // 2^30-1 (웹에서도 안전)
  static String _genId() {
    final t = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final r1 = _rand.nextInt(_randMax).toRadixString(36);
    final r2 = _rand.nextInt(_randMax).toRadixString(36);
    return 'j_${t}_$r1$r2';
  }

  // ===== 유틸: 안전 파싱/정규화 =====
  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is int) {
      final isSeconds = v.abs() < 100000000000;
      return isSeconds
          ? DateTime.fromMillisecondsSinceEpoch(v * 1000)
          : DateTime.fromMillisecondsSinceEpoch(v);
    }
    if (v is String) {
      final t = v.trim();
      if (t.isEmpty) return null;
      final n = int.tryParse(t);
      if (n != null) return _parseDate(n);
      return DateTime.tryParse(t);
    }
    return null;
  }

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v.trim()) ?? fallback;
    return fallback;
  }

  static bool _toBool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true' || t == '1' || t == 'yes') return true;
      if (t == 'false' || t == '0' || t == 'no') return false;
    }
    if (v is num) return v != 0;
    return fallback;
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
    return List.unmodifiable(out.take(maxImages).toList());
  }

  static List<String> _parseImagesFlexible(dynamic raw) {
    if (raw is List) {
      final tmp = <String>[];
      for (final e in raw) {
        if (e is String && e.trim().isNotEmpty) tmp.add(e.trim());
      }
      return tmp;
    }
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
        } catch (_) {/* ignore */}
      }
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

  static String _norm(String? s) => (s ?? '').trim();

  // ===== 식별자(불변) =====
  final String id;

  // ===== 기본 정보 (불변) =====
  final String image;
  final List<String> images;
  final int thumbnailIndex;
  final String title;
  final String location;   // 예: '진량공장 B동 / L1 / 2층' 또는 '배광시험동 2층 / R3 / 2층'
  final String description;
  final String registrant;
  final DateTime? storageDate;
  final DateTime? disposalDate;
  final String size;       // '소형' | '중형' | '대형'
  final String? jigHeight; // 선택: 지그 높이

  // ===== 좋아요 상태 (가변) =====
  int likes;
  bool isLiked;

  JigItemData({
    String? id,
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
  })  : id = id ?? _genId(),
        assert(title.isNotEmpty, 'title은 비어 있을 수 없습니다.'),
        assert(location.isNotEmpty, 'location은 비어 있을 수 없습니다.'),
        size = (allowedSizes.contains(_norm(size)) ? _norm(size) : sizeSmall),
        images = (() {
          final normalized = _normalizeImages(images, image);
          return normalized;
        })(),
        thumbnailIndex = (() {
          final normalized = _normalizeImages(images, image);
          return _safeIndex(thumbnailIndex, normalized.length);
        })(),
        image = (() {
          final normalized = _normalizeImages(images, image);
          final idx = _safeIndex(thumbnailIndex, normalized.length);
          return normalized.isNotEmpty ? normalized[idx] : image;
        })(),
        assert(
        jigHeight == null || allowedHeights.contains(_norm(jigHeight)),
        'jigHeight는 30cm 미만/50cm 미만/50cm 이상 중 하나여야 합니다.',
        );

  JigItemData copyWith({
    String? id,
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

    final seedImage = image ?? this.image;
    final normalized = _normalizeImages(images ?? this.images, seedImage);
    final safeThumb =
    _safeIndex(thumbnailIndex ?? this.thumbnailIndex, normalized.length);
    final rep = normalized.isNotEmpty ? normalized[safeThumb] : seedImage;

    return JigItemData(
      id: id ?? this.id, // ✅ ID 보존
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
    'id': id,
    'image': representativeImage,
    'images': images,
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
    final rawImage = (map['image'] ?? '').toString();
    final parsed = _parseImagesFlexible(map['images']);
    final normalized = _normalizeImages(parsed, rawImage);

    final safeThumb =
    _safeIndex(_toInt(map['thumbnailIndex'], fallback: 0), normalized.length);

    final rep = normalized.isNotEmpty
        ? normalized[safeThumb]
        : (rawImage.isNotEmpty ? rawImage : '');

    String? jh;
    final jhRaw = map['jigHeight'];
    if (jhRaw is String) {
      final t = _norm(jhRaw);
      if (t.isNotEmpty && allowedHeights.contains(t)) jh = t;
    }

    final rawSize = _norm(map['size']?.toString() ?? sizeSmall);
    final safeSize = allowedSizes.contains(rawSize) ? rawSize : sizeSmall;

    // ✅ ID가 없으면 새로 생성
    final rawId = (map['id'] as String?)?.trim();
    final id = (rawId == null || rawId.isEmpty) ? _genId() : rawId;

    return JigItemData(
      id: id,
      image: rep,
      images: normalized,
      thumbnailIndex: safeThumb,
      title: (map['title'] ?? '').toString(),
      location: (map['location'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      registrant: (map['registrant'] ?? '').toString(),
      storageDate: _parseDate(map['storageDate']),
      disposalDate: _parseDate(map['disposalDate']),
      size: safeSize,
      jigHeight: jh,
      likes: _toInt(map['likes'], fallback: 0),
      isLiked: _toBool(map['isLiked'], fallback: false),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory JigItemData.fromJson(String source) =>
      JigItemData.fromMap(jsonDecode(source) as Map<String, dynamic>);

  // ===== 공통 높이 정책 =====
  /// 현재 위치/슬롯/층에서 허용되는 지그 높이 옵션
  /// - 배광시험동: 1~4층만 존재 → 층/슬롯 무관하게 항상 30/50 미만 (2가지 허용)
  /// - 진량공장 B동: L1/C1/R1
  ///   - 1~3층: 30/50 미만 허용
  ///   - 4층:   30/50 미만 + 50 이상 허용
  /// - 그 외 건물: 전부 허용
  static List<String> resolveHeightOptions(
      String location, String? slot, String? floor) {
    final parent =
    _norm(location).split('/').first.replaceFirst(RegExp(r'\s*\d+층$'), '');
    final s = _norm(slot);
    final f = _norm(floor);

    String? normFloor;
    if (f.isNotEmpty) {
      final m = RegExp(r'(\d+)').firstMatch(f);
      if (m != null) normFloor = '${m.group(1)}층';
    }

    // 배광시험동: 항상 2가지 허용
    if (parent == '배광시험동') {
      return const [heightLt30, heightLt50];
    }

    // 진량공장 B동
    if (parent == '진량공장 B동') {
      if (s == 'L1' || s == 'C1' || s == 'R1') {
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

    // 기본
    return const [heightLt30, heightLt50, heightGte50];
  }

  /// 현재 위치/슬롯/층/선택 높이에 대해 경고 문자열 계산
  static String? resolveHeightWarning(
      String location, String? slot, String? floor, String? jigHeight) {
    final jh = _norm(jigHeight);
    if (jh.isEmpty) return null;

    final allowed = resolveHeightOptions(location, slot, floor);
    if (allowed.contains(jh)) return null;

    if (jh == heightGte50) {
      return '현재 위치에서는 50cm 이상 지그 보관이 어려울 수 있어요. 직접 확인이 필요해요.';
    }
    return '현재 위치에서 허용되지 않는 높이일 수 있어요';
  }

  // ===== 동등성: ID 기준 =====
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is JigItemData && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'JigItemData(id: $id, title: $title, location: $location, size: $size, '
          'jigHeight: $jigHeight, images: ${images.length}, likes: $likes, liked: $isLiked)';
}
