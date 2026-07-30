import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'technician_firestore_service.dart';

class LocationService {
  final TechnicianFirestoreService _firestoreService = TechnicianFirestoreService();
  StreamSubscription<Position>? _positionStreamSub;
  String? _activeBookingId;
  String? _currentTechId;

  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return false;
    }

    permission = await Geolocator.checkPermission();
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
    _currentTechId = techId;
    _activeBookingId = activeBookingId;

    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) return;

    await stopLiveTracking();

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        if (_currentTechId != null) {
          _firestoreService.updateLiveLocation(
            _currentTechId!,
            _activeBookingId,
            position.latitude,
            position.longitude,
          );
        }
      },
      onError: (e) {
        debugPrint("Location tracking error: $e");
      },
    );
  }

  void setActiveBookingId(String? bookingId) {
    _activeBookingId = bookingId;
  }

  Future<void> stopLiveTracking() async {
    await _positionStreamSub?.cancel();
    _positionStreamSub = null;
  }
}
