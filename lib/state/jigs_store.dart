import 'package:flutter/foundation.dart';
import '../widgets/jig_item_data.dart';

/// 앱 전체에서 공유하는 지그 저장소 (간단한 전역 ValueNotifier)
class JigsStore {
  JigsStore._();
  static final ValueNotifier<List<JigItemData>> notifier =
  ValueNotifier<List<JigItemData>>(<JigItemData>[]);

  static List<JigItemData> get items => notifier.value;

  /// 초기값 세팅(앱 시작 시 한번 필요하면 사용)
  static void setInitial(List<JigItemData> initial) {
    notifier.value = List<JigItemData>.from(initial);
  }

  /// 등록
  static void add(JigItemData item) {
    notifier.value = [...notifier.value, item];
  }

  /// 수정(동일 id 개념이 있다면 거기에 맞게 교체)
  static void replaceWhere(bool Function(JigItemData) test, JigItemData newItem) {
    final next = List<JigItemData>.from(notifier.value);
    final idx = next.indexWhere(test);
    if (idx >= 0) {
      next[idx] = newItem;
      notifier.value = next;
    }
  }

  /// 삭제 (필요 시)
  static void removeWhere(bool Function(JigItemData) test) {
    notifier.value = notifier.value.where((e) => !test(e)).toList();
  }
}