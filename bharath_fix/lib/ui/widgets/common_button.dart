import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class CommonButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final IconData? icon;
  final bool isLoading;

  const CommonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isOutlined = false,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: isOutlined ? AppColors.primary : Colors.white,
    );

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          side: BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          elevation: 0,
        ),
        child: _buildButtonContent(textStyle),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        elevation: 0,
      ),
      child: _buildButtonContent(textStyle),
    );
  }

  Widget _buildButtonContent(TextStyle textStyle) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: isOutlined ? AppColors.primary : Colors.white,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textStyle.color),
          SizedBox(width: 8),
          Text(label, style: textStyle),
        ],
      );
    }
    return Text(label, style: textStyle);
  }
}