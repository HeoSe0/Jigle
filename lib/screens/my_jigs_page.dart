import 'package:flutter/material.dart';
import 'my_jig_screen.dart';
import 'my_sample_screen.dart';
import 'warehouse_screen.dart';
import 'admin_screen.dart';
import 'favorite_screen.dart';
import 'recent_screen.dart';
import 'event_screen.dart';

class MyJigsPage extends StatelessWidget {
  const MyJigsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 프로필 영역
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      '프로필',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // 메뉴 버튼 4개
            Container(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 4, //가로 : 세로 비율
                children: [
                  _buildMenuButton(context, '나의 지그', const MyJigScreen()),
                  _buildMenuButton(context, '나의 샘플', const MySampleScreen()),
                  _buildMenuButton(context, '창고 현황', const WarehouseScreen()),
                  _buildMenuButton(context, '관리자 설정', const AdminScreen()),
                ],
              ),
            ),

            // 하단 버튼 3개
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Row(
                children: [
                  _buildIconBox(context, Icons.favorite_border, '관심목록', const FavoriteScreen()),
                  _buildIconBox(context, Icons.history, '최근 본 글', const RecentScreen()),
                  _buildIconBox(context, Icons.star_border, '이벤트', const EventScreen()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 상단 네모 버튼 생성기
  Widget _buildMenuButton(BuildContext context, String label, Widget targetScreen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => targetScreen),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  // 하단 버튼 생성기 (비율 기반 크기 조정)
  Widget _buildIconBox(BuildContext context, IconData icon, String label, Widget targetScreen) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => targetScreen),
          );
        },
        child: AspectRatio(
          aspectRatio: 2, //가로 : 세로 비율
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
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
      ),
    );
  }
}