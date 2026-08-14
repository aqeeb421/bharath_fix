import 'package:flutter/material.dart';

class TechAppColors {
  static const primary = Color(0xFF000062);
  static const card = Colors.white;
  static const title = Color(0xFF111111);
  static const subtitle = Color(0xFF757575);
}

/// 1. EMPTY STATE WIDGET
class TechEmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onAction;

  const TechEmptyStateWidget({
    super.key,
    this.title = 'No Jobs Available',
    this.message = 'No jobs matching your active area right now.',
    this.icon = Icons.handyman_outlined,
    this.buttonText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: TechAppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: TechAppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TechAppColors.title), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(message, style: const TextStyle(fontSize: 13, color: TechAppColors.subtitle), textAlign: TextAlign.center),
            if (buttonText != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TechAppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(buttonText!, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 2. LOADING STATE WIDGET
class TechLoadingStateWidget extends StatelessWidget {
  final String message;

  const TechLoadingStateWidget({
    super.key,
    this.message = 'Fetching available jobs...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: TechAppColors.primary, strokeWidth: 3),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 13, color: TechAppColors.subtitle, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// 3. ERROR STATE WIDGET
class TechErrorStateWidget extends StatelessWidget {
  final String title;
  final String errorMessage;
  final VoidCallback? onRetry;

  const TechErrorStateWidget({
    super.key,
    this.title = 'Job Sync Error',
    this.errorMessage = 'Could not retrieve job list. Please try again.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade700),
              const SizedBox(height: 12),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade900), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(errorMessage, style: TextStyle(fontSize: 12, color: Colors.red.shade800), textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 4. NO INTERNET WIDGET
class TechNoInternetWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const TechNoInternetWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.orange.shade800,
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Offline Mode: Reconnecting to job network...',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          if (onRetry != null)
            InkWell(
              onTap: onRetry,
              child: const Padding(
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
class TechSlowNetworkWidget extends StatelessWidget {
  const TechSlowNetworkWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Row(
        children: [
          Icon(Icons.network_check_rounded, color: Colors.amber.shade900, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Slow network connection. GPS and job sync may be delayed.',
              style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
