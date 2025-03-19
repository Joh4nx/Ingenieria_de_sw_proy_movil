import 'package:appmarketplace/screens/notifications_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/forgot_password_page.dart';
import 'screens/home_page.dart';
import 'screens/publicar_page.dart';
import 'screens/admin_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Detecta si el dispositivo es una tablet
  bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  // Paleta de colores moderna
  static const Color primaryColor = Color(0xFF6C5CE7);
  static const Color secondaryColor = Color(0xFF00B894);
  static const Color accentColor = Color(0xFFFF7675);
  static const Color backgroundColor = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marketplace Pro',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light, // Forzamos el modo light
      theme: getAppTheme(context),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/home': (context) => const HomePage(),
        '/publicar': (context) => const PublicarPage(),
        '/adminPanel': (context) => const AdminHomePage(),
        '/notifications': (context) => const NotificationsPage(),
      },
    );
  }

  // Configura el tema según el tipo de dispositivo
  ThemeData getAppTheme(BuildContext context) {
    bool tablet = isTablet(context);

    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Colors.white,
        background: backgroundColor,
        error: accentColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black,
        onBackground: Colors.black,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontSize: tablet ? 28 : 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: tablet
              ? const EdgeInsets.symmetric(horizontal: 40, vertical: 20)
              : const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          textStyle: TextStyle(
            fontSize: tablet ? 20 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: tablet
            ? const EdgeInsets.symmetric(horizontal: 35, vertical: 25)
            : const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: tablet ? 6 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: tablet ? 34 : 28,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF2D3436),
        ),
        titleLarge: TextStyle(
          fontSize: tablet ? 26 : 22,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2D3436),
        ),
        bodyLarge: TextStyle(
          fontSize: tablet ? 20 : 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF2D3436),
        ),
        bodyMedium: TextStyle(
          fontSize: tablet ? 18 : 14,
          color: const Color(0xFF636E72),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.white,
        elevation: 10,
        selectedLabelStyle: TextStyle(
          fontWeight: tablet ? FontWeight.bold : FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
    );
  }

  // Método para determinar el número de columnas en función del dispositivo
  int getGridCount(BuildContext context) {
    return isTablet(context) ? 4 : 2;
  }
}
