import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/features/profile/presentation/pages/transaction_detail_page.dart';

class MyTransactionsPage extends StatefulWidget {
  const MyTransactionsPage({super.key});

  @override
  State<MyTransactionsPage> createState() => _MyTransactionsPageState();
}

class _MyTransactionsPageState extends State<MyTransactionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _buyingTransactions = [];
  List<dynamic> _sellingTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAllTransactions();
  }

  Future<void> _fetchAllTransactions() async {
    final session = UserSession();
    if (session.userId == null) return;
    setState(() => _isLoading = true);

    try {
      final apiClient = ApiClient();
      // Fetch Buying
      final buyRes = await apiClient.get('/transactions/user/${session.userId}?type=buying');
      // Fetch Selling
      final sellRes = await apiClient.get('/transactions/user/${session.userId}?type=selling');
      
      if (mounted) {
        setState(() {
          _buyingTransactions = buyRes is List ? buyRes : [];
          _sellingTransactions = sellRes is List ? sellRes : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
      try {
          final apiClient = ApiClient();
          await apiClient.patch('/transactions/$id/status', {'status': newStatus});
          _fetchAllTransactions(); // Refresh
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      } catch (e) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
  }

  void _showDisputeDialog(String transactionId) {
    showDialog(
      context: context,
      builder: (context) {
        String reason = '';
        String selectedCategory = 'Item not received';
        final List<String> categories = ['Item not received', 'Item damaged/not as described', 'Fake payment proof', 'Seller unresponsive', 'Other'];

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Report Issue / Dispute', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Dispute Reason',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: GoogleFonts.outfit()))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text('Describe the issue:', style: GoogleFonts.outfit()),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (v) => reason = v,
                    decoration: const InputDecoration(
                      hintText: 'Provide details...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                          // Mock upload evidence
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evidence attached (Mock)')));
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Evidence (Photo)'),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (reason.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a description'), backgroundColor: Colors.red));
                      return;
                    }
                    Navigator.pop(context);
                    
                    try {
                        final apiClient = ApiClient();
                        await apiClient.post('/disputes', {
                            'transaction_id': transactionId,
                            'reporter_id': UserSession().userId,
                            'category': selectedCategory,
                            'description': reason,
                            'status': 'New'
                        });
                    } catch (e) {
                        // ignore error
                    }

                    _updateStatus(transactionId, 'Disputed');
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispute submitted. A moderator will review it.')));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Submit Dispute', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showRateDialog(String transactionId, String revieweeId) {
    showDialog(
      context: context, 
      builder: (context) => RateUserDialog(
        transactionId: transactionId, 
        revieweeId: revieweeId,
        onSubmitted: () {
            _fetchAllTransactions(); // Refresh UI to hide button ideally or show "Rated"
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Transactions', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        bottom: TabBar(
            controller: _tabController,
            tabs: const [Tab(text: 'Purchases'), Tab(text: 'Sales')],
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
                _buildList(_buyingTransactions, isBuying: true),
                _buildList(_sellingTransactions, isBuying: false),
            ],
        ),
    );
  }

  Widget _buildList(List<dynamic> transactions, {required bool isBuying}) {
      if (transactions.isEmpty) {
          return Center(child: Text(isBuying ? 'No purchases yet.' : 'No sales yet.', style: GoogleFonts.outfit()));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
            final item = transactions[index];
            final product = item['product'] ?? {};
            final otherParty = isBuying ? (item['seller'] ?? {}) : (item['buyer'] ?? {});
            final status = item['status'];
            final reviews = item['reviews'] as List?;
            final hasRated = reviews != null && reviews.isNotEmpty;
            final productImg = product['image_urls'] != null && (product['image_urls'] as List).isNotEmpty ? product['image_urls'][0] : (product['imageUrl'] ?? '');

            return GestureDetector(
                onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionDetailPage(transactionId: item['id'])));
                },
                child: Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         // Product Image with Overlay
                         ClipRRect(
                           borderRadius: BorderRadius.circular(12),
                           child: Stack(
                             children: [
                               SizedBox(
                                 width: 80, height: 80,
                                 child: productImg.isNotEmpty 
                                   ? Image.network('${ApiClient.baseUrl.replaceAll('/api', '')}$productImg', fit: BoxFit.cover, 
                                        errorBuilder: (c,o,s) => Container(color: Colors.grey[200], child: const Icon(Icons.error))) 
                                   : Container(color: Colors.grey[200]),
                               ),
                               if (status == 'Completed' || status == 'Reserved')
                                 Positioned.fill(
                                   child: Container(
                                     color: Colors.black.withValues(alpha: 0.4),
                                     child: Center(
                                       child: Text(
                                         status == 'Completed' ? 'SOLD' : 'RESERVED',
                                         style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                                       ),
                                     ),
                                   ),
                                 )
                             ],
                           ),
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Row(
                                    children: [
                                        Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: _getStatusColor(status).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8)
                                            ),
                                            child: Text(status, style: GoogleFonts.outfit(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 10)),
                                        ),
                                        const Spacer(),
                                        Text('RM ${item['amount']}', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, color: Theme.of(context).colorScheme.primary)),
                                    ],
                                ),
                                const SizedBox(height: 8),
                                Text(product['title'] ?? 'Unknown Item', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(
                                    isBuying ? 'Seller: ${otherParty['full_name'] ?? 'Unknown'}' : 'Buyer: ${otherParty['full_name'] ?? 'Unknown'}',
                                    style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12)
                                ),
                                const SizedBox(height: 8),
                                _buildStatusStepper(status),
                                const SizedBox(height: 8),
                                // Actions Row (Extracted)
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                        if (status == 'Pending') ...[
                                            SizedBox(
                                              height: 32,
                                              child: TextButton(
                                                  onPressed: () => _updateStatus(item['id'], 'Cancelled'),
                                                  child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.red, fontSize: 12)),
                                              ),
                                            ),
                                            if (!isBuying) 
                                                SizedBox(
                                                  height: 32,
                                                  child: ElevatedButton(
                                                      onPressed: () => _updateStatus(item['id'], 'Scheduled'),
                                                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                                                      child: Text('Confirm', style: GoogleFonts.outfit(fontSize: 12)),
                                                  ),
                                                ),
                                        ],
                                        if (status == 'Scheduled' && isBuying) ...[
                                                SizedBox(
                                                  height: 32,
                                                  child: ElevatedButton(
                                                      onPressed: () => _showPaymentDialog(item['id']),
                                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 12)),
                                                      child: Text('Submit Payment', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12)),
                                                  ),
                                                ),
                                        ],
                                        if (status == 'To Confirm' && !isBuying) ...[
                                                SizedBox(
                                                  height: 32,
                                                  child: ElevatedButton(
                                                      onPressed: () => _updateStatus(item['id'], 'Completed'),
                                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 12)),
                                                      child: Text('Verify Payment', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12)),
                                                  ),
                                                ),
                                        ],
                                        if (status == 'To Confirm' && isBuying) ...[
                                                Text('Pending Verification', style: GoogleFonts.outfit(fontSize: 12, color: Colors.orange)),
                                        ],
                                         if (status == 'Completed' && isBuying) ...[
                                                hasRated 
                                                ? Row(children: [const Icon(Icons.star, color: Colors.amber, size: 14), const SizedBox(width: 4), Text('Rated', style: GoogleFonts.outfit(fontSize: 12, color: Colors.amber))]) 
                                                : SizedBox(
                                                  height: 32,
                                                  child: OutlinedButton(
                                                      onPressed: () => _showRateDialog(item['id'], otherParty['id']),
                                                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                                                      child: Text('Rate', style: GoogleFonts.outfit(fontSize: 12)),
                                                  ),
                                                ),
                                        ],
                                        if (status == 'Scheduled' || status == 'Completed') ...[
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            height: 32,
                                            child: TextButton.icon(
                                                onPressed: () => _showDisputeDialog(item['id']),
                                                icon: const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                                                label: Text('Report', style: GoogleFonts.outfit(color: Colors.red, fontSize: 12)),
                                            ),
                                          ),
                                        ],
                                    ],
                                )
                            ],
                           ),
                         )
                      ],
                    )
                ),
            ), // Closes Card
            );
        },
      );
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
      if (status == 'Cancelled' || status == 'Disputed') return const SizedBox.shrink();
      
      final stages = ['Pending', 'Scheduled', 'To Confirm', 'Completed'];
      final labels = ['Pending', 'Meetup', 'Payment', 'Done'];
      int currentIndex = stages.indexOf(status);
      if (currentIndex == -1) currentIndex = 0;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: List.generate(stages.length * 2 - 1, (index) {
             if (index % 2 != 0) {
                // Divider line
                int stepIndex = index ~/ 2;
                bool isActive = currentIndex > stepIndex;
                return Expanded(
                  child: Container(
                    height: 3, 
                    color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey[200]
                  )
                );
             } else {
                // Node dot with label
                int stepIndex = index ~/ 2;
                bool isPassed = currentIndex > stepIndex;
                bool isCurrent = currentIndex == stepIndex;
                Color nodeColor = isPassed || isCurrent ? Theme.of(context).colorScheme.primary : Colors.grey[300]!;

                return Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                      Container(
                         width: 16, height: 16,
                         decoration: BoxDecoration(
                            color: nodeColor,
                            shape: BoxShape.circle,
                            border: isCurrent ? Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), width: 4) : null,
                         ),
                         child: isPassed ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                         labels[stepIndex], 
                         style: GoogleFonts.outfit(
                            fontSize: 9, 
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

  void _showPaymentDialog(String transactionId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Submit Payment', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please upload your cashless transfer receipt or confirm cash payment at meetup.', style: GoogleFonts.outfit()),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt attached (Mock)')));
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Receipt (Photo)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateStatus(transactionId, 'To Confirm');
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment proof submitted. Awaiting seller confirmation.')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Submit Payment', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class RateUserDialog extends StatefulWidget {
  final String transactionId;
  final String revieweeId;
  final VoidCallback onSubmitted;

  const RateUserDialog({super.key, required this.transactionId, required this.revieweeId, required this.onSubmitted});

  @override
  State<RateUserDialog> createState() => _RateUserDialogState();
}

class _RateUserDialogState extends State<RateUserDialog> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  void _submitReview() async {
    setState(() => _isSubmitting = true);
    final session = UserSession();

    try {
      final apiClient = ApiClient();
      await apiClient.post('/reviews', {
        'transaction_id': widget.transactionId,
        'reviewer_id': session.userId,
        'reviewee_id': widget.revieweeId,
        'rating': _rating,
        'comment': _commentController.text
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review Submitted!')));
        widget.onSubmitted();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rate Experience', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => setState(() => _rating = index + 1),
                icon: Icon(
                  index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'How was your experience?',
              hintStyle: GoogleFonts.outfit(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.outfit())),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview, 
          child: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text('Submit', style: GoogleFonts.outfit()),
        ),
      ],
    );
  }
}
