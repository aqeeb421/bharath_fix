
class SubCategoryModel {
  final String id;
  final String name;
  final String placeholderImage;
  final String image;
  final bool isInstallationNeeded;
  final bool isInstallationFree;
  final String installationFee;

  const SubCategoryModel({
    required this.id,
    required this.name,
    required this.placeholderImage,
    this.image = '',
    this.isInstallationNeeded = false,
    this.isInstallationFree = true,
    this.installationFee = '₹299',
  });

  factory SubCategoryModel.fromMap(Map<String, dynamic> map) {
    final img = (map['image'] ?? map['placeholderImage'] ?? '').toString();
    return SubCategoryModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      placeholderImage: img,
      image: img,
      isInstallationNeeded: map['isInstallationNeeded'] as bool? ?? false,
      isInstallationFree: map['isInstallationFree'] as bool? ?? true,
      installationFee: map['installationFee']?.toString() ?? '₹299',
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'placeholderImage': placeholderImage,
      'image': image,
      'isInstallationNeeded': isInstallationNeeded,
      'isInstallationFree': isInstallationFree,
      'installationFee': installationFee,
    };
  }
}