import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/core/services/socket_service.dart';

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
  final ImagePicker _picker = ImagePicker();

  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String _currentStatus = '';
  Timer? _pollTimer;

  @override
  void dispose() {
    SocketService().socket?.off('receive_new_message');
    _pollTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status;
    _fetchMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchMessagesSilently();
    });

    // Listen to real-time support ticket/dispute chat messages
    SocketService().socket?.on('receive_new_message', (data) {
      if (mounted && data != null) {
        final refId = data['reference_id']?.toString();
        if (refId == widget.referenceId.toString()) {
          setState(() {
            final id = data['id'];
            if (id == null || !_messages.any((m) => m['id'] == id)) {
              _messages.add(data);
              _scrollToBottom();
            }
          });
        }
      }
    });
  }

  Future<void> _fetchMessagesSilently() async {
    try {
      final res = await _apiClient.get('/tickets/thread/${widget.referenceId}');
      _fetchStatus();
      if (mounted && res is List) {
        final bool countChanged = res.length != _messages.length;
        setState(() {
          _messages = res;
        });
        if (countChanged) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      // Silently ignore background polling errors
    }
  }

  Future<void> _fetchStatus() async {
    try {
      final res = await _apiClient.get('/tickets/thread/${widget.referenceId}/status');
      if (mounted && res is Map && res.containsKey('status')) {
        setState(() {
          _currentStatus = res['status'] ?? '';
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final res = await _apiClient.get('/tickets/thread/${widget.referenceId}');
      _fetchStatus();
      if (mounted) {
        setState(() {
          _messages = res is List ? res : [];
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, 'Error loading thread: ${_getFriendlyErrorMessage(e)}');
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getFriendlyErrorMessage(dynamic e) {
    final message = e.toString();
    if (message.contains('SocketException') || message.contains('Connection error') || message.contains('Failed host lookup')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    if (message.contains('TimeoutException') || message.contains('Connection timed out')) {
      return 'Connection timed out. Please check your network and try again.';
    }
    return message.replaceAll(RegExp(r'^Exception:\s*'), '').replaceAll(RegExp(r'^ApiException:\s*'), '');
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
        _showErrorSnackBar(context, 'Failed to send: ${_getFriendlyErrorMessage(e)}');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF006940)),
              title: Text('Choose Photo from Gallery', style: GoogleFonts.outfit()),
              onTap: () {
                Navigator.pop(ctx);
                _pickFile(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF006940)),
              title: Text('Take Photo with Camera', style: GoogleFonts.outfit()),
              onTap: () {
                Navigator.pop(ctx);
                _pickFile(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;
    
    setState(() => _isSending = true);
    try {
      final uploadRes = await _apiClient.postMultipart('/upload', image);
      final evidenceUrl = uploadRes['url'];
      
      await _apiClient.post('/tickets/thread/${widget.referenceId}', {
        'reference_type': widget.referenceType,
        'content': '[Attachment]',
        'attachment_url': evidenceUrl,
      });
      await _fetchMessages();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, 'Failed to upload: ${_getFriendlyErrorMessage(e)}');
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

  String _formatTimestamp(String? createdAtStr) {
    if (createdAtStr == null) return '';
    try {
      final dt = DateTime.parse(createdAtStr).toLocal();
      final now = DateTime.now();
      final isPreviousDay = dt.day != now.day || dt.month != now.month || dt.year != now.year;
      
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final timeStr = '$hour:$minute $ampm';
      
      if (isPreviousDay) {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final dateStr = '${months[dt.month - 1]} ${dt.day}';
        return '$timeStr, $dateStr';
      }
      return timeStr;
    } catch (e) {
      return '';
    }
  }

  String _getAttachmentUrl(String? path) {
    if (path == null) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final baseUrl = ApiClient.baseUrl.replaceAll('/api', '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$cleanPath';
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
                isMod ? 'Moderator Support' : (sender['full_name'] ?? (sender['username'] != null ? '@${sender['username']}' : (sender['email'] ?? 'User'))),
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
                    _getAttachmentUrl(msg['attachment_url']),
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _formatTimestamp(msg['createdAt']),
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : Colors.grey[500],
                ),
              ),
            ),
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
            Text(_currentStatus, style: const TextStyle(fontSize: 12)),
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
          () {
            final isClosed = _currentStatus == 'Resolved' || _currentStatus == 'Closed' || _currentStatus == 'Dismissed' || _currentStatus == 'Uphold';
            if (isClosed) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[100],
                  border: Border(top: BorderSide(color: Colors.grey.withAlpha(50))),
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'This ${widget.referenceType == 'Dispute' ? 'dispute' : 'ticket'} is resolved and closed.',
                        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Container(
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
            );
          }(),
        ],
      ),
    );
  }
}
