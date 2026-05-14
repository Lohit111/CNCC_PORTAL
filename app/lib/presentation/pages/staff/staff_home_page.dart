import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/type_entity.dart';
import 'package:cncc_portal/presentation/pages/shared/create_request_dialog.dart';
import 'package:cncc_portal/presentation/pages/shared/my_requests_page.dart';
import 'package:cncc_portal/presentation/pages/staff/assigned_to_me_page.dart';
import 'package:cncc_portal/presentation/pages/staff/in_progress_page.dart';
import 'package:cncc_portal/presentation/pages/staff/completed_by_me_page.dart';
import 'package:cncc_portal/presentation/pages/staff/my_store_requests_page.dart';

class StaffHomePage extends ConsumerStatefulWidget {
  const StaffHomePage({super.key});

  @override
  ConsumerState<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends ConsumerState<StaffHomePage> {
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
      setState(() => _selectedIndex = 4);
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
        return const AssignedToMePage();
      case 1:
        return const InProgressPage();
      case 2:
        return const CompletedByMePage();
      case 3:
        return const MyStoreRequestsPage();
      case 4:
        return MyRequestsPage(key: _myRequestsKey);
      default:
        return const AssignedToMePage();
    }
  }
}
