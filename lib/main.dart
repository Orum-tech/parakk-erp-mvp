// FILE: lib/main.dart
import 'package:flutter/material.dart';
import 'screens/role_selection_screen.dart'; // First screen import ki

void main() {
  runApp(const ParakkApp());
}

class ParakkApp extends StatelessWidget {
  const ParakkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Parakk ERP',
      theme: ThemeData(
        // "Decent Bluish" Global Theme setup
        primaryColor: const Color(0xFF1565C0), 
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0), // Royal Blue base
          brightness: Brightness.light,
        ),
      ),
      home: const RoleSelectionScreen(), // App yahan se start hoga
    );
  }
}