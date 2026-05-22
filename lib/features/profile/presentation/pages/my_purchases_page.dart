import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/core/widgets/empty_state_widget.dart';
import 'package:campus_swap/features/product/presentation/pages/sell_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/transaction_detail_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/rate_experience_page.dart';
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
  String _filterStatus = 'All';
  final List<String> _statusOptions = ['All', 'Pending', 'Scheduled', 'Completed', 'Cancelled', 'Disputed'];

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
                    if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispute submitted. A moderator will review it.')));
                    }
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

  void _showRateDialog(String transactionId, String revieweeId, bool isBuying, String revieweeName, String productName) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => RateExperiencePage(
      transactionId: transactionId,
      revieweeId: revieweeId,
      isSeller: !isBuying,
      revieweeName: revieweeName,
      productName: productName,
      onSubmitted: () {
          _fetchAllTransactions(); // Refresh UI to hide button ideally or show "Rated"
      }
    )));
  }

  @override
  Widget build(BuildContext context) {
    final filteredBuying = _filterStatus == 'All' ? _buyingTransactions : _buyingTransactions.where((t) => t['status'] == _filterStatus).toList();
    final filteredSelling = _filterStatus == 'All' ? _sellingTransactions : _sellingTransactions.where((t) => t['status'] == _filterStatus).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        bottom: TabBar(
            controller: _tabController,
            tabs: [
                Tab(text: 'Purchases (${filteredBuying.length})'), 
                Tab(text: 'Sales (${filteredSelling.length})')
            ],
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
            if (!_isLoading) Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                    children: [
                        Text("Filter by:", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: DropdownButtonFormField<String>(
                                value: _filterStatus,
                                isDense: true,
                                decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.outfit()))).toList(),
                                onChanged: (val) {
                                    if (val != null) setState(() => _filterStatus = val);
                                },
                            ),
                        )
                    ],
                ),
            ),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                        _buildList(filteredBuying, isBuying: true),
                        _buildList(filteredSelling, isBuying: false),
                    ],
                ),
            ),
        ],
      ),
    );
  }

  Widget _buildList(List<dynamic> transactions, {required bool isBuying}) {
      if (transactions.isEmpty) {
          return EmptyStateWidget(
              icon: isBuying ? Icons.shopping_bag_outlined : Icons.receipt_long_outlined,
              title: isBuying ? 'No Purchases Yet' : 'No Sales Yet',
              message: isBuying ? 'You haven\'t bought anything yet. Explore the marketplace to find great deals!' : 'You haven\'t sold anything yet. List your items to start earning!',
              buttonText: isBuying ? 'Explore Market' : 'Start Selling',
              onActionPressed: () {
                  if (isBuying) {
                      Navigator.pop(context); // Go back to profile -> home
                  } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SellPage())).then((_) => _fetchTransactions());
                  }
              },
          );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
            final item = transactions[index];
            final product = item['product'] ?? {};
            final status = item['status'];
            final productImg = product['image_urls'] != null && (product['image_urls'] as List).isNotEmpty ? product['image_urls'][0] : (product['imageUrl'] ?? '');

            return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           // Product Image
                           ClipRRect(
                             borderRadius: BorderRadius.circular(12),
                             child: SizedBox(
                               width: 72, height: 72,
                               child: productImg.isNotEmpty 
                                 ? Image.network('${ApiClient.baseUrl.replaceAll('/api', '')}$productImg', fit: BoxFit.cover, 
                                      errorBuilder: (c,o,s) => Container(color: Colors.grey[200], child: const Icon(Icons.error))) 
                                 : Container(color: Colors.grey[200]),
                             ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text(product['title'] ?? 'Unknown Item', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text('RM ${item['amount']}', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, color: Theme.of(context).colorScheme.primary)),
                                  const SizedBox(height: 8),
                                  Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: _getStatusColor(status).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8)
                                      ),
                                      child: Text(status, style: GoogleFonts.outfit(color: _getStatusColor(status), fontWeight: FontWeight.w600, fontSize: 12)),
                                  ),
                              ],
                             ),
                           )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                            onPressed: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionDetailPage(transactionId: item['id'])));
                                _fetchAllTransactions();
                            },
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                            child: Text('View Progress', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ),
                  ],
                ),
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
