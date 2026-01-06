import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';
import 'package:campus_swap/features/product/presentation/pages/product_details_page.dart';
import 'package:campus_swap/features/home/presentation/widgets/product_card.dart';
import 'package:campus_swap/features/home/presentation/widgets/category_chip.dart';
import 'package:campus_swap/features/chat/presentation/pages/chat_page.dart';
import 'package:campus_swap/features/product/presentation/pages/sell_page.dart';
import 'package:campus_swap/features/saved/presentation/pages/saved_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/profile_page.dart';
import 'package:campus_swap/features/notification/presentation/pages/notifications_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _selectedCategoryIndex = 0;
  List<Product> _products = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': Icons.grid_view_rounded},
    {'label': 'Books', 'icon': Icons.menu_book_rounded},
    {'label': 'Electronics', 'icon': Icons.devices_other_rounded},
    {'label': 'Fashion', 'icon': Icons.checkroom_rounded},
    {'label': 'Furniture', 'icon': Icons.chair_rounded},
    {'label': 'Sports', 'icon': Icons.sports_basketball_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts([String? query]) async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      String endpoint = '/products';
      
      // Build Params
      List<String> params = [];
      if (query != null && query.isNotEmpty) {
        params.add('search=$query');
      }
      if (_selectedCategoryIndex != 0) {
        String cat = _categories[_selectedCategoryIndex]['label'];
        params.add('category=$cat');
      }

      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }

      // Append filter
      endpoint += endpoint.contains('?') ? '&' : '?';
      endpoint += 'min_price=${_priceRange.start}&max_price=${_priceRange.end}';

      final response = await apiClient.get(endpoint);
      if (response is List) {
        setState(() {
          _products = response.map((data) => Product.fromJson(data)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching products: $e');
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
      const SavedPage(),
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
            icon: Icon(Icons.favorite_outline_rounded),
             selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Saved',
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
      child: Column(
        children: [
          // Custom Header
          Padding(
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
                GestureDetector(
                  onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
                  },
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(Icons.notifications_none_rounded, color: Theme.of(context).colorScheme.primary),
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms).scale(),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search books, electronics...',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.filter_list_rounded),
                    onPressed: _showFilterDialog,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white, 
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                style: GoogleFonts.outfit(),
                onSubmitted: (value) => _fetchProducts(value),
                textInputAction: TextInputAction.search,
              ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.2),

          const SizedBox(height: 24),

          // Categories
          SizedBox(
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
                    });
                    _fetchProducts(); // Refresh with new category
                  },
                ).animate().fadeIn(duration: 400.ms, delay: (100 * index).ms).slideX();
              },
            ),
          ),

          const SizedBox(height: 16),

          // Product Grid
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty 
                  ? Center(child: Text('No items found. Be the first to sell!', style: GoogleFonts.outfit()))
                  : RefreshIndicator(
                      onRefresh: _fetchProducts,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.70, // Slightly taller for better cards
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          return ProductCard(
                            product: _products[index],
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ProductDetailsPage(product: _products[index])
                              ));
                            },
                          ).animate().fadeIn(duration: 500.ms, delay: (50 * index).ms).scale(begin: const Offset(0.9, 0.9));
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  RangeValues _priceRange = const RangeValues(0, 1000);

  void _showFilterDialog() {
      showModalBottomSheet(
          context: context,
          builder: (context) {
              return StatefulBuilder(
                  builder: (context, setModalState) {
                      return Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text("Filter Items", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 24),
                                  Text("Price Range: RM ${_priceRange.start.round()} - RM ${_priceRange.end.round()}", style: GoogleFonts.outfit()),
                                  RangeSlider(
                                      values: _priceRange,
                                      min: 0,
                                      max: 1000,
                                      divisions: 20,
                                      labels: RangeLabels(
                                          _priceRange.start.round().toString(), 
                                          _priceRange.end.round().toString()
                                      ),
                                      onChanged: (values) {
                                          setModalState(() {
                                              _priceRange = values;
                                          });
                                      },
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                          onPressed: () {
                                              Navigator.pop(context);
                                              _fetchProducts(); // Apply filter
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
                      );
                  }
              );
          }
      );
  }
}
