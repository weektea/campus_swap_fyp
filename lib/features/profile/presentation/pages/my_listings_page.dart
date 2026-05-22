import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';
import 'package:campus_swap/features/product/presentation/pages/product_details_page.dart';
import 'package:campus_swap/features/product/presentation/pages/edit_listing_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/core/widgets/empty_state_widget.dart';
import 'package:campus_swap/features/product/presentation/pages/sell_page.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> with SingleTickerProviderStateMixin {
  List<Product> _products = [];
  bool _isLoading = true;
  late TabController _tabController;
  
  String _filterType = 'All';
  String _sortBy = 'Newest';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchMyListings();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyListings() async {
    final session = UserSession();
    if (session.userId == null) return;

    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('/products?seller_id=${session.userId}');
      
      if (response is List) {
        if (mounted) {
            setState(() {
            _products = response.map((data) => Product.fromJson(data)).toList();
            _isLoading = false;
            });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
      bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
              title: Text('Delete Listing', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: Text('Are you sure you want to delete this listing?', style: GoogleFonts.outfit()),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.outfit())),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold))),
              ]
          )
      ) ?? false;

      if (!confirm) return;

      try {
          final apiClient = ApiClient();
          await apiClient.delete('/products/${product.id}');
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Listing deleted successfully', style: GoogleFonts.outfit())));
              _fetchMyListings();
          }
      } catch (e) {
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
          }
      }
  }

  @override
  Widget build(BuildContext context) {
    var filteredList = List<Product>.from(_products);
    
    if (_filterType == 'Sale') {
      filteredList = filteredList.where((p) => p.type.toLowerCase() == 'sale').toList();
    } else if (_filterType == 'Rent') {
      filteredList = filteredList.where((p) => p.type.toLowerCase() == 'rent').toList();
    }

    if (_sortBy == 'Newest') {
      filteredList.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    } else if (_sortBy == 'Oldest') {
      filteredList.sort((a, b) => a.postedAt.compareTo(b.postedAt));
    }

    final active = filteredList.where((p) => p.status == 'Available').toList();
    final reserved = filteredList.where((p) => p.status == 'Reserved').toList();
    final sold = filteredList.where((p) => p.status == 'Sold').toList();
    final suspended = filteredList.where((p) => p.status == 'Suspended').toList();

    return Scaffold(
      appBar: AppBar(
          title: Text('My Inventory', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20)),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: _showFilterSortSheet,
            ),
          ],
          bottom: TabBar(
              controller: _tabController,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.outfit(),
              tabs: [
                  Tab(text: active.isNotEmpty ? 'Active (${active.length})' : 'Active'),
                  Tab(text: reserved.isNotEmpty ? 'Reserved (${reserved.length})' : 'Reserved'),
                  Tab(text: sold.isNotEmpty ? 'Sold (${sold.length})' : 'Sold'),
                  Tab(text: suspended.isNotEmpty ? 'Suspended (${suspended.length})' : 'Suspended'),
              ],
          ),
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
                _buildList(active),
                _buildList(reserved),
                _buildList(sold),
                _buildList(suspended),
            ],
        )
    );
  }

  Widget _buildList(List<Product> list) {
      if (list.isEmpty) {
          return EmptyStateWidget(
              icon: Icons.storefront_outlined,
              title: 'Your Shop is Empty',
              message: 'Got textbooks or gadgets collecting dust? Turn them into cash or rent them out to other students!',
              buttonText: 'Open your shop',
              onActionPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SellPage())).then((_) => _fetchMyListings());
              },
          );
      }
      return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
              return _buildInventoryCard(list[index]);
          }
      );
  }

  Widget _buildInventoryCard(Product product) {
      final isRent = product.type.toLowerCase() == 'rent';
      final priceStr = isRent ? 'RM ${product.rentalPricePerDay.toStringAsFixed(2)} /day' : 'RM ${product.price.toStringAsFixed(2)}';

      return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
              onTap: () {
                   Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ProductDetailsPage(product: product)
                   )).then((_) => _fetchMyListings());
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                          // Image
                          ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                  width: 68,
                                  height: 68,
                                  child: product.imageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: product.imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(color: Colors.grey[100]),
                                          errorWidget: (context, url, error) => Container(color: Colors.grey[100], child: const Icon(Icons.broken_image, color: Colors.grey, size: 24)),
                                      )
                                      : Container(color: Colors.grey[100], child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 24)),
                              )
                          ),
                          const SizedBox(width: 16),
                          // Details
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      Text(
                                          product.title, 
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16, color: const Color(0xFF0F172A)), 
                                          maxLines: 1, 
                                          overflow: TextOverflow.ellipsis
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                          priceStr, 
                                          style: GoogleFonts.outfit(color: const Color(0xFF475569), fontSize: 14)
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                      children: [
                                      Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12)
                                          ),
                                          child: Text(
                                              product.status,
                                              style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)
                                          )
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                              color: isRent ? Colors.orange.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12)
                                          ),
                                          child: Text(
                                              isRent ? 'For Rent' : 'For Sale',
                                              style: GoogleFonts.outfit(color: isRent ? Colors.orange : Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)
                                          )
                                      ),
                                      ],
                                      )
                                  ]
                              )
                          ),
                          // Actions
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (product.status == 'Available')
                                IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF64748B), size: 22),
                                    onPressed: () async {
                                        final result = await Navigator.push(
                                            context, 
                                            MaterialPageRoute(builder: (_) => EditListingPage(product: product))
                                        );
                                        if (result == true) {
                                            _fetchMyListings();
                                        }
                                    }
                                ),
                              IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 22),
                                  onPressed: () => _deleteProduct(product)
                              ),
                            ],
                          ),
                      ]
                  )
              )
          )
      );
  }

  void _showFilterSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Filter & Sort", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text("Listing Type", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'All', label: Text('All')),
                      ButtonSegment(value: 'Sale', label: Text('For Sale')),
                      ButtonSegment(value: 'Rent', label: Text('For Rent')),
                    ],
                    selected: {_filterType},
                    onSelectionChanged: (val) {
                      setModalState(() => _filterType = val.first);
                      setState(() => _filterType = val.first);
                    },
                  ),
                  const SizedBox(height: 24),
                  Text("Sort By", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: ['Newest', 'Oldest'].map((sort) {
                      return ChoiceChip(
                        label: Text(sort),
                        selected: _sortBy == sort,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => _sortBy = sort);
                            setState(() => _sortBy = sort);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16)
                      ),
                      child: Text("Done", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }
}
