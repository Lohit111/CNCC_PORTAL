import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cncc_portal/firebase_options.dart';
import 'package:cncc_portal/presentation/providers/auth_provider.dart';
import 'package:cncc_portal/presentation/pages/login_page.dart';
import 'package:cncc_portal/presentation/pages/user/user_home_page.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_home_page.dart';
import 'package:cncc_portal/presentation/pages/staff/staff_home_page.dart';
import 'package:cncc_portal/presentation/pages/store/store_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CNCC Portal',
      theme: _buildDarkTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.dark,
      home: const HomeBuilder(),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildDarkTheme() {
    const seed = Color(0xFF6C63FF); // indigo-violet accent
    final cs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      surface: const Color(0xFF1E1E2E),
      onSurface: const Color(0xFFCDD6F4),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFF181825),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E2E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF181825),
        foregroundColor: Color(0xFFCDD6F4),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFCDD6F4),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E2E),
        indicatorColor: seed.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seed,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF313244),
        selectedColor: seed.withValues(alpha: 0.3),
        labelStyle: const TextStyle(fontSize: 12),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF313244),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: seed, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF9399B2)),
        hintStyle: const TextStyle(color: Color(0xFF6C7086)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: seed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFCDD6F4),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          color: Color(0xFFCDD6F4),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF313244),
        contentTextStyle: const TextStyle(color: Color(0xFFCDD6F4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class HomeBuilder extends ConsumerWidget {
  const HomeBuilder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authState.error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.error_outline_rounded,
                      size: 36, color: Colors.red),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Authentication Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  authState.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.red.withValues(alpha: 0.8), fontSize: 13),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () => ref.read(authProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = authState.user;

    if (user == null) {
      return const LoginPage();
    }

    // Navigate based on user role
    switch (user.role) {
      case 'USER':
        return const UserHomePage();
      case 'ADMIN':
        return const AdminHomePage();
      case 'STAFF':
        return const StaffHomePage();
      case 'STORE':
        return const StoreHomePage();
      default:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      size: 36, color: Colors.orange),
                ),
                const SizedBox(height: 20),
                Text('Unknown role: ${user.role}',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 6),
                const Text('Please contact your administrator',
                    style: TextStyle(color: Color(0xFF6C7086))),
              ],
            ),
          ),
        );
    }
  }
}
