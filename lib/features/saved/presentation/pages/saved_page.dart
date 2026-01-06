import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';
import 'package:campus_swap/features/home/presentation/widgets/product_card.dart';
import 'package:campus_swap/features/product/presentation/pages/product_details_page.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  List<Product> _savedProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSavedProducts();
  }

  Future<void> _fetchSavedProducts() async {
    final session = UserSession();
    if (!session.isLoggedIn) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('/saved/${session.userId}');
      if (response is List) {
        setState(() {
          _savedProducts = response.map((data) => Product.fromJson(data)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Items')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _savedProducts.isEmpty
          ? const Center(child: Text('No saved items yet.'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _savedProducts.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  product: _savedProducts[index],
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ProductDetailsPage(product: _savedProducts[index])
                    )).then((_) => _fetchSavedProducts()); // Refresh on back
                  },
                );
              },
            ),
    );
  }
}
