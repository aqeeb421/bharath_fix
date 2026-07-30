class ProductSaleModel {
  final String id;
  final String name;
  final String subCategory;
  final String price;
  final String image;

  const ProductSaleModel({
    required this.id,
    required this.name,
    required this.subCategory,
    required this.price,
    required this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subCategory': subCategory,
      'price': price,
      'image': image,
    };
  }

  factory ProductSaleModel.fromMap(Map<String, dynamic> map) {
    return ProductSaleModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      subCategory: map['subCategory'] ?? '',
      price: map['price'] ?? '',
      image: map['image'] ?? '',
    );
  }
}