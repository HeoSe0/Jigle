import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jigle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Pretendard-M'),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'jigle_logo.png',
                width: 200,
                height: 200,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JigItemData {
  final String image;
  final String title;
  final String location;
  final String description;
  final int likes;

  JigItemData({
    required this.image,
    required this.title,
    required this.location,
    required this.description,
    this.likes = 0,
  });
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<JigItemData> jigItems = [
    JigItemData(
      image: "jig_example1.jpg",
      title: "LX3 진동&배광 지그 1대분",
      location: "진량공장 2층",
      description: "전장램프설계6팀 최은석 사원",
    )
  ];

  String selectedLocation = '진량공장 2층';

  void _showAddJigDialog() {
    String title = '';
    String description = '';
    DateTime? startDate;
    DateTime? endDate;
    String currentLocation = selectedLocation;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white, // ✅ 흰 배경 추가
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text("지그 등록", style: TextStyle(fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: () {}, child: const Text("사진 추가")),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: "제목"),
                  onChanged: (value) => title = value,
                ),
                const SizedBox(height: 10),
                TextField(
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "자세한 설명",
                    alignLabelWithHint: true,
                  ),
                  onChanged: (value) => description = value,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("보관기한:"),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => startDate = picked);
                        }
                      },
                      child: Text(startDate == null
                          ? '보관날짜'
                          : '${startDate!.year}-${startDate!.month}-${startDate!.day}'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => endDate = picked);
                        }
                      },
                      child: Text(endDate == null
                          ? '폐기날짜'
                          : '${endDate!.year}-${endDate!.month}-${endDate!.day}'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent,
                    minimumSize: const Size.fromHeight(40),
                  ),
                  onPressed: () {
                    setState(() {
                      jigItems.add(JigItemData(
                        image: "jig_example1.jpg",
                        title: title,
                        location: currentLocation,
                        description:
                        "${startDate?.toLocal()} ~ ${endDate?.toLocal()}\n$description",
                      ));
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("작성 완료"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Text(selectedLocation),
            PopupMenuButton<String>(
              icon: const Icon(Icons.keyboard_arrow_down),
              onSelected: (String value) {
                setState(() {
                  selectedLocation = value;
                });
              },
              itemBuilder: (BuildContext context) => const [
                PopupMenuItem(value: '진량공장 2층', child: Text('진량공장 2층')),
                PopupMenuItem(value: '배광실 2층', child: Text('배광실 2층')),
                PopupMenuItem(value: '본관 4층', child: Text('본관 4층')),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade200,
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          for (var item in jigItems)
            if (item.location == selectedLocation) // ✅ 해당 장소 필터링
              JigItem(
                image: item.image,
                title: item.title,
                location: item.location,
                price: item.description,
                likes: item.likes,
              ),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: _showAddJigDialog,
              style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text("+ 지그 등록"),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: "지도"),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "나의 지그"),
          ],
        ),
      ),
    );
  }
}

class JigItem extends StatelessWidget {
  final String image;
  final String title;
  final String location;
  final String price;
  final int likes;

  const JigItem({
    super.key,
    required this.image,
    required this.title,
    required this.location,
    required this.price,
    this.likes = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Image.asset(image, width: 100, height: 100, fit: BoxFit.cover),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(location),
                Text(price),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.favorite, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('$likes'),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
