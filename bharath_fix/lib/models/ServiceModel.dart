class ServiceModel {
  final String id;
  final String name;
  final String description;
  final String price;
  final String intentMode;
  final String bannerImage;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.intentMode,
    required this.bannerImage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'intentMode': intentMode,
      'bannerImage': bannerImage,
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: map['price'] ?? '',
      intentMode: map['intentMode'] ?? '',
      bannerImage: map['bannerImage'] ?? '',
    );
  }
}
