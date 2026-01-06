import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';
import 'package:campus_swap/features/home/presentation/widgets/product_card.dart';
import 'package:campus_swap/features/product/presentation/pages/product_details_page.dart';
import 'package:google_fonts/google_fonts.dart';

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
    if (session.userId == null) return;

    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('/saved/${session.userId}');
      
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
      appBar: AppBar(title: Text('Saved Items', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _products.isEmpty
            ? Center(child: Text('No saved items yet.', style: GoogleFonts.outfit()))
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
                      )).then((_) => _fetchSavedItems()); // Refresh on back
                    },
                  );
                },
              ),
    );
  }
}
