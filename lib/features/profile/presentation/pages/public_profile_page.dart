import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';
import 'package:campus_swap/features/product/presentation/pages/product_details_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_swap/core/session/user_session.dart';

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
        final userRes = await apiClient.get('/auth/user/${widget.userId}');
        if (userRes != null && userRes['user'] != null) {
            _userProfile = userRes['user'];
        }

        // 2. Fetch User Listings
        String endpoint = '/products?seller_id=${widget.userId}';
        if (UserSession().isLoggedIn) {
            endpoint += '&exclude_reported_by=${UserSession().userId}';
        }
        final productsRes = await apiClient.get(endpoint);
        if (productsRes is List) {
            _listings = productsRes.map((data) => Product.fromJson(data)).toList();
            _listings = _listings.where((p) => p.status == 'Available').toList();
        }

        if (mounted) setState(() => _isLoading = false);
    } catch (e) {
        // print("Error fetching public profile: $e");
        if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? isoString) {
      if (isoString == null) return 'N/A';
      try {
          final dt = DateTime.parse(isoString);
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      } catch (e) {
          return 'N/A';
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
                                        backgroundImage: (_userProfile != null && _userProfile!['profile_image_url'] != null)
                                            ? NetworkImage('${ApiClient.baseUrl.replaceAll('/api', '')}${_userProfile!['profile_image_url']}')
                                            : null,
                                        child: (_userProfile == null || _userProfile!['profile_image_url'] == null) 
                                            ? Text(widget.userName[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold))
                                            : null,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(widget.userName, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                                    if (_userProfile != null && _userProfile!['reputation_score'] != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.star_rounded, size: 20, color: Colors.amber),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${double.parse(_userProfile!['reputation_score'].toString()).toStringAsFixed(1)} (${_userProfile!['total_reviews'] ?? 0})',
                                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text("Member since ${_formatDate(_userProfile?['createdAt'])}", style: GoogleFonts.outfit(color: Colors.grey))
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
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _listings.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                    final product = _listings[index];
                                    return GestureDetector(
                                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product))),
                                        child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: Row(
                                                children: [
                                                    // Image
                                                    ClipRRect(
                                                        borderRadius: BorderRadius.circular(12),
                                                        child: product.imageUrl.isNotEmpty
                                                            ? CachedNetworkImage(imageUrl: product.imageUrl, width: 90, height: 90, fit: BoxFit.cover)
                                                            : Container(width: 90, height: 90, color: Colors.grey[200]),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    // Details
                                                    Expanded(
                                                        child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                                Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                                                                const SizedBox(height: 6),
                                                                Container(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                                                    child: Text(product.type == 'Rent' ? 'RENTAL' : 'SALE', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                                                ),
                                                                const SizedBox(height: 8),
                                                                Text(
                                                                    'RM ${product.type == 'Rent' ? '${product.rentalPricePerDay.toStringAsFixed(2)}/day' : product.price.toStringAsFixed(2)}', 
                                                                    style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)
                                                                ),
                                                            ],
                                                        )
                                                    ),
                                                    const Icon(Icons.chevron_right, color: Colors.grey)
                                                ],
                                            ),
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
