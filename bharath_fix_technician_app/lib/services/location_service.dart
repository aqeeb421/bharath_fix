import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'technician_firestore_service.dart';

class LocationService {
  final TechnicianFirestoreService _firestoreService = TechnicianFirestoreService();
  StreamSubscription<Position>? _positionStreamSub;
  String? _activeBookingId;
  String? _currentTechId;
  DateTime? _lastLocationUpdate;

  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
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
