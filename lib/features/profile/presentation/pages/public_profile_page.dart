import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';
import 'package:campus_swap/features/product/presentation/pages/product_details_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PublicProfilePage extends StatefulWidget {
  final String userId;
  final String userName;

  const PublicProfilePage({super.key, required this.userId, required this.userName});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  Map<String, dynamic>? _userProfile;
  List<Product> _listings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final apiClient = ApiClient();
    try {
        // 1. Fetch User Info
        // Assuming we expose a public endpoint or reuse auth/user/:id which should be somewhat public for basic info
        final userRes = await apiClient.get('/auth/user/${widget.userId}');
        _userProfile = userRes;

        // 2. Fetch User Listings
        final productsRes = await apiClient.get('/products?seller_id=${widget.userId}');
        if (productsRes is List) {
            _listings = productsRes.map((data) => Product.fromJson(data)).toList();
        }

        if (mounted) setState(() => _isLoading = false);
    } catch (e) {
        // print("Error fetching public profile: $e");
        if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.userName, style: GoogleFonts.outfit())),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // Header
                        Center(
                            child: Column(
                                children: [
                                    CircleAvatar(
                                        radius: 40,
                                        backgroundImage: (_userProfile != null && _userProfile!['profile_picture'] != null)
                                            ? NetworkImage('${ApiClient.baseUrl.replaceAll('/api', '')}${_userProfile!['profile_picture']}')
                                            : null,
                                        child: (_userProfile == null || _userProfile!['profile_picture'] == null) 
                                            ? Text(widget.userName[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold))
                                            : null,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(widget.userName, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                                    // Reputation / Eco stats could go here
                                    const SizedBox(height: 8),
                                    Text("Member since ${_userProfile != null ? DateTime.parse(_userProfile!['createdAt']).year : 'N/A'}", style: GoogleFonts.outfit(color: Colors.grey))
                                ],
                            ),
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text("Listings", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
                        _listings.isEmpty 
                            ? Center(child: Text("No active listings", style: GoogleFonts.outfit(color: Colors.grey)))
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16
                                ),
                                itemCount: _listings.length,
                                itemBuilder: (context, index) {
                                    final product = _listings[index];
                                    return GestureDetector(
                                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product))),
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Expanded(
                                                    child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(12),
                                                        child: product.imageUrl.isNotEmpty
                                                            ? CachedNetworkImage(imageUrl: product.imageUrl, fit: BoxFit.cover, width: double.infinity)
                                                            : Container(color: Colors.grey[200]),
                                                    ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                                Text('RM ${product.price}', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary)),
                                            ],
                                        ),
                                    );
                                },
                            )
                    ],
                ),
            )
    );
  }
}
