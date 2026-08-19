import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/technician_firestore_service.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_style.dart';
import 'tabs/jobs_tab.dart';
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
        setState(() {
          _currentIndex = 0; // Redirect to Jobs tab on notification click
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

    if (mounted) {
      setState(() {
        _techName = data['name'] ?? 'Technician';
        _techCategory = computedCategory;
        _isOnline = data['isOnline'] ?? true;
      });
    }
  }

  void _handleOnlineToggle(bool value) async {
    setState(() => _isOnline = value);
    final techId = _authService.currentUser?.uid;
    if (techId != null) {
      await _firestoreService.toggleOnlineStatus(techId, value);
      if (value) {
        _locationService.startLiveTracking(techId);
      } else {
        _locationService.stopLiveTracking();
      }
    }
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
      EarningsTab(techId: techId),
      ProfileTab(
        techName: _techName,
        techCategory: _techCategory,
        isOnline: _isOnline,
      ),
    ];

    return Scaffold(
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
              color: _isOnline
                  ? AppColors.success.withOpacity(0.12)
                  : Colors.grey.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isOnline ? AppColors.success : Colors.grey,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 4,
                  backgroundColor: _isOnline ? AppColors.success : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  _isOnline ? "ONLINE" : "OFFLINE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _isOnline ? AppColors.success : Colors.grey,
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
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_rounded),
            label: "My Jobs",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: "Earnings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
