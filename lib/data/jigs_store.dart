import 'package:flutter/foundation.dart';
import '../widgets/jig_item_data.dart';

/// 앱 전체 지그의 단일 소스(Single Source of Truth)
class JigsStore {
  static final ValueNotifier<List<JigItemData>> notifier =
  ValueNotifier<List<JigItemData>>(<JigItemData>[]);

  static List<JigItemData> get items => notifier.value;

  /// 최초 진입 시 1회 주입
  static void setInitial(List<JigItemData> initial) {
    if (items.isEmpty && initial.isNotEmpty) {
      notifier.value = List<JigItemData>.from(initial);
    }
  }

  /// 추가
  static void add(JigItemData item) {
    notifier.value = <JigItemData>[item, ...notifier.value];
  }

  /// 교체(좋아요 상태 보존)
  static void replace(JigItemData oldItem, JigItemData updated) {
    final list = List<JigItemData>.from(notifier.value);
    int i = list.indexOf(oldItem);
    if (i == -1) {
      i = list.indexWhere((e) =>
      e.title == oldItem.title &&
          e.location == oldItem.location &&
          e.registrant == oldItem.registrant);
    }
    if (i != -1) {
      final keep = list[i];
      list[i] = updated.copyWith(likes: keep.likes, isLiked: keep.isLiked);
      notifier.value = list;
    }
  }

  /// 삭제(동일 객체 기준)
  static void removeExact(JigItemData item) {
    final list = List<JigItemData>.from(notifier.value);
    list.remove(item);
    notifier.value = list;
  }

  // ========= 화면 Notifier와 양방향 미러 =========
  static final Set<ValueNotifier<List<JigItemData>>> _mirrors = {};
  static final Map<ValueNotifier<List<JigItemData>>, VoidCallback> _storeToMirror = {};
  static final Map<ValueNotifier<List<JigItemData>>, VoidCallback> _mirrorToStore = {};
  static bool _syncing = false;

  /// 화면의 ValueNotifier를 전역과 묶는다.
  static void attachMirror(ValueNotifier<List<JigItemData>> vn, {bool seedFromStore = true}) {
    if (_mirrors.contains(vn)) return;
    _mirrors.add(vn);

    if (seedFromStore) {
      vn.value = List<JigItemData>.from(notifier.value);
    }

    void pullFromStore() {
      if (_syncing) return;
      _syncing = true;
      try {
        vn.value = List<JigItemData>.from(notifier.value);
      } finally {
        _syncing = false;
      }
    }

    void pushToStore() {
      if (_syncing) return;
      _syncing = true;
      try {
        notifier.value = List<JigItemData>.from(vn.value);
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
