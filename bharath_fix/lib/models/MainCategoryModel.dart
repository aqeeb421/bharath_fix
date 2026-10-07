import 'package:flutter/material.dart';
import 'SubCategoryModel.dart';

class MainCategoryModel {
  final String id;
  final String name;
  final IconData iconData;
  final String? assetPath;
  final String? imageUrl;
  final List<SubCategoryModel> subCategories;

  const MainCategoryModel({
    required this.id,
    required this.name,
    required this.iconData,
    this.assetPath,
    this.imageUrl,
    required this.subCategories,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconData.codePoint,
      'assetPath': assetPath,
      'imageUrl': imageUrl,
      'subCategories': subCategories.map((s) => s.toMap()).toList(),
    };
  }

  factory MainCategoryModel.fromMap(Map<String, dynamic> map) {
    final subList = (map['subCategories'] as List<dynamic>? ?? [])
        .map((s) => SubCategoryModel.fromMap(Map<String, dynamic>.from(s as Map)))
        .toList();
    final codePoint = map['iconCodePoint'] as int? ?? Icons.settings_rounded.codePoint;
    return MainCategoryModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      iconData: IconData(codePoint, fontFamily: 'MaterialIcons'),
      assetPath: map['assetPath']?.toString(),
      imageUrl: (map['iconUrl'] ?? map['imageUrl'] ?? map['image'])?.toString(),
      subCategories: subList,
    );
  }
}