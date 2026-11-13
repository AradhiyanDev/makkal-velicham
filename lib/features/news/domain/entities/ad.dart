class Ad {
  final String id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final int displayInterval;

  Ad({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
    this.displayInterval = 5,
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      linkUrl: json['linkUrl'],
      displayInterval: json['displayInterval'] ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'linkUrl': linkUrl,
      'displayInterval': displayInterval,
    };
  }
}