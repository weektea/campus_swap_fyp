import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';
import 'package:campus_swap/features/home/presentation/widgets/product_card.dart';
import 'package:campus_swap/features/product/presentation/pages/product_details_page.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyListings();
  }

  Future<void> _fetchMyListings() async {
    final session = UserSession();
    if (session.userId == null) return;

    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('/products?seller_id=${session.userId}');
      
      if (response is List) {
        setState(() {
          _products = response.map((data) => Product.fromJson(data)).toList();
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
    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _products.isEmpty
            ? const Center(child: Text('You haven\'t listed any items yet.'))
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
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
                      )).then((_) => _fetchMyListings());
                    },
                  );
                },
              ),
    );
  }
}
