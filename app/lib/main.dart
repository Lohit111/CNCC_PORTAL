import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cncc_portal/firebase_options.dart';
import 'package:cncc_portal/core/network/network_client.dart';
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
      theme: _buildLightTheme(),
      themeMode: ThemeMode.light,
      home: const HomeBuilder(),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildLightTheme() {
    const seed = Color(0xFF6C63FF); // indigo-violet accent
    final cs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      surface: Colors.white,
      onSurface: const Color(0xFF1C1B1F),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFFF4F4F8),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF4F4F8),
        foregroundColor: Color(0xFF1C1B1F),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF1C1B1F),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: seed.withValues(alpha: 0.18),
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
        backgroundColor: const Color(0xFFE8EAF0),
        selectedColor: seed.withValues(alpha: 0.2),
        labelStyle: const TextStyle(fontSize: 12),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEEEEF5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: seed, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF6B6B80)),
        hintStyle: const TextStyle(color: Color(0xFF9E9EAF)),
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
          foregroundColor: const Color(0xFF1C1B1F),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.08),
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF1C1B1F),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color.fromARGB(255, 95, 95, 95),
        contentTextStyle: const TextStyle(color: Colors.white),
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

    // Force name entry if not set
    if (user.name == null || user.name!.trim().isEmpty) {
      return _NameGatePage(user: user);
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

/// Blocking page shown when the user has no name set.
/// Cannot be dismissed — user must enter a name to proceed.
class _NameGatePage extends ConsumerStatefulWidget {
  final dynamic user;
  const _NameGatePage({required this.user});

  @override
  ConsumerState<_NameGatePage> createState() => _NameGatePageState();
}

class _NameGatePageState extends ConsumerState<_NameGatePage> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = NetworkClient();
      await client
          .put('/users/me/name', data: {'name': _controller.text.trim()});
      await ref.read(authProvider.notifier).refresh();
    } catch (e) {
      setState(() {
        _error = 'Failed to save name. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.person_rounded,
                          size: 36, color: cs.primary),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'What should we call you?',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please enter your name to continue.',
                      style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'e.g. John Doe',
                        prefixIcon: Icon(Icons.badge_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Name cannot be empty';
                        if (v.trim().length < 2) return 'Name is too short';
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: TextStyle(color: cs.error, fontSize: 13)),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Continue',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
