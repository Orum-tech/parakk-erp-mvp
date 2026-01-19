// FILE: lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/auth_wrapper.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';
import 'services/localization_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize theme service
  await ThemeService().initialize();
  // Initialize localization service
  await LocalizationService().initialize();
  runApp(const ParakkApp());
}

class ParakkApp extends StatefulWidget {
  const ParakkApp({super.key});

  @override
  State<ParakkApp> createState() => _ParakkAppState();
}

class _ParakkAppState extends State<ParakkApp> {
  final ThemeService _themeService = ThemeService();
  final LocalizationService _localizationService = LocalizationService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    // Listen to theme changes
    _themeService.themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadTheme() async {
    await _themeService.loadTheme();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ValueListenableBuilder<Locale>(
      valueListenable: _localizationService.localeNotifier,
      builder: (context, locale, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _themeService.themeNotifier,
          builder: (context, isDarkMode, _) {
            return MaterialApp(
              key: ValueKey(locale.languageCode), // Force complete rebuild on locale change
              debugShowCheckedModeBanner: false,
              title: 'Parakk ERP',
              locale: locale,
              localizationsDelegates: [
                const AppLocalizationsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('hi'),
              ],
              theme: ThemeData(
                primaryColor: const Color(0xFF1565C0),
                scaffoldBackgroundColor: Colors.white,
                fontFamily: 'Roboto',
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF1565C0),
                  brightness: Brightness.light,
                ),
              ),
              darkTheme: ThemeData(
                primaryColor: const Color(0xFF1565C0),
                scaffoldBackgroundColor: const Color(0xFF121212),
                fontFamily: 'Roboto',
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF1565C0),
                  brightness: Brightness.dark,
                ),
              ),
              themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}
