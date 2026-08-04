import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/chat/presentation/pages/chat_detail_page.dart';
import 'package:campus_swap/core/widgets/empty_state_widget.dart';

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

  String _formatChatTime(dynamic rawTime) {
    if (rawTime == null) return '';
    final DateTime? dt = DateTime.tryParse(rawTime.toString())?.toLocal();
    if (dt == null) return '';

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    final DateTime msgDate = DateTime(dt.year, dt.month, dt.day);

    if (msgDate == today) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    } else if (now.year == dt.year) {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]}';
    } else {
      final month = dt.month.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      return '$day/$month/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messages',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
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
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Please login to view messages.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchConversations,
                  child: _conversations.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: const EmptyStateWidget(
                                icon: Icons.chat_bubble_outline,
                                title: 'No Messages Yet',
                                message: 'Start a conversation by exploring items in the market!',
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          itemCount: _conversations.length,
                          itemBuilder: (context, index) {
                            final chat = _conversations[index];
                            final name = (chat['full_name'] != null && chat['full_name'].toString().trim().isNotEmpty)
                                ? chat['full_name'].toString()
                                : (chat['name'] ?? 'User');
                            final lastMsg = chat['lastMessage'] ?? '';
                            final rawTime = chat['time'];
                            final formattedTime = _formatChatTime(rawTime);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.shadow.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
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
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 26,
                                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                          backgroundImage: (chat['profile_image_url'] != null && chat['profile_image_url'].toString().isNotEmpty)
                                              ? NetworkImage('${ApiClient.baseUrl.replaceAll('/api', '')}${chat['profile_image_url']}')
                                              : null,
                                          child: (chat['profile_image_url'] == null || chat['profile_image_url'].toString().isEmpty)
                                              ? Text(
                                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    color: theme.colorScheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      name,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: theme.textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                  if (formattedTime.isNotEmpty) ...[
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      formattedTime,
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        color: theme.colorScheme.onSurfaceVariant,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                lastMsg,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }

}
