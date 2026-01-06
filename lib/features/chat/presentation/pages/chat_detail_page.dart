import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';

class ChatDetailPage extends StatefulWidget {
  final String sellerName;
  final String? otherUserId; // Needed for API

  const ChatDetailPage({super.key, required this.sellerName, this.otherUserId});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
     final session = UserSession();
     if (widget.otherUserId == null || !session.isLoggedIn) {
         setState(() => _isLoading = false);
         return; 
     }

     try {
       final apiClient = ApiClient();
       final response = await apiClient.get('/messages/conversation/${session.userId}/${widget.otherUserId}');
       
       if (response is List) {
         setState(() {
           _messages = response;
           _isLoading = false;
         });
       }
     } catch (e) {
       print('Error fetching messages: $e');
       setState(() => _isLoading = false);
     }
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;
    
    final session = UserSession();
    if (widget.otherUserId == null || !session.isLoggedIn) return;

    final content = _controller.text;
    _controller.clear(); 

    // Optimistic update
    setState(() {
      _messages.add({
        'content': content, 
        'sender_id': session.userId, 
        'createdAt': DateTime.now().toIso8601String()
      });
    });

    try {
      final apiClient = ApiClient();
      await apiClient.post('/messages', {
        'sender_id': session.userId,
        'receiver_id': widget.otherUserId,
        'content': content
      });
      // Optionally refresh to confirm sync
    } catch (e) {
      print('Send error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send')));
    }
  }

  bool _isMe(dynamic message) {
     final session = UserSession();
     return message['sender_id'] == session.userId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sellerName)),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = _isMe(msg);
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? Theme.of(context).colorScheme.primary : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      msg['content'] ?? '',
                      style: TextStyle(color: isMe ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send))
              ],
            ),
          )
        ],
      ),
    );
  }
}
