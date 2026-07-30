// lib/Chat/chat_screen.dart
import 'package:flutter/material.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chats', style: AppTextStyle.mainTitle),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.extraLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 56, color: Colors.grey),
              const SizedBox(height: AppSpacing.large),
              const Text('No conversations yet', style: AppTextStyle.sectionHeader),
              const SizedBox(height: AppSpacing.small),
              Text(
                'Chat opens after your booking is accepted.',
                textAlign: TextAlign.center,
                style: AppTextStyle.subtitle.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}