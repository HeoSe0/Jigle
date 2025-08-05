class JigItemData {
  final String image;
  String title;
  String location;
  String description;
  String registrant;
  int likes;

  JigItemData({
    required this.image,
    required this.title,
    required this.location,
    required this.description,
    required this.registrant,
    this.likes = 0,
  });
}
