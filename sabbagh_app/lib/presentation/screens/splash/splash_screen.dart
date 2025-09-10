import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';
import 'package:sabbagh_app/core/constants/app_strings.dart';
import 'package:sabbagh_app/presentation/controllers/splash_controller.dart';

/// Splash screen
class SplashScreen extends GetView<SplashController> {
  /// Creates a new [SplashScreen]
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top spacer
                    const SizedBox(height: 20),
                    
                    // Logo section
                    Expanded(
                      flex: 3,
                      child: Container(
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: constraints.maxWidth * 0.4,
                          height: constraints.maxWidth * 0.4,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    
                    // App name
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          AppStrings.appName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: constraints.maxWidth < 600 ? 22 : 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    // Loading section
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.white, 
                              fontSize: constraints.maxWidth < 600 ? 16 : 20
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Bottom spacer
                    const SizedBox(height: 20),
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