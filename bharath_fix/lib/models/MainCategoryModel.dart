import 'package:flutter/material.dart';
import 'SubCategoryModel.dart';

class MainCategoryModel {
  final String id;
  final String name;
  final IconData iconData;
  final String? assetPath;
  final List<SubCategoryModel> subCategories;

  const MainCategoryModel({
    required this.id,
    required this.name,
    required this.iconData,
    this.assetPath,
    required this.subCategories,
  });
}