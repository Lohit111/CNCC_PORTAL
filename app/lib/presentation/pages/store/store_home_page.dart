import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:ticket_management_app/presentation/pages/store/pending_store_requests_page.dart';
import 'package:ticket_management_app/presentation/pages/store/approved_store_requests_page.dart';
import 'package:ticket_management_app/presentation/pages/store/fulfilled_rejected_page.dart';

class StoreHomePage extends ConsumerStatefulWidget {
  const StoreHomePage({super.key});

  @override
  ConsumerState<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends ConsumerState<StoreHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Dashboard'),
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
            icon: Icon(Icons.pending),
            label: 'Pending',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle),
            label: 'Approved',
          ),
          NavigationDestination(
            icon: Icon(Icons.archive),
            label: 'Completed',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const PendingStoreRequestsPage();
      case 1:
        return const ApprovedStoreRequestsPage();
      case 2:
        return const FulfilledRejectedPage();
      default:
        return const PendingStoreRequestsPage();
    }
  }
}
