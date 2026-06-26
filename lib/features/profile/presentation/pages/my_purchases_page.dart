import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/core/widgets/empty_state_widget.dart';
import 'package:campus_swap/features/product/presentation/pages/sell_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/transaction_detail_page.dart';
import 'package:campus_swap/features/home/presentation/pages/home_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/rate_experience_page.dart';

class MyTransactionsPage extends StatefulWidget {
  final bool isPushed;
  const MyTransactionsPage({super.key, this.isPushed = false});

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


  @override
  Widget build(BuildContext context) {
    final filteredBuying = _filterStatus == 'All' ? _buyingTransactions : _buyingTransactions.where((t) => t['status'] == _filterStatus).toList();
    final filteredSelling = _filterStatus == 'All' ? _sellingTransactions : _sellingTransactions.where((t) => t['status'] == _filterStatus).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: widget.isPushed,
        bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
                Tab(text: 'Purchases (${filteredBuying.length})'), 
                Tab(text: 'Sales (${filteredSelling.length})')
            ],
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.outfit(),
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
                      if (widget.isPushed) {
                          Navigator.pop(context, 'go_to_home'); // Return result to switch tab to home page
                      } else {
                          // Directly embedded in HomePage, change selected tab to Home (index 0)
                          final homeState = context.findAncestorStateOfType<HomePageState>();
                          if (homeState != null) {
                              homeState.setSelectedIndex(0);
                          }
                      }
                  } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SellPage(isPushed: true))).then((_) => _fetchAllTransactions());
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
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
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
                                          color: _getStatusColor(status).withValues(alpha: 0.15),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                  onPressed: () async {
                                      await Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionDetailPage(transactionId: item['id'])));
                                      _fetchAllTransactions();
                                  },
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black87,
                                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                  ),
                                  child: Text('View Progress', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ),
                          ),
                          if (status == 'Completed' && (isBuying ? item['rating_from_buyer'] == null : item['rating_from_seller'] == null)) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                    onPressed: () async {
                                        final otherParty = isBuying ? item['seller'] : item['buyer'];
                                        await Navigator.push(context, MaterialPageRoute(
                                            builder: (_) => RateExperiencePage(
                                                transactionId: item['id'].toString(),
                                                revieweeId: otherParty['id']?.toString() ?? '',
                                                isSeller: !isBuying,
                                                revieweeName: otherParty['full_name'] ?? 'User',
                                                productName: product['title'] ?? 'Item',
                                                onSubmitted: () {
                                                    _fetchAllTransactions();
                                                },
                                            )
                                        ));
                                        _fetchAllTransactions();
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0D503C), // Matching RateExperiencePage button
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                    ),
                                    child: Text('Rate Experience', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                              ),
                            ),
                          ],
                        ],
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

}
