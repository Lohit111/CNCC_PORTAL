import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:ticket_management_app/presentation/pages/staff/assigned_to_me_page.dart';
import 'package:ticket_management_app/presentation/pages/staff/in_progress_page.dart';
import 'package:ticket_management_app/presentation/pages/staff/completed_by_me_page.dart';
import 'package:ticket_management_app/presentation/pages/staff/my_store_requests_page.dart';

class StaffHomePage extends ConsumerStatefulWidget {
  const StaffHomePage({super.key});

  @override
  ConsumerState<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends ConsumerState<StaffHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await fb.FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_ind),
            label: 'Assigned',
          ),
          NavigationDestination(
            icon: Icon(Icons.work),
            label: 'In Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle),
            label: 'Completed',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory),
            label: 'Store Requests',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const AssignedToMePage();
      case 1:
        return const InProgressPage();
      case 2:
        return const CompletedByMePage();
      case 3:
        return const MyStoreRequestsPage();
      default:
        return const AssignedToMePage();
    }
  }
}
