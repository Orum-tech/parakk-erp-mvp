import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _keyLanguage = 'selected_language';
  
  static final LocalizationService _instance = LocalizationService._internal();
  
  factory LocalizationService() {
    return _instance;
  }
  
  LocalizationService._internal();

  final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en'));

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_keyLanguage) ?? 'en';
    localeNotifier.value = Locale(languageCode);
  }

  Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, languageCode);
    localeNotifier.value = Locale(languageCode);
  }

  String getLanguage(BuildContext context) {
    return Localizations.localeOf(context).languageCode;
  }

  // Translations
  String translate(String key, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return _getTranslation(key, locale);
  }

  String _getTranslation(String key, String locale) {
    final translations = locale == 'hi' ? _hindiTranslations : _englishTranslations;
    return translations[key] ?? key;
  }

  static const Map<String, String> _englishTranslations = {
    'app_name': 'Parakk ERP',
    'welcome': 'Welcome to Parakk',
    'select_role': 'Select your role to get started',
    'student': 'Student',
    'student_desc': 'View assignments, results & progress',
    'teacher': 'Teacher',
    'teacher_desc': 'Manage classes, attendance & marks',
    'parent': 'Parent',
    'parent_desc': 'Track child\'s performance & updates',
    'settings': 'Settings',
    'general': 'General',
    'preferences': 'Preferences',
    'push_notifications': 'Push Notifications',
    'notifications_desc': 'Get updates about homework & exams',
    'dark_mode': 'Dark Mode',
    'dark_mode_desc': 'Switch to dark theme',
    'biometric': 'Face ID / Fingerprint',
    'biometric_desc': 'Secure login with biometric authentication',
    'biometric_unavailable': 'Biometric not available on this device',
    'change_language': 'Change Language',
    'select_language': 'Select Language',
    'secure_private': 'Secure • Private • v1.0',
    // Dashboard & Navigation
    'dashboard': 'Dashboard',
    'home': 'Home',
    'profile': 'Profile',
    'logout': 'Logout',
    'login': 'Login',
    'signup': 'Sign Up',
    'email': 'Email',
    'password': 'Password',
    'confirm_password': 'Confirm Password',
    'forgot_password': 'Forgot Password?',
    'dont_have_account': 'Don\'t have an account?',
    'already_have_account': 'Already have an account?',
    'loading': 'Loading...',
    'cancel': 'Cancel',
    'submit': 'Submit',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'back': 'Back',
    'next': 'Next',
    'done': 'Done',
    'error': 'Error',
    'success': 'Success',
    'warning': 'Warning',
    'info': 'Information',
    'yes': 'Yes',
    'no': 'No',
    'ok': 'OK',
  };

  static const Map<String, String> _hindiTranslations = {
    'app_name': 'परक्क ERP',
    'welcome': 'परक्क में आपका स्वागत है',
    'select_role': 'शुरू करने के लिए अपनी भूमिका चुनें',
    'student': 'छात्र',
    'student_desc': 'असाइनमेंट, परिणाम और प्रगति देखें',
    'teacher': 'शिक्षक',
    'teacher_desc': 'कक्षा, उपस्थिति और अंक प्रबंधित करें',
    'parent': 'माता-पिता',
    'parent_desc': 'बच्चे की प्रगति और अपडेट ट्रैक करें',
    'settings': 'सेटिंग्स',
    'general': 'सामान्य',
    'preferences': 'प्राथमिकताएं',
    'push_notifications': 'पुश सूचनाएं',
    'notifications_desc': 'होमवर्क और परीक्षाओं के बारे में अपडेट प्राप्त करें',
    'dark_mode': 'डार्क मोड',
    'dark_mode_desc': 'डार्क थीम पर स्विच करें',
    'biometric': 'फेस आईडी / फिंगरप्रिंट',
    'biometric_desc': 'बायोमेट्रिक प्रमाणीकरण के साथ सुरक्षित लॉगिन',
    'biometric_unavailable': 'इस डिवाइस पर बायोमेट्रिक उपलब्ध नहीं है',
    'change_language': 'भाषा बदलें',
    'select_language': 'भाषा चुनें',
    'secure_private': 'सुरक्षित • निजी • v1.0',
    // Dashboard & Navigation
    'dashboard': 'डैशबोर्ड',
    'home': 'होम',
    'profile': 'प्रोफाइल',
    'logout': 'लॉगआउट',
    'login': 'लॉगिन',
    'signup': 'साइन अप',
    'email': 'ईमेल',
    'password': 'पासवर्ड',
    'confirm_password': 'पासवर्ड की पुष्टि करें',
    'forgot_password': 'पासवर्ड भूल गए?',
    'dont_have_account': 'खाता नहीं है?',
    'already_have_account': 'पहले से खाता है?',
    'loading': 'लोड हो रहा है...',
    'cancel': 'रद्द करें',
    'submit': 'जमा करें',
    'save': 'सहेजें',
    'delete': 'हटाएं',
    'edit': 'संपादित करें',
    'back': 'वापस',
    'next': 'अगला',
    'done': 'पूर्ण',
    'error': 'त्रुटि',
    'success': 'सफल',
    'warning': 'चेतावनी',
    'info': 'जानकारी',
    'yes': 'हाँ',
    'no': 'नहीं',
    'ok': 'ठीक है',
  };
}

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  String get appName => LocalizationService()._getTranslation('app_name', locale.languageCode);
  String get welcome => LocalizationService()._getTranslation('welcome', locale.languageCode);
  String get selectRole => LocalizationService()._getTranslation('select_role', locale.languageCode);
  String get student => LocalizationService()._getTranslation('student', locale.languageCode);
  String get studentDesc => LocalizationService()._getTranslation('student_desc', locale.languageCode);
  String get teacher => LocalizationService()._getTranslation('teacher', locale.languageCode);
  String get teacherDesc => LocalizationService()._getTranslation('teacher_desc', locale.languageCode);
  String get parent => LocalizationService()._getTranslation('parent', locale.languageCode);
  String get parentDesc => LocalizationService()._getTranslation('parent_desc', locale.languageCode);
  String get settings => LocalizationService()._getTranslation('settings', locale.languageCode);
  String get general => LocalizationService()._getTranslation('general', locale.languageCode);
  String get preferences => LocalizationService()._getTranslation('preferences', locale.languageCode);
  String get pushNotifications => LocalizationService()._getTranslation('push_notifications', locale.languageCode);
  String get notificationsDesc => LocalizationService()._getTranslation('notifications_desc', locale.languageCode);
  String get darkMode => LocalizationService()._getTranslation('dark_mode', locale.languageCode);
  String get darkModeDesc => LocalizationService()._getTranslation('dark_mode_desc', locale.languageCode);
  String get biometric => LocalizationService()._getTranslation('biometric', locale.languageCode);
  String get biometricDesc => LocalizationService()._getTranslation('biometric_desc', locale.languageCode);
  String get biometricUnavailable => LocalizationService()._getTranslation('biometric_unavailable', locale.languageCode);
  String get changeLanguage => LocalizationService()._getTranslation('change_language', locale.languageCode);
  String get selectLanguage => LocalizationService()._getTranslation('select_language', locale.languageCode);
  String get securePrivate => LocalizationService()._getTranslation('secure_private', locale.languageCode);
  
  // Dashboard & Navigation
  String get dashboard => LocalizationService()._getTranslation('dashboard', locale.languageCode);
  String get home => LocalizationService()._getTranslation('home', locale.languageCode);
  String get profile => LocalizationService()._getTranslation('profile', locale.languageCode);
  String get logout => LocalizationService()._getTranslation('logout', locale.languageCode);
  String get login => LocalizationService()._getTranslation('login', locale.languageCode);
  String get signup => LocalizationService()._getTranslation('signup', locale.languageCode);
  String get email => LocalizationService()._getTranslation('email', locale.languageCode);
  String get password => LocalizationService()._getTranslation('password', locale.languageCode);
  String get confirmPassword => LocalizationService()._getTranslation('confirm_password', locale.languageCode);
  String get forgotPassword => LocalizationService()._getTranslation('forgot_password', locale.languageCode);
  String get dontHaveAccount => LocalizationService()._getTranslation('dont_have_account', locale.languageCode);
  String get alreadyHaveAccount => LocalizationService()._getTranslation('already_have_account', locale.languageCode);
  String get loading => LocalizationService()._getTranslation('loading', locale.languageCode);
  String get cancel => LocalizationService()._getTranslation('cancel', locale.languageCode);
  String get submit => LocalizationService()._getTranslation('submit', locale.languageCode);
  String get save => LocalizationService()._getTranslation('save', locale.languageCode);
  String get delete => LocalizationService()._getTranslation('delete', locale.languageCode);
  String get edit => LocalizationService()._getTranslation('edit', locale.languageCode);
  String get back => LocalizationService()._getTranslation('back', locale.languageCode);
  String get next => LocalizationService()._getTranslation('next', locale.languageCode);
  String get done => LocalizationService()._getTranslation('done', locale.languageCode);
  String get error => LocalizationService()._getTranslation('error', locale.languageCode);
  String get success => LocalizationService()._getTranslation('success', locale.languageCode);
  String get warning => LocalizationService()._getTranslation('warning', locale.languageCode);
  String get info => LocalizationService()._getTranslation('info', locale.languageCode);
  String get yes => LocalizationService()._getTranslation('yes', locale.languageCode);
  String get no => LocalizationService()._getTranslation('no', locale.languageCode);
  String get ok => LocalizationService()._getTranslation('ok', locale.languageCode);
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

// Helper extension to get translations easily from any context
extension LocalizationHelper on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this);
  
  String translate(String key) {
    return LocalizationService()._getTranslation(key, Localizations.localeOf(this).languageCode);
  }
}
