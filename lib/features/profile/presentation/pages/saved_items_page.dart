import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';
import 'package:campus_swap/features/home/presentation/widgets/product_card.dart';
import 'package:campus_swap/features/product/presentation/pages/product_details_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/core/widgets/empty_state_widget.dart';

class SavedItemsPage extends StatefulWidget {
  const SavedItemsPage({super.key});

  @override
  State<SavedItemsPage> createState() => _SavedItemsPageState();
}

class _SavedItemsPageState extends State<SavedItemsPage> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSavedItems();
  }

  Future<void> _fetchSavedItems() async {
    final session = UserSession();
    if (session.userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('/saved');
      
      if (response is List && mounted) {
        setState(() {
          _products = response.map((data) => Product.fromJson(data)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite(String productId) async {
    // Optimistic remove
    setState(() {
      _products.removeWhere((p) => p.id == productId);
    });
    try {
      final apiClient = ApiClient();
      await apiClient.post('/saved/toggle', {'product_id': productId});
    } catch (e) {
      // Revert on failure
      _fetchSavedItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Items', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          if (_products.isNotEmpty)
            TextButton(
              onPressed: _fetchSavedItems,
              child: Text('Refresh', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary)),
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : !UserSession().isLoggedIn
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('Login to save items', style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            : _products.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.favorite_border_rounded,
                    title: 'No Saved Items',
                    message: 'Tap the ♡ on any listing to save it here for later.',
                    buttonText: 'Explore Market',
                    onActionPressed: () => Navigator.pop(context),
                  )
                : GridView.builder(
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
                        isFavorite: true, // All items here are already saved
                        onFavoriteToggle: () => _toggleFavorite(product.id),
                        onTap: () {
                           Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ProductDetailsPage(product: product)
                          )).then((_) => _fetchSavedItems());
                        },
                      );
                    },
                  ),
    );
  }
}
