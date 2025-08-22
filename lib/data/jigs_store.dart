// lib/data/jigs_store.dart
import 'package:flutter/foundation.dart';
import '../widgets/jig_item_data.dart';

/// 앱 전체 지그의 단일 소스(Single Source of Truth)
class JigsStore {
  static final ValueNotifier<List<JigItemData>> notifier =
  ValueNotifier<List<JigItemData>>(<JigItemData>[]);

  static List<JigItemData> get items => notifier.value;

  // ---------- 내부 유틸 ----------
  static int _findIndexById(List<JigItemData> list, String id) =>
      list.indexWhere((e) => e.id == id);

  static int _findIndex(List<JigItemData> list, JigItemData target) =>
      _findIndexById(list, target.id);

  static List<JigItemData> _clone(List<JigItemData> src) =>
      List<JigItemData>.from(src);

  static List<JigItemData> _dedupById(Iterable<JigItemData> src) {
    final seen = <String>{};
    final out = <JigItemData>[];
    for (final it in src) {
      if (seen.add(it.id)) out.add(it);
    }
    return out;
  }

  // ---------- CRUD ----------
  /// 최초 진입 1회 주입 (ID 기준 중복 제거)
  static void setInitial(List<JigItemData> initial) {
    if (items.isEmpty && initial.isNotEmpty) {
      notifier.value = _dedupById(initial);
    }
  }

  /// 존재하면 교체, 없으면 맨 앞에 추가 (ID 기준)
  static void upsert(JigItemData item) {
    final list = _clone(notifier.value);
    final i = _findIndex(list, item);
    if (i == -1) {
      list.insert(0, item);
    } else {
      // 좋아요 상태 보존
      final keep = list[i];
      list[i] = item.copyWith(likes: keep.likes, isLiked: keep.isLiked);
    }
    notifier.value = list;
  }

  /// 맨 앞에 추가 (단, 같은 ID가 이미 있으면 교체)
  static void add(JigItemData item) {
    final list = _clone(notifier.value);
    final i = _findIndex(list, item);
    if (i != -1) {
      final keep = list[i];
      list[i] = item.copyWith(likes: keep.likes, isLiked: keep.isLiked);
    } else {
      list.insert(0, item);
    }
    notifier.value = list;
  }

  /// 기존 항목 교체 (좋아요 상태 보존)
  static void replace(JigItemData oldItem, JigItemData updated) {
    final list = _clone(notifier.value);
    final i = _findIndex(list, oldItem);
    if (i != -1) {
      final keep = list[i];
      list[i] = updated.copyWith(likes: keep.likes, isLiked: keep.isLiked);
      notifier.value = list;
    }
  }

  /// ID로 교체 (좋아요 상태 보존)
  static void replaceById(String id, JigItemData updated) {
    final list = _clone(notifier.value);
    final i = _findIndexById(list, id);
    if (i != -1) {
      final keep = list[i];
      list[i] = updated.copyWith(id: keep.id, likes: keep.likes, isLiked: keep.isLiked);
      notifier.value = list;
    }
  }

  /// 삭제 (ID 기준)
  static void removeExact(JigItemData item) {
    final list = _clone(notifier.value);
    final i = _findIndex(list, item);
    if (i != -1) {
      list.removeAt(i);
      notifier.value = list;
    }
  }

  /// ID로 삭제
  static void removeById(String id) {
    final list = _clone(notifier.value);
    final i = _findIndexById(list, id);
    if (i != -1) {
      list.removeAt(i);
      notifier.value = list;
    }
  }

  // ---------- 좋아요 ----------
  /// 좋아요 토글(필요시 to=true/false로 강제 설정). ID 기준.
  static void toggleLike(JigItemData item, {bool? to}) {
    final list = _clone(notifier.value);
    final i = _findIndex(list, item);
    if (i == -1) return;

    final cur = list[i];
    final nextIsLiked = to ?? !cur.isLiked;
    var nextLikes = cur.likes;
    if (nextIsLiked && !cur.isLiked) nextLikes++;
    if (!nextIsLiked && cur.isLiked) nextLikes = nextLikes > 0 ? nextLikes - 1 : 0;

    // 가변 필드 업데이트
    cur.isLiked = nextIsLiked;
    cur.likes = nextLikes;

    notifier.value = _clone(list); // 리스너 트리거
  }

  static void setLike(JigItemData item, bool value) => toggleLike(item, to: value);

  /// 현재 스토어에서 좋아요된 항목 목록 (필요 시 정렬 추가 가능)
  static List<JigItemData> get likedItems =>
      items.where((e) => e.isLiked).toList();

  // ========= (옵션) 화면 Notifier 미러 =========
  static final Set<ValueNotifier<List<JigItemData>>> _mirrors = {};
  static final Map<ValueNotifier<List<JigItemData>>, VoidCallback> _storeToMirror = {};
  static final Map<ValueNotifier<List<JigItemData>>, VoidCallback> _mirrorToStore = {};
  static bool _syncing = false;

  /// 화면의 ValueNotifier를 전역과 묶는다.
  static void attachMirror(ValueNotifier<List<JigItemData>> vn, {bool seedFromStore = true}) {
    if (_mirrors.contains(vn)) return;
    _mirrors.add(vn);

    if (seedFromStore) {
      vn.value = _clone(notifier.value);
    }

    void pullFromStore() {
      if (_syncing) return;
      _syncing = true;
      try {
        vn.value = _clone(notifier.value);
      } finally {
        _syncing = false;
      }
    }

    void pushToStore() {
      if (_syncing) return;
      _syncing = true;
      try {
        notifier.value = _clone(vn.value);
      } finally {
        _syncing = false;
      }
    }

    _storeToMirror[vn] = pullFromStore;
    _mirrorToStore[vn] = pushToStore;

    notifier.addListener(pullFromStore);
    vn.addListener(pushToStore);
  }

  /// 미러 해제(화면 dispose 시)
  static void detachMirror(ValueNotifier<List<JigItemData>> vn) {
    if (!_mirrors.remove(vn)) return;
    final a = _storeToMirror.remove(vn);
    final b = _mirrorToStore.remove(vn);
    if (a != null) notifier.removeListener(a);
    if (b != null) vn.removeListener(b);
  }
}
