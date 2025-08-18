// lib/screens/my_jigs_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ ValueListenable

import '../my_jig_page/my_jig_screen.dart';
import '../my_jig_page/my_sample_screen.dart';
import '../my_jig_page/warehouse_screen.dart';
import '../my_jig_page/admin_screen.dart';
import '../my_jig_page/recent_screen.dart';
import '../my_jig_page/event_screen.dart';

import '../widgets/jig_item_data.dart';
import '../widgets/jig_item.dart';
import '../widgets/jig_form_bottom_sheet.dart'; // ✅ 수정 폼 추가

class MyJigsPage extends StatelessWidget {
  const MyJigsPage({
    super.key,
    required this.likedItems,
    required this.jigsNotifier, // ✅ 전체 지그 목록
  });

  final List<JigItemData> likedItems;
  final ValueListenable<List<JigItemData>> jigsNotifier;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ProfileHeader(),
              const SizedBox(height: 8),
              // 동적 위젯이라 const 제거
              MenuGrid(
                items: [
                  const _MenuSpec('나의 지그', MyJigScreen()),
                  const _MenuSpec('나의 샘플', MySampleScreen()),
                  // ✅ WarehouseScreen에 전체 지그 전달
                  _MenuSpec('창고 현황', WarehouseScreen(allItems: jigsNotifier.value)),
                  const _MenuSpec('관리자 설정', AdminScreen()),
                ],
              ),
              const SizedBox(height: 6),
              QuickActions(
                // ✅ 관심목록 화면에 jigsNotifier도 넘겨서 저장 시 전체 목록 동기화
                onTapLiked: () => _push(context, LikedJigsScreen(
                  likedItems: likedItems,
                  jigsNotifier: jigsNotifier,
                )),
                onTapRecent: () => _push(context, const RecentScreen()),
                onTapEvent: () => _push(context, const EventScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

/* -------------------------- sub widgets -------------------------- */

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text('프로필', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
        ],
      ),
    );
  }
}

class MenuGrid extends StatelessWidget {
  const MenuGrid({super.key, required this.items});
  final List<_MenuSpec> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 4,
        ),
        itemBuilder: (_, i) => _MenuButton(label: items[i].label, target: items[i].screen),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.label, required this.target});
  final String label;
  final Widget target;

  @override
  Widget build(BuildContext context) {
    return _CardButton(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => target)),
      child: Center(child: Text(label, style: const TextStyle(fontSize: 16))),
    );
  }
}

class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.onTapLiked,
    required this.onTapRecent,
    required this.onTapEvent,
  });

  final VoidCallback onTapLiked;
  final VoidCallback onTapRecent;
  final VoidCallback onTapEvent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Row(
        children: [
          _IconBox(icon: Icons.favorite_border, label: '관심목록', onTap: onTapLiked),
          _IconBox(icon: Icons.history, label: '최근 본 글', onTap: onTapRecent),
          _IconBox(icon: Icons.star_border, label: '공지사항', onTap: onTapEvent),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 2,
        child: _CardButton(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(12);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: border,
          border: Border.all(color: Colors.grey.shade400, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              offset: const Offset(2, 2),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/* -------------------------- liked list screen (수정 가능) -------------------------- */

class LikedJigsScreen extends StatefulWidget {
  const LikedJigsScreen({
    super.key,
    required this.likedItems,
    required this.jigsNotifier, // ✅ 전체 목록 동기화용
  });

  final List<JigItemData> likedItems;
  final ValueListenable<List<JigItemData>> jigsNotifier;

  @override
  State<LikedJigsScreen> createState() => _LikedJigsScreenState();
}

class _LikedJigsScreenState extends State<LikedJigsScreen> {
  // 이 화면에서 즉시 반영되도록 로컬 상태로 관리
  late final ValueNotifier<List<JigItemData>> _likedVN =
  ValueNotifier<List<JigItemData>>(List<JigItemData>.from(widget.likedItems));

  JigItemData _withPreservedLike({required JigItemData edited, required JigItemData old}) =>
      edited.copyWith(likes: old.likes, isLiked: old.isLiked);

  void _openEdit(BuildContext context, JigItemData item, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => JigFormBottomSheet(
        editItem: item,
        onSubmit: (newJig) {
          final updated = _withPreservedLike(edited: newJig, old: item);

          // 1) 관심목록(로컬) 갱신
          final list = List<JigItemData>.from(_likedVN.value);
          list[index] = updated;
          _likedVN.value = list;

          // 2) 전체 목록 동기화 (가능한 경우)
          final ln = widget.jigsNotifier;
          if (ln is ValueNotifier<List<JigItemData>>) {
            final all = List<JigItemData>.from(ln.value);
            // 우선 참조 동일성으로 찾고, 없으면 타이틀/위치로 매칭
            int gi = all.indexOf(item);
            if (gi == -1) {
              gi = all.indexWhere((e) =>
              e.title == item.title &&
                  e.location == item.location &&
                  e.registrant == item.registrant);
            }
            if (gi != -1) {
              all[gi] = _withPreservedLike(edited: newJig, old: all[gi]);
              ln.value = all;
            }
          }

          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('관심 지그', style: TextStyle(color: Colors.black)),
      ),
      body: ValueListenableBuilder<List<JigItemData>>(
        valueListenable: _likedVN,
        builder: (_, likedItems, __) {
          if (likedItems.isEmpty) {
            return const _EmptyLikedState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: likedItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final item = likedItems[index];
              return Stack(
                children: [
                  JigItem(
                    image: item.image,
                    title: item.title,
                    location: item.location,
                    price: item.description,
                    registrant: item.registrant,
                    likes: item.likes,
                    isLiked: item.isLiked,
                    storageDate: item.storageDate,
                    disposalDate: item.disposalDate,
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      tooltip: '수정',
                      icon: const Icon(Icons.edit, color: Colors.black),
                      onPressed: () => _openEdit(context, item, index),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyLikedState extends StatelessWidget {
  const _EmptyLikedState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.favorite_border, size: 48),
            SizedBox(height: 12),
            Text('아직 관심목록이 비어 있어요.'),
            SizedBox(height: 4),
            Text('지그 상세에서 ❤ 를 눌러 추가해 보세요.'),
          ],
        ),
      ),
    );
  }
}

/* -------------------------- utils -------------------------- */

class _MenuSpec {
  const _MenuSpec(this.label, this.screen);
  final String label;
  final Widget screen;
}
