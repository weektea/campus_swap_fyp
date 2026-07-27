import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';
import 'package:campus_swap/features/home/presentation/widgets/product_card.dart';
import 'package:campus_swap/features/home/presentation/widgets/product_list_row.dart';
import 'package:campus_swap/core/services/view_preference_service.dart';
import 'package:campus_swap/features/product/presentation/pages/product_details_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/public_profile_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/core/widgets/empty_state_widget.dart';

class SavedItemsPage extends StatefulWidget {
  const SavedItemsPage({super.key});

  @override
  State<SavedItemsPage> createState() => _SavedItemsPageState();
}

class _SavedItemsPageState extends State<SavedItemsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Product> _products = [];
  List<dynamic> _followingSellers = [];
  bool _isLoadingProducts = true;
  bool _isLoadingFollowing = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSavedItems();
    _fetchFollowingSellers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchSavedItems() async {
    final session = UserSession();
    if (session.userId == null) {
      setState(() => _isLoadingProducts = false);
      return;
    }

    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('/saved');
      
      if (response is List && mounted) {
        setState(() {
          _products = response.map((data) => Product.fromJson(data)).toList();
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _fetchFollowingSellers() async {
    final session = UserSession();
    if (session.userId == null) {
      setState(() => _isLoadingFollowing = false);
      return;
    }

    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('/auth/user/following');
      if (response is List && mounted) {
        setState(() {
          _followingSellers = response;
          _isLoadingFollowing = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingFollowing = false);
    }
  }

  Future<void> _toggleFavorite(String productId) async {
    setState(() {
      _products.removeWhere((p) => p.id == productId);
    });
    try {
      final apiClient = ApiClient();
      await apiClient.post('/saved/toggle', {'product_id': productId});
    } catch (e) {
      _fetchSavedItems();
    }
  }

  Future<void> _unfollowSeller(String sellerId) async {
    setState(() {
      _followingSellers.removeWhere((s) => s['id'] == sellerId);
    });
    try {
      final apiClient = ApiClient();
      await apiClient.post('/auth/user/$sellerId/unfollow', {});
    } catch (e) {
      _fetchFollowingSellers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoggedIn = UserSession().isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: Text('Saved & Following', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Saved Items'),
            Tab(text: 'Following Sellers'),
          ],
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: ViewPreferenceService(),
            builder: (context, isGrid, _) {
              return IconButton(
                icon: Icon(isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded),
                tooltip: isGrid ? 'Switch to List View' : 'Switch to Grid View',
                onPressed: () => ViewPreferenceService().toggleViewMode(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _fetchSavedItems();
              _fetchFollowingSellers();
            },
          ),
        ],
      ),
      body: !isLoggedIn
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Login to view saved content', style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Saved Items
                _isLoadingProducts
                    ? const Center(child: CircularProgressIndicator())
                    : _products.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.favorite_border_rounded,
                            title: 'No Saved Items',
                            message: 'Tap the ♡ on any listing to save it here for later.',
                            buttonText: 'Explore Market',
                            onActionPressed: () => Navigator.pop(context),
                          )
                        : ValueListenableBuilder<bool>(
                            valueListenable: ViewPreferenceService(),
                            builder: (context, isGrid, _) {
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: isGrid
                                    ? GridView.builder(
                                        key: const PageStorageKey('saved_items_grid'),
                                        padding: const EdgeInsets.all(16),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.70,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                        ),
                                        itemCount: _products.length,
                                        itemBuilder: (context, index) {
                                          final product = _products[index];
                                          return ProductCard(
                                            product: product,
                                            isFavorite: true,
                                            onFavoriteToggle: () => _toggleFavorite(product.id),
                                            onTap: () {
                                              Navigator.push(context, MaterialPageRoute(
                                                builder: (_) => ProductDetailsPage(product: product)
                                              )).then((_) => _fetchSavedItems());
                                            },
                                          );
                                        },
                                      )
                                    : ListView.builder(
                                        key: const PageStorageKey('saved_items_list'),
                                        padding: const EdgeInsets.all(16),
                                        itemCount: _products.length,
                                        itemBuilder: (context, index) {
                                          final product = _products[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 12.0),
                                            child: ProductListRow(
                                              product: product,
                                              isFavorite: true,
                                              onFavoriteToggle: () => _toggleFavorite(product.id),
                                              onTap: () {
                                                Navigator.push(context, MaterialPageRoute(
                                                  builder: (_) => ProductDetailsPage(product: product)
                                                )).then((_) => _fetchSavedItems());
                                              },
                                            ),
                                          );
                                        },
                                      ),
                              );
                            },
                          ),

                // Tab 2: Following Sellers
                _isLoadingFollowing
                    ? const Center(child: CircularProgressIndicator())
                    : _followingSellers.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.people_outline_rounded,
                            title: 'Not Following Anyone',
                            message: 'Follow sellers to receive instant updates when they post new listings.',
                            buttonText: 'Explore Sellers',
                            onActionPressed: () => Navigator.pop(context),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _followingSellers.length,
                            itemBuilder: (context, index) {
                              final seller = _followingSellers[index];
                              final String profileUrl = seller['profile_image_url'] ?? '';
                              final String fullName = seller['full_name'] ?? seller['username'] ?? 'User';
                              final String username = seller['username'] ?? '';
                              final String faculty = seller['faculty'] ?? 'FCI';
                              final int year = seller['year_of_study'] ?? 1;
                              final int activeListings = seller['active_listings_count'] ?? 0;
                              final bool isVerified = seller['is_verified'] ?? false;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => PublicProfilePage(userId: seller['id'], userName: username)
                                    )).then((_) => _fetchFollowingSellers());
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundImage: profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                          child: profileUrl.isEmpty
                                              ? Text(
                                                  fullName[0].toUpperCase(),
                                                  style: GoogleFonts.outfit(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                    color: theme.colorScheme.primary,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      fullName,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.outfit(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isVerified)
                                                    const Padding(
                                                      padding: EdgeInsets.only(left: 4.0),
                                                      child: Icon(Icons.verified_rounded, color: Colors.blue, size: 16),
                                                    ),
                                                ],
                                              ),
                                              Text(
                                                '@$username',
                                                style: GoogleFonts.outfit(
                                                  color: Colors.grey[600],
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: theme.colorScheme.primary.withOpacity(0.08),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      faculty,
                                                      style: TextStyle(
                                                        color: theme.colorScheme.primary,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      'Year $year',
                                                      style: TextStyle(
                                                        color: Colors.grey[700],
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '$activeListings active listings',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: theme.colorScheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () => _unfollowSeller(seller['id']),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.grey),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          child: Text(
                                            'Unfollow',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ],
            ),
    );
  }
}
