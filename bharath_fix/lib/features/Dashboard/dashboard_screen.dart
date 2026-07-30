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
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;
  bool _hasCheckedArguments = false;

  // Location tracking states
  String _currentLocationName = "Fetching location...";
  bool _isServiceableRegion = false;
  bool _isLoadingLocation = true;

  // The 8 official functional taluks of Hassan District
  final List<String> _hassanTaluks = [
    'hassan', 'alur', 'arkalgud', 'arsikere',
    'belur', 'channarayapatna', 'holenarasipura', 'sakleshpura', 'sakleshpur'
  ];

  @override
  void initState() {
    super.initState();
    _determineUserPositionWorkflow();
  }

  Future<void> _determineUserPositionWorkflow({bool showDialogOnFail = true}) async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setFallbackLocation("Location services disabled");
        if (showDialogOnFail && mounted) {
          _showEnableLocationServiceDialog();
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setFallbackLocation("Permission denied");
          if (showDialogOnFail && mounted) {
            _showLocationPermissionDeniedDialog(permanently: false);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setFallbackLocation("Permissions permanently denied");
        if (showDialogOnFail && mounted) {
          _showLocationPermissionDeniedDialog(permanently: true);
        }
        return;
      }

      // Fetch precise GPS coordinates
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Reverse-geocode coordinates to find district, town, and postal parameters
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // Clean up string tokens
        String district = (place.subAdministrativeArea ?? "").trim().toLowerCase();
        String locality = (place.locality ?? "").trim().toLowerCase();
        String subLocality = (place.subLocality ?? "").trim().toLowerCase();

        // 1. Direct check: Is the district explicitly Hassan?
        bool isHassanDistrict = district == 'hassan' || district.startsWith('hassan');

        // 2. Exact word check against Hassan Taluks (prevents "bengALURu" matching "alur")
        bool isAnyTaluk = _hassanTaluks.any((taluk) {
          return district == taluk ||
              locality == taluk ||
              subLocality == taluk ||
              RegExp('\\b$taluk\\b', caseSensitive: false).hasMatch(district) ||
              RegExp('\\b$taluk\\b', caseSensitive: false).hasMatch(locality);
        });

        String displayName = place.locality?.isNotEmpty == true
            ? "${place.locality}, KA"
            : "${place.subAdministrativeArea ?? 'Unknown'}, KA";

        setState(() {
          _currentLocationName = displayName;
          // TODO: Location restriction hidden for the time being
          // _isServiceableRegion = isHassanDistrict || isAnyTaluk;
          _isServiceableRegion = true;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      _setFallbackLocation("Bengaluru, KA"); // Graceful fallback
    }
  }

  void _showEnableLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_off_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Enable Location Services', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Location services are currently turned off on your device. Please turn on Location Services to automatically detect your service address and assign nearby technicians.',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, color: AppColors.subtitle, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.subtitle)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Open Location Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Location Permission', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          permanently
              ? 'Location permission is permanently denied in app settings. Please enable Location permissions in App Settings so BharathFix can locate nearby technicians.'
              : 'Location permission is required to detect your current service area. Please grant location access.',
          style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, color: AppColors.subtitle, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss', style: TextStyle(color: AppColors.subtitle)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(permanently ? 'Open App Settings' : 'Grant Permission', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _setFallbackLocation(String fallbackName) {
    setState(() {
      _currentLocationName = fallbackName;
      // TODO: Location restriction hidden for the time being
      // _isServiceableRegion = false;
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
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final List<Widget> screens = [
      HomeScreen(
        detectedLocation: _currentLocationName,
        isServiceable: _isServiceableRegion,
        onRetryLocation: () => _determineUserPositionWorkflow(showDialogOnFail: true),
        onProfileTap: () => setState(() => _currentIndex = 3),
      ),
      const BookingsScreen(),
      const ChatScreen(),
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
        if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit BharathFix', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, fontWeight: FontWeight.w500)),
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
        backgroundColor: AppColors.background,
        body: IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border, width: 1.0))),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: AppColors.background,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.subtitle,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w500, fontSize: 11),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment_rounded), label: 'Bookings'),
              BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), activeIcon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}