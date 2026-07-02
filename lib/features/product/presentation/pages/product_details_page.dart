import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/chat/presentation/pages/chat_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:campus_swap/features/profile/presentation/pages/public_profile_page.dart';
import 'package:campus_swap/features/product/presentation/pages/edit_listing_page.dart';
import 'package:campus_swap/features/product/presentation/pages/report_listing_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  final bool initialIsSaved;

  const ProductDetailsPage({
    super.key, 
    required this.product,
    this.initialIsSaved = false,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  bool _isSaved = false;
  bool _isBuying = false;
  List<Product> _sellerProducts = [];
  List<Product> _similarProducts = [];
  // bool _isLoadingSellerItems = true;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.initialIsSaved;
    _checkIfSaved();
    _trackView();
    _fetchSellerProducts();
    _fetchSimilarProducts();
    _fetchCampusLocations();
  }

  Future<void> _checkIfSaved() async {
    if (!UserSession().isLoggedIn) return;
    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('/saved');
      if (response is List && mounted) {
        final isSaved = response.any((item) => (item['id'] ?? '').toString() == widget.product.id);
        setState(() {
          _isSaved = isSaved;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _fetchSellerProducts() async {
      try {
          final apiClient = ApiClient();
          String endpoint = '/products?seller_id=${widget.product.sellerId}';
          if (UserSession().isLoggedIn) {
              endpoint += '&exclude_reported_by=${UserSession().userId}';
          }
          final response = await apiClient.get(endpoint);
          if (response is List) {
              if (mounted) {
                  setState(() {
                      // Filter out current product and non-available listings
                      _sellerProducts = response
                          .map((data) => Product.fromJson(data))
                          .where((p) => p.id != widget.product.id && p.status == 'Available')
                          .toList();
                      // _isLoadingSellerItems = false;
                  });
              }
          }
      } catch (e) {
          // Ignore
      }
  }

  double _calculateCosineSimilarity(Product target, Product candidate) {
    // Combine title and description to construct content texts
    final text1 = '${target.title} ${target.description}'.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ');
    final text2 = '${candidate.title} ${candidate.description}'.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ');

    final tokens1 = text1.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final tokens2 = text2.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    if (tokens1.isEmpty || tokens2.isEmpty) return 0.0;

    final allTerms = <String>{...tokens1, ...tokens2};

    final tf1 = <String, double>{};
    final tf2 = <String, double>{};

    for (final t in tokens1) {
      tf1[t] = (tf1[t] ?? 0.0) + 1.0;
    }
    for (final t in tokens2) {
      tf2[t] = (tf2[t] ?? 0.0) + 1.0;
    }

    // Normalize Term Frequency
    tf1.updateAll((key, value) => value / tokens1.length);
    tf2.updateAll((key, value) => value / tokens2.length);

    double dotProduct = 0.0;
    double mag1 = 0.0;
    double mag2 = 0.0;

    for (final term in allTerms) {
      final v1 = tf1[term] ?? 0.0;
      final v2 = tf2[term] ?? 0.0;

      dotProduct += v1 * v2;
      mag1 += v1 * v1;
      mag2 += v2 * v2;
    }

    if (mag1 == 0.0 || mag2 == 0.0) return 0.0;
    return dotProduct / (math.sqrt(mag1) * math.sqrt(mag2));
  }

  Future<void> _fetchSimilarProducts() async {
      try {
          final apiClient = ApiClient();
          String endpoint = '';
          bool usedSubCategory = false;
          if (widget.product.subCategoryId.isNotEmpty) {
              endpoint = '/products?sub_category_id=${widget.product.subCategoryId}';
              usedSubCategory = true;
          } else {
              endpoint = '/products?category=${widget.product.category}';
          }
          if (UserSession().isLoggedIn) {
              endpoint += '&exclude_reported_by=${UserSession().userId}';
          }
          var response = await apiClient.get(endpoint);
          
          List<Product> sortedList = [];
          if (response is List) {
              sortedList = response
                  .map((data) => Product.fromJson(data as Map<String, dynamic>))
                  .where((p) => p.id != widget.product.id && p.status == 'Available' && p.sellerId != UserSession().userId)
                  .toList();
          }

          // Fallback to broad category if subcategory search yields no available candidate items
          if (sortedList.isEmpty && usedSubCategory) {
              String fallbackEndpoint = '/products?category=${widget.product.category}';
              if (UserSession().isLoggedIn) {
                  fallbackEndpoint += '&exclude_reported_by=${UserSession().userId}';
              }
              final fallbackResponse = await apiClient.get(fallbackEndpoint);
              if (fallbackResponse is List) {
                  sortedList = fallbackResponse
                      .map((data) => Product.fromJson(data as Map<String, dynamic>))
                      .where((p) => p.id != widget.product.id && p.status == 'Available' && p.sellerId != UserSession().userId)
                      .toList();
              }
          }

          // Sort candidate products based on cosine similarity to the current product
          sortedList.sort((a, b) {
              final scoreA = _calculateCosineSimilarity(widget.product, a);
              final scoreB = _calculateCosineSimilarity(widget.product, b);
              return scoreB.compareTo(scoreA); // Descending (highest similarity first)
          });

          if (mounted) {
              setState(() {
                  // Take only the top 4 similar items
                  _similarProducts = sortedList.take(4).toList();
              });
          }
      } catch (e) {
          // Ignore
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
                backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
                child: BackButton(color: theme.colorScheme.onSurface),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
                  child: IconButton(
                    icon: Icon(Icons.share, color: theme.colorScheme.onSurface),
                    onPressed: () async {
                        // ignore: deprecated_member_use
                        await Share.share('Check out ${widget.product.title} for RM ${widget.product.price} on Campus Swap!');
                    },
                  ),
                ),
              ),
              if (UserSession().userId != widget.product.sellerId)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
                    child: IconButton(
                      icon: Icon(
                        _isSaved ? Icons.favorite : Icons.favorite_border,
                        color: _isSaved ? Colors.red : theme.colorScheme.onSurface,
                      ),
                      onPressed: _toggleSave,
                    ),
                  ),
                ),
              if (UserSession().userId != widget.product.sellerId)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
                      onSelected: (value) {
                        if (value == 'report') {
                          _reportListing();
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Report Listing', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
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
                      if (widget.product.subCategoryName.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.product.subCategoryName,
                            style: GoogleFonts.outfit(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                           Icon(Icons.schedule, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                           const SizedBox(width: 4),
                           Text(
                             _timeAgo(widget.product.postedAt),
                             style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
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
                                   child: Text('/ day', style: GoogleFonts.outfit(color: theme.colorScheme.onSurfaceVariant, fontSize: 16)),
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
                  
                  if (widget.product.type == 'Rent') ...[
                     const SizedBox(height: 12),
                     Container(
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: Colors.blue.withValues(alpha: 0.05),
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                       ),
                       child: Row(
                         children: [
                           Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                           const SizedBox(width: 8),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text("Rental Details", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.blue[800])),
                                 Text("Deposit required: RM ${widget.product.rentalDeposit.toStringAsFixed(2)}", style: GoogleFonts.outfit(color: Colors.blue[800], fontSize: 13)),
                                 Text("Max Duration: ${widget.product.maxRentalDuration} days", style: GoogleFonts.outfit(color: Colors.blue[800], fontSize: 13)),
                               ]
                             )
                           )
                         ]
                       )
                     ).animate().fadeIn(duration: 500.ms, delay: 250.ms),
                  ],

                  if (widget.product.co2Saved > 0) ...[
                     const SizedBox(height: 12),
                     Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                           color: Colors.green.withValues(alpha: 0.1),
                           borderRadius: BorderRadius.circular(8),
                           border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                               const Icon(Icons.eco, color: Colors.green, size: 18),
                               const SizedBox(width: 8),
                               Text(
                                   "Eco-Impact: Saves ${widget.product.co2Saved} kg CO2e",
                                   style: GoogleFonts.outfit(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 13)
                               )
                           ],
                        ),
                     ).animate().fadeIn(duration: 500.ms, delay: 280.ms),
                  ],
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
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.outlineVariant : Colors.grey.withValues(alpha: 0.1)),
                      boxShadow: Theme.of(context).brightness == Brightness.dark 
                          ? [] 
                          : [
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
                          backgroundImage: widget.product.sellerAvatar.isNotEmpty
                              ? NetworkImage(widget.product.sellerAvatar)
                              : null,
                          child: widget.product.sellerAvatar.isEmpty
                              ? Text(
                                  widget.product.sellerName[0].toUpperCase(),
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Seller",
                                  style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)
                              ),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.product.sellerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                  Text(
                                    '${widget.product.sellerReputation.toStringAsFixed(1)} (${widget.product.sellerTotalReviews})',
                                    style: GoogleFonts.outfit(fontSize: 14, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant)
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
                                          )).then((result) {
                                              if (result == 'reported') {
                                                  _fetchSellerProducts();
                                                  _fetchSimilarProducts();
                                              }
                                          });
                                    },
                                    child: Container(
                                        width: 110,
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.outlineVariant : Colors.grey.shade200)
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
                    style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6, fontSize: 15),
                  ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
                  
                  const SizedBox(height: 32),
                  // Similar Items Section
                  if (_similarProducts.isNotEmpty) ...[
                      Text("Similar Items Recommended", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _similarProducts.length,
                            itemBuilder: (context, index) {
                                final item = _similarProducts[index];
                                return GestureDetector(
                                    onTap: () {
                                         Navigator.push(context, MaterialPageRoute(
                                            builder: (_) => ProductDetailsPage(product: item)
                                          )).then((result) {
                                              if (result == 'reported') {
                                                  _fetchSellerProducts();
                                                  _fetchSimilarProducts();
                                              }
                                          });
                                    },
                                    child: Container(
                                        width: 110,
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.outlineVariant : Colors.grey.shade200)
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
                  ],

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
          color: Theme.of(context).colorScheme.surface,
          boxShadow: Theme.of(context).brightness == Brightness.dark 
              ? [] 
              : [
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
          return Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(
                        builder: (_) => EditListingPage(product: widget.product)
                     ));
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: Text('Edit Listing', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: theme.colorScheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                 child: ElevatedButton.icon(
                    onPressed: _deleteProduct, 
                    icon: const Icon(Icons.delete_outline),
                    label: Text('Remove', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.red.withValues(alpha: 0.2) : Colors.red[50],
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                 ),
              ),
            ],
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
                         otherUserAvatar: widget.product.sellerAvatar,
                         initialMessage: "Hi ${widget.product.sellerName}, I'm interested in your listing: [ ${widget.product.title} ] for RM ${widget.product.price.toStringAsFixed(2)}!",
                         relatedProduct: widget.product,
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
            behavior: SnackBarBehavior.floating,
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
  List<String> _campusLocations = ['Library', 'Student Center', 'Cafeteria A', 'Main Hall', 'Sports Complex', 'Hostel Block B'];
  bool _hasFetchedLocations = false;

  Future<void> _fetchCampusLocations([StateSetter? modalState]) async {
    if (!UserSession().isLoggedIn) return;
    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('/zones');
      debugPrint('Fetched active campus locations response: $response');
      if (response is List && response.isNotEmpty) {
        final List<String> loadedNames = response
            .map<String>((item) {
              final map = item as Map<String, dynamic>;
              return (map['name'] ?? '').toString().trim();
            })
            .where((name) => name.isNotEmpty)
            .toList();
        debugPrint('Parsed active campus locations loaded: $loadedNames');
        if (loadedNames.isNotEmpty && mounted) {
          setState(() {
            _campusLocations = loadedNames;
            _hasFetchedLocations = true;
            if (!_campusLocations.contains(_selectedLocation)) {
              _selectedLocation = _campusLocations.first;
            }
          });
          if (modalState != null) {
            modalState(() {});
          }
        }
      }
    } catch (e, stack) {
      debugPrint('Error fetching active campus locations: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  DateTime? _rentStartDate;
  DateTime? _rentEndDate;

  void _reportListing() {
    if (!UserSession().isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to report')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportListingPage(product: widget.product),
      ),
    ).then((result) {
      if (result == 'reported' && mounted) {
        Navigator.pop(context, 'reported');
      }
    });
  }

  void _showBuyConfirmation(BuildContext context) {
    if (!UserSession().isLoggedIn) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: Text('Please login first', style: GoogleFonts.outfit()),
         behavior: SnackBarBehavior.floating,
       ));
       return;
    }

    final isRent = widget.product.type == 'Rent';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full height for keyboard
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        String? selectedPaymentMethod;
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (widget.product.acceptedPaymentMethods.isNotEmpty) {
                selectedPaymentMethod ??= widget.product.acceptedPaymentMethods.first;
            }
            if (!_hasFetchedLocations) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_hasFetchedLocations) {
                        _fetchCampusLocations(setModalState);
                    }
                });
            }

            int rentDays = 0;
            double totalRentCost = 0.0;
            if (isRent && _rentStartDate != null && _rentEndDate != null) {
              rentDays = _rentEndDate!.difference(_rentStartDate!).inDays + 1; // Inclusive
              totalRentCost = rentDays * widget.product.rentalPricePerDay;
            }

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

                const SizedBox(height: 16),
                Text("Select Payment Method", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12)
                    ),
                    child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                            value: selectedPaymentMethod,
                            isExpanded: true,
                            items: widget.product.acceptedPaymentMethods.map((method) => DropdownMenuItem(
                                value: method,
                                child: Row(
                                    children: [
                                        Icon(
                                            method == 'Cash' 
                                                ? Icons.money_outlined 
                                                : (method == 'TNG' ? Icons.account_balance_wallet_outlined : Icons.account_balance_outlined), 
                                            color: Theme.of(context).colorScheme.primary, 
                                            size: 18
                                        ),
                                        const SizedBox(width: 8),
                                        Text(method, style: GoogleFonts.outfit()),
                                    ],
                                )
                            )).toList(),
                            onChanged: (val) {
                                if (val != null) setModalState(() => selectedPaymentMethod = val);
                            }
                        ),
                    ),
                ),
                
                 const SizedBox(height: 16),

                 if (isRent) ...[
                   Text("Select Rental Period", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   InkWell(
                     onTap: () async {
                       final DateTimeRange? picked = await showDateRangePicker(
                         context: context,
                         firstDate: DateTime.now(),
                         lastDate: DateTime.now().add(const Duration(days: 365)),
                         builder: (context, child) {
                           return Theme(
                             data: Theme.of(context).copyWith(
                               colorScheme: Theme.of(context).colorScheme.copyWith(
                                 primary: Theme.of(context).colorScheme.primary,
                               ),
                             ),
                             child: child!,
                           );
                         },
                       );
                       if (picked != null) {
                         int selectedDays = picked.end.difference(picked.start).inDays + 1;
                         if (selectedDays > widget.product.maxRentalDuration) {
                              if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text('Maximum rental duration is ${widget.product.maxRentalDuration} days!', style: GoogleFonts.outfit()),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                  ));
                              }
                              return;
                         }
                         setModalState(() {
                           _rentStartDate = picked.start;
                           _rentEndDate = picked.end;
                         });
                       }
                     },
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                       decoration: BoxDecoration(
                         border: Border.all(color: Colors.grey.shade300),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text(
                             _rentStartDate != null && _rentEndDate != null
                                 ? '${_rentStartDate!.toString().split(' ')[0]} to ${_rentEndDate!.toString().split(' ')[0]}'
                                 : 'Tap to select dates',
                             style: GoogleFonts.outfit(
                               color: _rentStartDate != null ? Colors.black87 : Colors.grey.shade600,
                             ),
                           ),
                           const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                         ],
                       ),
                     ),
                   ),
                   const SizedBox(height: 16),
                 ],
                
                Text(isRent ? 'Rental Summary:' : 'Product Summary:', style: GoogleFonts.outfit(color: Colors.grey[600])),
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
                          if (isRent) ...[
                            Text(
                              'RM ${widget.product.rentalPricePerDay.toStringAsFixed(2)} / day',
                              style: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 12)
                            ),
                              if (_rentStartDate != null && _rentEndDate != null)
                                Text(
                                  'Total ($rentDays days): RM ${totalRentCost.toStringAsFixed(2)}',
                                  style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)
                                ),
                          ] else ...[
                            Text(
                                'RM ${widget.product.price.toStringAsFixed(2)}', 
                                style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ],
                      ),
                    )
                  ],
                ),
                 const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isBuying || (isRent && (_rentStartDate == null || _rentEndDate == null))) ? null : () {
                      _buyNow(
                        context, 
                        isRent ? totalRentCost : widget.product.price,
                        rentStartDate: _rentStartDate,
                        rentEndDate: _rentEndDate,
                        paymentMethod: selectedPaymentMethod,
                      ); 
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
        },
      );
    },
  );
}

  void _buyNow(BuildContext context, double finalPrice, {DateTime? rentStartDate, DateTime? rentEndDate, String? paymentMethod}) async {
      setState(() => _isBuying = true);
      try {
        final apiClient = ApiClient();
        
        final Map<String, dynamic> payload = {
            'buyer_id': UserSession().userId, 
            'seller_id': widget.product.sellerId, 
            'product_id': widget.product.id,
            'amount': finalPrice, // Use dynamically calculated price
            'meetup_location': _selectedLocation, // Use selected location
            'selected_payment_method': paymentMethod ?? 'Cash'
        };

        if (widget.product.type == 'Rent' && rentStartDate != null && rentEndDate != null) {
            payload['rental_start_date'] = rentStartDate.toIso8601String();
            payload['rental_end_date'] = rentEndDate.toIso8601String();
        }

        await apiClient.post('/transactions', payload);
        
        if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.product.type == 'Rent' ? 'Rental Request Sent!' : 'Purchase Request Sent!', style: GoogleFonts.outfit()),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              )
            );
            Navigator.pop(context); // Close details page on success? Or just stay. Usually stay is fine or go to chat.
        }
      } catch (e) {
          if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
               content: Text('Failed: $e', style: GoogleFonts.outfit()),
               behavior: SnackBarBehavior.floating,
             ));
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
            return CachedNetworkImage(
                    imageUrl: images[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
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
