import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants/colors.dart';
import 'screens/splash_screen.dart';
import 'services/nutrition_service.dart';
import 'services/reward_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NutritionService()),
        ChangeNotifierProvider(create: (_) => RewardService()),
      ],
      child: const CekPiringKuApp(),
    ),
  );
}

class CekPiringKuApp extends StatelessWidget {
  const CekPiringKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cek-PiringKu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryGreen,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
          secondary: AppColors.secondaryGreen,
          surface: AppColors.white,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
