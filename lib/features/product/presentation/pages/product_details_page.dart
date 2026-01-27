import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/chat/presentation/pages/chat_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:campus_swap/features/profile/presentation/pages/public_profile_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  bool _isSaved = false;
  bool _isBuying = false;
  List<Product> _sellerProducts = [];
  // bool _isLoadingSellerItems = true;

  @override
  void initState() {
    super.initState();
    _trackView();
    _fetchSellerProducts();
  }

  Future<void> _fetchSellerProducts() async {
      try {
          final apiClient = ApiClient();
          final response = await apiClient.get('/products?seller_id=${widget.product.sellerId}');
          if (response is List) {
              if (mounted) {
                  setState(() {
                      // Filter out current product
                      _sellerProducts = response
                          .map((data) => Product.fromJson(data))
                          .where((p) => p.id != widget.product.id)
                          .toList();
                      // _isLoadingSellerItems = false;
                  });
              }
          }
      } catch (e) {
          // print("Error fetching seller items: $e");
          // if (mounted) setState(() => _isLoadingSellerItems = false);
      }
  }

  void _trackView() {
    if (UserSession().isLoggedIn) {
       ApiClient().post('/recommendations/track', {
         'product_id': widget.product.id,
         'type': 'view'
       }).catchError((e) {
          // print("Track Error: $e");
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            stretch: true,
            backgroundColor: theme.colorScheme.surface,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                child: BackButton(color: theme.colorScheme.onSurface),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.8),
                  child: IconButton(
                    icon: Icon(Icons.share, color: theme.colorScheme.onSurface),
                    onPressed: () async {
                        // ignore: deprecated_member_use
                        await Share.share('Check out ${widget.product.title} for RM ${widget.product.price} on Campus Swap!');
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.8),
                  child: IconButton(
                    icon: Icon(
                      _isSaved ? Icons.favorite : Icons.favorite_border,
                      color: _isSaved ? Colors.red : theme.colorScheme.onSurface,
                    ),
                    onPressed: _toggleSave,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
                title: Text(widget.product.title, style: TextStyle(color: Colors.transparent)),
                background: _buildImageGallery(widget.product),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.product.type == 'Rent' ? Colors.blue.withValues(alpha: 0.1) : theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.product.type == 'Rent' ? 'RENTAL' : widget.product.category.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: widget.product.type == 'Rent' ? Colors.blue : theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                           Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                           const SizedBox(width: 4),
                           Text(
                             _timeAgo(widget.product.postedAt),
                             style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12),
                           )
                        ],
                      )
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                  const SizedBox(height: 16),
                  Text(
                    widget.product.title,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                  const SizedBox(height: 12),
                  Row(
                     children: [
                       Flexible(
                         child: FittedBox(
                           fit: BoxFit.scaleDown,
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             crossAxisAlignment: CrossAxisAlignment.baseline,
                             textBaseline: TextBaseline.alphabetic,
                             children: [
                               Text(
                                 'RM',
                                 style: GoogleFonts.outfit(
                                   fontSize: 16,
                                   fontWeight: FontWeight.bold,
                                   color: theme.colorScheme.primary,
                                 ),
                               ),
                               const SizedBox(width: 4),
                               Text(
                                 widget.product.type == 'Rent' ? widget.product.rentalPricePerDay.toStringAsFixed(2) : widget.product.price.toStringAsFixed(2),
                                 style: GoogleFonts.outfit(
                                   fontSize: 32,
                                   fontWeight: FontWeight.w900,
                                   color: theme.colorScheme.primary,
                                 ),
                               ),
                               if (widget.product.type == 'Rent') 
                                 Padding(
                                   padding: const EdgeInsets.only(left: 4.0),
                                   child: Text('/ day', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16)),
                                 ),
                             ],
                           ),
                         ),
                       ),
                       const Spacer(),
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.product.condition,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                     ],
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                  const SizedBox(height: 32),
                  
                  // Seller Section
                  GestureDetector(
                    onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfilePage(
                            userId: widget.product.sellerId,
                            userName: widget.product.sellerName
                        )));
                    },
                    child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                          child: Text(
                            widget.product.sellerName[0].toUpperCase(),
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                          )
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Seller",
                                  style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12)
                              ),
                              Text(
                                widget.product.sellerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.grey)
                      ],
                    ),
                  ),
                  ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.1),

                  const SizedBox(height: 32),
                  // Seller Portfolio
                  if (_sellerProducts.isNotEmpty) ...[
                      Text("More from ${widget.product.sellerName}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _sellerProducts.length,
                            itemBuilder: (context, index) {
                                final item = _sellerProducts[index];
                                return GestureDetector(
                                    onTap: () {
                                        // Navigate to that product
                                         Navigator.push(context, MaterialPageRoute(
                                            builder: (_) => ProductDetailsPage(product: item)
                                          ));
                                    },
                                    child: Container(
                                        width: 110,
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey.shade200)
                                        ),
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Expanded(
                                                    child: ClipRRect(
                                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                                        child: item.imageUrl.isNotEmpty
                                                            ? CachedNetworkImage(
                                                                imageUrl: item.imageUrl,
                                                                fit: BoxFit.cover,
                                                                width: double.infinity,
                                                              )
                                                            : Container(color: Colors.grey[100]),
                                                    ),
                                                ),
                                                Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                            Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                                                            Text('RM ${item.price.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                                                        ],
                                                    ),
                                                )
                                            ],
                                        ),
                                    ),
                                );
                            },
                        ),
                      ),
                      const SizedBox(height: 32),
                  ],
                  Text('Description', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: GoogleFonts.outfit(color: Colors.grey[700], height: 1.6, fontSize: 15),
                  ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          child: _buildBottomBar(context, theme),
        ),
      ).animate().slideY(begin: 1.0, end: 0, duration: 400.ms, curve: Curves.easeOutQuint),
    );
  }

  Widget _buildBottomBar(BuildContext context, ThemeData theme) {
      final session = UserSession();
      final isSeller = session.userId == widget.product.sellerId;

      if (isSeller) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: Row(
              children: [
                   Expanded(
                     child: OutlinedButton.icon(
                        onPressed: _markAsSold, 
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text('Mark Sold', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: ElevatedButton.icon(
                        onPressed: _deleteProduct, 
                        icon: const Icon(Icons.delete_outline),
                        label: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                     ),
                   ),
              ],
            ),
          );
      }

      return Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailPage(
                         sellerName: widget.product.sellerName,
                         otherUserId: widget.product.sellerId,
                     )));
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: theme.colorScheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Chat', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showBuyConfirmation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(widget.product.type == 'Rent' ? 'Rent Now' : 'Buy Now', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
  }

  void _markAsSold() async {
      final confirm = await showDialog(
          context: context, 
          builder: (context) => AlertDialog(
              title: Text("Mark as Sold?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: Text("This will mark the item as sold and hide it from future searches.", style: GoogleFonts.outfit()),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Confirm", style: TextStyle(color: Colors.green))),
              ],
          )
      );

      if (confirm == true) {
          try {
              final apiClient = ApiClient();
              await apiClient.patch('/products/${widget.product.id}', {'status': 'Sold'});
              if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item marked as Sold!")));
                  Navigator.pop(context); // Go back
              }
          } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
          }
      }
  }

  void _deleteProduct() async {
      final confirm = await showDialog(
          context: context, 
          builder: (context) => AlertDialog(
              title: Text("Delete Listing?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: Text("Are you sure you want to remove this item? This cannot be undone.", style: GoogleFonts.outfit()),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
              ],
          )
      );

      if (confirm == true) {
          try {
              final apiClient = ApiClient();
              await apiClient.delete('/products/${widget.product.id}');
              if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Listing Deleted")));
                  Navigator.pop(context); // Go back
              }
          } catch (e) {
              if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete: $e")));
          }
      }
  }

  String _timeAgo(DateTime date) {
    // Simple helper for now, usually use timeago package
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  void _toggleSave() async {
      final session = UserSession();
      if (!session.isLoggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Login to save items', style: GoogleFonts.outfit()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
          return;
      }

      setState(() {
         _isSaved = !_isSaved; 
      });

      try {
         final apiClient = ApiClient();
         await apiClient.post('/saved/toggle', {
           'product_id': widget.product.id
         });
         
         if (_isSaved) {
             apiClient.post('/recommendations/track', {
                'product_id': widget.product.id,
                'type': 'save'
             });
         }

      } catch (e) {
         setState(() => _isSaved = !_isSaved);
      }
  }

  String _selectedLocation = 'Library';
  final List<String> _campusLocations = ['Library', 'Student Center', 'Cafeteria A', 'Main Hall', 'Sports Complex', 'Hostel Block B'];

  void _showBuyConfirmation(BuildContext context) {
    if (!UserSession().isLoggedIn) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login first')));
       return;
    }

    final isRent = widget.product.type == 'Rent';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full height for keyboard
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
                left: 24, 
                right: 24, 
                top: 24, 
                bottom: MediaQuery.of(context).viewInsets.bottom + 24 // Keyboard padding
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isRent ? 'Confirm Rental' : 'Confirm Purchase', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // Location Selector (FYP Map Requirement)
                Text("Select Meetup Location", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12)
                    ),
                    child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                            value: _selectedLocation,
                            isExpanded: true,
                            items: _campusLocations.map((loc) => DropdownMenuItem(
                                value: loc,
                                child: Row(
                                    children: [
                                        const Icon(Icons.location_on, color: Colors.blue, size: 18),
                                        const SizedBox(width: 8),
                                        Text(loc, style: GoogleFonts.outfit()),
                                    ],
                                )
                            )).toList(),
                            onChanged: (val) {
                                if (val != null) setModalState(() => _selectedLocation = val);
                            }
                        ),
                    ),
                ),
                
                 const SizedBox(height: 24),
                
                Text(isRent ? 'You are about to send a rental request based on this item:' : 'Product Summary:', style: GoogleFonts.outfit(color: Colors.grey[600])),
                 const SizedBox(height: 8),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: widget.product.imageUrl.isNotEmpty 
                        ? CachedNetworkImage(imageUrl: widget.product.imageUrl, width: 60, height: 60, fit: BoxFit.cover)
                        : Container(width: 60, height: 60, color: Colors.grey[200]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.product.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(
                              isRent ? 'RM ${widget.product.rentalPricePerDay.toStringAsFixed(2)} / day' : 'RM ${widget.product.price.toStringAsFixed(2)}', 
                              style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                 const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isBuying ? null : () {
                      // Navigator.pop(context); // Don't pop here, let _buyNow handle it or keep it open?
                      // The original logic popped it immediately which is weird if it fails.
                      // Let's keep modal open until success?
                      // Actually, usually we pop confirmation then show loading overlay, or keep confirmation open with loading.
                      // For simplicity, let's keep it open and show loading inside button.
                      _buyNow(context); 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isBuying
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : Text('Confirm & Schedule', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        }
      )
    );
  }

  void _buyNow(BuildContext context) async {
      setState(() => _isBuying = true);
      try {
        final apiClient = ApiClient();
        await apiClient.post('/transactions', {
            'buyer_id': UserSession().userId, 
            'seller_id': widget.product.sellerId, 
            'product_id': widget.product.id,
            'amount': widget.product.price,
            'meetup_location': _selectedLocation // Use selected location
        });
        
        if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.product.type == 'Rent' ? 'Rental Request Sent!' : 'Purchase Request Sent!', style: GoogleFonts.outfit()),
                backgroundColor: Colors.green,
              )
            );
            Navigator.pop(context); // Close details page on success? Or just stay. Usually stay is fine or go to chat.
        }
      } catch (e) {
          if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
          }
      } finally {
          if (mounted) setState(() => _isBuying = false);
      }
  }

  int _currentImageIndex = 0;

  Widget _buildImageGallery(Product product) {
    // Priority: imageUrls > imageUrl
    List<String> images = product.imageUrls.isNotEmpty 
        ? product.imageUrls 
        : (product.imageUrl.isNotEmpty ? [product.imageUrl] : []);
    
    if (images.isEmpty) {
        return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
        );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          onPageChanged: (index) {
             if (mounted) setState(() => _currentImageIndex = index);
          },
          itemCount: images.length,
          itemBuilder: (context, index) {
            return Hero(
                tag: 'product_image_${product.id}_$index', // Unique tag per image? careful with Hero
                // Simple tag for first image usually works best for transition
                child: CachedNetworkImage(
                    imageUrl: images[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
            );
          },
        ),
        if (images.length > 1) 
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: images.asMap().entries.map((entry) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black)
                        .withValues(alpha: _currentImageIndex == entry.key ? 0.9 : 0.4),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
