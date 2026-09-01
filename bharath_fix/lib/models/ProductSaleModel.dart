class ProductSaleModel {
  final String id;
  final String name;
  final String subCategory;
  final String price;
  final String image;
  final String description;
  final Map<String, String> specifications;
  final int stockQuantity;
  final String originalPrice;
  final int discountPercentage;
  final String warrantyPeriod;
  final int deliveryDays;
  final bool isInstallationNeeded;
  final bool isInstallationFree;
  final String installationFee;

  const ProductSaleModel({
    required this.id,
    required this.name,
    required this.subCategory,
    required this.price,
    required this.image,
    this.description = '',
    this.specifications = const {},
    this.stockQuantity = 10,
    this.originalPrice = '',
    this.discountPercentage = 0,
    this.warrantyPeriod = '1 Year Comprehensive Warranty',
    this.deliveryDays = 2,
    this.isInstallationNeeded = false,
    this.isInstallationFree = true,
    this.installationFee = '₹299',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subCategory': subCategory,
      'price': price,
      'image': image,
      'description': description,
      'specifications': specifications,
      'stockQuantity': stockQuantity,
      'originalPrice': originalPrice,
      'discountPercentage': discountPercentage,
      'warrantyPeriod': warrantyPeriod,
      'deliveryDays': deliveryDays,
      'isInstallationNeeded': isInstallationNeeded,
      'isInstallationFree': isInstallationFree,
      'installationFee': installationFee,
    };
  }

  factory ProductSaleModel.fromMap(Map<String, dynamic> map) {
    Map<String, String> parsedSpecs = {};
    if (map['specifications'] != null && map['specifications'] is Map) {
      (map['specifications'] as Map).forEach((key, value) {
        parsedSpecs[key.toString()] = value.toString();
      });
    }

    return ProductSaleModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      subCategory: map['subCategory'] ?? '',
      price: map['price'] ?? '',
      image: map['image'] ?? '',
      description: map['description'] ?? '',
      specifications: parsedSpecs,
      stockQuantity: (map['stockQuantity'] as num?)?.toInt() ?? 10,
      originalPrice: map['originalPrice'] ?? '',
      discountPercentage: (map['discountPercentage'] as num?)?.toInt() ?? 0,
      warrantyPeriod: map['warrantyPeriod'] ?? '1 Year Comprehensive Warranty',
      deliveryDays: (map['deliveryDays'] as num?)?.toInt() ?? 2,
      isInstallationNeeded: map['isInstallationNeeded'] as bool? ?? false,
      isInstallationFree: map['isInstallationFree'] as bool? ?? true,
      installationFee: map['installationFee']?.toString() ?? '₹299',
    );
  }

}