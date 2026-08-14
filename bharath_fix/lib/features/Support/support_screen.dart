import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_text_style.dart';
import 'about_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _makeCall(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWhatsApp(String number) async {
    final Uri uri = Uri.parse("https://wa.me/91$number");
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri uri = Uri(scheme: 'mailto', path: email);
    if (!await launchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.title, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Support Marketplace', style: AppTextStyle.sectionHeader),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Logo Banner
            Container(
              padding: EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECF8),
                borderRadius: BorderRadius.circular(AppRadius.large),
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.handyman_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                  SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BharathFix Service Support', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                        SizedBox(height: 2),
                        Text('We are available 24/7 to assist with doorstep services & bookings.', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: AppColors.subtitle)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.large),
            Text('How can we help you today?', style: AppTextStyle.subtitle),
            SizedBox(height: AppSpacing.medium),

            _buildSupportChannelCard(
              icon: Icons.call_rounded,
              title: 'Call Support',
              subtitle: '+91 9148699386 (Speak directly to our expert)',
              onTap: () => _makeCall('9148699386'),
            ),
            SizedBox(height: AppSpacing.medium),
            _buildSupportChannelCard(
              icon: Icons.chat_bubble_rounded,
              title: 'WhatsApp Support',
              subtitle: '+91 9148699386 (Instant resolution on WhatsApp)',
              onTap: () => _openWhatsApp('9148699386'),
            ),
            SizedBox(height: AppSpacing.medium),
            _buildSupportChannelCard(
              icon: Icons.email_rounded,
              title: 'Email Support',
              subtitle: 'bharathfixservice@gmail.com',
              onTap: () => _sendEmail('bharathfixservice@gmail.com'),
            ),

            SizedBox(height: AppSpacing.large),
            Text('Frequently Asked Questions', style: AppTextStyle.sectionHeader),
            SizedBox(height: AppSpacing.medium),

            _buildFAQTile('How do I cancel my booking slot?'),
            _buildFAQTile('Are local service providers verified?'),
            _buildFAQTile('What payments methods are accepted?'),

            SizedBox(height: AppSpacing.large),
            _buildSupportChannelCard(
              icon: Icons.info_outline_rounded,
              title: 'About Us',
              subtitle: 'App version, company profile & services info',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
            SizedBox(height: AppSpacing.medium),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportChannelCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.medium),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.title,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyle.subtitle.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.subtitle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQTile(String question) {
    return Theme(
      // Cleans out the unwanted default top/bottom accent border lines on ExpansionTile widgets
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.medium),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.border),
        ),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.title,
            ),
          ),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.subtitle,
          childrenPadding: EdgeInsets.only(
            left: AppSpacing.medium,
            right: AppSpacing.medium,
            bottom: AppSpacing.medium,
          ),
          expandedAlignment: Alignment.topLeft,
          children: [Text(
              'You can securely manage details or update changes directly through the system dashboard interface.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                color: AppColors.subtitle,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}