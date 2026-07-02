import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';
import 'package:campus_swap/features/product/presentation/pages/product_details_page.dart';
import 'package:campus_swap/features/home/presentation/widgets/product_card.dart';
import 'package:campus_swap/features/home/presentation/widgets/product_list_row.dart';
import 'package:campus_swap/features/home/presentation/widgets/category_chip.dart';
import 'package:campus_swap/features/chat/presentation/pages/chat_page.dart';
import 'package:campus_swap/features/product/presentation/pages/sell_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/profile_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/my_purchases_page.dart';
import 'package:campus_swap/features/notification/presentation/pages/notifications_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:campus_swap/core/services/notification_service.dart';
import 'package:campus_swap/core/session/user_session.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  void setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    NotificationService().stopPolling();
    super.dispose();
  }

  final ScrollController _scrollController = ScrollController();

  List<Product> _newestProducts = [];
  int _newestPage = 1;
  bool _newestHasMore = true;
  bool _isLoadingNewest = false;
  bool _isLoadingMoreNewest = false;

  void _onScroll() {
    if (_selectedTab != 'Newest') return;
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      _fetchNextPageNewest();
    }
  }

  String getTimeframe(DateTime date, DateTime now) {
    final localDate = date.toLocal(); // TimeZone Guard
    final dateOnly = DateTime(localDate.year, localDate.month, localDate.day);
    final todayOnly = DateTime(now.year, now.month, now.day);
    final difference = todayOnly.difference(dateOnly).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return 'This Week';
    } else if (difference < 30) {
      return 'This Month';
    } else {
      return 'Older';
    }
  }

  List<dynamic> get _newestListItems {
    final List<dynamic> items = [];
    String? currentFrame;
    final now = DateTime.now();
    
    // Pagination Boundary Guard: Sequential evaluation of the combined list
    // guarantees that we never insert duplicate timeline text dividers.
    for (final product in _newestProducts) {
      final frame = getTimeframe(product.postedAt, now);
      if (frame != currentFrame) {
        currentFrame = frame;
        items.add(frame);
      }
      items.add(product);
    }
    
    if (_isLoadingMoreNewest) {
      items.add(const _LoadingMoreMarker());
    }
    
    return items;
  }

  Future<void> _fetchFirstPageNewest() async {
    if (mounted) {
      setState(() {
        _isLoadingNewest = true;
        _newestProducts = [];
        _newestPage = 1;
        _newestHasMore = true;
      });
    }
    
    try {
      final apiClient = ApiClient();
      const limit = 10;
      
      String endpoint = '/items/newest?limit=$limit&page=1';
      if (UserSession().isLoggedIn) {
        endpoint += '&exclude_reported_by=${UserSession().userId}';
      }
      
      final response = await apiClient.get(endpoint);
      if (response is List && mounted) {
        final List<Product> newProducts = response.map((data) => Product.fromJson(data)).toList();
        setState(() {
          _newestProducts = newProducts;
          if (newProducts.length < limit) {
            _newestHasMore = false;
          }
          _isLoadingNewest = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingNewest = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingNewest = false;
        });
      }
    }
  }

  Future<void> _fetchNextPageNewest() async {
    if (_isLoadingNewest || _isLoadingMoreNewest || !_newestHasMore) return;
    
    if (mounted) {
      setState(() {
        _isLoadingMoreNewest = true;
      });
    }
    
    try {
      final apiClient = ApiClient();
      const limit = 10;
      final page = _newestPage + 1;
      
      String endpoint = '/items/newest?limit=$limit&page=$page';
      if (UserSession().isLoggedIn) {
        endpoint += '&exclude_reported_by=${UserSession().userId}';
      }
      
      final response = await apiClient.get(endpoint);
      if (response is List && mounted) {
        final List<Product> newProducts = response.map((data) => Product.fromJson(data)).toList();
        setState(() {
          if (newProducts.isEmpty || newProducts.length < limit) {
            _newestHasMore = false;
          }
          _newestProducts.addAll(newProducts);
          _newestPage = page;
          _isLoadingMoreNewest = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingMoreNewest = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMoreNewest = false;
        });
      }
    }
  }

  int _selectedIndex = 0;
  int _selectedCategoryIndex = 0;
  String? _selectedSubCategoryId;
  List<Product> _products = [];
  bool _isLoading = true;
  Set<String> _savedProductIds = {};
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': Icons.grid_view_rounded, 'subcategories': []},
    {'label': 'Books & Study Materials', 'icon': Icons.menu_book_rounded, 'subcategories': []},
    {'label': 'Electronics & Gadgets', 'icon': Icons.devices_other_rounded, 'subcategories': []},
    {'label': 'Fashion & Accessories', 'icon': Icons.checkroom_rounded, 'subcategories': []},
    {'label': 'Furniture & Appliances', 'icon': Icons.chair_rounded, 'subcategories': []},
    {'label': 'Sports', 'icon': Icons.sports_basketball_rounded, 'subcategories': []},
    {'label': 'Stationery', 'icon': Icons.edit_rounded, 'subcategories': []},
  ];

  String _sortBy = 'newest'; // newest, price_asc, price_desc
  double? _minPrice;
  double? _maxPrice;
  String? _selectedCondition;
  String _selectedListingType = 'All'; // 'All', 'Sale', 'Rent'

  List<Product> _recommendedProducts = [];
  List<Product> _trendingProducts = [];

  final List<String> _tabs = ['For You', 'All Listings', 'Popular', 'Newest'];
  String _selectedTab = 'For You';

  List<Product> get _gridProducts {
      if (_selectedTab == 'For You') {
          return _recommendedProducts.isNotEmpty ? _recommendedProducts : _products;
      }
      if (_selectedTab == 'Popular') {
          return _trendingProducts.isNotEmpty ? _trendingProducts : _products;
      }
      return _products;
  }

  Future<void> _fetchTrending() async {
    if (!UserSession().isLoggedIn) return;
    try {
       final apiClient = ApiClient();
       final response = await apiClient.get('/recommendations/trending');
       if (response is List && mounted) {
          setState(() {
             _trendingProducts = response.map((e) => Product.fromJson(e)).toList();
          });
       }
    } catch(e) {
       // Ignore
    }
  }

  Future<void> _fetchRecommendations() async {
    // Only fetch for logged-in users? Or generic
    if (!UserSession().isLoggedIn) return;

    try {
       final apiClient = ApiClient();
       final response = await apiClient.get('/recommendations');
       if (response is List && mounted) {
          setState(() {
             _recommendedProducts = response.map((e) => Product.fromJson(e)).toList();
          });
       }
    } catch(e) {
       // print("Rec Error: $e");
    }
  }

  Future<void> _fetchSavedItems() async {
      if (!UserSession().isLoggedIn) return;
      try {
          final apiClient = ApiClient();
          final response = await apiClient.get('/saved');
          if (response is List && mounted) {
              setState(() {
                  _savedProductIds = response.map((item) => item['id'].toString()).toSet();
              });
          }
      } catch(e) {
          // Ignore fetch error silently
      }
  }

  Future<void> _toggleFavorite(String productId) async {
      if (!UserSession().isLoggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to save items.')));
          return;
      }
      
      // Optimistic update
      setState(() {
          if (_savedProductIds.contains(productId)) {
              _savedProductIds.remove(productId);
          } else {
              _savedProductIds.add(productId);
          }
      });

      try {
          final apiClient = ApiClient();
          await apiClient.post('/saved/toggle', {'product_id': productId});
      } catch (e) {
          // Revert on failure
          setState(() {
              if (_savedProductIds.contains(productId)) {
                  _savedProductIds.remove(productId);
              } else {
                  _savedProductIds.add(productId);
              }
          });
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update wishlist.')));
          }
      }
  }

  IconData _getCategoryIcon(String name) {
    switch (name) {
      case 'Books & Study Materials':
        return Icons.menu_book_rounded;
      case 'Electronics & Gadgets':
        return Icons.devices_other_rounded;
      case 'Fashion & Accessories':
        return Icons.checkroom_rounded;
      case 'Furniture & Appliances':
        return Icons.chair_rounded;
      case 'Sports':
        return Icons.sports_basketball_rounded;
      case 'Stationery':
        return Icons.edit_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('/categories');
      if (response is List && mounted) {
        final List<Map<String, dynamic>> loadedCategories = [
          {'label': 'All', 'icon': Icons.grid_view_rounded, 'subcategories': []}
        ];
        for (var cat in response) {
          loadedCategories.add({
            'label': cat['name'] as String,
            'icon': _getCategoryIcon(cat['name'] as String),
            'id': cat['id'] as String,
            'subcategories': cat['subcategories'] as List<dynamic>
          });
        }
        setState(() {
          _categories = loadedCategories;
        });
      }
    } catch (e) {
      // Keep using default initial categories
    }
  }

  List<dynamic> get _currentSubcategories {
    if (_selectedCategoryIndex < 0 || _selectedCategoryIndex >= _categories.length) {
      return [];
    }
    return _categories[_selectedCategoryIndex]['subcategories'] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchCategories();
    _fetchProducts();
    _fetchRecommendations();
    _fetchTrending();
    _fetchSavedItems();
    if (UserSession().isLoggedIn) {
      NotificationService().startPolling();
    }
  }

  @override
  void didChangeDependencies() {
     super.didChangeDependencies();
     if (UserSession().isLoggedIn) {
        _fetchSavedItems(); // Reload saved items just in case it was toggled on another tab
        _fetchTrending();
     }
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      String endpoint = '/products';
      
      // Build Params
      List<String> params = [];
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        params.add('search=${Uri.encodeComponent(query)}');
      }
      if (_selectedCategoryIndex != 0) {
        String cat = _categories[_selectedCategoryIndex]['label'];
        params.add('category=${Uri.encodeComponent(cat)}');
      }
      if (_selectedSubCategoryId != null) {
        params.add('sub_category_id=$_selectedSubCategoryId');
      }
      
      // Sorting
      params.add('sort=$_sortBy');

      // Price Filter
      if (_minPrice != null) {
        params.add('min_price=$_minPrice');
      }
      if (_maxPrice != null) {
        params.add('max_price=$_maxPrice');
      }

      if (_selectedCondition != null) {
          params.add('condition=$_selectedCondition');
      }

      if (_selectedListingType != 'All') {
          params.add('type=$_selectedListingType');
      }

      if (UserSession().isLoggedIn) {
          params.add('exclude_reported_by=${UserSession().userId}');
      }

      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }

      final response = await apiClient.get(endpoint);
      if (response is List) {
        setState(() {
          _products = response.map((data) => Product.fromJson(data)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define the pages for the bottom navigation
    final List<Widget> pages = [
      _buildHomeView(),
      const ChatPage(),
      const SellPage(),
      const MyTransactionsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _selectedIndex = idx;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded, size: 32),
            selectedIcon: Icon(Icons.add_circle_rounded, size: 32),
            label: 'Sell',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeView() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          if (_selectedTab == 'Newest') {
            await _fetchFirstPageNewest();
          } else if (_selectedTab == 'For You') {
            await _fetchRecommendations();
          } else if (_selectedTab == 'Popular') {
            await _fetchTrending();
          } else {
            await _fetchProducts();
          }
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Custom Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back,',
                          style: GoogleFonts.outfit(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                        ),
                        Text(
                          'Find Your Needs',
                          style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),
                    ValueListenableBuilder<int>(
                      valueListenable: NotificationService().unreadCountNotifier,
                      builder: (context, count, child) {
                        return GestureDetector(
                          onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
                              NotificationService().checkForNotifications();
                            },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                child: Icon(Icons.notifications_none_rounded, color: Theme.of(context).colorScheme.primary),
                              ),
                              if (count > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      count > 9 ? '9+' : count.toString(),
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).scale(),
                  ],
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search books, electronics...',
                      hintStyle: GoogleFonts.outfit(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white.withValues(alpha: 0.38) 
                            : Colors.grey[400],
                      ),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.sort_rounded),
                            onPressed: _showSortDialog,
                          ),
                          IconButton(
                            icon: const Icon(Icons.filter_list_rounded),
                            onPressed: _showFilterDialog,
                          ),
                        ],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF1E1E1E) 
                          : Colors.white, 
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    style: GoogleFonts.outfit(),
                    onSubmitted: (value) {
                      if (_selectedTab == 'For You') {
                        setState(() => _selectedTab = 'All Listings');
                      }
                      _fetchProducts();
                    },
                    textInputAction: TextInputAction.search,
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.2),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Categories
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    return CategoryChip(
                      label: _categories[index]['label'],
                      icon: _categories[index]['icon'],
                      isSelected: _selectedCategoryIndex == index,
                      onTap: () {
                        setState(() {
                          _selectedCategoryIndex = index;
                          _selectedSubCategoryId = null; // Reset subcategory when category changes
                          if (_selectedTab == 'For You') {
                            _selectedTab = 'All Listings';
                          }
                        });
                        _fetchProducts(); // Refresh with new category
                      },
                    ).animate().fadeIn(duration: 400.ms, delay: (100 * index).ms).slideX();
                  },
                ),
              ),
            ),

            // Subcategories Row
            if (_selectedCategoryIndex != 0 && _currentSubcategories.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 38,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _currentSubcategories.length + 1, // +1 for "All" option
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = _selectedSubCategoryId == null;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSubCategoryId = null;
                            });
                            _fetchProducts();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) 
                                  : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[50]),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary 
                                    : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.grey[200]!),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'All',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: isSelected 
                                      ? Theme.of(context).colorScheme.primary 
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      
                      final subcat = _currentSubcategories[index - 1];
                      final subcatId = subcat['id'] as String;
                      final subcatName = subcat['name'] as String;
                      final productCount = subcat['product_count'] ?? 0;
                      final isSelected = _selectedSubCategoryId == subcatId;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSubCategoryId = isSelected ? null : subcatId;
                          });
                          _fetchProducts();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) 
                                : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[50]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary 
                                  : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.grey[200]!),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Row(
                              children: [
                                Text(
                                  subcatName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: isSelected 
                                        ? Theme.of(context).colorScheme.primary 
                                        : Theme.of(context).colorScheme.onSurface,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '($productCount)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: isSelected 
                                        ? Theme.of(context).colorScheme.primary 
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Display Tabs
            SliverToBoxAdapter(
              child: SizedBox(
                height: 38,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _tabs.length,
                  itemBuilder: (context, index) {
                    final tab = _tabs[index];
                    final isSelected = _selectedTab == tab;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedTab = tab);
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                        if (tab == 'Newest') {
                            _fetchFirstPageNewest();
                        } else if (tab == 'All Listings') {
                            _sortBy = 'newest'; 
                            _fetchProducts(); 
                        } else if (tab == 'Popular') {
                            _fetchProducts();
                        } else if (tab == 'For You') {
                            _fetchRecommendations(); // Refresh recommendation
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary 
                              : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            tab,
                            style: GoogleFonts.outfit(
                              color: isSelected 
                                  ? Colors.white.withValues(alpha: 0.87) 
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: (50*index).ms);
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // "For You" notice banner
            if (_selectedTab == 'For You')
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.amber.withValues(alpha: 0.08) 
                          : Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.amber.shade700.withValues(alpha: 0.5) 
                            : Colors.amber.shade300, 
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded, 
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.amber.shade200 
                              : Colors.amber.shade700, 
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'For You shows personalised picks — search, sort & filter apply to All Listings tab.',
                            style: GoogleFonts.outfit(
                              fontSize: 12, 
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.amber.shade200 
                                  : Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_selectedTab == 'For You') const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Product Grid / List
            if (_selectedTab == 'Newest') ...[
              if (_isLoadingNewest)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_newestProducts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white.withValues(alpha: 0.38) 
                                : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No items found',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to list an item for sale or rent!',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _newestListItems[index];
                        if (item is String) {
                          return _buildTimelineDivider(item);
                        } else if (item is Product) {
                          final product = item;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                            child: ProductListRow(
                              product: product,
                              isFavorite: _savedProductIds.contains(product.id),
                              onFavoriteToggle: () => _toggleFavorite(product.id),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => ProductDetailsPage(
                                    product: product,
                                    initialIsSaved: _savedProductIds.contains(product.id),
                                  )
                                )).then((result) {
                                  _fetchSavedItems();
                                  _fetchTrending();
                                  if (result == 'reported') {
                                    _fetchFirstPageNewest();
                                  }
                                });
                              },
                            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
                          );
                        } else if (item is _LoadingMoreMarker) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      childCount: _newestListItems.length,
                    ),
                  ),
                ),
            ] else ...[
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_gridProducts.isEmpty) ...[
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            (_searchController.text.isNotEmpty ||
                                    _selectedCategoryIndex != 0 ||
                                    _selectedSubCategoryId != null ||
                                    _minPrice != null ||
                                    _maxPrice != null ||
                                    _selectedCondition != null ||
                                    _selectedListingType != 'All')
                                ? 'No items match your criteria'
                                : 'No items found',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (_searchController.text.isNotEmpty ||
                                    _selectedCategoryIndex != 0 ||
                                    _selectedSubCategoryId != null ||
                                    _minPrice != null ||
                                    _maxPrice != null ||
                                    _selectedCondition != null ||
                                    _selectedListingType != 'All')
                                ? 'Try adjusting your search query, price range, or category filter.'
                                : 'Be the first to list an item for sale or rent!',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_searchController.text.isNotEmpty ||
                              _selectedCategoryIndex != 0 ||
                              _selectedSubCategoryId != null ||
                              _minPrice != null ||
                              _maxPrice != null ||
                              _selectedCondition != null ||
                              _selectedListingType != 'All') ...[
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _selectedCategoryIndex = 0;
                                  _selectedSubCategoryId = null;
                                  _minPrice = null;
                                  _maxPrice = null;
                                  _selectedCondition = null;
                                  _selectedListingType = 'All';
                                });
                                _fetchProducts();
                              },
                              icon: const Icon(Icons.clear_all_rounded, color: Colors.white),
                              label: Text(
                                'Clear Filters',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              ]
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.70, // Slightly taller for better cards
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = _gridProducts[index];
                        return ProductCard(
                          product: product,
                          isFavorite: _savedProductIds.contains(product.id),
                          onFavoriteToggle: () => _toggleFavorite(product.id),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ProductDetailsPage(
                                product: product,
                                initialIsSaved: _savedProductIds.contains(product.id),
                              )
                            )).then((result) {
                              _fetchSavedItems();
                              _fetchTrending();
                              if (result == 'reported') {
                                _fetchProducts();
                                _fetchRecommendations();
                              }
                            });
                          },
                        ).animate().fadeIn(duration: 500.ms, delay: (50 * index).ms).scale(begin: const Offset(0.9, 0.9));
                      },
                      childCount: _gridProducts.length,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineDivider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 32.0, right: 16.0),
              height: 1,
              color: Colors.grey[300],
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 16.0, right: 32.0),
              height: 1,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
      showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (context) {
              return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text("Sort By", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _buildSortOption('Newest Listed', 'newest'),
                          _buildSortOption('Price: Low to High', 'price_asc'),
                          _buildSortOption('Price: High to Low', 'price_desc'),
                      ],
                  ),
              );
          }
      );
  }

  Widget _buildSortOption(String label, String value) {
      final isSelected = _sortBy == value;
      return ListTile(
          title: Text(label, style: GoogleFonts.outfit(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
          onTap: () {
              Navigator.pop(context);
              setState(() => _sortBy = value);
              _fetchProducts();
          },
      );
  }

  void _showFilterDialog() {
      final minPriceController = TextEditingController(text: _minPrice != null ? _minPrice!.toStringAsFixed(0) : '');
      final maxPriceController = TextEditingController(text: _maxPrice != null ? _maxPrice!.toStringAsFixed(0) : '');
      
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (context) {
              return StatefulBuilder(
                  builder: (context, setModalState) {
                      return Padding(
                          padding: EdgeInsets.only(
                              top: 24.0,
                              left: 24.0,
                              right: 24.0,
                              bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
                          ),
                          child: SingleChildScrollView(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                          Text("Filter Items", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                                          TextButton(
                                              onPressed: () {
                                                  setModalState(() {
                                                      _selectedListingType = 'All';
                                                      _selectedCondition = null;
                                                      minPriceController.clear();
                                                      maxPriceController.clear();
                                                  });
                                              },
                                              child: Text("Reset", style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text("Listing Type", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  SegmentedButton<String>(
                                      segments: const [
                                          ButtonSegment(value: 'All', label: Text('All')),
                                          ButtonSegment(value: 'Sale', label: Text('Buy')),
                                          ButtonSegment(value: 'Rent', label: Text('Rent')),
                                      ],
                                      selected: {_selectedListingType},
                                      onSelectionChanged: (val) {
                                          setModalState(() => _selectedListingType = val.first);
                                      },
                                  ),
                                  const SizedBox(height: 24),
                                  Text("Price Range (RM)", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  Row(
                                      children: [
                                          Expanded(
                                              child: TextFormField(
                                                  controller: minPriceController,
                                                  keyboardType: TextInputType.number,
                                                  decoration: InputDecoration(
                                                      labelText: 'Min Price',
                                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                                      prefixText: 'RM ',
                                                  ),
                                              ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                              child: TextFormField(
                                                  controller: maxPriceController,
                                                  keyboardType: TextInputType.number,
                                                  decoration: InputDecoration(
                                                      labelText: 'Max Price',
                                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                                      prefixText: 'RM ',
                                                  ),
                                              ),
                                          ),
                                      ],
                                  ),
                                  const SizedBox(height: 24),
                                  Text("Item Condition", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  Wrap(
                                      spacing: 8.0,
                                      children: ['Any', 'New', 'Like New', 'Good', 'Fair', 'Poor'].map((condition) {
                                          final isSelected = _selectedCondition == condition || (condition == 'Any' && _selectedCondition == null);
                                          return ChoiceChip(
                                              label: Text(condition),
                                              selected: isSelected,
                                              onSelected: (bool selected) {
                                                  setModalState(() {
                                                       _selectedCondition = (condition == 'Any' || !selected) ? null : condition;
                                                  });
                                              },
                                              selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                              labelStyle: GoogleFonts.outfit(
                                                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black
                                              ),
                                              checkmarkColor: Theme.of(context).colorScheme.primary,
                                          );
                                      }).toList(),
                                  ),
                                  const SizedBox(height: 32),
                                  SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                          onPressed: () {
                                              Navigator.pop(context);
                                              setState(() {
                                                  _minPrice = double.tryParse(minPriceController.text);
                                                  _maxPrice = double.tryParse(maxPriceController.text);
                                              }); 
                                              _fetchProducts(); // Apply filter with new condition
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context).colorScheme.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 16)
                                          ),
                                          child: Text("Apply Filters", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                      ),
                                  )
                              ],
                          ),
                          ),
                      );
                  }
              );
          }
      );
  }
}

class _LoadingMoreMarker {
  const _LoadingMoreMarker();
}
