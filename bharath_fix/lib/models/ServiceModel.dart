class ServiceModel {
  final String id;
  final String name;
  final String description;
  final String price;
  final String intentMode;
  final String bannerImage;
  final String image;
  final bool isInstallationNeeded;
  final bool isInstallationFree;
  final String installationFee;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.intentMode,
    required this.bannerImage,
    this.image = '',
    this.isInstallationNeeded = false,
    this.isInstallationFree = true,
    this.installationFee = '₹199',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'intentMode': intentMode,
      'bannerImage': bannerImage,
      'image': image,
      'isInstallationNeeded': isInstallationNeeded,
      'isInstallationFree': isInstallationFree,
      'installationFee': installationFee,
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] ?? '',
      name: map['name'] ?? map['partName'] ?? map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? map['standardPrice'] ?? '').toString(),
      intentMode: map['intentMode'] ?? '',
      bannerImage: map['bannerImage'] ?? map['image'] ?? '',
      image: map['image'] ?? map['bannerImage'] ?? '',
      isInstallationNeeded: map['isInstallationNeeded'] as bool? ?? false,
      isInstallationFree: map['isInstallationFree'] as bool? ?? true,
      installationFee: map['installationFee']?.toString() ?? '₹199',
    );
  }

}

