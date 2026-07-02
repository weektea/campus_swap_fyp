import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/chat/presentation/pages/chat_detail_page.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchConversations();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app comes back into foreground
    if (state == AppLifecycleState.resumed) {
      _fetchConversations();
    }
  }

  Future<void> _fetchConversations() async {
    final session = UserSession();
    if (!session.isLoggedIn) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('/messages/list');
      if (response is List && mounted) {
        setState(() {
          _conversations = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchConversations();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !UserSession().isLoggedIn
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('Please login to view messages.',
                          style: GoogleFonts.outfit(fontSize: 18, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchConversations,
                  child: _conversations.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble_outline, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                  const SizedBox(height: 16),
                                  Text('No messages yet.',
                                      style: GoogleFonts.outfit(fontSize: 18, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text('Start a conversation by exploring items!',
                                      style: GoogleFonts.outfit(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          itemCount: _conversations.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final chat = _conversations[index];
                            final name = chat['name'] ?? 'Unknown';
                            final lastMsg = chat['lastMessage'] ?? '';
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 28,
                                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                backgroundImage: chat['profile_image_url'] != null
                                    ? NetworkImage('${ApiClient.baseUrl.replaceAll('/api', '')}${chat['profile_image_url']}')
                                    : null,
                                child: chat['profile_image_url'] == null
                                    ? Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                lastMsg,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatDetailPage(
                                      sellerName: name,
                                      otherUserId: chat['id']?.toString(),
                                      otherUserAvatar: chat['profile_image_url']?.toString(),
                                    ),
                                  ),
                                ).then((_) => _fetchConversations());
                              },
                            );
                          },
                        ),
                ),
    );
  }
}
