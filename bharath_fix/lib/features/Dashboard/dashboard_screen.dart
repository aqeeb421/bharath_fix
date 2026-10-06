import '../../services/theme_service.dart';
import '../../services/notification_service.dart';
import '../../services/language_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../ui/theme/app_colors.dart';
import '../Home/home_screen.dart';
import '../Market/market_screen.dart';
import '../Bookings/bookings_screen.dart';
import '../Orders/orders_screen.dart';
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
    LanguageService().currentLangNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _onLanguageChanged() {
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
    LanguageService().currentLangNotifier.addListener(_onLanguageChanged);
    NotificationService.onNotificationTap = (data) {
      if (mounted) {
        setState(() {
          final type = (data?['type'] as String? ?? '').toUpperCase();
          if (type.contains('ORDER')) {
            _currentIndex = 3; // Orders tab
          } else {
            _currentIndex = 2; // Bookings tab
          }
        });
      }
    };
    _determineUserPositionWorkflow(showDialogOnFail: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptKannadaOnboarding();
    });
  }

  Future<void> _checkAndPromptKannadaOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPrompted = prefs.getBool('has_prompted_language_selection') ?? false;
      if (!hasPrompted && mounted) {
        await prefs.setBool('has_prompted_language_selection', true);
        _showLanguageOnboardingSheet();
      }
    } catch (e) {
      debugPrint("Error checking language onboarding: $e");
    }
  }

  void _showLanguageOnboardingSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.card,
      builder: (sheetContext) {
        String selected = LanguageService().currentLanguage;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.language_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Choose Language / ಭಾಷೆ ಆಯ್ಕೆ",
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.title,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Select your preferred app language",
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12,
                                  color: AppColors.subtitle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Option 1: English
                    InkWell(
                      onTap: () {
                        setSheetState(() => selected = 'en');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: selected == 'en'
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected == 'en' ? AppColors.primary : AppColors.border,
                            width: selected == 'en' ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('🇮🇳', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'English',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.title,
                                    ),
                                  ),
                                  Text(
                                    'Default app experience',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 11,
                                      color: AppColors.subtitle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              selected == 'en'
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: selected == 'en' ? AppColors.primary : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Option 2: Kannada
                    InkWell(
                      onTap: () {
                        setSheetState(() => selected = 'kn');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: selected == 'kn'
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected == 'kn' ? AppColors.primary : AppColors.border,
                            width: selected == 'kn' ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('💛❤️', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ಕನ್ನಡ (Kannada)',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.title,
                                    ),
                                  ),
                                  Text(
                                    'ಹಾಸನ, ಬೆಳಗಾವಿ ಮತ್ತು ಕರ್ನಾಟಕ ಸ್ಥಳೀಯ ಆವೃತ್ತಿ',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 11,
                                      color: AppColors.subtitle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              selected == 'kn'
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: selected == 'kn' ? AppColors.primary : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          await LanguageService().setLanguage(selected);
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                          if (mounted) setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Continue / ಮುಂದುವರಿಸಿ',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
        onProfileTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        },
        onSwitchTab: (tabIndex) => setState(() => _currentIndex = tabIndex),
      ),
      const MarketScreen(),
      const BookingsScreen(),
      OrdersScreen(
        onSwitchTab: (tabIndex) => setState(() => _currentIndex = tabIndex),
      ),
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
            selectedLabelStyle: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.storefront_outlined),
                activeIcon: Icon(Icons.storefront_rounded),
                label: 'Market',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment_rounded),
                label: 'Bookings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_shipping_outlined),
                activeIcon: Icon(Icons.local_shipping_rounded),
                label: 'Orders',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
