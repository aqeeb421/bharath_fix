import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_style.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const CommonAppBar({
    super.key,
    this.title="",
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      leading: showBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.title, size: 20),
        onPressed: () => Navigator.maybePop(context),
      )
          : null,
      title: Text(title, style: AppTextStyle.sectionHeader),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}