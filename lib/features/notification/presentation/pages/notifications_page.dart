import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/features/profile/presentation/pages/transaction_detail_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/ticket_chat_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/help_center_page.dart';
import 'package:campus_swap/core/services/notification_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:campus_swap/features/chat/presentation/pages/chat_detail_page.dart';
import 'package:campus_swap/features/product/presentation/pages/product_details_page.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';

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
        final res = await apiClient.get('/notifications');
        if (mounted) {
            setState(() {
                _notifications = res is List ? res : [];
                _isLoading = false;
                
                // Recalculate unread badge status
                final unreadCount = _notifications.where((n) => n['is_read'] == false).length;
                NotificationService().unreadCountNotifier.value = unreadCount;
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
                   if (NotificationService().unreadCountNotifier.value > 0) {
                       NotificationService().unreadCountNotifier.value--;
                   }
               }
           });
       } catch (e) {
           // print('Error marking read: $e');
       }
  }

  Future<void> _deleteNotification(String id, bool wasUnread) async {
       try {
           final apiClient = ApiClient();
           await apiClient.delete('/notifications/$id');
           if (wasUnread) {
               if (NotificationService().unreadCountNotifier.value > 0) {
                   NotificationService().unreadCountNotifier.value--;
               }
           }
       } catch (e) {
           // print('Error deleting notification: $e');
       }
  }

  Future<void> _clearReadNotifications() async {
       try {
           final apiClient = ApiClient();
           await apiClient.delete('/notifications/clear-read');
           setState(() {
               _notifications.removeWhere((n) => n['is_read'] == true);
           });
           if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                       content: Text('Cleared all read notifications', style: GoogleFonts.outfit()),
                       behavior: SnackBarBehavior.floating,
                   ),
               );
           }
       } catch (e) {
           if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                       content: Text('Failed to clear read notifications', style: GoogleFonts.outfit()),
                       behavior: SnackBarBehavior.floating,
                   ),
               );
           }
       }
  }

  void _showClearConfirmation() {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              title: Text('Clear Read Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: Text('Are you sure you want to clear all read notifications? This action cannot be undone.', style: GoogleFonts.outfit()),
              actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                          Navigator.pop(context);
                          _clearReadNotifications();
                      },
                      child: Text('Clear', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
              ],
          ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final hasReadNotifications = _notifications.any((n) => n['is_read'] == true);

    return Scaffold(
        appBar: AppBar(
            title: Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            actions: [
                if (hasReadNotifications)
                    IconButton(
                        icon: const Icon(Icons.delete_sweep),
                        tooltip: 'Clear read notifications',
                        onPressed: _showClearConfirmation,
                    ),
            ],
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Icon(
                              Icons.done_all_rounded,
                              size: 60,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ).animate()
                           .scale(duration: 500.ms, curve: Curves.easeOutBack)
                           .fadeIn(duration: 400.ms),
                          const SizedBox(height: 24),
                          Text(
                            "You're all caught up!",
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
                          const SizedBox(height: 12),
                          Text(
                            "No new notifications.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                        final note = _notifications[index];
                        final isRead = note['is_read'] ?? false;

                        return Dismissible(
                            key: Key(note['id'].toString()),
                            direction: DismissDirection.horizontal,
                            background: Container(
                                color: Colors.redAccent.withValues(alpha: 0.9),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20.0),
                                child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                            ),
                            secondaryBackground: Container(
                                color: Colors.redAccent.withValues(alpha: 0.9),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20.0),
                                child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                            ),
                            confirmDismiss: (direction) async {
                                return await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                        title: Text('Delete Notification', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                        content: Text('Are you sure you want to delete this notification?', style: GoogleFonts.outfit()),
                                        actions: [
                                            TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
                                            ),
                                            ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.redAccent,
                                                    foregroundColor: Colors.white,
                                                ),
                                                onPressed: () => Navigator.pop(context, true),
                                                child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                            ),
                                        ],
                                    ),
                                ) ?? false;
                            },
                            onDismissed: (direction) {
                                final noteId = note['id'].toString();
                                final wasUnread = !isRead;

                                // Optimistic UI update
                                setState(() {
                                    _notifications.removeAt(index);
                                });

                                // Call API and update sync in background
                                _deleteNotification(noteId, wasUnread);

                                // Show floating SnackBar for feedback
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Notification removed', style: GoogleFonts.outfit()),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                        action: SnackBarAction(
                                            label: 'Dismiss',
                                            textColor: Colors.white,
                                            onPressed: () {
                                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                            },
                                        ),
                                    ),
                                );
                            },
                            child: Container(
                                color: isRead ? Colors.white : Colors.blue.withValues(alpha: 0.05),
                                child: ListTile(
                                    leading: CircleAvatar(
                                        backgroundColor: isRead ? Colors.grey[200] : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                        child: Icon(
                                            note['type'] == 'Transaction' ? Icons.shopping_bag : 
                                            note['type'] == 'Promotion' ? Icons.card_giftcard : Icons.notifications,
                                            color: isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
                                        ),
                                    ),
                                    title: Text(note['title'], style: GoogleFonts.outfit(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                                    subtitle: Text(note['message'], style: GoogleFonts.outfit()),
                                    trailing: isRead ? null : const Icon(Icons.circle, color: Colors.blue, size: 10),
                                    onTap: () async {
                                        if (!isRead) _markAsRead(note['id']);
                                        final title = note['title']?.toString() ?? '';
                                        final apiClient = ApiClient();
                                        if (note['type'] == 'PRICE_DROP') {
                                             if (note['related_id'] != null) {
                                                  // Show loading spinner
                                                  showDialog(
                                                      context: context,
                                                      barrierDismissible: false,
                                                      builder: (context) => const Center(child: CircularProgressIndicator()),
                                                  );
                                                  try {
                                                      final res = await apiClient.get('/products/${note['related_id']}');
                                                      if (context.mounted) {
                                                          Navigator.pop(context); // Pop loading dialog
                                                          final product = Product.fromJson(res);
                                                          Navigator.push(context, MaterialPageRoute(
                                                              builder: (_) => ProductDetailsPage(product: product)
                                                          ));
                                                      }
                                                  } catch (e) {
                                                      if (context.mounted) {
                                                          Navigator.pop(context); // Pop loading dialog
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(content: Text('Failed to load item details: $e'))
                                                          );
                                                      }
                                                  }
                                             }
                                        } else if (title.contains('Dispute') || title.contains('Support Ticket')) {
                                            if (note['related_id'] != null) {
                                                Navigator.push(context, MaterialPageRoute(
                                                    builder: (_) => TicketChatPage(
                                                        referenceId: note['related_id'],
                                                        referenceType: title.contains('Dispute') ? 'Dispute' : 'SupportTicket',
                                                        title: title,
                                                        status: 'Check Thread',
                                                    )
                                                ));
                                            }
                                         } else if (note['type'] == 'CHAT' || title.contains('Message')) {
                                             if (note['related_id'] != null) {
                                                 final rawSenderName = title.replaceAll(RegExp(r'^(New )?Message from '), '');
                                                 final senderName = rawSenderName.isNotEmpty ? rawSenderName : 'Chat Partner';
                                                 Navigator.push(context, MaterialPageRoute(
                                                     builder: (_) => ChatDetailPage(
                                                         otherUserId: note['related_id'].toString(),
                                                         sellerName: senderName,
                                                     )
                                                 ));
                                             }
                                         } else if (title.contains('Report')) {
                                            Navigator.push(context, MaterialPageRoute(
                                                builder: (_) => const HelpCenterPage()
                                            ));
                                        } else if (note['type'] == 'Transaction' || note['type'] == 'System' || note['type'] == 'Promotion') {
                                             if (note['related_id'] != null && !title.contains('Cancelled')) {
                                                 Navigator.push(context, MaterialPageRoute(
                                                     builder: (_) => TransactionDetailPage(transactionId: note['related_id'])
                                                 ));
                                             } else {
                                                 // Tapping on a broadcast notification opens a simple dialog showing the full announcement content.
                                                 showDialog(
                                                     context: context,
                                                     builder: (context) => AlertDialog(
                                                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                         title: Row(
                                                             children: [
                                                                 Icon(
                                                                     note['type'] == 'Promotion' ? Icons.card_giftcard : Icons.campaign,
                                                                     color: Theme.of(context).colorScheme.primary,
                                                                 ),
                                                                 const SizedBox(width: 10),
                                                                 Expanded(
                                                                     child: Text(
                                                                         note['title'] ?? 'Announcement',
                                                                         style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                                                                     ),
                                                                 ),
                                                             ],
                                                         ),
                                                         content: Text(
                                                             note['message'] ?? '',
                                                             style: GoogleFonts.outfit(fontSize: 15),
                                                         ),
                                                         actions: [
                                                             TextButton(
                                                                 onPressed: () => Navigator.pop(context),
                                                                 child: Text(
                                                                     'Dismiss',
                                                                     style: GoogleFonts.outfit(
                                                                         fontWeight: FontWeight.bold,
                                                                         color: Theme.of(context).colorScheme.primary,
                                                                     ),
                                                                 ),
                                                             ),
                                                         ],
                                                     ),
                                                 );
                                             }
                                         }
                                    },
                                ),
                            ),
                        );
                    },
                )
    );
  }
}
