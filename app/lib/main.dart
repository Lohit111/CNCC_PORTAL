import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'presentation/providers/authenticated_user_provider.dart';
import 'core/guards/role_guard.dart';
import 'features/user/screens/user_home_screen.dart';
import 'features/admin/screens/admin_home_screen.dart';
import 'features/staff/screens/staff_home_screen.dart';
import 'features/store/screens/store_home_screen.dart';
import 'features/auth/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ticket Management System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authenticatedUserProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(authenticatedUserProvider.notifier).refresh();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (userData) {
        if (userData == null) {
          return const LoginScreen();
        }

        // Role-based routing
        return RoleGuard(
          role: userData.role,
          child: _getHomeScreen(userData.role),
        );
      },
    );
  }

  Widget _getHomeScreen(String role) {
    switch (role) {
      case 'USER':
        return const UserHomeScreen();
      case 'ADMIN':
        return const AdminHomeScreen();
      case 'STAFF':
        return const StaffHomeScreen();
      case 'STORE':
        return const StoreHomeScreen();
      default:
        return const Scaffold(
          body: Center(child: Text('Invalid role')),
        );
    }
  }
}
