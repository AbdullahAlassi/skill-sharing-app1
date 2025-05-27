import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_provider.dart';
import '../../models/user_model.dart';
import '../../widget/app_drawer.dart';
import '../chat/chat_screen.dart';
import 'add_friend_screen.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({Key? key}) : super(key: key);

  @override
  _FriendListScreenState createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<FriendProvider>().loadFriends();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddFriendScreen(),
                ),
              );
            },
          ),
        ],
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
                    onPressed: () => friendProvider.loadFriends(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (friendProvider.friends.isEmpty) {
            return const Center(
              child: Text('No friends yet. Add some friends to get started!'),
            );
          }

          return ListView.builder(
            itemCount: friendProvider.friends.length,
            itemBuilder: (context, index) {
              final friend = friendProvider.friends[index];
              return FriendCard(
                friend: friend,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(friend: friend),
                    ),
                  );
                },
                onRemove: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Remove Friend'),
                      content: Text(
                          'Are you sure you want to remove ${friend.name} from your friends?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await friendProvider.removeFriend(friend.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class FriendCard extends StatelessWidget {
  final User friend;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const FriendCard({
    Key? key,
    required this.friend,
    required this.onTap,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              friend.profilePicture != null && friend.profilePicture!.isNotEmpty
                  ? NetworkImage(friend.profilePicture!)
                  : null,
          child: (friend.profilePicture == null ||
                  friend.profilePicture!.isEmpty)
              ? Text(
                  friend.name.isNotEmpty ? friend.name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(friend.name),
        subtitle: Text(friend.bio ?? 'No bio'),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.chat),
                    title: const Text('Message'),
                    onTap: () {
                      Navigator.pop(context);
                      onTap();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('View Profile'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to friend's profile
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.remove_circle_outline),
                    title: const Text('Remove Friend'),
                    onTap: () {
                      Navigator.pop(context);
                      onRemove();
                    },
                  ),
                ],
              ),
            );
          },
        ),
        onTap: onTap,
      ),
    );
  }
}
