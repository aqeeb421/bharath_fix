import 'package:flutter/material.dart';

class AdminAppColors {
  static const primary = Color(0xFF000062);
  static const card = Colors.white;
  static const title = Color(0xFF111111);
  static const subtitle = Color(0xFF757575);
}

/// 1. ADMIN EMPTY STATE WIDGET
class AdminEmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onAction;

  const AdminEmptyStateWidget({
    super.key,
    this.title = 'No Records Found',
    this.message = 'No data matching your current filters in admin portal.',
    this.icon = Icons.folder_off_rounded,
    this.buttonText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AdminAppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AdminAppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminAppColors.title), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(message, style: const TextStyle(fontSize: 13, color: AdminAppColors.subtitle), textAlign: TextAlign.center),
            if (buttonText != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminAppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

/// 2. ADMIN LOADING STATE WIDGET
class AdminLoadingStateWidget extends StatelessWidget {
  final String message;

  const AdminLoadingStateWidget({
    super.key,
    this.message = 'Loading Admin Command Data...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AdminAppColors.primary, strokeWidth: 3),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 13, color: AdminAppColors.subtitle, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// 3. ADMIN ERROR STATE WIDGET
class AdminErrorStateWidget extends StatelessWidget {
  final String title;
  final String errorMessage;
  final VoidCallback? onRetry;

  const AdminErrorStateWidget({
    super.key,
    this.title = 'Portal Sync Error',
    this.errorMessage = 'Could not load data from Firestore command center.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

/// 4. ADMIN NO SEARCH RESULTS WIDGET
class AdminNoSearchResultsWidget extends StatelessWidget {
  final String query;
  final VoidCallback? onClearSearch;

  const AdminNoSearchResultsWidget({
    super.key,
    required this.query,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: AdminAppColors.subtitle.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No Admin Results for "$query"', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminAppColors.title), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            const Text(
              'Try searching with a different Booking ID, Customer Phone, or Partner Name.',
              style: TextStyle(fontSize: 12, color: AdminAppColors.subtitle),
              textAlign: TextAlign.center,
            ),
            if (onClearSearch != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onClearSearch,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminAppColors.primary,
                  side: const BorderSide(color: AdminAppColors.primary),
                ),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Clear Filters', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
