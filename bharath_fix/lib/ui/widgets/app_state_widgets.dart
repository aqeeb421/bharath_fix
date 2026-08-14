import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_style.dart';

/// 1. EMPTY STATE WIDGET
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    this.title = 'No Items Found',
    this.message = 'There are no records to display at this time.',
    this.icon = Icons.inbox_rounded,
    this.buttonText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            SizedBox(height: AppSpacing.medium),
            Text(title, style: AppTextStyle.sectionHeader, textAlign: TextAlign.center),
            SizedBox(height: 6),
            Text(message, style: AppTextStyle.subtitle, textAlign: TextAlign.center),
            if (buttonText != null && onAction != null) ...[
              SizedBox(height: AppSpacing.medium),
              ElevatedButton.icon(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: Icon(Icons.refresh_rounded, size: 18),
                label: Text(buttonText!, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 2. LOADING STATE WIDGET (Spinner & Skeleton Loading)
class LoadingStateWidget extends StatelessWidget {
  final String message;
  final bool isOverlay;

  const LoadingStateWidget({
    super.key,
    this.message = 'Loading data...',
    this.isOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          SizedBox(height: AppSpacing.medium),
          Text(message, style: AppTextStyle.subtitle.copyWith(color: AppColors.title, fontWeight: FontWeight.w600)),
        ],
      ),
    );

    if (isOverlay) {
      return Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: content,
      );
    }
    return content;
  }
}

/// 3. ERROR STATE WIDGET
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String errorMessage;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    this.title = 'Something Went Wrong',
    this.errorMessage = 'Unable to complete your request. Please try again.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.large),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade700),
              SizedBox(height: AppSpacing.small),
              Text(title, style: AppTextStyle.sectionHeader.copyWith(color: Colors.red.shade900), textAlign: TextAlign.center),
              SizedBox(height: 6),
              Text(errorMessage, style: AppTextStyle.subtitle.copyWith(color: Colors.red.shade800), textAlign: TextAlign.center),
              if (onRetry != null) ...[
                SizedBox(height: AppSpacing.medium),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                  ),
                  icon: Icon(Icons.replay_rounded, size: 18),
                  label: Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 4. NO INTERNET WIDGET (Offline Banner)
class NoInternetWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoInternetWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.orange.shade800,
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No internet connection. Showing cached data.',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          if (onRetry != null)
            InkWell(
              onTap: onRetry,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text('Retry 🔄', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }
}

/// 5. SLOW NETWORK WIDGET
class SlowNetworkWidget extends StatelessWidget {
  const SlowNetworkWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Row(
        children: [
          Icon(Icons.network_check_rounded, color: Colors.amber.shade900, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Slow network connection detected. Loading may take longer...',
              style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// 6. NO SEARCH RESULTS WIDGET
class NoSearchResultsWidget extends StatelessWidget {
  final String query;
  final VoidCallback? onClearSearch;

  const NoSearchResultsWidget({
    super.key,
    required this.query,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppColors.subtitle.withValues(alpha: 0.5)),
            SizedBox(height: AppSpacing.medium),
            Text('No Results for "$query"', style: AppTextStyle.sectionHeader, textAlign: TextAlign.center),
            SizedBox(height: 6),
            Text(
              'Check spelling or try searching for AC repair, Plumbing, or Electrical.',
              style: AppTextStyle.subtitle,
              textAlign: TextAlign.center,
            ),
            if (onClearSearch != null) ...[
              SizedBox(height: AppSpacing.medium),
              OutlinedButton.icon(
                onPressed: onClearSearch,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                ),
                icon: Icon(Icons.close_rounded, size: 16),
                label: Text('Clear Search', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 7. PERMISSION DENIED WIDGET
class PermissionDeniedWidget extends StatelessWidget {
  final String permissionName;
  final String explanation;
  final VoidCallback onGrantPermission;

  const PermissionDeniedWidget({
    super.key,
    required this.permissionName,
    required this.explanation,
    required this.onGrantPermission,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.security_rounded, size: 48, color: Colors.amber.shade800),
            ),
            SizedBox(height: AppSpacing.medium),
            Text('$permissionName Required', style: AppTextStyle.sectionHeader, textAlign: TextAlign.center),
            SizedBox(height: 6),
            Text(explanation, style: AppTextStyle.subtitle, textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.medium),
            ElevatedButton.icon(
              onPressed: onGrantPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
              ),
              icon: Icon(Icons.settings_rounded, size: 18),
              label: Text('Enable Permission', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 8. SESSION EXPIRED DIALOG WIDGET
class SessionExpiredDialog extends StatelessWidget {
  final VoidCallback onLoginAgain;

  const SessionExpiredDialog({super.key, required this.onLoginAgain});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_clock_rounded, size: 56, color: Colors.orange.shade800),
            SizedBox(height: AppSpacing.medium),
            Text('Session Expired', style: AppTextStyle.sectionHeader, textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text(
              'Your login session has expired for security. Please log in again to continue.',
              style: AppTextStyle.subtitle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.medium),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: onLoginAgain,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                ),
                child: Text('Log In Again', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 9. FORM VALIDATION HELPER
class FormValidationHelper {
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 10) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP code is required';
    }
    if (value.trim().length != 4) {
      return 'Enter 4-digit verification code';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}

/// 10. SUCCESS STATE WIDGET
class SuccessStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onDone;

  const SuccessStateWidget({
    super.key,
    this.title = 'Operation Successful! 🎉',
    required this.message,
    this.buttonText = 'Continue',
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, size: 52, color: Colors.green.shade600),
            ),
            SizedBox(height: AppSpacing.medium),
            Text(title, style: AppTextStyle.sectionHeader, textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text(message, style: AppTextStyle.subtitle, textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.medium),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                ),
                child: Text(buttonText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
