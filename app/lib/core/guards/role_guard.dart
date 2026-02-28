import 'package:flutter/material.dart';

class RoleGuard extends StatelessWidget {
  final String role;
  final Widget child;

  const RoleGuard({
    super.key,
    required this.role,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Validate role
    const validRoles = ['USER', 'ADMIN', 'STAFF', 'STORE'];
    
    if (!validRoles.contains(role)) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Invalid Role: $role',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return child;
  }
}
