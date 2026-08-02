import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRent = product.type.toLowerCase() == 'rent';
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.outlineVariant : Colors.grey[200]!, width: 1),
        ),
        color: Theme.of(context).cardTheme.color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Badges
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                   product.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.grey[200],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        )
                      : Container(
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 40,
                          ),
                        ),
                      ),
                  
                  // Top Left Badge: FOR RENT or FOR SALE
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isRent ? const Color(0xFF00C875) : const Color(0xFF337BFF), // Green for rent, Blue for sale
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isRent ? 'FOR RENT' : 'FOR SALE',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Top Right Badge: Favorite Heart & Counter
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: Theme.of(context).brightness == Brightness.dark 
                            ? [] 
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                      ),
                      child: InkWell(
                        onTap: onFavoriteToggle,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                              size: 16, 
                              color: isFavorite ? Colors.red : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF1E293B))
                            ),
                            if (product.favoriteCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${product.favoriteCount}',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isFavorite ? Colors.red : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF1E293B)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Details Section
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Price and Condition Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price
                        Expanded(
                          child: FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: isRent 
                                        ? 'RM ${product.rentalPricePerDay.toStringAsFixed(2)}'
                                        : 'RM ${product.price.toStringAsFixed(0)}',
                                    style: GoogleFonts.outfit(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  if (isRent)
                                    TextSpan(
                                      text: ' /day',
                                      style: GoogleFonts.outfit(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Condition Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.condition,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    Divider(color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.outlineVariant : Colors.grey[200], height: 1),
                    const SizedBox(height: 8),
                    
                    // Bottom Row: Avatar, Name, Location, Time
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: primaryColor.withValues(alpha: 0.1),
                          backgroundImage: product.sellerAvatar.isNotEmpty
                              ? NetworkImage(product.sellerAvatar)
                              : null,
                          child: product.sellerAvatar.isEmpty
                              ? Text(
                                 product.sellerName.isNotEmpty ? product.sellerName[0].toUpperCase() : '?',
                                 style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.bold),
                               )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      product.sellerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                                  Text(
                                    product.sellerReputation.toStringAsFixed(1),
                                    style: GoogleFonts.outfit(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatTimeAgo(product.postedAt),
                          style: GoogleFonts.outfit(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
