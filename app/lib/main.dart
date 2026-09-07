import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cncc_portal/firebase_options.dart';
import 'package:cncc_portal/core/services/notification_service.dart';
import 'package:cncc_portal/presentation/providers/auth_provider.dart';
import 'package:cncc_portal/presentation/pages/shared/pages/login_page.dart';
import 'package:cncc_portal/presentation/pages/shared/entry-gates/name_gate_page.dart';
import 'package:cncc_portal/presentation/pages/user/user_home_page.dart';
import 'package:cncc_portal/presentation/pages/admin/admin_home_page.dart';
import 'package:cncc_portal/presentation/pages/staff/staff_home_page.dart';
import 'package:cncc_portal/presentation/pages/store/store_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final container = ProviderContainer();
  await NotificationService.init(container);
  runApp(UncontrolledProviderScope(
    container: container,
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CNCC Portal',
      theme: _buildLightTheme(),
      themeMode: ThemeMode.light,
      home: const HomeBuilder(),
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
    );
  }

  ThemeData _buildLightTheme() {
    // Primary accent: professional indigo-blue.
    const seed = Color(0xFF5B5FC7);

    // Neutral surfaces.
    const background = Color(0xFFE9EAEE);
    const textPrimary = Color(0xFF202124);
    const textSecondary = Color(0xFF6B6F78);

    final cs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      surface: Colors.white,
      onSurface: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,

      // ----------------------------------------------------------
      // GENERAL
      // ----------------------------------------------------------

      scaffoldBackgroundColor: background,

      fontFamily: 'Roboto',

      visualDensity: VisualDensity.standard,

      // ----------------------------------------------------------
      // APP BAR
      // ----------------------------------------------------------

      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),

      // ----------------------------------------------------------
      // CARDS
      // ----------------------------------------------------------

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.07),
          ),
        ),
      ),

      // ----------------------------------------------------------
      // NAVIGATION BAR
      // ----------------------------------------------------------

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        height: 68,
        indicatorColor: seed.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: seed,
                size: 23,
              );
            }

            return const IconThemeData(
              color: textSecondary,
              size: 23,
            );
          },
        ),
      ),

      // ----------------------------------------------------------
      // FLOATING ACTION BUTTON
      // ----------------------------------------------------------

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seed,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      // ----------------------------------------------------------
      // INPUT FIELDS
      // ----------------------------------------------------------

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F3F6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: seed,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: Color(0xFFD32F2F),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: Color(0xFFD32F2F),
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF9699A3),
          fontSize: 14,
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      // ----------------------------------------------------------
      // ELEVATED BUTTON
      // ----------------------------------------------------------

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ----------------------------------------------------------
      // OUTLINED BUTTON
      // ----------------------------------------------------------

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size(0, 46),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ----------------------------------------------------------
      // TEXT BUTTON
      // ----------------------------------------------------------

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: seed,
          minimumSize: const Size(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ----------------------------------------------------------
      // CHIPS
      // ----------------------------------------------------------

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE1E2E7),
        selectedColor: seed.withValues(alpha: 0.15),
        disabledColor: const Color(0xFFE5E5E7),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 2,
        ),
      ),

      // ----------------------------------------------------------
      // DIVIDERS
      // ----------------------------------------------------------

      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.08),
        thickness: 1,
        space: 1,
      ),

      // ----------------------------------------------------------
      // DIALOGS
      // ----------------------------------------------------------

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
          height: 1.4,
        ),
      ),

      // ----------------------------------------------------------
      // BOTTOM SHEETS
      // ----------------------------------------------------------

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
      ),

      // ----------------------------------------------------------
      // DROPDOWNS / MENUS
      // ----------------------------------------------------------

      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          color: textPrimary,
          fontSize: 14,
        ),
      ),

      // ----------------------------------------------------------
      // LIST TILES
      // ----------------------------------------------------------

      listTileTheme: const ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 2,
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 12,
        ),
      ),

      // ----------------------------------------------------------
      // PROGRESS INDICATORS
      // ----------------------------------------------------------

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: seed,
        linearTrackColor: Color(0xFFE0E1E6),
        circularTrackColor: Color(0xFFE0E1E6),
      ),

      // ----------------------------------------------------------
      // CHECKBOX
      // ----------------------------------------------------------

      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: BorderSide(
          color: Colors.black.withValues(alpha: 0.3),
        ),
        fillColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return seed;
            }

            return Colors.transparent;
          },
        ),
      ),

      // ----------------------------------------------------------
      // SNACKBAR
      // ----------------------------------------------------------

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF323338),
        elevation: 4,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        actionTextColor: Colors.white,
      ),

      // ----------------------------------------------------------
      // TOOLTIP
      // ----------------------------------------------------------

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF323338),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),

      // ----------------------------------------------------------
      // ICONS
      // ----------------------------------------------------------

      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 22,
      ),

      // ----------------------------------------------------------
      // TABS
      // ----------------------------------------------------------

      tabBarTheme: const TabBarThemeData(
        labelColor: seed,
        unselectedLabelColor: textSecondary,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: seed,
        indicatorSize: TabBarIndicatorSize.label,
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

    // Gate: force profile completion if name or phone is missing
    if (user.name == null ||
        user.name!.trim().isEmpty ||
        user.phone == null ||
        user.phone!.trim().isEmpty) {
      return NameGatePage(user: user);
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
