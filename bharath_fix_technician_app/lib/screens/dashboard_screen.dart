import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/technician_firestore_service.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_style.dart';
import 'tabs/jobs_tab.dart';
import 'tabs/deliveries_tab.dart';
import 'tabs/earnings_tab.dart';
import 'tabs/profile_tab.dart';
import '../services/job_matching_service.dart';

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _isOnline = true;
  bool _canDeliver = true;
  bool _isBusy = false;
  String _techName = "Technician";
  String _techCategory = "Appliance Repair Specialist";
  StreamSubscription? _notifSub;

  final _authService = AuthService();
  final _firestoreService = TechnicianFirestoreService();
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    NotificationService.onNotificationTap = (data) {
      if (mounted) {
        final type = (data['type'] ?? data['notifType'] ?? '').toString().toUpperCase();
        setState(() {
          if (type.contains('ORDER') || type.contains('DELIVERY')) {
            _currentIndex = _canDeliver ? 1 : 0;
          } else {
            _currentIndex = 0; // Repairs Tab
          }
        });
      }
    };

    final techId = _authService.currentUser?.uid;
    if (techId != null) {
      bool isInitial = true;
      _notifSub = NotificationService.getTechNotificationsStream(techId).listen(
        (snapshot) {
          if (isInitial) {
            isInitial = false;
            return;
          }
          if (mounted) setState(() {});
        },
      );
    }
  }

  StreamSubscription? _profileSub;

  Future<void> _loadProfileData() async {
    final techId = _authService.currentUser?.uid;
    if (techId == null) return;

    _profileSub?.cancel();
    _profileSub = FirebaseFirestore.instance
        .collection('providers')
        .doc(techId)
        .snapshots()
        .listen((snap) {
      if (snap.exists && snap.data() != null && mounted) {
        _updateProfileFromDoc(snap.data()!);
      } else {
        FirebaseFirestore.instance
            .collection('providers')
            .doc(techId)
            .get()
            .then((techSnap) {
          if (techSnap.exists && techSnap.data() != null && mounted) {
            _updateProfileFromDoc(techSnap.data()!);
          }
        });
      }
    });

    if (_isOnline) {
      _locationService.startLiveTracking(techId);
    }
  }

  void _updateProfileFromDoc(Map<String, dynamic> data) {
    final List<dynamic> skillsRaw = data['skills'] as List<dynamic>? ?? [];
    final List<String> skills = skillsRaw.map((e) => e.toString()).toList();
    final String rawCategory = (data['category'] as String?) ?? '';
    final String computedCategory = JobMatchingService.getCategoryDisplayLabel(skills, rawCategory);
    final bool canDeliver = (data['canDeliver'] != false && data['isDeliveryPartner'] != false);
    final bool isBusy = (data['isBusy'] == true || (data['activeBookingId'] != null && data['activeBookingId'].toString().isNotEmpty));

    if (mounted) {
      setState(() {
        _techName = data['name'] ?? 'Technician';
        _techCategory = computedCategory;
        _isOnline = data['isOnline'] ?? true;
        _canDeliver = canDeliver;
        _isBusy = isBusy;
      });
    }
  }

  void _handleOnlineToggle(bool value) async {
    final techId = _authService.currentUser?.uid;
    if (techId == null) return;

    if (!value) {
      // Offline Guard: check if technician has ongoing repair or delivery
      try {
        final activeJobsSnap = await FirebaseFirestore.instance
            .collection('bookings')
            .where('technicianId', isEqualTo: techId)
            .get();
        final hasActiveJob = activeJobsSnap.docs.any((d) {
          final s = (d.data()['status'] ?? '').toString().toLowerCase();
          return ['accepted', 'in_progress', 'work_in_progress', 'work_started', 'repair_in_progress', 'inspection_in_progress'].contains(s);
        });

        final activeDeliveriesSnap = await FirebaseFirestore.instance
            .collection('orders')
            .where('deliveryPartnerId', isEqualTo: techId)
            .get();
        final hasActiveDelivery = activeDeliveriesSnap.docs.any((d) {
          final s = (d.data()['orderStatus'] ?? '').toString().toLowerCase();
          return ['outfordelivery', 'out_for_delivery', 'assigned'].contains(s);
        });

        if (hasActiveJob || hasActiveDelivery) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                    SizedBox(width: 8),
                    Text("Cannot Go Offline", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                content: Text(
                  hasActiveJob
                      ? "You currently have an active repair service in progress. Please complete the repair and verify completion OTP before going offline."
                      : "You currently have an appliance delivery order in transit. Please complete the customer handover before going offline.",
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text("Understood", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
          return;
        }
      } catch (e) {
        debugPrint("Error checking active tasks before offline toggle: $e");
      }
    }

    setState(() => _isOnline = value);
    await _firestoreService.toggleOnlineStatus(techId, value);
    if (value) {
      _locationService.startLiveTracking(techId);
    } else {
      _locationService.stopLiveTracking();
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Exit Technician App?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          "Are you sure you want to close the technician app?",
          style: TextStyle(fontSize: 13, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text("Exit App", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _notifSub?.cancel();
    _locationService.stopLiveTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final techId = _authService.currentUser?.uid ?? '';

    final pages = [
      JobsTab(techId: techId, isOnline: _isOnline),
      if (_canDeliver) DeliveriesTab(techId: techId),
      EarningsTab(techId: techId),
      ProfileTab(
        techName: _techName,
        techCategory: _techCategory,
        isOnline: _isOnline,
      ),
    ];

    final safeIndex = _currentIndex.clamp(0, pages.length - 1);

    Color statusBadgeColor = Colors.grey;
    String statusBadgeText = "OFFLINE";
    if (_isBusy) {
      statusBadgeColor = Colors.orange;
      statusBadgeText = "BUSY ON JOB";
    } else if (_isOnline) {
      statusBadgeColor = AppColors.success;
      statusBadgeText = "ONLINE";
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (safeIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          _showExitConfirmation();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _techName,
                style: AppTextStyle.mainTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 2),
              Text(
                _techCategory,
                style: AppTextStyle.subtitle.copyWith(fontSize: 12),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBadgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: statusBadgeColor,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 4,
                    backgroundColor: statusBadgeColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusBadgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusBadgeColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: _isOnline,
                    activeThumbColor: AppColors.success,
                    onChanged: _handleOnlineToggle,
                  ),
                ],
              ),
            ),
          ],
        ),
        body: IndexedStack(index: safeIndex, children: pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          backgroundColor: AppColors.background,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.handyman_rounded),
              label: "Repairs",
            ),
            if (_canDeliver)
              const BottomNavigationBarItem(
                icon: Icon(Icons.local_shipping_rounded),
                label: "Deliveries",
              ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: "Earnings",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}
