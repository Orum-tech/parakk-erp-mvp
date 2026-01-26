import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class SettingsService {
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyDarkMode = 'dark_mode_enabled';
  static const String _keyBiometric = 'biometric_enabled';
  static const String _keyLanguage = 'selected_language';

  final LocalAuthentication _localAuth = LocalAuthentication();

  // Notifications
  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotifications) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }

  // Dark Mode
  Future<bool> getDarkModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  Future<void> setDarkModeEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  // Biometric
  Future<bool> getBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometric) ?? false;
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometric, value);
  }

  // Check if biometric is available
  Future<bool> isBiometricAvailable() async {
    try {
      // First check if device supports biometrics
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) {
        return false;
      }
      
      // Check available biometric types
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  // Authenticate with biometric
  Future<Map<String, dynamic>> authenticateWithBiometric() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return {
          'success': false,
          'error': 'Biometric authentication is not available on this device',
        };
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to enable biometric login',
        options: const AuthenticationOptions(
          biometricOnly: false, // Allow fallback to device PIN/password
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      
      if (authenticated) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'error': 'Authentication was cancelled or failed',
        };
      }
    } on PlatformException catch (e) {
      String errorMessage = 'Biometric authentication failed';
      
      switch (e.code) {
        case 'NotAvailable':
          errorMessage = 'Biometric authentication is not available';
          break;
        case 'NotEnrolled':
          errorMessage = 'No biometrics enrolled. Please set up Face ID or Fingerprint in device settings';
          break;
        case 'LockedOut':
          errorMessage = 'Biometric authentication is locked. Please unlock your device';
          break;
        case 'PermanentlyLockedOut':
          errorMessage = 'Biometric authentication is permanently locked. Please use device PIN/password';
          break;
        case 'UserCancel':
          errorMessage = 'Authentication was cancelled';
          break;
        default:
          errorMessage = 'Authentication failed: ${e.message ?? e.code}';
      }
      
      debugPrint('Biometric authentication error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      debugPrint('Unexpected biometric error: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred: $e',
      };
    }
  }

  // Language
  Future<String> getSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'en';
  }

  Future<void> setSelectedLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, languageCode);
  }

  // Get available languages - Only Hindi for students
  List<Map<String, String>> getAvailableLanguages() {
    return [
      {'code': 'hi', 'name': 'हिंदी (Hindi)'},
    ];
  }
}
