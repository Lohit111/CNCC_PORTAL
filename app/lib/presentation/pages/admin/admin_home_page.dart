import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/type_entity.dart';
import 'package:cncc_portal/presentation/pages/shared/create_request_dialog.dart';
import 'package:cncc_portal/presentation/pages/shared/my_requests_page.dart';
import 'package:cncc_portal/presentation/pages/admin/raised_requests_page.dart';
import 'package:cncc_portal/presentation/pages/admin/replied_requests_page.dart';
import 'package:cncc_portal/presentation/pages/admin/assigned_requests_page.dart';
import 'package:cncc_portal/presentation/pages/admin/completed_requests_page.dart';
import 'package:cncc_portal/presentation/pages/admin/manage_roles_page.dart';
import 'package:cncc_portal/presentation/pages/admin/manage_types_page.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  final _networkClient = NetworkClient();
  int _selectedIndex = 0;
  final _myRequestsKey = GlobalKey<MyRequestsPageState>();

  void _showCreateRequestDialog() async {
    final mainTypes = await _loadMainTypes();
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateRequestDialog(mainTypes: mainTypes),
    );

    if (result == true && mounted) {
      // Switch to My Requests tab and refresh
      setState(() => _selectedIndex = 5);
      _myRequestsKey.currentState?.refresh();
    }
  }

  Future<List<MainType>> _loadMainTypes() async {
    try {
      final response = await _networkClient.get('/types/main');
      return (response.data as List)
          .map((json) => MainType.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

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
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'My Requests',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateRequestDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
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
      case 5:
        return MyRequestsPage(key: _myRequestsKey);
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
      ],
    );
  }
}
