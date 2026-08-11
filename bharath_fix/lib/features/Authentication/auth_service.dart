import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Firebase Phone Verification
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onError,
    Function(PhoneAuthCredential credential)? onAutoVerification,
  }) async {
    try {
      final formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (onAutoVerification != null) {
            onAutoVerification(credential);
          } else {
            await _auth.signInWithCredential(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint("Phone verification failed: ${e.message}");
          onError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint("verifyPhoneNumber exception: $e");
      rethrow;
    }
  }

  // Sign in with SMS OTP Code
  Future<UserCredential> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("OTP Verification failed: $e");
      rethrow;
    }
  }

  // Sign in as test user fallback if phone SMS verification is in test mode
  Future<UserCredential?> signInAsTestUser(String phoneNumber) async {
    try {
      if (_auth.currentUser != null) {
        return UserCredentialMock(_auth.currentUser!);
      }
      return await _auth.signInAnonymously();
    } catch (e) {
      debugPrint("Test user sign in fallback exception handled safely: $e");
      return null;
    }
  }


  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Sign out failed: $e");
    }
  }
}

class UserCredentialMock implements UserCredential {
  final User _user;
  UserCredentialMock(this._user);

  @override
  User? get user => _user;

  @override
  AuthCredential? get credential => null;

  @override
  AdditionalUserInfo? get additionalUserInfo => null;
}