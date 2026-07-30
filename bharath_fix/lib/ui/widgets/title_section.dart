import 'package:bharath_fix/ui/theme/app_spacing.dart';
import 'package:bharath_fix/ui/theme/app_text_style.dart';
import 'package:flutter/material.dart';

class TitleSection extends StatelessWidget {
  final IconData icon;

  final String title;

  final String subtitle;

  const TitleSection({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF000062), width: 1.5),
          ),
          child: Image.asset(
            'assets/images/app_icon.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(icon, size: 40, color: const Color(0xFF000062)),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        Text(title,style: AppTextStyle.heading),

        const SizedBox(height: AppSpacing.sm),

        Text(
          subtitle,
          style: AppTextStyle.subtitle,
        ),
      ],
    );
  }
}