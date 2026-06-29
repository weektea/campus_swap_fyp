import 'package:flutter/material.dart';
import 'dart:async';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/profile/presentation/pages/public_profile_page.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';
import 'package:campus_swap/features/product/presentation/pages/product_details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:campus_swap/features/location/domain/entities/safe_zone.dart';
import 'package:campus_swap/features/location/presentation/pages/safe_zone_map_page.dart';
import 'package:campus_swap/core/services/socket_service.dart';

class ChatDetailPage extends StatefulWidget {
  final String sellerName;
  final String? otherUserId; // Needed for API
  final String? initialMessage; // Contextual smart greeting
  final Product? relatedProduct;

  const ChatDetailPage({super.key, required this.sellerName, this.otherUserId, this.initialMessage, this.relatedProduct});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  Timer? _timer;
  List<SafeZone> _allZones = [];

  @override
  void dispose() {
    SocketService().socket?.off('receive_new_message');
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null) {
        _controller.text = widget.initialMessage!;
    }
    _fetchMessages();
    _fetchZones();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchMessages(silent: true));

    // Connect WebSocket listener for real-time messages
    SocketService().socket?.on('receive_new_message', (data) {
      if (mounted && data != null && widget.otherUserId != null) {
        final senderId = data['sender_id']?.toString();
        final receiverId = data['receiver_id']?.toString();
        if (senderId == widget.otherUserId.toString() || receiverId == widget.otherUserId.toString()) {
          setState(() {
            final id = data['id'];
            if (id == null || !_messages.any((m) => m['id'] == id)) {
              _messages.add(data);
            }
          });
        }
      }
    });
  }

  Future<void> _fetchZones() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('/zones');
      if (response is List) {
        final loadedZones = response
            .map((item) => SafeZone.fromJson(item as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _allZones = loadedZones;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching zones in chat: $e');
    }
  }

  Future<void> _fetchMessages({bool silent = false}) async {
     final session = UserSession();
     if (widget.otherUserId == null || !session.isLoggedIn) {
         setState(() => _isLoading = false);
         return; 
     }

     try {
       final apiClient = ApiClient();
       final response = await apiClient.get('/messages/conversation/${widget.otherUserId}');
       
       if (response is List) {
         setState(() {
           _messages = response;
           _isLoading = false;
         });
       }
     } catch (e) {
       // print('Error fetching messages: $e');
       if (!silent) setState(() => _isLoading = false);
     }
  }

  void _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    
    final session = UserSession();
    if (widget.otherUserId == null || !session.isLoggedIn) return;

    _controller.clear(); 

    // Optimistic update
    setState(() {
      _messages.add({
        'content': content, 
        'sender_id': session.userId, 
        'sent_at': DateTime.now().toIso8601String()
      });
    });

    try {
      final apiClient = ApiClient();
      await apiClient.post('/messages', {
        'receiver_id': widget.otherUserId,
        'content': content
      });
      // Optionally refresh to confirm sync
    } catch (e) {
      // print('Send error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send')));
      }
    }
  }

  bool _isMe(dynamic message) {
     final session = UserSession();
     // Compare as strings to handle int vs string mismatch between DB and JWT
     return message['sender_id']?.toString() == session.userId?.toString();
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final date = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return 'Today';
      }
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
    } catch (_) { return ''; }
  }

  String _formatTime(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final date = DateTime.parse(isoString).toLocal();
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final ampm = date.hour >= 12 ? 'PM' : 'AM';
      final min = date.minute.toString().padLeft(2, '0');
      return '$hour:$min $ampm';
    } catch (_) { return ''; }
  }

  void _showSafeMeetupDialog() async {
      final SafeZone? result = await Navigator.push<SafeZone>(
          context,
          MaterialPageRoute(builder: (_) => const SafeZoneMapPage()),
      );
      if (result != null) {
          _controller.text = "📍 Let's meet at ${result.name}\nMAP:${result.id}";
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
            onTap: () {
                if (widget.otherUserId != null) {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfilePage(
                         userId: widget.otherUserId!, 
                         userName: widget.sellerName
                     )));
                }
            },
            child: Row(
              children: [
                 CircleAvatar(
                     radius: 16,
                     backgroundColor: Colors.grey[200],
                     child: Text(widget.sellerName[0].toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                 ),
                 const SizedBox(width: 8),
                 Text(widget.sellerName, style: const TextStyle(fontSize: 18)),
              ],
            ),
        ),
        actions: [
            IconButton(
                icon: const Icon(Icons.report_gmailerrorred_rounded, color: Colors.red),
                onPressed: () {
                    if (widget.otherUserId != null) {
                        _showReportUserDialog(context, widget.otherUserId!, widget.sellerName);
                    }
                },
            )
        ],
      ),
      body: Column(
        children: [
          // Safety Banner (Chapter 3 UC21)
          Container(
             width: double.infinity,
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             color: Colors.amber[100],
             child: Row(
               children: [
                 const Icon(Icons.security, color: Colors.orange, size: 20),
                 const SizedBox(width: 8),
                 Expanded(
                   child: Text(
                     "Safety Tip: Always meet in well-lit, public Safe Zones on campus.",
                     style: TextStyle(color: Colors.orange[900], fontSize: 13, fontWeight: FontWeight.w500),
                   ),
                 ),
               ],
             )
          ),
          if (widget.relatedProduct != null)
             GestureDetector(
               onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsPage(product: widget.relatedProduct!)));
               },
               child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(12),
                     boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
                     ],
                     border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                     children: [
                        ClipRRect(
                           borderRadius: BorderRadius.circular(8),
                           child: widget.relatedProduct!.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: widget.relatedProduct!.imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : Container(width: 50, height: 50, color: Colors.grey[200]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                           child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                 Text(
                                    widget.relatedProduct!.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                 ),
                                 const SizedBox(height: 4),
                                 Text(
                                    'RM ${widget.relatedProduct!.price.toStringAsFixed(2)}',
                                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, fontWeight: FontWeight.bold),
                                 ),
                              ],
                           ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                     ],
                  ),
               ),
             ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = _isMe(msg);
                final isoTime = msg['sent_at'] ?? msg['createdAt'] ?? '';
                
                bool showDateHeader = false;
                if (index == 0) {
                   showDateHeader = true;
                } else {
                   final prevMsg = _messages[index - 1];
                   final prevIso = prevMsg['sent_at'] ?? prevMsg['createdAt'] ?? '';
                   if (isoTime.isNotEmpty && prevIso.isNotEmpty) {
                       try {
                           final date1 = DateTime.parse(isoTime).toLocal();
                           final date2 = DateTime.parse(prevIso).toLocal();
                           if (date1.year != date2.year || date1.month != date2.month || date1.day != date2.day) {
                               showDateHeader = true;
                           }
                       } catch (_) {}
                   }
                }

                final String contentStr = msg['content'] ?? '';
                final bool isMap = contentStr.contains('MAP:');
                String textContent = contentStr;
                SafeZone? targetZone;
                
                if (isMap) {
                    final parts = contentStr.split('\nMAP:');
                    textContent = parts[0];
                    if (parts.length > 1) {
                       final mapKey = parts[1].trim();
                       try {
                          targetZone = _allZones.firstWhere(
                            (z) => z.id == mapKey || z.name == mapKey
                          );
                       } catch (_) {
                          try {
                             targetZone = SafeZone.predefinedZones.firstWhere(
                               (z) => z.id == mapKey || z.name == mapKey
                             );
                          } catch (_) {}
                       }
                    }
                }

                Widget messageContent;
                if (isMap && targetZone != null) {
                   messageContent = Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                         Text(textContent, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 8),
                         Container(
                            height: 120,
                            width: 200,
                            decoration: BoxDecoration(
                               color: Colors.grey[200],
                               borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: FlutterMap(
                               options: MapOptions(
                                  initialCenter: targetZone.coordinates,
                                  initialZoom: 17.5,
                                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                               ),
                               children: [
                                  TileLayer(
                                     urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                     userAgentPackageName: 'com.campusswap.app',
                                  ),
                                  MarkerLayer(
                                     markers: [
                                        Marker(
                                           point: targetZone.coordinates,
                                           width: 40, height: 40,
                                           child: const Icon(Icons.location_on, color: Colors.red, size: 32),
                                        )
                                     ]
                                  )
                               ]
                            )
                         ),
                         const SizedBox(height: 8),
                         ElevatedButton.icon(
                             onPressed: () async {
                                 final lat = targetZone?.coordinates.latitude ?? 0.0;
                                 final lng = targetZone?.coordinates.longitude ?? 0.0;
                                 final url = Uri.parse('https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=18/$lat/$lng');
                                 if (await canLaunchUrl(url)) {
                                     await launchUrl(url);
                                 }
                             },
                             icon: const Icon(Icons.map, size: 16),
                             label: const Text('Open Maps', style: TextStyle(fontSize: 12)),
                             style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Theme.of(context).colorScheme.primary, minimumSize: const Size(200, 32)),
                         )
                      ]
                   );
                } else {
                   messageContent = Text(
                      textContent,
                      style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
                   );
                }

                Widget messageBubble = Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? Theme.of(context).colorScheme.primary : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        messageContent,
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(isoTime),
                          style: TextStyle(color: isMe ? Colors.white70 : Colors.black54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );

                if (showDateHeader) {
                    return Column(
                        children: [
                            Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: Colors.blueGrey[50], 
                                        borderRadius: BorderRadius.circular(12)
                                    ),
                                    child: Text(_formatDate(isoTime), style: TextStyle(color: Colors.blueGrey[600], fontSize: 12, fontWeight: FontWeight.bold))
                                ),
                            ),
                            messageBubble,
                        ]
                    );
                }
                return messageBubble;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                  onPressed: _showSafeMeetupDialog,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: _sendMessage, icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary))
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showReportUserDialog(BuildContext context, String targetUserId, String targetUserName) {
      showDialog(
          context: context,
          builder: (context) {
              String description = '';
              String violationType = 'Harassment';
              bool isSubmitting = false;
              return StatefulBuilder(
                  builder: (context, setState) {
                      return AlertDialog(
                          title: Text('Report @$targetUserName', style: const TextStyle(fontWeight: FontWeight.bold)),
                          content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                  DropdownButtonFormField<String>(
                                      value: violationType,
                                      decoration: const InputDecoration(
                                          labelText: 'Reason for Report',
                                          border: OutlineInputBorder(),
                                      ),
                                      items: const [
                                          DropdownMenuItem(value: 'Harassment', child: Text('Offline Harassment')),
                                          DropdownMenuItem(value: 'No-show', child: Text('No-show / Flaked')),
                                          DropdownMenuItem(value: 'Scam', child: Text('Scam / Fraud')),
                                          DropdownMenuItem(value: 'Spam', child: Text('Spamming')),
                                          DropdownMenuItem(value: 'Other', child: Text('Other Misbehavior')),
                                      ],
                                      onChanged: (val) {
                                          if (val != null) {
                                              setState(() => violationType = val);
                                          }
                                      },
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                      onChanged: (val) => description = val,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                          labelText: 'Details of Misconduct',
                                          hintText: 'Explain the issue or behavior...',
                                          border: OutlineInputBorder(),
                                      ),
                                  ),
                              ],
                          ),
                          actions: [
                              TextButton(
                                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                          if (description.trim().isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Please provide details of misconduct')),
                                              );
                                              return;
                                          }
                                          setState(() => isSubmitting = true);
                                          try {
                                              final apiClient = ApiClient();
                                              await apiClient.post('/auth/user/$targetUserId/report', {
                                                  'violation_type': violationType,
                                                  'description': description.trim(),
                                              });
                                              if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('User reported successfully.'), backgroundColor: Colors.green),
                                                  );
                                                  Navigator.pop(context);
                                              }
                                          } catch (e) {
                                              if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Failed to submit report: $e'), backgroundColor: Colors.red),
                                                  );
                                              }
                                          } finally {
                                              if (context.mounted) {
                                                  setState(() => isSubmitting = false);
                                              }
                                          }
                                      },
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006940)),
                                  child: isSubmitting
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Submit', style: TextStyle(color: Colors.white)),
                              ),
                          ],
                      );
                  },
              );
          },
      );
  }
}
