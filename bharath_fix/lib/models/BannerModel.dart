import 'package:flutter/material.dart';

class BannerModel {
  final String id;
  final String title;
  final String offerText;
  final Color backgroundColor;

  const BannerModel({
    required this.id,
    required this.title,
    required this.offerText,
    required this.backgroundColor,
  });
}