import 'package:flutter/material.dart';
import 'package:management_app/database/database_helper.dart';
import 'package:management_app/screens/splash_screen.dart';

void main() async {
  // Pastikan Flutter binding diinisialisasi
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inisialisasi database dengan error handling
    await DatabaseHelper().database;
  } catch (e) {
    debugPrint('Error initializing database: $e');
    // Bisa tambahkan logging atau error reporting di sini
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keuangan Fotokopian',
      theme: _buildTheme(),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildTheme() {
  return ThemeData(
    primarySwatch: MaterialColor(0xFF1565C0, const {
      50: Color(0xFFE3F2FD),
      100: Color(0xFFBBDEFB),
      200: Color(0xFF90CAF9),
      300: Color(0xFF64B5F6),
      400: Color(0xFF42A5F5),
      500: Color(0xFF2196F3),
      600: Color(0xFF1976D2),
      700: Color(0xFF1565C0),
      800: Color(0xFF0D47A1),
      900: Color(0xFF0A3D91),
    }),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1565C0),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );

  }
}