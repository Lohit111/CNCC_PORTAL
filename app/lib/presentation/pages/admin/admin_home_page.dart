import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cncc_portal/presentation/pages/admin/raised_requests_page.dart';
import 'package:cncc_portal/presentation/pages/admin/replied_requests_page.dart';
import 'package:cncc_portal/presentation/pages/admin/assigned_requests_page.dart';
import 'package:cncc_portal/presentation/pages/admin/completed_requests_page.dart';
import 'package:cncc_portal/presentation/pages/admin/manage_roles_page.dart';
import 'package:cncc_portal/presentation/pages/admin/manage_types_page.dart';
import 'package:cncc_portal/presentation/pages/admin/manage_assignments_page.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
            icon: Icon(Icons.add_circle),
            label: 'Raised',
          ),
          NavigationDestination(
            icon: Icon(Icons.reply),
            label: 'Replied',
          ),
          NavigationDestination(
            icon: Icon(Icons.work),
            label: 'Assigned',
          ),
          NavigationDestination(
            icon: Icon(Icons.archive),
            label: 'Archive',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const RaisedRequestsPage();
      case 1:
        return const RepliedRequestsPage();
      case 2:
        return const AssignedRequestsPage();
      case 3:
        return const CompletedRequestsPage();
      case 4:
        return _buildSettingsTab();
      default:
        return const RaisedRequestsPage();
    }
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Admin Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Manage Roles'),
            subtitle: const Text('Assign roles to users'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageRolesPage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Manage Types'),
            subtitle: const Text('Configure request types'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageTypesPage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('View All Assignments'),
            subtitle: const Text('See all staff assignments'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageAssignmentsPage(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
