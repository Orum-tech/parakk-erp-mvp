import 'package:flutter/material.dart';
import 'dart:async';
import 'auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    
    _controller.forward();
    
    // Navigate to auth_wrapper after 5 seconds
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Clamp animation values to ensure they're within valid range
          final fadeValue = _fadeAnimation.value.clamp(0.0, 1.0);
          final scaleValue = _scaleAnimation.value.clamp(0.0, 1.0);
          
          return Center(
            child: Opacity(
              opacity: fadeValue,
              child: Transform.scale(
                scale: scaleValue,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Image with shadow
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1565C0).withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'lib/logo.jpeg',
                          width: 280,
                          height: 280,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback if image fails to load
                            return Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                size: 120,
                                color: Color(0xFF1565C0),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
