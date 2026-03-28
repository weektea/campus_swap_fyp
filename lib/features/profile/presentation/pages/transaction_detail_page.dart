import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/features/chat/presentation/pages/chat_detail_page.dart';
import 'package:url_launcher/url_launcher.dart';

class TransactionDetailPage extends StatefulWidget {
  final String transactionId;

  const TransactionDetailPage({super.key, required this.transactionId});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  bool _isLoading = true;
  dynamic _transaction;
  final session = UserSession();

  @override
  void initState() {
    super.initState();
    _fetchTransactionDetails();
  }

  Future<void> _fetchTransactionDetails() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      final res = await apiClient.get('/transactions/${widget.transactionId}');
      if (mounted) {
        setState(() {
          _transaction = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading details: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
      try {
          final apiClient = ApiClient();
          await apiClient.patch('/transactions/${widget.transactionId}/status', {'status': newStatus});
          _fetchTransactionDetails(); // Refresh
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      } catch (e) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
  }

  Color _getStatusColor(String status) {
      switch(status) {
          case 'Pending': return Colors.orange;
          case 'Scheduled': return Colors.blue;
          case 'To Confirm': return Colors.amber;
          case 'Completed': return Colors.green;
          case 'Cancelled': return Colors.red;
          case 'Disputed': return Colors.purple;
          default: return Colors.grey;
      }
  }

  Widget _buildStatusStepper(String status) {
      if (status == 'Cancelled' || status == 'Disputed') {
          return Center(child: Text('Transaction $status', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)));
      }
      
      final stages = ['Pending', 'Scheduled', 'To Confirm', 'Completed'];
      final labels = ['Pending', 'Meetup', 'Payment', 'Done'];
      int currentIndex = stages.indexOf(status);
      if (currentIndex == -1) currentIndex = 0;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: List.generate(stages.length * 2 - 1, (index) {
             if (index % 2 != 0) {
                int stepIndex = index ~/ 2;
                bool isActive = currentIndex > stepIndex;
                return Expanded(
                  child: Container(
                    height: 3, 
                    color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey[200]
                  )
                );
             } else {
                int stepIndex = index ~/ 2;
                bool isPassed = currentIndex > stepIndex;
                bool isCurrent = currentIndex == stepIndex;
                Color nodeColor = isPassed || isCurrent ? Theme.of(context).colorScheme.primary : Colors.grey[300]!;

                return Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                      Container(
                         width: 24, height: 24,
                         decoration: BoxDecoration(
                            color: nodeColor,
                            shape: BoxShape.circle,
                            border: isCurrent ? Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), width: 4) : null,
                         ),
                         child: isPassed ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                         labels[stepIndex], 
                         style: GoogleFonts.outfit(
                            fontSize: 11, 
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isPassed || isCurrent ? Colors.black87 : Colors.grey
                         )
                      )
                   ]
                );
             }
          }),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Order Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_transaction == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Order Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
        body: Center(child: Text('Transaction not found', style: GoogleFonts.outfit())),
      );
    }

    final product = _transaction['product'] ?? {};
    final bool isBuying = _transaction['buyer_id'] == session.userId;
    final otherParty = isBuying ? _transaction['seller'] : _transaction['buyer'];
    final status = _transaction['status'];
    final productImg = product['image_urls'] != null && (product['image_urls'] as List).isNotEmpty ? product['image_urls'][0] : '';
    final String otherPartyName = otherParty['full_name'] ?? 'Unknown User';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #...${widget.transactionId.substring(widget.transactionId.length - 6)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Stepper
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(
                    children: [
                        Text('Transaction Progress', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildStatusStepper(status),
                    ],
                )
            ),
            const SizedBox(height: 24),

            // Product Brief
            Text('Item Summary', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
               child: Row(
                   children: [
                       ClipRRect(
                           borderRadius: BorderRadius.circular(8),
                           child: productImg.isNotEmpty 
                             ? Image.network('${ApiClient.baseUrl.replaceAll('/api', '')}$productImg', width: 60, height: 60, fit: BoxFit.cover)
                             : Container(width: 60, height: 60, color: Colors.grey.shade200)
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                           child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                   Text(product['title'] ?? 'Unknown Item', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                                   Text('${product['type'] ?? 'Sale'} Request', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13)),
                               ]
                           )
                       ),
                       Text('RM ${_transaction['amount']}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
                   ]
               )
            ),
            const SizedBox(height: 24),

            // Party Info & Chat
            Text(isBuying ? 'Seller Info' : 'Buyer Info', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(otherPartyName[0].toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
              ),
              title: Text(otherPartyName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              subtitle: Text(otherParty['email'] ?? '', style: GoogleFonts.outfit(fontSize: 12)),
              trailing: ElevatedButton.icon(
                  onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailPage(
                           sellerName: otherPartyName,
                           otherUserId: otherParty['id']
                       )));
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Chat'),
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 24),

            // Actions Based on Status
            Text('Actions Required', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildActionPanel(status, isBuying),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPanel(String status, bool isBuying) {
      if (status == 'Cancelled' || status == 'Completed' || status == 'Disputed') {
          return Center(child: Text('No pending actions needed.', style: GoogleFonts.outfit(color: Colors.grey)));
      }

      Widget actionBtn = const SizedBox.shrink();

      if (status == 'Pending') {
          if (isBuying) {
             actionBtn = Text('Wait for the seller to confirm your request.', style: GoogleFonts.outfit());
          } else {
             actionBtn = Row(
               children: [
                 Expanded(child: OutlinedButton(onPressed: () => _updateStatus('Cancelled'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text('Cancel Request'))),
                 const SizedBox(width: 16),
                 Expanded(child: ElevatedButton(onPressed: () => _updateStatus('Scheduled'), child: const Text('Confirm Order'))),
               ],
             );
          }
      } else if (status == 'Scheduled') {
          if (isBuying) {
             actionBtn = SizedBox(
                 width: double.infinity,
                 child: ElevatedButton.icon(
                      onPressed: () => _updateStatus('To Confirm'),
                      icon: const Icon(Icons.payment),
                      label: const Text('Submit Payment / Handover Confirm'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16))
                 ),
             );
          } else {
             actionBtn = Text('Wait for the buyer to submit payment or confirm receiving the item.', style: GoogleFonts.outfit());
          }
      } else if (status == 'To Confirm') {
          if (isBuying) {
             actionBtn = Text('Payment submitted. Awaiting seller validation.', style: GoogleFonts.outfit(color: Colors.orange));
          } else {
             actionBtn = SizedBox(
                 width: double.infinity,
                 child: ElevatedButton.icon(
                      onPressed: () => _updateStatus('Completed'),
                      icon: const Icon(Icons.verified),
                      label: const Text('Verify Payment & Complete Order'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16))
                 ),
             );
          }
      }

      return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2))
          ),
          child: actionBtn
      );
  }
}
