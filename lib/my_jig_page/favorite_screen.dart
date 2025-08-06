import 'package:flutter/material.dart';
import '../my_jig_page/my_jig_screen.dart';
import '../my_jig_page/my_sample_screen.dart';
import '../my_jig_page/warehouse_screen.dart';
import '../my_jig_page/admin_screen.dart';
import '../my_jig_page/recent_screen.dart';
import '../my_jig_page/event_screen.dart';
import '../widgets/jig_item_data.dart';
import '../widgets/jig_item.dart';

class MyJigsPage extends StatelessWidget {
  final List<JigItemData> likedItems;

  const MyJigsPage({super.key, required this.likedItems});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
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
            Container(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 4,
                children: [
                  _buildMenuButton(context, '나의 지그', const MyJigScreen()),
                  _buildMenuButton(context, '나의 샘플', const MySampleScreen()),
                  _buildMenuButton(context, '창고 현황', const WarehouseScreen()),
                  _buildMenuButton(context, '관리자 설정', const AdminScreen()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Row(
                children: [
                  _buildIconBox(context, Icons.favorite_border, '관심목록', _buildLikedListScreen(context)),
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

  Widget _buildLikedListScreen(BuildContext context) {
    return Theme(
      data: ThemeData(scaffoldBackgroundColor: Colors.white),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text("관심 지그", style: TextStyle(color: Colors.black)),
        ),
        body: Container(
          color: Colors.white,
          child: ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: likedItems.length,
            itemBuilder: (context, index) {
              final item = likedItems[index];
              return Container(
                color: Colors.white,
                child: JigItem(
                  image: item.image,
                  title: item.title,
                  location: item.location,
                  price: item.description,
                  registrant: item.registrant,
                  likes: item.likes,
                  isLiked: item.isLiked,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

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
          aspectRatio: 2,
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