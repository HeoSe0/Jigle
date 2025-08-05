import 'package:flutter/material.dart';
import 'jig_item_data.dart';

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
      description: "LX3 진동&배광 지그",
      registrant: "전장램프설계6팀 최은석 사원",
    )
  ];

  String selectedLocation = '진량공장 2층';
  int selectedTab = 0; // 0: 홈

  void _showAddOrEditJigDialog({JigItemData? editItem, int? editIndex}) {
    String title = editItem?.title ?? '';
    String description = editItem?.description ?? '';
    String registrant = editItem?.registrant ?? '';
    DateTime? startDate;
    DateTime? endDate;
    String locationForJig = editItem?.location ?? selectedLocation;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setModalState) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(editItem == null ? "지그 등록" : "지그 수정",
                          style: const TextStyle(fontSize: 18, color: Colors.black)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    onPressed: () {},
                    child: const Text("사진 추가", style: TextStyle(color: Colors.black)),
                  ),
                  const SizedBox(height: 10),
                  const Text("제목", style: TextStyle(color: Colors.black)),
                  TextField(onChanged: (value) => title = value, controller: TextEditingController(text: title)),
                  const SizedBox(height: 10),
                  const Text("자세한 설명", style: TextStyle(color: Colors.black)),
                  TextField(
                    maxLines: 3,
                    onChanged: (value) => description = value,
                    controller: TextEditingController(text: description),
                  ),
                  const SizedBox(height: 10),
                  const Text("등록자", style: TextStyle(color: Colors.black)),
                  TextField(onChanged: (value) => registrant = value, controller: TextEditingController(text: registrant)),
                  const SizedBox(height: 10),
                  const Text("보관장소", style: TextStyle(color: Colors.black)),
                  Wrap(
                    spacing: 8,
                    children: [
                      '진량공장 2층', '배광실 2층', '본관 4층'
                    ].map((place) {
                      final isSelected = locationForJig == place;
                      return ChoiceChip(
                        label: Text(place, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                        selected: isSelected,
                        selectedColor: Colors.blue,
                        backgroundColor: Colors.white,
                        onSelected: (_) => setModalState(() => locationForJig = place),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  const Text("보관기한", style: TextStyle(color: Colors.black)),
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setModalState(() => startDate = picked);
                          }
                        },
                        child: Text(
                          startDate == null ? '보관날짜' : '${startDate!.year}-${startDate!.month}-${startDate!.day}',
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setModalState(() => endDate = picked);
                          }
                        },
                        child: Text(
                          endDate == null ? '폐기날짜' : '${endDate!.year}-${endDate!.month}-${endDate!.day}',
                          style: const TextStyle(color: Colors.black),
                        ),
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
                        selectedLocation = locationForJig;
                        if (editItem != null && editIndex != null) {
                          jigItems[editIndex] = JigItemData(
                            image: "jig_example1.jpg",
                            title: title,
                            location: locationForJig,
                            description: "${startDate?.toLocal().toString().split(' ')[0]} ~ ${endDate?.toLocal().toString().split(' ')[0]}\n$description",
                            registrant: registrant,
                          );
                        } else {
                          jigItems.add(JigItemData(
                            image: "jig_example1.jpg",
                            title: title,
                            location: locationForJig,
                            description: "${startDate?.toLocal()} ~ ${endDate?.toLocal()}\n$description",
                            registrant: registrant,
                          ));
                        }
                      });
                      Navigator.pop(context);
                    },
                    child: Text(editItem == null ? "작성 완료" : "수정 완료",
                        style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("삭제하시겠습니까?", style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("아니오", style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () {
              setState(() => jigItems.removeAt(index));
              Navigator.pop(ctx);
            },
            child: const Text("예", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
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
                setState(() => selectedLocation = value);
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
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: jigItems.length,
        itemBuilder: (context, index) {
          final item = jigItems[index];
          if (item.location != selectedLocation) return const SizedBox.shrink();
          return Stack(
            children: [
              JigItem(
                image: item.image,
                title: item.title,
                location: item.location,
                price: item.description,
                registrant: item.registrant,
                likes: item.likes,
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black),
                      onPressed: () => _showAddOrEditJigDialog(editItem: item, editIndex: index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () => _confirmDelete(index),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedTab,
        onTap: (index) {
          setState(() {
            selectedTab = index;
          });
        },
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
      floatingActionButton: selectedTab == 0
          ? OutlinedButton(
        onPressed: () => _showAddOrEditJigDialog(),
        style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
        child: const Text("+ 지그 등록"),
      )
          : null,
    );
  }
}

class JigItem extends StatelessWidget {
  final String image;
  final String title;
  final String location;
  final String price;
  final String registrant;
  final int likes;

  const JigItem({
    super.key,
    required this.image,
    required this.title,
    required this.location,
    required this.price,
    required this.registrant,
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
                Text("등록자: $registrant"),
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
