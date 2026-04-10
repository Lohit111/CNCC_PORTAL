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
      title: 'Request Management System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeBuilder(),
      debugShowCheckedModeBanner: false,
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Authentication Error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  authState.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).refresh();
                  },
                  child: const Text('Retry'),
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
                const Icon(
                  Icons.warning,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                Text('Unknown role: ${user.role}'),
                const SizedBox(height: 8),
                const Text('Please contact your administrator'),
              ],
            ),
          ),
        );
    }
  }
}
