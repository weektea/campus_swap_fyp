import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/core/services/socket_service.dart';
import 'package:campus_swap/core/theme/app_theme.dart';

class ChatMessage {
  final String content;
  final String sender; // 'bot', 'user', 'moderator'
  final DateTime timestamp;
  final String? attachmentUrl;

  ChatMessage({
    required this.content,
    required this.sender,
    required this.timestamp,
    this.attachmentUrl,
  });
}

class CustomerSupportChatPage extends StatefulWidget {
  const CustomerSupportChatPage({super.key});

  @override
  State<CustomerSupportChatPage> createState() => _CustomerSupportChatPageState();
}

class _CustomerSupportChatPageState extends State<CustomerSupportChatPage> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final DateTime _startTime = DateTime.now();
  DateTime? _handoverTime;

  final List<ChatMessage> _qaMessages = [];
  final List<ChatMessage> _localHandoverMessages = [];
  List<dynamic> _backendRawMessages = [];
  
  bool _isHandedOver = false;
  String? _ticketId;
  String _currentStatus = 'Active';
  bool _isBotTyping = false;
  bool _isSending = false;
  Timer? _pollTimer;

  final List<String> _quickReplies = [
    "How to report an item?",
    "Dispute a transaction",
    "Other issues",
  ];

  bool _showQuickReplies = true;

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Combine local bot greeting, Q&A, and backend thread messages
  List<ChatMessage> get _allMessages {
    final list = <ChatMessage>[];
    
    // 1. Initial greeting
    list.add(ChatMessage(
      content: "Hi there! How can I help you today?",
      sender: 'bot',
      timestamp: _startTime,
    ));

    // 2. Q&A interaction
    list.addAll(_qaMessages);

    // 3. Handover state
    if (_isHandedOver) {
      if (_handoverTime != null) {
        list.add(ChatMessage(
          content: "I've noted your issue. A moderator will be with you shortly.",
          sender: 'bot',
          timestamp: _handoverTime!,
        ));
      }
      
      // Map backend messages, skipping the first custom message if we want, but since it represents
      // the custom message that initiated the handover, let's just render all backend messages directly.
      for (var m in _backendRawMessages) {
        final senderObj = m['sender'] ?? {};
        final senderRole = senderObj['role'] ?? 'student';
        final isMe = m['sender_id'] == UserSession().userId;
        list.add(ChatMessage(
          content: m['content'] ?? '',
          sender: isMe ? 'user' : (senderRole == 'admin' || senderRole == 'moderator' ? 'moderator' : 'user'),
          timestamp: DateTime.parse(m['createdAt'] ?? DateTime.now().toIso8601String()).toLocal(),
          attachmentUrl: m['attachment_url'],
        ));
      }
    } else {
      list.addAll(_localHandoverMessages);
    }

    return list;
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

  void _handleQuickReply(String reply) {
    if (!_showQuickReplies) return;
    
    setState(() {
      _showQuickReplies = false;
      _qaMessages.add(ChatMessage(
        content: reply,
        sender: 'user',
        timestamp: DateTime.now(),
      ));
      _isBotTyping = true;
    });
    _scrollToBottom();

    // Answer logic with a slight delay for realism
    Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      String answer = "";
      if (reply == "How to report an item?") {
        answer = "To report an item, go to the item detail page, tap the options icon (three dots) in the top right, and select 'Report Listing'.";
      } else if (reply == "Dispute a transaction") {
        answer = "If you need to dispute a transaction, go to your Profile > Resolution Center, select the transaction, and open a Dispute. Our team will review the case.";
      } else {
        answer = "For other issues, please describe your problem in detail below and we will connect you to a live moderator.";
      }

      setState(() {
        _qaMessages.add(ChatMessage(
          content: answer,
          sender: 'bot',
          timestamp: DateTime.now(),
        ));
        _isBotTyping = false;
        // Keep showing quick replies unless they selected "Other issues" or they choose to start typing
        if (reply != "Other issues") {
          _showQuickReplies = true;
        }
      });
      _scrollToBottom();
    });
  }

  Future<void> _sendCustomMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    setState(() {
      _showQuickReplies = false;
    });

    if (!_isHandedOver) {
      // First custom message: Initiate handover
      _handoverTime = DateTime.now();
      setState(() {
        _localHandoverMessages.add(ChatMessage(
          content: text,
          sender: 'user',
          timestamp: DateTime.now(),
        ));
        _localHandoverMessages.add(ChatMessage(
          content: "I've noted your issue. A moderator will be with you shortly.",
          sender: 'bot',
          timestamp: _handoverTime!,
        ));
        _isSending = true;
        _isBotTyping = true;
      });
      _scrollToBottom();

      try {
        // 1. Silently create Support Ticket (status: Pending)
        final ticket = await _apiClient.post('/tickets', {
          'category': 'General',
          'subject': text.length > 40 ? '${text.substring(0, 37)}...' : text,
          'description': text,
          'status': 'Pending',
        });
        
        final newTicketId = ticket['id'].toString();
        
        // 2. Silently write the message to the thread
        await _apiClient.post('/tickets/thread/$newTicketId', {
          'reference_type': 'SupportTicket',
          'content': text,
        });

        if (!mounted) return;

        setState(() {
          _ticketId = newTicketId;
          _isHandedOver = true;
          _isSending = false;
          _isBotTyping = false;
          _currentStatus = 'Awaiting Moderator';
        });

        // 3. Initialize real-time poll and socket listeners
        _startLiveChatSync();

      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initiate live chat: $e')),
        );
        setState(() {
          _localHandoverMessages.clear(); // Rollback local handover view
          _isSending = false;
          _isBotTyping = false;
          _showQuickReplies = true;
        });
      }
    } else {
      // Handed over: Send directly to the active ticket thread
      setState(() {
        _isSending = true;
      });
      try {
        await _apiClient.post('/tickets/thread/$_ticketId', {
          'reference_type': 'SupportTicket',
          'content': text,
        });
        await _fetchMessagesSilently();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send message: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
          _scrollToBottom();
        }
      }
    }
  }

  Future<void> _pickAndUploadAttachment() async {
    if (_ticketId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please send your question first to connect with support.')),
      );
      return;
    }

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
                _uploadAttachment(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF006940)),
              title: Text('Take Photo with Camera', style: GoogleFonts.outfit()),
              onTap: () {
                Navigator.pop(ctx);
                _uploadAttachment(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadAttachment(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: source);
    if (file == null) return;

    setState(() => _isSending = true);
    try {
      final uploadRes = await _apiClient.postMultipart('/upload', file);
      final attachmentUrl = uploadRes['url'];

      await _apiClient.post('/tickets/thread/$_ticketId', {
        'reference_type': 'SupportTicket',
        'content': '[Attachment]',
        'attachment_url': attachmentUrl,
      });

      await _fetchMessagesSilently();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _startLiveChatSync() {
    _fetchMessagesSilently();
    
    // Poll every 3 seconds as a fallback
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchMessagesSilently();
    });

    // Listen to real-time events
    SocketService().socket?.on('receive_new_message', (data) {
      if (mounted && data != null) {
        final refId = data['reference_id']?.toString();
        if (refId == _ticketId) {
          _fetchMessagesSilently();
        }
      }
    });
  }

  Future<void> _fetchMessagesSilently() async {
    if (_ticketId == null) return;
    try {
      final res = await _apiClient.get('/tickets/thread/$_ticketId');
      if (mounted && res is List) {
        final countChanged = res.length != _backendRawMessages.length;
        setState(() {
          _backendRawMessages = res;
        });
        if (countChanged) {
          _scrollToBottom();
        }
      }
      
      // Also sync ticket status
      final statusRes = await _apiClient.get('/tickets/thread/$_ticketId/status');
      if (mounted && statusRes is Map && statusRes.containsKey('status')) {
        setState(() {
          final s = statusRes['status'] ?? 'Pending';
          if (s == 'In-Progress') {
            _currentStatus = 'Moderator Connected';
          } else if (s == 'Resolved') {
            _currentStatus = 'Resolved';
          } else {
            _currentStatus = 'Awaiting Moderator';
          }
        });
      }
    } catch (e) {
      // Silent catch for background polling
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.sender == 'user';
    final isBot = msg.sender == 'bot';
    
    Color bubbleColor;
    Color textColor;
    if (isMe) {
      bubbleColor = AppTheme.primaryColor;
      textColor = Colors.white;
    } else if (isBot) {
      bubbleColor = Colors.grey[200]!;
      textColor = Colors.black87;
    } else {
      // Moderator
      bubbleColor = Colors.blue[50]!;
      textColor = Colors.blue[900]!;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isBot ? Colors.teal[100] : Colors.blue[100],
              child: Icon(
                isBot ? Icons.smart_toy_outlined : Icons.support_agent_rounded,
                size: 18,
                color: isBot ? Colors.teal[900] : Colors.blue[900],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMe && !isBot) ...[
                    Text(
                      "Moderator Support",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    msg.content,
                    style: GoogleFonts.outfit(
                      color: textColor,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(msg.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.2),
              child: Text(
                UserSession().username?.substring(0, 1).toUpperCase() ?? 'U',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final messages = _allMessages;
    final isClosed = _currentStatus == 'Resolved';

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Support',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentStatus == 'Resolved' ? Colors.red : Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _currentStatus,
                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat Stream
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(messages[index]),
            ),
          ),

          // Bot Typing Indicator
          if (_isBotTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.teal[100],
                    child: const Icon(Icons.smart_toy_outlined, size: 14, color: Colors.teal),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Typing...',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),

          // Quick Replies Chips
          if (_showQuickReplies && !_isHandedOver)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickReplies.length,
                itemBuilder: (context, index) {
                  final reply = _quickReplies[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        reply,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                      side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: () => _handleQuickReply(reply),
                    ),
                  );
                },
              ),
            ),

          // Input field / Closed state
          isClosed
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  color: isDark ? Colors.black26 : Colors.grey[100],
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'This support session is resolved and closed.',
                          style: GoogleFonts.outfit(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        offset: const Offset(0, -1),
                        blurRadius: 3,
                      )
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.attach_file, color: Colors.grey),
                          onPressed: _pickAndUploadAttachment,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _msgController,
                            style: GoogleFonts.outfit(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Type your question...',
                              hintStyle: GoogleFonts.outfit(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendCustomMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _isSending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.send),
                                color: AppTheme.primaryColor,
                                iconSize: 26,
                                onPressed: _sendCustomMessage,
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
