import 'package:flutter/foundation.dart';

class DutyService extends ChangeNotifier {
  bool _isOnline = false;
  bool _isDutyBlocked = false;
  double _codDebt = 0.0;
  double _walletBalance = 450.0;

  bool get isOnline => _isOnline;
  bool get isDutyBlocked => _isDutyBlocked;
  double get codDebt => _codDebt;
  double get walletBalance => _walletBalance;

  void toggleDutyStatus() {
    if (_isDutyBlocked && !_isOnline) {
      // Prevent going online if COD debt exceeded
      return;
    }
    _isOnline = !_isOnline;
    notifyListeners();
  }

  void updateCodDebt(double debt) {
    _codDebt = debt;
    if (_codDebt >= 5000) {
      _isDutyBlocked = true;
      _isOnline = false;
    } else {
      _isDutyBlocked = false;
    }
    notifyListeners();
  }
}
