/*
// lib/Home/services_list_screen.dart
import 'package:flutter/material.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';
import 'service_details_screen.dart';

class ServicesListScreen extends StatefulWidget {
  final String categoryName;

  const ServicesListScreen({super.key, required this.categoryName});

  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
  int _selectedFilterIndex = 0;

  final List<String> _filters = ['All', 'Top rated', 'Price: Low to High', 'Price: High to Low'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.title, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.categoryName, style: AppTextStyle.sectionHeader),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.medium),
              children: [
                _buildServiceListItem(
                  context,
                  title: 'Full Home Deep Cleaning',
                  duration: '240 min',
                  rating: '4.9',
                  description: 'Team of 3 professionals, high-pressure jets, eco-friendly chemicals...',
                  price: '₹2999',
                ),
                const SizedBox(height: AppSpacing.medium),
                _buildServiceListItem(
                  context,
                  title: 'Bathroom Cleaning',
                  duration: '60 min',
                  rating: '4.6',
                  description: 'Descale tiles, sanitise fittings, deep clean floor layout.',
                  price: '₹499',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.small),
            child: ChoiceChip(
              label: Text(_filters[index]),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilterIndex = index);
                }
              },
              selectedColor: AppColors.accentGreen,
              backgroundColor: AppColors.card,
              labelStyle: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.subtitle,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceListItem(
      BuildContext context, {
        required String title,
        required String duration,
        required String rating,
        required String description,
        required String price,
      }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyle.sectionHeader.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      '$rating · $duration',
                      style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: AppColors.subtitle, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  description,
                  style: AppTextStyle.subtitle.copyWith(fontSize: 13, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(price, style: AppTextStyle.mainTitle.copyWith(fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&q=60&w=200'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceDetailsScreen(serviceTitle: title, servicePrice: price),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: Container(
                  width: 76,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Add',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}*/
