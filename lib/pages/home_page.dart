import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../components/user_tile.dart';

class HomePage extends StatelessWidget {
  final AuthService _auth = AuthService();
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    String currentUserId = _chatService.getCurrentUserId();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _auth.getCurrentUserInfo(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        "Error loading user info",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(
                      child: Text(
                        "User info not found",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final userInfo = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userInfo['username'] ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userInfo['email'] ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
                await _auth.signOut();
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatService.getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No users found"));
          }
          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              String displayName = user['username']?.isNotEmpty == true
                  ? user['username']
                  : user['email'] ?? 'Unknown';
              String otherUserId = user['user_id'];

              return StreamBuilder<int>(
                stream: _chatService.getUnreadMessagesCount(currentUserId, otherUserId),
                builder: (context, unreadSnapshot) {
                  if (unreadSnapshot.connectionState == ConnectionState.waiting) {
                    return UserTile(
                      email: displayName,
                      unreadCount: 0,
                      onTap: () => Navigator.pushNamed(context, '/chat', arguments: user),
                    );
                  }
                  if (unreadSnapshot.hasError) {
                    print('Error fetching unread count for $otherUserId: ${unreadSnapshot.error}');
                    return UserTile(
                      email: displayName,
                      unreadCount: 0,
                      onTap: () => Navigator.pushNamed(context, '/chat', arguments: user),
                    );
                  }
                  int unreadCount = unreadSnapshot.data ?? 0;
                  print('Unread count for $otherUserId: $unreadCount');
                  return UserTile(
                    email: displayName,
                    unreadCount: unreadCount,
                    onTap: () => Navigator.pushNamed(context, '/chat', arguments: user),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}