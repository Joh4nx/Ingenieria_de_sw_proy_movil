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

  // Nueva paleta de colores moderna
  static final Color primaryColor = const Color(0xFF6C5CE7);    // Púrpura moderno
  static final Color secondaryColor = const Color(0xFF00B894);  // Verde fresco
  static final Color accentColor = const Color(0xFFFF7675);     // Coral suave
  static final Color backgroundColor = const Color(0xFFF8F9FA); // Gris muy claro

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marketplace Pro',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light, // Forzamos el modo light
      theme: ThemeData(
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
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6C5CE7),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            fontSize: 22,
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
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D3436),
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D3436),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3436),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF636E72),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: Colors.white,
          elevation: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        ),
      ),
      // Configuración de rutas
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
}
