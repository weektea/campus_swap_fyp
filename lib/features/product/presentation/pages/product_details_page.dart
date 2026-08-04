import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/chat/presentation/pages/chat_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:campus_swap/features/profile/presentation/pages/public_profile_page.dart';
import 'package:campus_swap/features/product/presentation/pages/edit_listing_page.dart';
import 'package:campus_swap/features/product/presentation/pages/report_listing_page.dart';
import 'package:campus_swap/features/product/presentation/pages/full_screen_image_viewer.dart';
import 'package:campus_swap/core/widgets/reputation_badge.dart';

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
  int _favoriteCount = 0;
  List<Product> _sellerProducts = [];
  List<Product> _similarProducts = [];

  @override
  void initState() {
    super.initState();
    _isSaved = widget.initialIsSaved;
    _favoriteCount = widget.product.favoriteCount;
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
    UserSession().addSessionInteraction(widget.product.id);
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
                        color: _isSaved ? theme.colorScheme.error : theme.colorScheme.onSurface,
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
                        PopupMenuItem<String>(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: theme.colorScheme.error, size: 20),
                              const SizedBox(width: 8),
                              Text('Report Listing', style: TextStyle(color: theme.colorScheme.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
                title: Text(widget.product.title, style: const TextStyle(color: Colors.transparent)),
                background: _buildImageGallery(widget.product),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.product.category,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          if (widget.product.subCategoryName.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.product.subCategoryName,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Icon(Icons.schedule, size: 14, color: theme.colorScheme.onSurfaceVariant),
                           const SizedBox(width: 4),
                           Text(
                             _timeAgo(widget.product.postedAt),
                             style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                           )
                        ],
                      )
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                  if (_favoriteCount > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_rounded, size: 14, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            '$_favoriteCount ${_favoriteCount == 1 ? 'user saved' : 'users saved'} this item',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    widget.product.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
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
                                 style: theme.textTheme.titleMedium?.copyWith(
                                   fontWeight: FontWeight.bold,
                                   color: theme.colorScheme.primary,
                                 ),
                               ),
                               const SizedBox(width: 4),
                               Text(
                                 widget.product.type == 'Rent' ? widget.product.rentalPricePerDay.toStringAsFixed(2) : widget.product.price.toStringAsFixed(2),
                                 style: theme.textTheme.headlineMedium?.copyWith(
                                   fontWeight: FontWeight.w900,
                                   color: theme.colorScheme.primary,
                                 ),
                               ),
                               if (widget.product.type == 'Rent') 
                                 Padding(
                                   padding: const EdgeInsets.only(left: 4.0),
                                   child: Text('/ day', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                 ),
                             ],
                           ),
                         ),
                       ),
                       const Spacer(),
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.product.condition,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
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
                         color: theme.colorScheme.secondary.withValues(alpha: 0.05),
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
                       ),
                       child: Row(
                         children: [
                           Icon(Icons.info_outline, color: theme.colorScheme.secondary, size: 20),
                           const SizedBox(width: 8),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   "Rental Details",
                                   style: theme.textTheme.bodyMedium?.copyWith(
                                     fontWeight: FontWeight.bold,
                                     color: theme.colorScheme.onSecondaryContainer,
                                   ),
                                 ),
                                 Text(
                                   "Deposit required: RM ${widget.product.rentalDeposit.toStringAsFixed(2)}",
                                   style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
                                 ),
                                 Text(
                                   "Max Duration: ${widget.product.maxRentalDuration} days",
                                   style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
                                 ),
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
                           color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                           borderRadius: BorderRadius.circular(8),
                           border: Border.all(color: theme.colorScheme.tertiary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                               Icon(Icons.eco, color: theme.colorScheme.tertiary, size: 18),
                               const SizedBox(width: 8),
                               Text(
                                   "Eco-Impact: Saves ${widget.product.co2Saved} kg CO2e",
                                   style: theme.textTheme.bodySmall?.copyWith(
                                     color: theme.colorScheme.onTertiaryContainer,
                                     fontWeight: FontWeight.bold,
                                   ),
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
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(alpha: 0.03),
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
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
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
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)
                              ),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    widget.product.sellerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star_rounded, size: 16, color: theme.colorScheme.secondary),
                                      const SizedBox(width: 2),
                                      Text(
                                        widget.product.sellerTotalReviews == 0
                                            ? 'No Rating (${widget.product.sellerTotalReviews})'
                                            : '${widget.product.sellerReputation.toStringAsFixed(1)} (${widget.product.sellerTotalReviews})',
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  ReputationBadge(
                                    completedTransactionsCount: widget.product.sellerTotalReviews,
                                    score: widget.product.sellerReputation,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant)
                      ],
                    ),
                  ),
                  ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.1),

                  const SizedBox(height: 32),
                  // Seller Portfolio
                  if (_sellerProducts.isNotEmpty) ...[
                      Text("More from ${widget.product.sellerName}", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: theme.colorScheme.outlineVariant)
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
                                                            : Container(color: theme.colorScheme.surfaceContainer),
                                                    ),
                                                ),
                                                Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                            Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                                                            Text('RM ${item.price.toStringAsFixed(0)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
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
                  Text('Description', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.6),
                  ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
                  
                  const SizedBox(height: 32),
                  // Similar Items Section
                  if (_similarProducts.isNotEmpty) ...[
                      Text("Similar Items Recommended", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: theme.colorScheme.outlineVariant)
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
                                                            : Container(color: theme.colorScheme.surfaceContainer),
                                                    ),
                                                ),
                                                Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                            Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                                                            Text('RM ${item.price.toStringAsFixed(0)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
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
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
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
                  label: const Text('Edit Listing'),
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
                    label: const Text('Remove'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.errorContainer,
                      foregroundColor: theme.colorScheme.onErrorContainer,
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
                     if (UserSession().isLoggedIn) {
                        ApiClient().post('/recommendations/track', {
                           'product_id': widget.product.id,
                           'type': 'message'
                        }).catchError((_) {});
                     }
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
                  child: const Text('Chat'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => widget.product.type == 'Rent'
                      ? _showBuyConfirmation(context)
                      : _showMakeOfferConfirmation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.product.type == 'Rent' ? theme.colorScheme.primary : Colors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.product.type == 'Rent' ? 'Rent Now' : 'Make Offer',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          );
  }

  void _deleteProduct() async {
      final theme = Theme.of(context);
      final confirm = await showDialog(
          context: context, 
          builder: (context) => AlertDialog(
              title: Text("Delete Listing?", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              content: const Text("Are you sure you want to remove this item? This cannot be undone."),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete", style: TextStyle(color: theme.colorScheme.error))),
              ],
          )
      );

      if (confirm == true) {
          try {
              final apiClient = ApiClient();
              await apiClient.delete('/products/${widget.product.id}');
              if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Listing deleted successfully!"),
                      backgroundColor: theme.colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context); // Go back
              }
          } catch (e) {
              if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to delete: ${_getFriendlyErrorMessage(e)}"),
                      backgroundColor: theme.colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
              }
          }
      }
  }

  String _getFriendlyErrorMessage(dynamic e) {
    final message = e.toString();
    if (message.contains('SocketException') || message.contains('Connection error') || message.contains('Failed host lookup')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    if (message.contains('TimeoutException') || message.contains('Connection timed out')) {
      return 'Connection timed out. Please check your network and try again.';
    }
    return message.replaceAll(RegExp(r'^Exception:\s*'), '').replaceAll(RegExp(r'^ApiException:\s*'), '');
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  void _toggleSave() async {
      final session = UserSession();
      if (!session.isLoggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Login to save items'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ));
          return;
      }

      setState(() {
         _isSaved = !_isSaved; 
         _favoriteCount += _isSaved ? 1 : -1;
         if (_favoriteCount < 0) _favoriteCount = 0;
      });

      try {
         final apiClient = ApiClient();
         final res = await apiClient.post('/saved/toggle', {
           'product_id': widget.product.id
         });

         if (res is Map && res['favorite_count'] != null && mounted) {
           setState(() {
             _favoriteCount = int.tryParse(res['favorite_count'].toString()) ?? _favoriteCount;
           });
         }
         
         if (_isSaved) {
             apiClient.post('/recommendations/track', {
                'product_id': widget.product.id,
                'type': 'save'
             });
         }

      } catch (e) {
         setState(() {
           _isSaved = !_isSaved;
           _favoriteCount += _isSaved ? 1 : -1;
           if (_favoriteCount < 0) _favoriteCount = 0;
         });
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

  void _showMakeOfferConfirmation(BuildContext context) {
    if (!UserSession().isLoggedIn) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
         content: Text('Please login first'),
         behavior: SnackBarBehavior.floating,
       ));
       return;
    }

    final theme = Theme.of(context);
    final offerPriceController = TextEditingController(text: widget.product.price.toStringAsFixed(2));
    String? selectedLocation = _selectedLocation;
    if (_campusLocations.isNotEmpty && !_campusLocations.contains(selectedLocation)) {
        selectedLocation = _campusLocations.first;
    }
    final List<String> availablePaymentMethods = widget.product.acceptedPaymentMethods.isNotEmpty
        ? widget.product.acceptedPaymentMethods
        : ['Cash'];

    String? selectedPaymentMethod = availablePaymentMethods.isNotEmpty ? availablePaymentMethods.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  left: 24, 
                  right: 24, 
                  top: 24, 
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Make a Custom Offer', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    Text("Your Proposed Offer Price (RM)", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: offerPriceController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your offer price',
                        prefixText: 'RM ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),

                    Text("Select Meetup Location", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outline),
                            borderRadius: BorderRadius.circular(12)
                        ),
                        child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                                value: selectedLocation,
                                isExpanded: true,
                                items: _campusLocations.map((loc) => DropdownMenuItem(
                                    value: loc,
                                    child: Row(
                                        children: [
                                            Icon(Icons.location_on, color: theme.colorScheme.primary, size: 18),
                                            const SizedBox(width: 8),
                                            Text(loc, style: theme.textTheme.bodyMedium),
                                        ],
                                    )
                                )).toList(),
                                onChanged: (val) {
                                    if (val != null) {
                                        setModalState(() {
                                            selectedLocation = val;
                                            _selectedLocation = val;
                                        });
                                    }
                                }
                            ),
                        ),
                    ),
                    const SizedBox(height: 16),

                    Text("Select Payment Method (Accepted by Seller)", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outline),
                            borderRadius: BorderRadius.circular(12)
                        ),
                        child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                                value: selectedPaymentMethod,
                                isExpanded: true,
                                hint: const Text('Select payment method'),
                                items: availablePaymentMethods.map((method) => DropdownMenuItem(
                                    value: method,
                                    child: Row(
                                        children: [
                                            Icon(
                                                method == 'Cash' 
                                                    ? Icons.money_outlined 
                                                    : (method == 'TNG' ? Icons.account_balance_wallet_outlined : Icons.account_balance_outlined), 
                                                color: theme.colorScheme.primary, 
                                                size: 18
                                            ),
                                            const SizedBox(width: 8),
                                            Text(method, style: theme.textTheme.bodyMedium),
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

                    Text('Offer Summary:', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: widget.product.imageUrl.isNotEmpty 
                            ? CachedNetworkImage(imageUrl: widget.product.imageUrl, width: 60, height: 60, fit: BoxFit.cover)
                            : Container(width: 60, height: 60, color: theme.colorScheme.surfaceContainer),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.product.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(
                                'Proposed Offer: RM ${(double.tryParse(offerPriceController.text) ?? widget.product.price).toStringAsFixed(2)}',
                                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.orange[800], fontWeight: FontWeight.bold)
                              ),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 12, color: theme.colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Meetup: ${selectedLocation ?? _selectedLocation}',
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
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
                          final double? enteredPrice = double.tryParse(offerPriceController.text);
                          if (enteredPrice == null || enteredPrice <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('Please enter a valid price greater than 0'),
                                  backgroundColor: Colors.red,
                              ));
                              return;
                          }
                          if (selectedPaymentMethod == null || !availablePaymentMethods.contains(selectedPaymentMethod)) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('Please select one of the seller\'s accepted payment methods.'),
                                  backgroundColor: Colors.red,
                              ));
                              return;
                          }
                          Navigator.pop(context); // Close the bottom sheet first
                          _buyNow(
                            context,
                            enteredPrice,
                            paymentMethod: selectedPaymentMethod,
                            meetupLocation: selectedLocation,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isBuying
                            ? Center(child: CircularProgressIndicator(color: theme.colorScheme.onPrimary))
                            : const Text('Submit Offer'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBuyConfirmation(BuildContext context) {
    if (!UserSession().isLoggedIn) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
         content: Text('Please login first'),
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
        final List<String> availablePaymentMethods = widget.product.acceptedPaymentMethods.isNotEmpty
            ? widget.product.acceptedPaymentMethods
            : ['Cash'];
        String? selectedPaymentMethod = availablePaymentMethods.isNotEmpty ? availablePaymentMethods.first : null;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
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
                Text(isRent ? 'Confirm Rental' : 'Confirm Purchase', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // Location Selector (FYP Map Requirement)
                Text("Select Meetup Location", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
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
                                        Icon(Icons.location_on, color: theme.colorScheme.primary, size: 18),
                                        const SizedBox(width: 8),
                                        Text(loc, style: theme.textTheme.bodyMedium),
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
                Text("Select Payment Method (Accepted by Seller)", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(12)
                    ),
                    child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                            value: selectedPaymentMethod,
                            isExpanded: true,
                            hint: const Text('Select payment method'),
                            items: availablePaymentMethods.map((method) => DropdownMenuItem(
                                value: method,
                                child: Row(
                                    children: [
                                        Icon(
                                            method == 'Cash' 
                                                ? Icons.money_outlined 
                                                : (method == 'TNG' ? Icons.account_balance_wallet_outlined : Icons.account_balance_outlined), 
                                            color: theme.colorScheme.primary, 
                                            size: 18
                                        ),
                                        const SizedBox(width: 8),
                                        Text(method, style: theme.textTheme.bodyMedium),
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
                   Text("Select Rental Period", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                                       content: Text('Maximum rental duration is ${widget.product.maxRentalDuration} days!'),
                                       backgroundColor: theme.colorScheme.error,
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
                         border: Border.all(color: theme.colorScheme.outline),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text(
                             _rentStartDate != null && _rentEndDate != null
                                 ? '${_rentStartDate!.toString().split(' ')[0]} to ${_rentEndDate!.toString().split(' ')[0]}'
                                 : 'Tap to select dates',
                             style: theme.textTheme.bodyMedium?.copyWith(
                               color: _rentStartDate != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                             ),
                           ),
                           Icon(Icons.calendar_today, size: 18, color: theme.colorScheme.primary),
                         ],
                       ),
                     ),
                   ),
                   const SizedBox(height: 16),
                 ],
                
                Text(isRent ? 'Rental Summary:' : 'Product Summary:', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                 const SizedBox(height: 8),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: widget.product.imageUrl.isNotEmpty 
                        ? CachedNetworkImage(imageUrl: widget.product.imageUrl, width: 60, height: 60, fit: BoxFit.cover)
                        : Container(width: 60, height: 60, color: theme.colorScheme.surfaceContainer),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.product.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (isRent) ...[
                            Text(
                              'RM ${widget.product.rentalPricePerDay.toStringAsFixed(2)} / day',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)
                            ),
                              if (_rentStartDate != null && _rentEndDate != null)
                                Text(
                                  'Total ($rentDays days): RM ${totalRentCost.toStringAsFixed(2)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)
                                ),
                          ] else ...[
                            Text(
                                'RM ${widget.product.price.toStringAsFixed(2)}', 
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)
                            ),
                          ],
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 12, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Meetup: $_selectedLocation',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
                    onPressed: (_isBuying || (isRent && (_rentStartDate == null || _rentEndDate == null))) ? null : () {
                      _buyNow(
                        context, 
                        isRent ? totalRentCost : widget.product.price,
                        rentStartDate: _rentStartDate,
                        rentEndDate: _rentEndDate,
                        paymentMethod: selectedPaymentMethod,
                        meetupLocation: _selectedLocation,
                      ); 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isBuying
                        ? Center(child: CircularProgressIndicator(color: theme.colorScheme.onPrimary))
                        : const Text('Confirm & Schedule'),
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

  void _buyNow(BuildContext context, double finalPrice, {DateTime? rentStartDate, DateTime? rentEndDate, String? paymentMethod, String? meetupLocation}) async {
      final theme = Theme.of(context);
      setState(() => _isBuying = true);
      try {
        final apiClient = ApiClient();
        
        final Map<String, dynamic> payload = {
            'buyer_id': UserSession().userId, 
            'seller_id': widget.product.sellerId, 
            'product_id': widget.product.id,
            'amount': finalPrice, // Use dynamically calculated price
            'meetup_location': meetupLocation ?? _selectedLocation, // Use selected location
            'selected_payment_method': paymentMethod ?? 'Cash'
        };

        if (widget.product.type == 'Rent' && rentStartDate != null && rentEndDate != null) {
            payload['rental_start_date'] = rentStartDate.toIso8601String();
            payload['rental_end_date'] = rentEndDate.toIso8601String();
        }

        await apiClient.post('/transactions', payload);

        // Record 'buy' interaction (+10 points) for popularity score tracking
        apiClient.post('/recommendations/track', {
           'product_id': widget.product.id,
           'type': 'buy'
        }).catchError((_) {});

        
        if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.product.type == 'Rent' ? 'Rental Request Sent!' : 'Purchase Request Sent!'),
                backgroundColor: theme.colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              )
            );
            Navigator.pop(context);
        }
      } catch (e) {
          if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
               content: Text('Failed: ${_getFriendlyErrorMessage(e)}'),
               backgroundColor: theme.colorScheme.error,
               behavior: SnackBarBehavior.floating,
             ));
          }
      } finally {
          if (mounted) setState(() => _isBuying = false);
      }
  }

  int _currentImageIndex = 0;

  Widget _buildImageGallery(Product product) {
    final theme = Theme.of(context);
    List<String> images = product.imageUrls.isNotEmpty 
        ? product.imageUrls 
        : (product.imageUrl.isNotEmpty ? [product.imageUrl] : []);
    
    if (images.isEmpty) {
        return Container(
            color: theme.colorScheme.surfaceContainer,
            child: Icon(Icons.image_not_supported, size: 64, color: theme.colorScheme.onSurfaceVariant),
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
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageViewer(
                      imageUrls: images,
                      initialIndex: index,
                    ),
                  ),
                );
              },
              child: CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: theme.colorScheme.surfaceContainer),
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
                    color: theme.colorScheme.onSurface.withValues(alpha: _currentImageIndex == entry.key ? 0.9 : 0.4),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
