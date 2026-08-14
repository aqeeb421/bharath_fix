import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
        title: Text('About BharathFix', style: AppTextStyle.sectionHeader),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.medium),
        child: Column(
          children: [
            SizedBox(height: AppSpacing.medium),
            
            // Central Logo Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [BoxShadow(
                          color: Color(0x1F000062),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.handyman_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.medium),
                  Text(
                    'BharathFix',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Version 1.0.0 (Build 100)',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      color: AppColors.subtitle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8ECF8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Trusted Doorstep Home Services',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.extraLarge),

            // Company Info Card
            _buildSectionCard(
              title: 'Company Profile',
              child: Text(
                'Bharath Fix Services is a leading on-demand home maintenance and appliance repair provider. Our platform seamlessly connects homeowners with certified, background-verified technicians for instant doorstep solutions.',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  color: AppColors.title,
                  height: 1.5,
                ),
              ),
            ),

            SizedBox(height: AppSpacing.medium),

            // Key Highlights
            _buildSectionCard(
              title: 'Why Choose BharathFix?',
              child: Column(
                children: [
                  _buildHighlightRow(Icons.verified_user_rounded, 'Verified Technicians', 'Background-checked certified service professionals.'),
                  SizedBox(height: 12),
                  _buildHighlightRow(Icons.price_check_rounded, 'Upfront Transparent Pricing', 'Flat visit charges with zero hidden fees.'),
                  SizedBox(height: 12),
                  _buildHighlightRow(Icons.location_on_rounded, 'Live GPS Tracking', 'Track your technician in real-time with OTP verification.'),
                  SizedBox(height: 12),
                  _buildHighlightRow(Icons.support_agent_rounded, 'Dedicated Customer Support', 'Direct helpline, WhatsApp & email support.'),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.medium),

            // Official Contact Information Card
            _buildSectionCard(
              title: 'Official Contact Info',
              child: Column(
                children: [
                  _buildContactListTile(
                    icon: Icons.phone_rounded,
                    title: 'Phone Support',
                    subtitle: '+91 9148699386',
                    onTap: () => _makeCall('9148699386'),
                  ),
                  const Divider(height: 16),
                  _buildContactListTile(
                    icon: Icons.chat_rounded,
                    title: 'WhatsApp Helpline',
                    subtitle: '+91 9148699386',
                    onTap: () => _openWhatsApp('9148699386'),
                  ),
                  const Divider(height: 16),
                  _buildContactListTile(
                    icon: Icons.email_rounded,
                    title: 'Official Email',
                    subtitle: 'bharathfixservice@gmail.com',
                    onTap: () => _sendEmail('bharathfixservice@gmail.com'),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.extraLarge),
            Text(
              '© 2026 Bharath Fix Services. All rights reserved.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                color: AppColors.subtitle,
              ),
            ),
            SizedBox(height: AppSpacing.medium),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.title,
            ),
          ),
          SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildHighlightRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Color(0xFFE8ECF8),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.title,
                ),
              ),
              SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  color: AppColors.subtitle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: AppColors.subtitle)),
                  SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.subtitle),
          ],
        ),
      ),
    );
  }
}
