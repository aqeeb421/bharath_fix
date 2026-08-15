import '../../services/theme_service.dart';
import '../../services/notification_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../ui/theme/app_colors.dart';
import '../Home/home_screen.dart';
import '../Bookings/bookings_screen.dart';
import '../Chat/chat_screen.dart';
import '../Account/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void dispose() {
    ThemeService().themeModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  int _currentIndex = 0;
  DateTime? _lastBackPressTime;
  bool _hasCheckedArguments = false;

  // Location tracking states
  String _currentLocationName = "Hassan, KA";
  bool _isServiceableRegion = true;
  bool _isLoadingLocation = false;

  // The 8 official functional taluks of Hassan District
  final List<String> _hassanTaluks = [
    'hassan',
    'alur',
    'arkalgud',
    'arsikere',
    'belur',
    'channarayapatna',
    'holenarasipura',
    'sakleshpura',
    'sakleshpur',
  ];

  @override
  void initState() {
    super.initState();
    ThemeService().themeModeNotifier.addListener(_onThemeChanged);
    NotificationService.onNotificationTap = (data) {
      if (mounted) {
        setState(() {
          _currentIndex = 1;
        });
      }
    };
    _determineUserPositionWorkflow(showDialogOnFail: false);
  }

  Future<void> _determineUserPositionWorkflow({
    bool showDialogOnFail = false,
  }) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setFallbackLocation("Hassan, KA");
        if (showDialogOnFail && mounted) {
          _showEnableLocationServiceDialog();
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setFallbackLocation("Hassan, KA");
          if (showDialogOnFail && mounted) {
            _showLocationPermissionDeniedDialog(permanently: false);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setFallbackLocation("Hassan, KA");
        if (showDialogOnFail && mounted) {
          _showLocationPermissionDeniedDialog(permanently: true);
        }
        return;
      }

      // 1. Try fast cached last known position first (0ms delay)
      Position? position = await Geolocator.getLastKnownPosition();

      // 2. If no cached position, request fresh GPS coordinates with safe timeout catch
      position ??=
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
            ),
          ).timeout(
            const Duration(seconds: 4),
            onTimeout: () {
              debugPrint(
                "GPS location request timed out. Using fallback location.",
              );
              throw TimeoutException("GPS Timeout");
            },
          );

      // Reverse-geocode coordinates to find district, town, and postal parameters
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // Prioritize town/sublocality name (e.g. Arkalgud) over generic district
        String bestLocationName = '';
        if (place.subLocality != null &&
            place.subLocality!.trim().isNotEmpty &&
            place.subLocality != 'Unnamed Road') {
          bestLocationName = place.subLocality!.trim();
        } else if (place.locality != null &&
            place.locality!.trim().isNotEmpty) {
          bestLocationName = place.locality!.trim();
        } else if (place.name != null &&
            place.name!.trim().isNotEmpty &&
            !place.name!.contains('+')) {
          bestLocationName = place.name!.trim();
        } else if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.trim().isNotEmpty) {
          bestLocationName = place.subAdministrativeArea!.trim();
        } else {
          bestLocationName = "Hassan";
        }

        String displayName = "$bestLocationName, KA";

        if (mounted) {
          setState(() {
            _currentLocationName = displayName;
            _isServiceableRegion = true;
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Location workflow exception caught safely: $e");
      if (mounted) {
        _setFallbackLocation("Hassan, KA");
      }
    }
  }

  void _showEnableLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_off_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Enable Location Services',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'Location services are currently turned off on your device. Please turn on Location Services to automatically detect your service address and assign nearby technicians.',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            color: AppColors.subtitle,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.subtitle),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Open Location Settings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationPermissionDeniedDialog({required bool permanently}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.security_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Location Permission',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          permanently
              ? 'Location permission is permanently denied in app settings. Please enable Location permissions in App Settings so BharathFix can locate nearby technicians.'
              : 'Location permission is required to detect your current service area. Please grant location access.',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            color: AppColors.subtitle,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Dismiss',
              style: TextStyle(color: AppColors.subtitle),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (permanently) {
                await Geolocator.openAppSettings();
              } else {
                _determineUserPositionWorkflow(showDialogOnFail: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              permanently ? 'Open App Settings' : 'Grant Permission',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setFallbackLocation([String fallbackName = "Hassan, KA"]) {
    setState(() {
      _currentLocationName = fallbackName;
      _isServiceableRegion = true;
      _isLoadingLocation = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedArguments) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        _currentIndex = args;
      }
      _hasCheckedArguments = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLocation) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final List<Widget> screens = [
      HomeScreen(
        detectedLocation: _currentLocationName,
        isServiceable: _isServiceableRegion,
        onRetryLocation: () =>
            _determineUserPositionWorkflow(showDialogOnFail: true),
        onProfileTap: () => setState(() => _currentIndex = 2),
      ),
      const BookingsScreen(),
      const ProfileScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Press back again to exit BharathFix',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
            ),
          );
          return;
        }
        await SystemNavigator.pop();
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBorder
                    : AppColors.border,
                width: 1.0,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            unselectedLabelStyle: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            items: [BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment_rounded),
                label: 'Bookings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
