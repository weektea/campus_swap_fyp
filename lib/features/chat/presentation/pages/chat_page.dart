import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/chat/presentation/pages/chat_detail_page.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    final session = UserSession();
    if (!session.isLoggedIn) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('/messages/list');
      if (response is List) {
        setState(() {
          _conversations = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      // print('Fetch Chat Error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _conversations.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(UserSession().isLoggedIn ? 'No messages yet.' : 'Please login to view messages.', 
                         style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (UserSession().isLoggedIn)
                       Text('Start a conversation by exploring items!', 
                         style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500])),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: _conversations.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final chat = _conversations[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        chat['name'] != null ? chat['name'][0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary, 
                          fontWeight: FontWeight.bold,
                          fontSize: 20
                        )
                      ),
                    ),
                    title: Text(
                      chat['name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      chat['lastMessage'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailPage(
                              sellerName: chat['name'], 
                              otherUserId: chat['id']
                          ),
                        ),
                      ).then((_) => _fetchConversations());
                    },
                  );
                },
              ),
    );
  }
}

