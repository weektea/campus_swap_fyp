import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:google_fonts/google_fonts.dart';

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
            final review = item['review']; // Check if already reviewed (need backend support for this include)

            return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Row(
                                children: [
                                    Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: _getStatusColor(status).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8)
                                        ),
                                        child: Text(status, style: GoogleFonts.outfit(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                    const Spacer(),
                                    Text('RM ${item['amount']}', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: Theme.of(context).colorScheme.primary)),
                                ],
                            ),
                            const SizedBox(height: 12),
                            Text(product['title'] ?? 'Unknown Item', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                                isBuying ? 'Seller: ${otherParty['full_name'] ?? 'Unknown'}' : 'Buyer: ${otherParty['full_name'] ?? 'Unknown'}',
                                style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13)
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            // Actions
                            Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                    if (status == 'Pending') ...[
                                        TextButton(
                                            onPressed: () => _updateStatus(item['id'], 'Cancelled'),
                                            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.red)),
                                        ),
                                        if (!isBuying) // Seller can confirm
                                            ElevatedButton(
                                                onPressed: () => _updateStatus(item['id'], 'Scheduled'),
                                                child: Text('Confirm Meetup', style: GoogleFonts.outfit()),
                                            ),
                                    ],
                                    if (status == 'Scheduled') ...[
                                         if (isBuying) // Buyer confirms receipt
                                            ElevatedButton(
                                                onPressed: () => _updateStatus(item['id'], 'Completed'),
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                                child: Text('Item Received', style: GoogleFonts.outfit(color: Colors.white)),
                                            ),
                                    ],
                                     if (status == 'Completed' && isBuying) ...[ // Only buyer rates seller for now
                                            OutlinedButton.icon(
                                                onPressed: () => _showRateDialog(item['id'], otherParty['id']),
                                                icon: const Icon(Icons.star, size: 16),
                                                label: Text('Rate Seller', style: GoogleFonts.outfit()),
                                            ),
                                    ],
                                ],
                            )
                        ],
                    ),
                ),
            );
        },
      );
  }

  Color _getStatusColor(String status) {
      switch(status) {
          case 'Pending': return Colors.orange;
          case 'Scheduled': return Colors.blue;
          case 'Completed': return Colors.green;
          case 'Cancelled': return Colors.red;
          default: return Colors.grey;
      }
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
