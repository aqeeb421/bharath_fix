import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'technician_firestore_service.dart';

class LocationService {
  final TechnicianFirestoreService _firestoreService = TechnicianFirestoreService();
  StreamSubscription<Position>? _positionStreamSub;
  String? _activeBookingId;
  String? _currentTechId;
  DateTime? _lastLocationUpdate;

  /// Prominent disclosure required by Google Play Developer Policy for location data
  static Future<bool> showProminentDisclosureDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded, color: Color(0xFF1565C0)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Location Access',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BharathFix Partner collects device location data to:',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• Match and dispatch repair service bookings near your current operating area.\n'
                '• Provide customers with accurate real-time transit updates while delivering retail appliances or en-route to service visits.',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Location tracking is only active while you are marked ONLINE and actively fulfilling customer orders.',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Deny', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Agree & Continue'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<bool> checkAndRequestPermissions({BuildContext? context}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (context != null && context.mounted) {
        final agreed = await showProminentDisclosureDialog(context);
        if (!agreed) return false;
      }
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return false;
    }

    return true;
  }

  void startLiveTracking(String techId, {String? activeBookingId}) async {
    // Prevent duplicate restart if tracking is already active for this techId
    if (_positionStreamSub != null && _currentTechId == techId) {
      _activeBookingId = activeBookingId;
      return;
    }

    _currentTechId = techId;
    _activeBookingId = activeBookingId;

    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) return;

    await stopLiveTracking();
    _currentTechId = techId;
    _activeBookingId = activeBookingId;

    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      _sendLocationUpdate(techId, initialPosition.latitude, initialPosition.longitude, force: true);
    } catch (e) {
      debugPrint("Initial position fetch error: $e");
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 15, // Only trigger on moving 15 meters
    );

    _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        if (_currentTechId != null) {
          _sendLocationUpdate(_currentTechId!, position.latitude, position.longitude);
        }
      },
      onError: (e) {
        debugPrint("Location tracking error: $e");
      },
    );
  }

  void _sendLocationUpdate(String techId, double lat, double lng, {bool force = false}) {
    final now = DateTime.now();
    if (!force && _lastLocationUpdate != null && now.difference(_lastLocationUpdate!).inSeconds < 10) {
      return; // Throttled: write to Firestore at most once every 10 seconds
    }
    _lastLocationUpdate = now;

    _firestoreService.updateLiveLocation(
      techId,
      _activeBookingId,
      lat,
      lng,
    );
  }

  void setActiveBookingId(String? bookingId) {
    _activeBookingId = bookingId;
  }

  Future<void> stopLiveTracking() async {
    await _positionStreamSub?.cancel();
    _positionStreamSub = null;
    _currentTechId = null;
    _lastLocationUpdate = null;
  }
}
