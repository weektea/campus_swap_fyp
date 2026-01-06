import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final session = UserSession();
    if (session.userId == null) return;

    setState(() => _isLoading = true);
    try {
        final apiClient = ApiClient();
        final res = await apiClient.get('/notifications/user/${session.userId}');
        if (mounted) {
            setState(() {
                _notifications = res is List ? res : [];
                _isLoading = false;
            });
        }
    } catch (e) {
        if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
       try {
           final apiClient = ApiClient();
           await apiClient.patch('/notifications/$id/read', {});
           // Update UI locally
           setState(() {
               final index = _notifications.indexWhere((n) => n['id'] == id);
               if (index != -1) {
                   _notifications[index]['is_read'] = true;
               }
           });
       } catch (e) {
           print('Error marking read: $e');
       }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? Center(child: Text('No notifications yet', style: GoogleFonts.outfit()))
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                        final note = _notifications[index];
                        final isRead = note['is_read'] ?? false;

                        return Container(
                            color: isRead ? Colors.white : Colors.blue.withOpacity(0.05),
                            child: ListTile(
                                leading: CircleAvatar(
                                    backgroundColor: isRead ? Colors.grey[200] : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                    child: Icon(
                                        note['type'] == 'Transaction' ? Icons.shopping_bag : Icons.notifications,
                                        color: isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
                                    ),
                                ),
                                title: Text(note['title'], style: GoogleFonts.outfit(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                                subtitle: Text(note['message'], style: GoogleFonts.outfit()),
                                trailing: isRead ? null : const Icon(Icons.circle, color: Colors.blue, size: 10),
                                onTap: () {
                                    if (!isRead) _markAsRead(note['id']);
                                    // Could navigate to details based on type/related_id
                                },
                            ),
                        );
                    },
                )
    );
  }
}
