import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_provider.dart';
import '../../models/friend_request.dart';
import '../../widget/app_drawer.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({Key? key}) : super(key: key);

  @override
  _FriendRequestsScreenState createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      context.read<FriendProvider>().loadFriendRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Incoming'),
            Tab(text: 'Outgoing'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
        ),
      ),
      drawer: const AppDrawer(),
      body: Consumer<FriendProvider>(
        builder: (context, friendProvider, child) {
          if (friendProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (friendProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${friendProvider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => friendProvider.loadFriendRequests(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Incoming Requests
              _buildRequestList(
                friendProvider.incomingRequests,
                isIncoming: true,
                onAccept: (request) =>
                    friendProvider.acceptFriendRequest(request.id),
                onReject: (request) =>
                    friendProvider.rejectFriendRequest(request.id),
              ),
              // Outgoing Requests
              _buildRequestList(
                friendProvider.outgoingRequests,
                isIncoming: false,
                onAccept: null,
                onReject: null,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestList(
    List<FriendRequest> requests, {
    required bool isIncoming,
    required Function(FriendRequest)? onAccept,
    required Function(FriendRequest)? onReject,
  }) {
    if (requests.isEmpty) {
      return Center(
        child: Text(
          isIncoming
              ? 'No incoming friend requests'
              : 'No outgoing friend requests',
        ),
      );
    }

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        final user = isIncoming ? request.sender.name : request.receiver.name;
        final profilePicture = isIncoming
            ? request.sender.profilePicture
            : request.receiver.profilePicture;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  profilePicture != null && profilePicture.isNotEmpty
                      ? NetworkImage(profilePicture)
                      : null,
              child: (profilePicture == null || profilePicture.isEmpty)
                  ? Text(
                      user?.isNotEmpty == true ? user![0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Text(user ?? 'Unknown User'),
            subtitle: Text(
              isIncoming ? 'Wants to be your friend' : 'Friend request sent',
            ),
            trailing: isIncoming
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => onAccept?.call(request),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => onReject?.call(request),
                      ),
                    ],
                  )
                : const Icon(Icons.hourglass_empty),
          ),
        );
      },
    );
  }
}
