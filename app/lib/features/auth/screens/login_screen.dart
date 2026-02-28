import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/authenticated_user_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authenticatedUserProvider);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.assignment,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Ticket Management System',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              authState.isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(authenticatedUserProvider.notifier)
                            .login();
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in with Google'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              authState.when(
                data: (_) => const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (error, _) => Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
