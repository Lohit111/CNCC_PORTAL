import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/domain/entities/type_entity.dart';
import 'package:cncc_portal/presentation/pages/shared/create_request_dialog.dart';
import 'package:cncc_portal/presentation/pages/user/active_requests_page.dart';
import 'package:cncc_portal/presentation/pages/user/replied_requests_user_page.dart';
import 'package:cncc_portal/presentation/pages/user/completed_requests_user_page.dart';

class UserHomePage extends ConsumerStatefulWidget {
  const UserHomePage({super.key});

  @override
  ConsumerState<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends ConsumerState<UserHomePage> {
  final _networkClient = NetworkClient();
  int _selectedIndex = 0;
  final _activeRequestsKey = GlobalKey<ActiveRequestsPageState>();

  void _showCreateRequestDialog() async {
    final mainTypes = await _loadMainTypes();
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateRequestDialog(mainTypes: mainTypes),
    );

    if (result == true && mounted) {
      setState(() => _selectedIndex = 0);
      _activeRequestsKey.currentState?.refresh();
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
        title: const Text('CNCC Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
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
            icon: Icon(Icons.pending_actions_rounded),
            selectedIcon: Icon(Icons.pending_actions_rounded),
            label: 'Active',
          ),
          NavigationDestination(
            icon: Icon(Icons.reply_rounded),
            selectedIcon: Icon(Icons.reply_rounded),
            label: 'Needs Response',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_rounded),
            selectedIcon: Icon(Icons.task_alt_rounded),
            label: 'Completed',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateRequestDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Request',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return ActiveRequestsPage(key: _activeRequestsKey);
      case 1:
        return const RepliedRequestsUserPage();
      case 2:
        return const CompletedRequestsUserPage();
      default:
        return const ActiveRequestsPage();
    }
  }
}
