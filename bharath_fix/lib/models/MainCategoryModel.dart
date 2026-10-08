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

  static IconData resolveIcon(String name, [int? codePoint]) {
    final lower = name.toLowerCase();
    if (lower.contains('water') && lower.contains('spare')) return Icons.build_circle_rounded;
    if (lower.contains('water') || lower.contains('purifier') || lower.contains('ro')) return Icons.water_drop_rounded;
    if (lower.contains('cctv') || lower.contains('camera')) return Icons.videocam_rounded;
    if (lower.contains('chimney')) return Icons.soup_kitchen_rounded;
    if (lower.contains('stabilizer') || lower.contains('voltage') || lower.contains('inverter')) return Icons.electric_bolt_rounded;
    if (lower.contains('geyser') || lower.contains('water heater')) return Icons.whatshot_rounded;
    if (lower.contains('solar')) return Icons.solar_power_rounded;
    if (lower.contains('cooler') || lower.contains('ac')) return Icons.ac_unit_rounded;
    if (lower.contains('plumb')) return Icons.plumbing_rounded;
    if (lower.contains('electric')) return Icons.electrical_services_rounded;
    if (lower.contains('clean')) return Icons.cleaning_services_rounded;
    if (lower.contains('repair') || lower.contains('service')) return Icons.build_rounded;
    return Icons.category_rounded;
  }

  factory MainCategoryModel.fromMap(Map<String, dynamic> map) {
    final subList = (map['subCategories'] as List<dynamic>? ?? [])
        .map((s) => SubCategoryModel.fromMap(Map<String, dynamic>.from(s as Map)))
        .toList();
    final name = map['name']?.toString() ?? '';
    final codePoint = map['iconCodePoint'] as int?;
    return MainCategoryModel(
      id: map['id']?.toString() ?? '',
      name: name,
      iconData: resolveIcon(name, codePoint),
      assetPath: map['assetPath']?.toString(),
      imageUrl: (map['iconUrl'] ?? map['imageUrl'] ?? map['image'])?.toString(),
      subCategories: subList,
    );
  }
}