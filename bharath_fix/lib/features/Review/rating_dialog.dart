import '../../services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_text_style.dart';

class RatingDialog extends StatefulWidget {
  final String bookingId;
  final String providerId;

  const RatingDialog({
    super.key,
    required this.bookingId,
    required this.providerId,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    ThemeService().themeModeNotifier.addListener(_onThemeChanged);
  }

  int _selectedStars = 5;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    ThemeService().themeModeNotifier.removeListener(_onThemeChanged);
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);

    try {
      final reviewText = _reviewController.text.trim();

      // Update Booking with rating
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
        'rating': _selectedStars,
        'reviewNotes': reviewText,
        'ratedAt': FieldValue.serverTimestamp(),
      });

      // Update Technician rating stats
      if (widget.providerId.isNotEmpty) {
        final techRef = FirebaseFirestore.instance.collection('providers').doc(widget.providerId);
        final doc = await techRef.get();
        if (doc.exists) {
          final data = doc.data()!;
          final double currentRating = (data['rating'] as num?)?.toDouble() ?? 5.0;
          final int completedJobs = (data['completedJobs'] as int?) ?? 1;
          final double newAvgRating = ((currentRating * completedJobs) + _selectedStars) / (completedJobs + 1);

          await techRef.update({
            'rating': double.parse(newAvgRating.toStringAsFixed(1)),
            'completedJobs': FieldValue.increment(1),
          });
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Thank you for your rating & feedback!"),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to submit rating: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
      title: Text("Rate Your Service Visit", style: AppTextStyle.sectionHeader),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("How satisfied were you with the technician's work?", style: AppTextStyle.subtitle),
            SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  icon: Icon(
                    starValue <= _selectedStars ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 36,
                  ),
                  onPressed: () => setState(() => _selectedStars = starValue),
                );
              }),
            ),
            SizedBox(height: 16),

            TextField(
              controller: _reviewController,
              maxLines: 3,
              style: TextStyle(color: AppColors.title),
              decoration: InputDecoration(
                hintText: "Write a short review or feedback (optional)",
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Skip"),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitRating,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isSubmitting
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text("Submit Review", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
