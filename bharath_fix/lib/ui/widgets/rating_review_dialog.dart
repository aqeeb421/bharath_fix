import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_radius.dart';

class RatingReviewDialog extends StatefulWidget {
  final String bookingId;
  final String providerName;
  final String providerId;

  const RatingReviewDialog({
    super.key,
    required this.bookingId,
    required this.providerName,
    required this.providerId,
  });

  @override
  State<RatingReviewDialog> createState() => _RatingReviewDialogState();
}

class _RatingReviewDialogState extends State<RatingReviewDialog> {
  double _ratingStars = 5.0;
  final TextEditingController _commentController = TextEditingController();
  final Set<String> _selectedTags = {};
  double _selectedTipAmount = 0.0;
  bool _isSubmitting = false;

  final List<String> _availableTags = [
    'On Time ⏰',
    'Polite & Respectful 🤝',
    'Quality Service ⭐',
    'Fair Pricing 💰',
    'Clean Work Environment 🧹',
  ];

  final List<double> _tipOptions = [0, 30, 50, 100];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() async {
    setState(() => _isSubmitting = true);

    final success = await DatabaseService().submitBookingRatingAndTip(
      bookingId: widget.bookingId,
      providerId: widget.providerId,
      ratingStars: _ratingStars,
      tags: _selectedTags.toList(),
      comment: _commentController.text.trim(),
      tipAmount: _selectedTipAmount,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.stars_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                _selectedTipAmount > 0
                    ? 'Thank you for your rating & ₹${_selectedTipAmount.toInt()} tip! 🙏'
                    : 'Thank you for your feedback! ⭐',
                style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.medium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.thumb_up_alt_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Rate Your Technician',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.blueGrey.shade900,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'How was your service with ${widget.providerName.isNotEmpty ? widget.providerName : "Technician"}?',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),

            // 5-Star Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return IconButton(
                  icon: Icon(
                    starIndex <= _ratingStars ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setState(() => _ratingStars = starIndex.toDouble()),
                );
              }),
            ),
            SizedBox(height: 8),

            // Multi-select Feedback Tags
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag, style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 11, color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 12),

            // Comment text area
            TextField(
              controller: _commentController,
              maxLines: 2,
              style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Share your feedback or suggestions...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
            SizedBox(height: 12),

            // Technician Tipping Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tip Your Technician (Optional)',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.blueGrey.shade800,
                ),
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: _tipOptions.map((tip) {
                final isSelected = _selectedTipAmount == tip;
                final label = tip == 0 ? 'No Tip' : '₹${tip.toInt()}';
                return ChoiceChip(
                  label: Text(label, style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : AppColors.primary)),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  onSelected: (val) {
                    if (val) setState(() => _selectedTipAmount = tip);
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 12),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Submit Rating & Review', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
