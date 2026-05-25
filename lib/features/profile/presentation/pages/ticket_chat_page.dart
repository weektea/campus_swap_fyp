import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:image_picker/image_picker.dart';

class TicketChatPage extends StatefulWidget {
  final String referenceId;
  final String referenceType; // 'Dispute' or 'SupportTicket'
  final String title;
  final String status;

  const TicketChatPage({
    super.key,
    required this.referenceId,
    required this.referenceType,
    required this.title,
    required this.status,
  });

  @override
  State<TicketChatPage> createState() => _TicketChatPageState();
}

class _TicketChatPageState extends State<TicketChatPage> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      final res = await _apiClient.get('/tickets/thread/${widget.referenceId}');
      if (mounted) {
        setState(() {
          _messages = res is List ? res : [];
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading thread: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _apiClient.post('/tickets/thread/${widget.referenceId}', {
        'reference_type': widget.referenceType,
        'content': _msgController.text.trim(),
        'attachment_url': null,
      });
      _msgController.clear();
      await _fetchMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    
    setState(() => _isSending = true);
    try {
      final uploadRes = await _apiClient.postMultipart('/upload', image);
      final evidenceUrl = uploadRes['url'];
      
      await _apiClient.post('/tickets/thread/${widget.referenceId}', {
        'reference_type': widget.referenceType,
        'content': '[Image Attached]',
        'attachment_url': evidenceUrl,
      });
      await _fetchMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildMessageBubble(dynamic msg) {
    final session = UserSession();
    final isMe = msg['sender_id'] == session.userId;
    final sender = msg['sender'] ?? {};
    final isMod = sender['role'] == 'moderator' || sender['role'] == 'admin';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF006940) : (isMod ? Colors.blue[50] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(12),
          border: isMod && !isMe ? Border.all(color: Colors.blue.withValues(alpha: 0.3)) : null,
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                isMod ? 'Moderator Support' : (sender['username'] ?? 'User'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isMod ? Colors.blue[800] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              msg['content'] ?? '',
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
            if (msg['attachment_url'] != null) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    '${ApiClient.baseUrl.replaceAll('/api', '')}${msg['attachment_url']}',
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 16)),
            Text(widget.status, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                  ),
          ),
          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    onPressed: _pickAndUploadImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: Colors.grey.withValues(alpha: 0.1),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSending 
                    ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                    : IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF006940)),
                        onPressed: _sendMessage,
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
