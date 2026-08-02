import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/core/widgets/empty_state_widget.dart';
import 'package:campus_swap/features/product/presentation/pages/sell_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/transaction_detail_page.dart';
import 'package:campus_swap/features/home/presentation/pages/home_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/rate_experience_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/e_receipt_modal.dart';
import 'package:campus_swap/core/services/socket_service.dart';

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

    SocketService().socket?.on('transaction_status_updated', _onSocketStatusUpdated);
  }

  void _onSocketStatusUpdated(dynamic data) {
    if (mounted) {
      _fetchAllTransactions();
    }
  }

  @override
  void dispose() {
    SocketService().socket?.off('transaction_status_updated', _onSocketStatusUpdated);
    _tabController.dispose();
    super.dispose();
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
    final theme = Theme.of(context);
    final filteredBuying = _filterStatus == 'All' 
        ? _buyingTransactions 
        : _buyingTransactions.where((t) => t['status']?.toString().toLowerCase() == _filterStatus.toLowerCase()).toList();
    final filteredSelling = _filterStatus == 'All' 
        ? _sellingTransactions 
        : _sellingTransactions.where((t) => t['status']?.toString().toLowerCase() == _filterStatus.toLowerCase()).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        automaticallyImplyLeading: widget.isPushed,
        bottom: TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
            indicatorColor: theme.colorScheme.onPrimary,
            tabs: [
                Tab(text: 'Purchases (${filteredBuying.length})'), 
                Tab(text: 'Sales (${filteredSelling.length})')
            ],
            labelStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: theme.textTheme.titleSmall,
        ),
      ),
      body: Column(
        children: [
            if (!_isLoading) Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                    children: [
                        Text(
                          "Filter:",
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                            child: DropdownButtonFormField<String>(
                                value: _filterStatus,
                                isDense: true,
                                decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: theme.textTheme.bodyMedium))).toList(),
                                onChanged: (val) {
                                    if (val != null) setState(() => _filterStatus = val);
                                },
                            ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'Total: ${_tabController.index == 0 ? filteredBuying.length : filteredSelling.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
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
      final theme = Theme.of(context);
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
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
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
                                 ? Image.network(
                                     '${ApiClient.baseUrl.replaceAll('/api', '')}$productImg',
                                     fit: BoxFit.cover, 
                                     errorBuilder: (c,o,s) => Container(
                                       color: theme.colorScheme.surfaceContainer,
                                       child: const Icon(Icons.error),
                                     ),
                                   ) 
                                 : Container(color: theme.colorScheme.surfaceContainer),
                             ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text(
                                    product['title'] ?? 'Unknown Item',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'RM ${item['amount']}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: _getStatusColor(context, status).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8)
                                      ),
                                      child: Text(
                                        status,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: _getStatusColor(context, status),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
                                      foregroundColor: theme.colorScheme.onSurface,
                                      side: BorderSide(color: theme.colorScheme.outline),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                  ),
                                  child: Text(
                                    'View Progress',
                                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                              ),
                            ),
                          ),
                          if (status.toString().toLowerCase() == 'completed') ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 44,
                              child: OutlinedButton.icon(
                                onPressed: () => EReceiptModal.show(context, item),
                                icon: const Icon(Icons.receipt_long, size: 18, color: Color(0xFF005A43)),
                                label: Text(
                                  'Receipt',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF005A43),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF005A43)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                          if (status.toString().toLowerCase() == 'completed' && (isBuying ? item['rating_from_buyer'] == null : item['rating_from_seller'] == null)) ...[
                            const SizedBox(width: 8),
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
                                                revieweeName: otherParty['username'] != null ? '@${otherParty['username']}' : 'User',
                                                productName: product['title'] ?? 'Item',
                                                onSubmitted: () {
                                                    _fetchAllTransactions();
                                                },
                                            )
                                        ));
                                        _fetchAllTransactions();
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                        foregroundColor: theme.colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                    ),
                                    child: Text(
                                      'Rate',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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

  Color _getStatusColor(BuildContext context, String status) {
      final theme = Theme.of(context);
      switch(status.toString().toLowerCase()) {
          case 'pending': return Colors.orange;
          case 'scheduled': return theme.colorScheme.secondary;
          case 'to confirm': return Colors.amber;
          case 'completed': return theme.colorScheme.primary;
          case 'cancelled': return theme.colorScheme.error;
          case 'disputed': return theme.colorScheme.errorContainer;
          default: return theme.colorScheme.onSurfaceVariant;
      }
  }
}
