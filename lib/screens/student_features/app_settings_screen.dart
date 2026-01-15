import 'package:flutter/material.dart';
import '../../services/settings_service.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  
  bool _notifications = true;
  bool _darkMode = false;
  bool _biometric = false;
  bool _biometricAvailable = false;
  String _selectedLanguage = 'en';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _settingsService.getNotificationsEnabled();
      final darkMode = await _settingsService.getDarkModeEnabled();
      final biometric = await _settingsService.getBiometricEnabled();
      final language = await _settingsService.getSelectedLanguage();
      final biometricAvailable = await _settingsService.isBiometricAvailable();

      setState(() {
        _notifications = notifications;
        _darkMode = darkMode;
        _biometric = biometric;
        _biometricAvailable = biometricAvailable;
        _selectedLanguage = language;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _handleNotificationsChanged(bool value) async {
    setState(() => _notifications = value);
    await _settingsService.setNotificationsEnabled(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _handleDarkModeChanged(bool value) async {
    setState(() => _darkMode = value);
    await _settingsService.setDarkModeEnabled(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Dark mode enabled. Restart app to apply.' : 'Dark mode disabled. Restart app to apply.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleBiometricChanged(bool value) async {
    if (value) {
      // Test biometric authentication before enabling
      final authenticated = await _settingsService.authenticateWithBiometric();
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }
    
    setState(() => _biometric = value);
    await _settingsService.setBiometricEnabled(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Biometric authentication enabled' : 'Biometric authentication disabled'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _showLanguageSelector() async {
    final languages = _settingsService.getAvailableLanguages();
    final currentLanguage = languages.firstWhere(
      (lang) => lang['code'] == _selectedLanguage,
      orElse: () => languages[0],
    );

    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Language',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...languages.map((lang) => ListTile(
              title: Text(lang['name'] ?? ''),
              trailing: lang['code'] == _selectedLanguage
                  ? const Icon(Icons.check, color: Color(0xFF1565C0))
                  : null,
              onTap: () => Navigator.pop(context, lang['code']),
            )),
          ],
        ),
      ),
    );

    if (selected != null && selected != _selectedLanguage) {
      setState(() => _selectedLanguage = selected);
      await _settingsService.setSelectedLanguage(selected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language changed to ${languages.firstWhere((l) => l['code'] == selected)['name']}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text("Settings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("General", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          _buildSwitchTile(
            "Push Notifications",
            "Get updates about homework & exams",
            _notifications,
            _handleNotificationsChanged,
          ),
          _buildSwitchTile(
            "Dark Mode",
            "Switch to dark theme",
            _darkMode,
            _handleDarkModeChanged,
          ),
          _buildSwitchTile(
            "Face ID / Fingerprint",
            _biometricAvailable ? "Secure login with biometric" : "Biometric not available on this device",
            _biometric,
            _handleBiometricChanged,
            enabled: _biometricAvailable,
          ),

          const SizedBox(height: 30),
          const Text("Preferences", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          _buildActionTile(
            "Change Language",
            Icons.language,
            _showLanguageSelector,
            subtitle: _settingsService.getAvailableLanguages()
                .firstWhere((l) => l['code'] == _selectedLanguage)['name'] ?? 'English',
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged, {
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        activeThumbColor: const Color(0xFF1565C0),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap, {String? subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}